import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ticket_service.dart';

class Mycontributions extends StatefulWidget {
  const Mycontributions({super.key});

  @override
  State<Mycontributions> createState() => _MycontributionsState();
}

class _MycontributionsState extends State<Mycontributions> {
  final user = FirebaseAuth.instance.currentUser;
  late final Future<List<Map<String, dynamic>>> _reportsFuture;
  int totalPoints = 0;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      final safeId = (user!.email != null && user!.email!.isNotEmpty)
          ? user!.email!
          : user!.uid;
      _reportsFuture = TicketService().getReports(safeId);

      // Listen to gamification points
      FirebaseFirestore.instance
          .collection('public')
          .where('email', isEqualTo: safeId)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.docs.isNotEmpty && mounted) {
              setState(() {
                totalPoints = snapshot.docs.first.data()['points'] ?? 0;
              });
            }
          });
    } else {
      _reportsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "My Reports",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 4),
                Text(
                  "$totalPoints Pts",
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("Please log in to view your reports."))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                final reports = snapshot.data ?? [];

                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "You haven't submitted any reports yet.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final data = reports[index];
                    final topPred =
                        data['top_prediction'] as Map<String, dynamic>? ?? {};

                    final imgId = data['id'] as String? ?? '';
                    final safeId =
                        (user!.email != null && user!.email!.isNotEmpty)
                        ? user!.email!
                        : user!.uid;
                    // The backend static file path: /user_data/{user_email}/{img_id}.jpg
                    final imageUrl =
                        '$kBackendUrl/user_data/$safeId/$imgId.jpg';

                    final location =
                        data['location'] as String? ?? 'Location not provided';

                    final label = topPred['label'] as String? ?? 'Unknown';
                    final category =
                        topPred['category'] as String? ?? 'unknown';
                    final confidence =
                        (topPred['confidence'] as num?)?.toDouble() ?? 0.0;

                    final summary =
                        data['summary'] as Map<String, dynamic>? ?? {};
                    final totalDetections =
                        summary['total_detections'] as int? ?? 0;

                    final isBio = category == 'bio';
                    final catColor = isBio ? Colors.green : Colors.orange;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imgId.isNotEmpty)
                            Image.network(
                              imageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        label.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Chip(
                                      backgroundColor: catColor.withOpacity(
                                        0.15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: catColor.withOpacity(0.5),
                                        ),
                                      ),
                                      label: Text(
                                        isBio ? "Bio" : "Non-Bio",
                                        style: TextStyle(
                                          color: catColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Confidence: ${(confidence * 100).toStringAsFixed(1)}%",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.scatter_plot_outlined,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Detections: $totalDetections",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: data['status'] == 'Disposed'
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        data['status'] == 'Disposed'
                                            ? Icons.check_circle
                                            : Icons.info_outline,
                                        size: 14,
                                        color: data['status'] == 'Disposed'
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Status: ${data['status'] ?? 'pending'}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: data['status'] == 'Disposed'
                                              ? Colors.green
                                              : Colors.blue,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
