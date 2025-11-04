import 'package:flutter/material.dart';
import 'package:aromaku/models/perfume.dart';
import 'package:aromaku/services/session_manager.dart'; 
import 'package:aromaku/db/database_helper.dart'; 
import 'package:intl/intl.dart'; 

class ProductDetailScreen extends StatelessWidget {
  final Perfume perfume;

  const ProductDetailScreen({super.key, required this.perfume});

  void _addToCart(BuildContext context) async {
    try {
      int? userId = await SessionManager().getUserId();
      if (userId == null) {
        throw Exception("User tidak ditemukan, silakan login ulang.");
      }
      await DatabaseHelper().upsertCartItem(userId, perfume.id);

      if (context.mounted) {
        // --- LOGIKA SNACKBAR (POSISI TENGAH) ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${perfume.name} ditambahkan ke keranjang!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.purple.shade700,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height / 2, 
              left: 20,
              right: 20,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // ---------------------------------------------
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- WIDGET HELPER UNTUK CHIP TAG ---
  Widget _buildTagChips(List<String> tags) {
    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: tags.map((tag) => Chip(
        label: Text(tag, style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: Colors.purple.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(perfume.name, overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. BAGIAN GAMBAR
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.purple.shade50, // Latar belakang ringan
            ),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [ // Bayangan elegan
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    perfume.image,
                    height: 280,
                    width: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, color: Colors.grey, size: 100);
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // 2. BAGIAN DETAIL & DESKRIPSI (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAMA & KATEGORI
                  Text(
                    perfume.name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Brand: ${perfume.category}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                  
                  const SizedBox(height: 15),

                  // TAGS/AROMA
                  _buildTagChips(perfume.tags),

                  const SizedBox(height: 25),

                  // DESKRIPSI
                  const Text(
                    'Deskripsi Aroma:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    perfume.description,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black54),
                  ),
                  
                  const SizedBox(height: 80), // Padding ekstra sebelum tombol
                ],
              ),
            ),
          ),
        ],
      ),
      
      // 3. BAGIAN HARGA & TOMBOL (Fixed di Bawah)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // HARGA
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Harga Total:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                Text(
                  'Rp ${NumberFormat("#,##0", "id_ID").format(perfume.price)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.purple),
                ),
              ],
            ),
            const SizedBox(width: 20),
            
            // TOMBOL
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: const Text('Tambah ke Keranjang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () => _addToCart(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}