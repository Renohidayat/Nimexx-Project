import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  TextStyle get _titleStyle => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: Color(0xFF2c3e50),
  );

  TextStyle get _headingStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Color(0xFF2980b9),
    height: 1.4,
  );

  TextStyle get _normalStyle =>
      const TextStyle(fontSize: 16, color: Color(0xFF34495e), height: 1.6);

  TextStyle get _highlightStyle => const TextStyle(
    fontSize: 16,
    color: Color(0xFFe74c3c),
    fontWeight: FontWeight.w600,
  );

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28.0, bottom: 12),
      child: Text(title, style: _headingStyle),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3, right: 8),
            child: Icon(Icons.circle, size: 8, color: Color(0xFF2980b9)),
          ),
          Expanded(child: Text(text, style: _normalStyle)),
        ],
      ),
    );
  }

  Widget _highlightBox(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAEDF0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kebijakan Privasi Nimexx",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFe74c3c),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kebijakan Privasi", style: _titleStyle),
            const SizedBox(height: 8),
            const Text(
              "Terakhir diperbarui: 1 Juli 2025",
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _highlightBox(
              Text(
                "Nimexx (\"kami\", \"kita\", atau \"milik kita\") berkomitmen untuk melindungi privasi Anda. "
                "Dokumen ini menjelaskan bagaimana informasi pribadi pengguna dikumpulkan, digunakan, dan dilindungi "
                "dalam aplikasi mobile dan web kami.",
                style: _normalStyle.copyWith(height: 1.7),
              ),
            ),

            _sectionTitle("1. Ruang Lingkup"),
            _bullet("Aplikasi Flutter Nimexx (Android/iOS)"),
            _bullet("Situs web Nimexx dan subdomain terkait"),
            _bullet(
              "Semua fitur termasuk streaming anime, komentar, sistem notifikasi, dan panel admin",
            ),

            _sectionTitle("2. Data yang Kami Kumpulkan"),
            _bullet(
              "Data Akun: Email, nama pengguna, dan foto profil (opsional)",
            ),
            _bullet(
              "Data Aktivitas: Riwayat tonton, daftar anime, komentar, dan pencarian",
            ),
            _bullet("Data Teknis: Alamat IP, tipe perangkat, versi aplikasi"),

            _sectionTitle("3. Keamanan Data"),
            _bullet("Enkripsi data transit (SSL/TLS)"),
            _bullet("Aturan keamanan Firebase yang ketat"),
            _bullet("Autentikasi berbasis OAuth 2.0"),

            _sectionTitle("4. Panel Admin"),
            _bullet("Moderasi komentar dan balasan"),
            _bullet("Manajemen pengguna (blokir/reset)"),
            _bullet("Statistik bulanan dan laporan"),
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: Text(
                "Admin tidak dapat melihat password pengguna.",
                style: _normalStyle.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),

            _sectionTitle("5. Persetujuan Pengguna"),
            _bullet("Penyimpanan riwayat tonton selama 1 tahun"),
            _bullet("Pemrosesan komentar dan notifikasi"),
            _bullet("Penggunaan cookie untuk pengalaman optimal"),

            _sectionTitle("Hak Pengguna"),
            _highlightBox(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bullet("Meminta penghapusan akun"),
                  _bullet("Mengekspor data pribadi"),
                  _bullet("Menonaktifkan riwayat pencarian"),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      text: "Permohonan dapat dikirim ke: ",
                      style: _normalStyle,
                      children: [
                        TextSpan(
                          text: "nimexx45@gmail.com",
                          style: _highlightStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _sectionTitle("6. Sekilas Teknologi"),
            _bullet("API Otakudesu: Hanya untuk konten anime"),
            _bullet("Firebase: Database realtime dan autentikasi"),
            _bullet("Cloud Functions: Proses notifikasi dan komentar"),

            _sectionTitle("7. Perubahan Kebijakan"),
            _bullet("Notifikasi in-app"),
            _bullet("Pembaruan di halaman ini"),
            _bullet("Email (untuk perubahan signifikan)"),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEAEDF0), width: 1),
                ),
              ),
              child: Text(
                "Versi 1.0 - Berlaku efektif sejak 1 Juli 2025",
                style: _normalStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7f8c8d),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
