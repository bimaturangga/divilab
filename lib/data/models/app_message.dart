/// Pesan notifikasi di tab "Pesan" (tabel `messages`).
/// Dibuat otomatis saat hasil pengukuran di luar rentang normal atau strip habis.
class AppMessage {
  const AppMessage({
    this.id,
    required this.ownerId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final int? id;
  final int ownerId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  Map<String, Object?> toMap() => {
        'id': id,
        'owner_id': ownerId,
        'title': title,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'read': read ? 1 : 0,
      };

  factory AppMessage.fromMap(Map<String, Object?> m) => AppMessage(
        id: m['id'] as int?,
        ownerId: m['owner_id'] as int,
        title: m['title'] as String,
        body: m['body'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        read: (m['read'] as int) == 1,
      );
}
