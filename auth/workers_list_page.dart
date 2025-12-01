import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../stats/worker_stats_page.dart';

class WorkersListPage extends StatelessWidget {
  const WorkersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'worker');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trabajadores registrados'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No hay trabajadores registrados.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name = (data['name'] ?? '') as String;
              final email = (data['email'] ?? '') as String;
              final phone = (data['phone'] ?? '') as String? ?? '';
              final active = (data['active'] ?? true) as bool;

              // Si el doc tiene workerId lo usamos, si no usamos el id del documento
              final workerId =
              (data['workerId'] ?? doc.id).toString().trim();

              final displayName =
              name.isEmpty ? '(Sin nombre)' : name.trim();

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(displayName),
                subtitle: Text(
                  [
                    if (email.isNotEmpty) email,
                    if (phone.isNotEmpty) 'Tel: $phone',
                  ].join(' · '),
                ),
                trailing: Chip(
                  label: Text(active ? 'Activo' : 'Inactivo'),
                  backgroundColor: active
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: active ? Colors.green[800] : Colors.red[800],
                  ),
                ),
                onTap: () {
                  // 👉 Al tocar un trabajador abrimos sus movimientos
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerStatsPage(
                        workerId: workerId,
                        workerName: displayName,
                      ),
                    ),
                  );
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}
