import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ticket_service.dart';

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  final TicketService _ticketService = TicketService();
  bool _isClassifying = false;

  // ─────────────────────────────────────────
  // PICK IMAGE → CLASSIFY → SHOW RESULT → SAVE IN BACKGROUND
  // ─────────────────────────────────────────
  Future<void> _handleImage(ImageSource source) async {
    Navigator.pop(context);

    // 1️⃣ Open Camera or Gallery IMMEDIATELY
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70, // compress for faster upload
      maxWidth: 640,
      maxHeight: 640,
    );
    if (picked == null) return;

    // 2️⃣ Start loading spinner
    setState(() => _isClassifying = true);

    String? locationStr;

    // 3️⃣ Gather Location AFTER taking photo so it feels smoother
    if (source == ImageSource.camera) {
      try {
        final position = await _ticketService.getLocation();
        locationStr = "${position.latitude}, ${position.longitude}";
      } catch (e) {
        locationStr = "GPS Unavailable";
      }
    } else {
      // If gallery, prompt for location entry
      final controller = TextEditingController();
      locationStr = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("Enter Location"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "E.g., Central Park, NY",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );
      if (locationStr == null || locationStr.isEmpty) {
        setState(() => _isClassifying = false);
        return; // User cancelled
      }
    }

    try {
      // ⚡ Step 4: classify & save to backend
      final result = await _ticketService.classifyOnly(picked, location: locationStr);
      if (!mounted) return;
      setState(() => _isClassifying = false);

      // ✅ Show result immediately
      _showResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isClassifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ─────────────────────────────────────────
  // RESULT DIALOG
  // ─────────────────────────────────────────
  void _showResult(ClassificationResult result) {
    final isBio = result.category == 'bio';
    final isUnknown = result.category == 'unknown';
    
    final categoryColor = isUnknown ? Colors.grey : (isBio ? Colors.green : Colors.orange);
    final categoryIcon = isUnknown ? Icons.help_outline : (isBio ? Icons.eco : Icons.delete_outline);
    final categoryLabel = isUnknown ? 'Unknown Waste' : (isBio ? 'Biodegradable' : 'Non-Biodegradable');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: categoryColor.withOpacity(0.15),
                    child: Icon(categoryIcon, color: categoryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Classification Result",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          categoryLabel,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Top Detection ────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: categoryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Top Detection",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: result.confidence,
                        minHeight: 10,
                        backgroundColor: categoryColor.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          categoryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${(result.confidence * 100).toStringAsFixed(1)}% confidence",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // ── Bio / Non-Bio Summary ────────────────────
              if (result.totalDetections > 0) ...[
                const SizedBox(height: 16),
                const Text(
                  "Detection Summary",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Bio bar
                    Expanded(
                      child: _summaryTile(
                        label: "🌿 Bio",
                        count: result.bioCount,
                        percent: result.bioPercent,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Non-bio bar
                    Expanded(
                      child: _summaryTile(
                        label: "🗑️ Non-Bio",
                        count: result.nonBioCount,
                        percent: result.nonBioPercent,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Total detections: ${result.totalDetections}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],

              // ── All Detections ───────────────────────────
              if (result.predictions.length > 1) ...[
                const SizedBox(height: 16),
                const Text(
                  "All Detections",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...result.predictions.take(5).map((p) {
                  final conf = (p['confidence'] as num).toDouble();
                  final cat = p['category'] as String? ?? 'non_bio';
                  final barColor = cat == 'bio' ? Colors.green : Colors.orange;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            p['label'] as String,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: conf,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                barColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${(conf * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Small summary tile widget ──────────────
  Widget _summaryTile({
    required String label,
    required int count,
    required double percent,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$count items",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            "$percent%",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // BOTTOM SHEET
  // ─────────────────────────────────────────
  void _showOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Select Image Source",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text("Take Photo"),
              subtitle: const Text("Use your camera"),
              onTap: () => _handleImage(ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.image, color: Colors.white),
              ),
              title: const Text("Choose from Gallery"),
              subtitle: const Text("Upload an existing image"),
              onTap: () => _handleImage(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Report Waste",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: _isClassifying
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 24),
                  const Text(
                    "Classifying waste...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sending image to AI model",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 100,
                    color: Colors.green.shade200,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Report Waste in Your Area",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Take or upload a photo to classify\nand report waste automatically",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _showOptions,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text("Report Waste"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _isClassifying
          ? null
          : FloatingActionButton(
              onPressed: _showOptions,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            ),
    );
  }
}
