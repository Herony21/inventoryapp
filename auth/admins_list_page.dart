import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminsListPage extends StatelessWidget {
  const AdminsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administradores'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay administradores registrados.'));
          }

          docs.sort((a, b) {
            final na = (a.data()['name'] ?? '') as String;
            final nb = (b.data()['name'] ?? '') as String;
            return na.compareTo(nb);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final name = (data['name'] ?? '') as String;
              final email = (data['email'] ?? '') as String;

              return ListTile(
                leading: const Icon(Icons.verified_user),
                title: Text(name),
                subtitle: Text(email),
              );
            },
          );
        },
      ),
    );
  }
}
