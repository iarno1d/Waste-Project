import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

// ⚠️ Change to your backend URL
// Local dev  : 'http://localhost:8000'
// Android emu: 'http://10.0.2.2:8000'
const String kBackendUrl = 'http://localhost:8000';

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────

class ClassificationResult {
  final String label;
  final double confidence;
  final String category; // "bio" or "non_bio"
  final List<Map<String, dynamic>> predictions;
  final Map<String, dynamic> summary;

  ClassificationResult({
    required this.label,
    required this.confidence,
    required this.category,
    required this.predictions,
    required this.summary,
  });

  int get totalDetections =>
      (summary['total_detections'] as num?)?.toInt() ?? 0;
  int get bioCount => (summary['bio_count'] as num?)?.toInt() ?? 0;
  int get nonBioCount => (summary['non_bio_count'] as num?)?.toInt() ?? 0;
  double get bioPercent =>
      (summary['bio_percentage'] as num?)?.toDouble() ?? 0.0;
  double get nonBioPercent =>
      (summary['non_bio_percentage'] as num?)?.toDouble() ?? 0.0;
}

// ─────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────

class TicketService {
  // 📍 LOCATION
  Future<Position> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services disabled");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // 🎫 TICKET ID
  String generateTicketId() => "TKT-${DateTime.now().millisecondsSinceEpoch}";




  // ─────────────────────────────────────────
  // 🤖 STEP 1 — Classify only (fast, shown to user immediately)
  // ─────────────────────────────────────────
  Future<ClassificationResult> classifyOnly(XFile imageFile, {String? location}) async {
    final bytes = await imageFile.readAsBytes();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$kBackendUrl/predict'),
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final safeId = (user.email != null && user.email!.isNotEmpty)
          ? user.email!
          : user.uid;
      request.fields['user_id'] = safeId;
    }
    if (location != null && location.isNotEmpty) {
      request.fields['location'] = location;
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception(
        "Backend timeout — is Python server running on $kBackendUrl?",
      ),
    );

    final response = await http.Response.fromStream(streamedResponse);

    // 🐛 Debug — check browser / terminal console
    print('=== Backend response ===');
    print('Status : ${response.statusCode}');
    print('Body   : ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // ✅ top_prediction
    final top = (data['top_prediction'] as Map?)?.cast<String, dynamic>() ?? {};

    // ✅ predictions list
    final predictions = ((data['predictions'] as List?) ?? [])
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();

    // ✅ summary
    final summary = (data['summary'] as Map?)?.cast<String, dynamic>() ?? {};

    return ClassificationResult(
      label: (top['label'] as String?) ?? 'Unknown',
      confidence: (top['confidence'] as num?)?.toDouble() ?? 0.0,
      category: (top['category'] as String?) ?? 'unknown',
      predictions: predictions,
      summary: summary,
    );
  }

  // ─────────────────────────────────────────
  // 💾 GET REPORTS FROM BACKEND (USER OR ADMIN)
  // ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getReports(String folderId) async {
    final response = await http.get(Uri.parse('$kBackendUrl/reports/$folderId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['reports'] as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load user reports');
    }
  }

  Future<List<Map<String, dynamic>>> getAllAdminReports() async {
    final response = await http.get(Uri.parse('$kBackendUrl/admin/reports'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['reports'] as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load admin reports');
    }
  }

  // ─────────────────────────────────────────
  // 🏷️ UPDATE STATUS
  // ─────────────────────────────────────────
  Future<void> updateTicketStatus(String userEmail, String ticketId, String status) async {
    final response = await http.put(
      Uri.parse('$kBackendUrl/admin/reports/$userEmail/$ticketId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update ticket status');
    }
  }

  // ─────────────────────────────────────────
  // 🏆 AWARD POINTS
  // ─────────────────────────────────────────
  static Future<void> awardPoints(String userEmail, int pointsToAdd) async {
    final query = await FirebaseFirestore.instance
        .collection('public')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;
      await docRef.update({
        'points': FieldValue.increment(pointsToAdd),
      });
    }
  }
}
