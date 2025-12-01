import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  final String role;      // "admin" o "worker"
  final String userId;    // uid del usuario logueado

  const NotificationBell({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final now = Timestamp.now();

    final query = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetRole', whereIn: ['all', role])
        .where('scheduledAt', isLessThanOrEqualTo: now)
        .orderBy('scheduledAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          );
        }

        final docs = snapshot.data!.docs;

        // No leídas = las que no tienen al userId en readBy
        final unread = docs.where((doc) {
          final data = doc.data();
          final List readBy = (data['readBy'] ?? []) as List;
          return !readBy.contains(userId);
        }).length;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {
                _showNotificationsSheet(context, docs, userId);
              },
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationsSheet(
      BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      String userId,
      ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No tienes notificaciones por ahora.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final title = data['title'] ?? '';
            final body = data['body'] ?? '';
            final ts = data['scheduledAt'] as Timestamp?;
            final date = ts?.toDate();
            final List readBy = (data['readBy'] ?? []) as List;
            final isRead = readBy.contains(userId);

            return ListTile(
              leading: Icon(
                isRead
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_active_rounded,
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: date == null
                  ? null
                  : Text(
                '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11),
              ),
              onTap: () async {
                // marcar como leída
                await doc.reference.update({
                  'readBy': FieldValue.arrayUnion([userId]),
                });
              },
            );
          },
        );
      },
    );
  }
}
