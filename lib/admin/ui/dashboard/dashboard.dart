import 'package:flutter/material.dart';
import '../../../../public/services/ticket_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = TicketService().getAllAdminReports();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final reports = snapshot.data ?? [];
        int total = reports.length;
        int disposedCount = 0;
        int pendingCount = 0;
        int bioCount = 0;
        int nonBioCount = 0;
        Map<String, int> locationsMap = {};

        for (var data in reports) {
          // Status check
          if (data['status'] == 'Disposed') {
            disposedCount++;
          } else {
            pendingCount++;
          }

          // Prediction category check
          final topPred = data['top_prediction'] as Map<String, dynamic>? ?? {};
          if (topPred['category'] == 'bio') {
            bioCount++;
          } else {
            nonBioCount++;
          }

          // Location tally
          final loc = data['location'] as String? ?? 'Unknown';
          locationsMap[loc] = (locationsMap[loc] ?? 0) + 1;
        }

        // Top 3 locations sorted by waste count
        final topLocations = (locationsMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
            .take(3)
            .toList();

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Waste Management Summary",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 20),

                // 📊 TICKET STATUS CARDS
                Row(
                  children: [
                    statusCard("Pending", pendingCount, Colors.blue, Icons.hourglass_empty),
                    const SizedBox(width: 15),
                    statusCard("Disposed", disposedCount, Colors.green, Icons.check_circle_outline),
                  ],
                ),
                const SizedBox(height: 20),

                // ♻️ CATEGORY BREAKDOWN (VISUAL GRAPH)
                cardContainer(
                  title: "Waste Analytics Breakdown",
                  icon: Icons.bar_chart_outlined,
                  child: Column(
                    children: [
                      const Text(
                        "Comparison of Waste Types",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            barWidget("Bio", bioCount, total, Colors.green),
                            barWidget("Non-Bio", nonBioCount, total, Colors.orange),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 📍 TOP WASTE LOCATIONS... (rest remains similar)
                cardContainer(
                  title: "Top Waste Locations",
                  icon: Icons.location_on_outlined,
                  child: Column(
                    children: topLocations.isEmpty
                        ? [const Text("No location data available")]
                        : topLocations.map((entry) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade50,
                          radius: 14,
                          child: Text(
                            "${topLocations.indexOf(entry) + 1}",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(entry.key, style: const TextStyle(fontSize: 14)),
                        trailing: Text(
                          "${entry.value} reports",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget barWidget(String label, int count, int total, Color color) {
    double percent = total == 0 ? 0 : count / total;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("$count", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 5),
        Container(
          width: 40,
          height: (percent * 80).clamp(5, 80).toDouble(),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget statusCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget cardContainer({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ],
          ),
          const Divider(height: 30),
          child,
        ],
      ),
    );
  }

  Widget categoryProgress(String label, int count, int total, Color color) {
    double percent = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text("$count reports (${(percent * 100).toStringAsFixed(1)}%)"),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: color.withOpacity(0.1),
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}