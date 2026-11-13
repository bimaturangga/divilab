import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../core/health.dart';
import '../../core/utils/date_fmt.dart';
import '../models/chat_message.dart';
import '../models/measurement.dart';

/// Ringkasan data kesehatan profil aktif yang dikirim sebagai konteks
/// ke asisten, supaya jawabannya berdasarkan data pengguna sendiri.
class HealthSnapshot {
  const HealthSnapshot({required this.profileName, required this.measurements});

  final String profileName;
  final List<Measurement> measurements; // urut terbaru dulu

  List<Measurement> ofType(MeasurementType t, {int days = 7}) {
    final from = DateTime.now().subtract(Duration(days: days));
    return measurements.where((m) => m.type == t && m.measuredAt.isAfter(from)).toList();
  }

  Measurement? latest(MeasurementType t) {
    for (final m in measurements) {
      if (m.type == t) return m;
    }
    return null;
  }

  String toPrompt() {
    final b = StringBuffer('Profil: $profileName\n');
    for (final t in MeasurementType.values) {
      final list = ofType(t);
      final last = latest(t);
      if (last == null) {
        b.writeln('- ${t.label}: belum ada data');
        continue;
      }
      b.write('- ${t.label}: terakhir ${last.displayValue} ${t.unit} (${last.status.label}, ${DateFmt.dateTime(last.measuredAt)})');
      if (list.length > 1 && t != MeasurementType.bloodPressure) {
        final avg = list.map((e) => e.value).reduce((a, b) => a + b) / list.length;
        b.write('; rata-rata 7 hari ${fmtNum(avg)} dari ${list.length} pengukuran');
      }
      b.writeln();
    }
    return b.toString();
  }
}

/// Asisten kesehatan.
/// - Jika `GEMINI_API_KEY` diberikan lewat --dart-define, memakai Gemini API.
/// - Jika tidak (atau gagal), memakai jawaban offline berbasis aturan
///   dari data SQLite, sehingga fitur tetap berjalan saat demo.
class AssistantService {
  AssistantService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _system =
      'Kamu adalah "Asisten DiVi", asisten kesehatan di aplikasi DiViLab. Jawab dalam Bahasa Indonesia yang ramah, '
      'singkat (maksimal 120 kata), dan berdasarkan data pengguna yang diberikan. Jangan mendiagnosis penyakit; '
      'sarankan konsultasi dokter bila hasil di luar rentang normal. Rentang normal: gula darah sewaktu 70–139 mg/dL, '
      'puasa 70–100, kolesterol total 100–200 mg/dL, asam urat 3–7 mg/dL, tekanan darah 90–139/60–89 mmHg.';

  Future<String> reply({required List<ChatMessage> history, required HealthSnapshot snapshot}) async {
    final question = history.last.text;
    if (!AppConfig.hasAssistantKey) return LocalAssistant.answer(question, snapshot);
    try {
      return await _gemini(history, snapshot);
    } catch (_) {
      return '${LocalAssistant.answer(question, snapshot)}\n\n(Mode offline: asisten AI sedang tidak dapat dihubungi.)';
    }
  }

  Future<String> _gemini(List<ChatMessage> history, HealthSnapshot snapshot) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${AppConfig.geminiModel}:generateContent',
    );
    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': 'Data kesehatan saya (dari aplikasi):\n${snapshot.toPrompt()}'},
        ],
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'Baik, saya akan menjawab berdasarkan data tersebut.'},
        ],
      },
      for (final m in history.where((m) => !m.isError).toList().reversed.take(10).toList().reversed)
        {
          'role': m.fromUser ? 'user' : 'model',
          'parts': [
            {'text': m.text},
          ],
        },
    ];
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': AppConfig.geminiApiKey},
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': _system},
              ],
            },
            'contents': contents,
            'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 512},
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('Gemini ${res.statusCode}');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) throw Exception('Jawaban kosong');
    final parts = ((candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>)['parts'] as List<dynamic>;
    final text = parts.map((p) => (p as Map<String, dynamic>)['text'] ?? '').join().trim();
    if (text.isEmpty) throw Exception('Jawaban kosong');
    return text;
  }
}

