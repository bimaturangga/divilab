/// Pesan di layar Tanya Asisten (disimpan di memori selama sesi).
class ChatMessage {
  ChatMessage({required this.text, required this.fromUser, DateTime? time, this.isError = false})
      : time = time ?? DateTime.now();

  final String text;
  final bool fromUser;
  final DateTime time;
  final bool isError;
}
