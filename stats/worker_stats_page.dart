import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WorkerStatsPage extends StatelessWidget {
  final String workerId;
  final String workerName;

  const WorkerStatsPage({
    super.key,
    required this.workerId,
    required this.workerName,
  });

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('production_records')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Movimientos de $workerName'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error al cargar datos: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];

          // 🔎 Filtra por workerId O por workerName
          final docs = allDocs.where((doc) {
            final data = doc.data();
            final wid = (data['workerId'] ?? '').toString();
            final wname = (data['workerName'] ?? '').toString();
            final idMatch =
                workerId.isNotEmpty && wid.isNotEmpty && wid == workerId;
            final nameMatch =
                workerName.isNotEmpty && wname.isNotEmpty && wname == workerName;
            return idMatch || nameMatch;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Este trabajador aún no tiene movimientos registrados.',
              ),
            );
          }

          // 👉 Totales
          int added = 0;
          int subtracted = 0;

          for (final doc in docs) {
            final data = doc.data();
            final type = (data['type'] ?? 'add') as String;
            final quantity = (data['quantity'] ?? 0) as int;

            if (type == 'add') {
              added += quantity;
            } else {
              subtracted += quantity;
            }
          }

          final net = added - subtracted;

          final maxY = [added, subtracted, net.abs()]
              .fold<int>(0, (prev, e) => e > prev ? e : prev)
              .toDouble();
          final chartMaxY = maxY == 0 ? 10.0 : maxY * 1.2;

          final barGroups = <BarChartGroupData>[
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: added.toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: subtracted.toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ];

          return Column(
            children: [
              // ---------- RESUMEN + GRÁFICA ----------
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _StatChip(label: 'Total sumado', value: added),
                        _StatChip(label: 'Total restado', value: subtracted),
                        _StatChip(label: 'Total neto', value: net),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          maxY: chartMaxY,
                          barGroups: barGroups,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0:
                                      return const Text('Sumado',
                                          style: TextStyle(fontSize: 10));
                                    case 1:
                                      return const Text('Restado',
                                          style: TextStyle(fontSize: 10));
                                    default:
                                      return const SizedBox.shrink();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ---------- LISTA DE MOVIMIENTOS ----------
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final productName =
                    (data['productName'] ?? 'Sin producto') as String;
                    final type = (data['type'] ?? 'add') as String;
                    final quantity = (data['quantity'] ?? 0) as int;
                    final reason = (data['reason'] ?? '') as String;
                    final shift = (data['shift'] ?? '') as String;

                    final createdAt = data['createdAt'];
                    String dateStr = '';
                    if (createdAt is Timestamp) {
                      dateStr =
                          createdAt.toDate().toString().split('.').first;
                    }

                    final isAdd = type == 'add';
                    final sign = isAdd ? '+' : '-';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          productName.isNotEmpty
                              ? productName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(productName),
                      subtitle: Text([
                        if (reason.isNotEmpty) reason,
                        if (shift.isNotEmpty) 'Turno: $shift',
                        if (dateStr.isNotEmpty) dateStr,
                      ].join(' · ')),
                      trailing: Text(
                        '$sign$quantity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAdd ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}