/// Jawaban offline berbasis kata kunci + data pengukuran.
class LocalAssistant {
  LocalAssistant._();

  static String answer(String question, HealthSnapshot s) {
    final q = question.toLowerCase();
    if (q.contains('gula') || q.contains('glukosa') || q.contains('diabetes')) {
      return _summary(s, MeasurementType.glucose,
          tip: 'Batasi minuman manis, perbanyak sayur dan serat, dan ukur ulang 2 jam setelah makan untuk melihat respons gula darah Anda.');
    }
    if (q.contains('kolesterol')) {
      return _summary(s, MeasurementType.cholesterol,
          tip: 'Kurangi gorengan dan lemak jenuh, pilih ikan atau kacang-kacangan, dan rutin berolahraga 30 menit sehari.');
    }
    if (q.contains('urat') || q.contains('asam')) {
      return _summary(s, MeasurementType.uricAcid,
          tip: 'Perbanyak minum air putih, kurangi jeroan, seafood, dan minuman manis berfruktosa tinggi.');
    }
    if (q.contains('tensi') || q.contains('tekanan') || q.contains('darah tinggi') || q.contains('hipertensi')) {
      return _summary(s, MeasurementType.bloodPressure,
          tip: 'Kurangi garam, kelola stres, cukup tidur, dan ukur di waktu yang sama setiap hari dalam posisi duduk tenang.');
    }
    if (q.contains('strip') || q.contains('pasang') || q.contains('alat') || q.contains('perangkat')) {
      return 'Cara memakai DiViLab Optima:\n'
          '1. Nyalakan perangkat dan aktifkan Bluetooth di ponsel.\n'
          '2. Tekan tombol + lalu pilih "Menggunakan Perangkat".\n'
          '3. Masukkan strip sesuai jenis pengukuran sampai berbunyi.\n'
          '4. Teteskan darah ke ujung strip, tunggu hasil muncul (±5 detik).\n'
          '5. Cabut strip dan tunggu hitungan selesai sebelum memasang strip baru.';
    }
    if (q.contains('halo') || q.contains('hai') || q.contains('hi ')) {
      return 'Halo, ${s.profileName}! Ada yang ingin Anda ketahui tentang hasil pengukuran hari ini?';
    }
    return 'Saya bisa membantu menjelaskan hasil gula darah, kolesterol, asam urat, dan tekanan darah Anda, '
        'atau cara memakai perangkat DiViLab. Coba tanyakan misalnya "Bagaimana gula darah saya minggu ini?".';
  }

  static String _summary(HealthSnapshot s, MeasurementType t, {required String tip}) {
    final last = s.latest(t);
    if (last == null) {
      return 'Belum ada data ${t.label.toLowerCase()} untuk ${s.profileName}. Lakukan pengukuran terlebih dahulu, lalu tanyakan lagi.';
    }
    final week = s.ofType(t);
    final b = StringBuffer();
    if (t == MeasurementType.bloodPressure) {
      b.write('Tekanan darah terakhir ${s.profileName} ${last.displayValue} mmHg');
      if (last.pulse != null) b.write(' dengan denyut ${last.pulse} bpm');
      b.write(' (${last.status.label.toLowerCase()}). ');
    } else {
      b.write('Hasil ${t.label.toLowerCase()} terakhir ${last.displayValue} ${t.unit} (${last.status.label.toLowerCase()}). ');
      if (week.length > 1) {
        final values = week.map((e) => e.value).toList();
        final avg = values.reduce((a, c) => a + c) / values.length;
        final hi = values.reduce((a, c) => a > c ? a : c);
        b.write('Rata-rata 7 hari terakhir ${fmtNum(avg)} ${t.unit} dari ${week.length} pengukuran, tertinggi ${fmtNum(hi)}. ');
      }
    }
    final abnormal = week.where((m) => m.status != HealthStatus.normal).length;
    if (last.status == HealthStatus.normal && abnormal == 0) {
      b.write('Semuanya masih dalam rentang normal 👍 ');
    } else {
      b.write('Ada hasil di luar rentang normal, sebaiknya konsultasikan dengan dokter. ');
    }
    b.write('\n\nTips: $tip');
    return b.toString();
  }
}
