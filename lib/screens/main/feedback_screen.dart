import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saran dan Kesan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER MATA KULIAH ---
            const Center(
              child: Text(
                'Mata Kuliah: Pemrograman Aplikasi Mobile',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.purple,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.purpleAccent,
                  decorationThickness: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),

            // --- KARTU KESAN ---
            _buildFeedbackCard(
              context,
              icon: Icons.sentiment_very_satisfied,
              title: 'Kesan (Impression):',
              content:
                  'Mata kuliah ini sangat membuka wawasan saya mengenai pengembangan aplikasi mobile, terutama dengan Flutter. Kemampuan untuk membuat aplikasi Android dari satu codebase sangat efisien. Menurut saya, materi yang diberikan (terutama koneksi database, API, dan LBS) sangat relevan dengan kebutuhan industri saat ini sehingga nantinya bisa menjadi bekal saya setelah lulus kuliah',
              iconColor: Colors.green.shade600,
              cardColor: Colors.purple.shade50,
            ),
            
            const SizedBox(height: 20),

            // --- KARTU SARAN ---
            _buildFeedbackCard(
              context,
              icon: Icons.lightbulb_outline,
              title: 'Saran (Suggestion):',
              content:
                  'Mungkin untuk kedepannya, metode pengajaran sedikit memadukan teori dan praktik. Setiap penyampaian konsep, disarankan sesekali dengan demonstrasi live coding singkat. Hal ini akan sangat membantu mahasiswa dalam menerapkan materi secara langsung',
              iconColor: Colors.blue.shade600,
              cardColor: Colors.purple.shade50,
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'Terima kasih atas bimbingannya!',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER UNTUK MEMBANGUN KARTU ---
  Widget _buildFeedbackCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
    required Color cardColor,
  }) {
    return Card(
      elevation: 6,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.purple.shade200, width: 1.5), // Border ungu tipis
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul dengan Ikon
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.purple.shade900,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1), // Garis pemisah
            
            // Isi Kesan/Saran
            Text(
              content,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 16, 
                height: 1.5, 
                color: Colors.grey.shade800
              ),
            ),
          ],
        ),
      ),
    );
  }
}