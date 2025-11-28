// cart_Screen.dart (Versi Final yang Diperbaiki)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:arunika/models/cart_item.dart';
import 'package:arunika/models/perfume.dart';
import 'package:arunika/services/session_manager.dart';
import 'package:arunika/db/database_helper.dart';
import 'package:arunika/api/api_service.dart';
import 'package:arunika/services/notification_service.dart'; 
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
// PASTIKAN PATH INI SESUAI DENGAN LOKASI FILE BARU ANDA!
// Jika file berada di folder 'screens', mungkin menjadi 'package:arunika/screens/map_selection_screen.dart';
import 'package:arunika/screens/main/map_selection_screen.dart'; 

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  int? _userId;

  Map<String, dynamic>? _rates;
  String _selectedCurrency = 'IDR';
  double _totalPrice = 0;

  // --- VARIABLE UNTUK LOKASI ---
  String _deliveryAddress = "Pilih lokasi pengiriman...";
  String? _selectedLatitude;
  String? _selectedLongitude;
  // ----------------------------------

  // Variabel untuk Timer
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _loadData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if(mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _userId = await SessionManager().getUserId();
      if (_userId == null) throw Exception("User tidak login");

      final results = await Future.wait([
        _apiService.getPerfumes(),
        _dbHelper.getCart(_userId!),
        _apiService.getExchangeRates(),
      ]);

      final allPerfumes = results[0] as List<Perfume>;
      final dbCart = results[1] as List<Map<String, dynamic>>;
      _rates = results[2] as Map<String, dynamic>?;

      List<CartItem> combinedItems = [];
      for (var dbItem in dbCart) {
        try {
          final perfume = allPerfumes.firstWhere(
            (p) => p.id == dbItem['productId'],
          );
          combinedItems.add(CartItem(
            perfume: perfume,
            quantity: dbItem['quantity'],
          ));
        } catch (e) {
          // Produk tidak ditemukan di API, abaikan
        }
      }

      setState(() {
        _cartItems = combinedItems;
        _calculateTotal(); 
        _isLoading = false;
      });

    } catch (e) {
      if(mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat keranjang: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      total += item.perfume.price * item.quantity;
    }
    setState(() {
      _totalPrice = total;
    });
  }
  
  void _updateQuantity(CartItem item, int newQuantity) async {
    if (_userId == null) return;
    try {
      if (newQuantity <= 0) {
        await _dbHelper.removeCartItem(_userId!, item.perfume.id);
      } else {
        await _dbHelper.updateCartItemQuantity(_userId!, item.perfume.id, newQuantity);
      }
      _loadData(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui kuantitas: ${e.toString()}'),
          backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeItem(CartItem item) async {
    if (_userId == null) return;
    try {
      await _dbHelper.removeCartItem(_userId!, item.perfume.id);
      _loadData(); 
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus item: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getConvertedPrice() {
    if (_rates == null) {
      _selectedCurrency = 'IDR';
      return 'Rp ${NumberFormat("#,##0", "id_ID").format(_totalPrice)}';
    }
    if (_selectedCurrency == 'IDR') {
      return 'Rp ${NumberFormat("#,##0", "id_ID").format(_totalPrice)}';
    }
    // Perlu pengecekan jika kunci tidak ada, kembali ke IDR
    if (!_rates!.containsKey(_selectedCurrency) || _rates![_selectedCurrency] == null) {
        return 'Rate error: IDR';
    }
    double rate = _rates![_selectedCurrency]; 
    double convertedTotal = _totalPrice * rate; 
    return NumberFormat.simpleCurrency(name: _selectedCurrency).format(convertedTotal);
  }

  String _getConvertedTime() {
    final now = tz.TZDateTime.now(tz.local);
    final format = DateFormat('HH:mm:ss');
    final wib = tz.TZDateTime.from(now, tz.getLocation('Asia/Jakarta'));
    final wita = tz.TZDateTime.from(now, tz.getLocation('Asia/Makassar'));
    final wit = tz.TZDateTime.from(now, tz.getLocation('Asia/Jayapura'));
    final london = tz.TZDateTime.from(now, tz.getLocation('Europe/London'));

    return '''
WIB: ${format.format(wib)}
WITA: ${format.format(wita)}
WIT: ${format.format(wit)}
London: ${format.format(london)}
      ''';
  }

  // --- FUNGSI PILIH LOKASI MENGGUNAKAN MAPS BARU (OpenStreetMap) ---
  Future<void> _selectDeliveryLocation() async {
    if (_cartItems.isEmpty) return;

    // Navigasi ke MapSelectionScreen dan tunggu hasilnya
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MapSelectionScreen(),
      ),
    );

    // Cek hasil yang dikembalikan dan pastikan tipe datanya benar
    if (result != null && result is Map<String, dynamic>) {
      if (mounted) {
        setState(() {
          // PERBAIKAN BARIS 204
          _deliveryAddress = result['address'] ?? "Lokasi Tidak Dikenal";
          // PERBAIKAN BARIS 205
          _selectedLatitude = result['latitude']; 
          _selectedLongitude = result['longitude'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lokasi dipilih: $_deliveryAddress')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemilihan lokasi dibatalkan.')),
        );
      }
    }
  }
  // ------------------------------------------------------------------


  Future<void> _launchWhatsApp() async {
    if (_userId == null) return;
    
    // CEK LOKASI DULU
    if (_selectedLatitude == null || _deliveryAddress == "Pilih lokasi pengiriman...") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon tentukan lokasi pengiriman terlebih dahulu!')),
        );
      }
      return;
    }

    const String waNumber = "6285600924354"; 
    String message = "Halo Admin arunika, saya ingin memesan:\n\n";
    for (var item in _cartItems) {
      message += "✅ ${item.perfume.name} (Qty: ${item.quantity})\n";
    }
    message += "\nTotal: ${_getConvertedPrice()} ($_selectedCurrency)";
    
    // TAMBAHKAN DETAIL LOKASI DAN TAUTAN GOOGLE MAPS YANG DAPAT DIKLIK
    // Kita gunakan format URL standar Google Maps untuk membuat link yang dapat diklik
    final String mapsUrl = 
      "https://www.google.com/maps/search/?api=1&query=$_selectedLatitude,$_selectedLongitude";
    
    message += "\n\nAlamat Kirim:\n $_deliveryAddress";
    message += "\nLink Maps (Klik untuk navigasi):\n $mapsUrl"; 

    final String waUrl = "https://wa.me/$waNumber?text=${Uri.encodeComponent(message)}";

    try {
      
      // 1. TAMPILKAN NOTIFIKASI INSTAN
      await _notificationService.showInstantNotification(
        1,
        'Terima Kasih',
        'Pesanan telah dibuat. Mohon segera konfirmasi ke owner via WhatsApp.',
      );
      
      // 2. HAPUS KERANJANG DI DB
      await _dbHelper.clearCart(_userId!);
      _loadData(); 

      // 3. BUKA WHATSAPP
      if (!await launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication)) {
        throw Exception('Tidak bisa membuka WhatsApp. Pastikan WhatsApp terinstall.');
      }
      
    } catch (e) {
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
         );
       }
    }
  }
  
  // FUNGSI UNTUK DISPLAY WAKTU INDIVIDUAL
  List<Widget> _buildTimeRows() {
    final timeData = _getConvertedTime().trim().split('\n');
    return timeData.map((line) {
      final parts = line.split(':');
      final zone = parts[0].trim();
      final time = parts.sublist(1).join(':').trim();
      
      IconData icon;
      Color color;

      if (zone == 'London') {
        icon = Icons.access_time_filled;
        color = Colors.blueGrey;
      } else {
        icon = Icons.flag_circle;
        color = Colors.amber.shade700;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.0), 
        child: Row(
          children: [
            Icon(icon, size: 14, color: color), 
            const SizedBox(width: 6), 
            Text('$zone:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), 
            const Spacer(),
            Text(time, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan apakah tombol WhatsApp harus dinonaktifkan
    bool isCheckoutDisabled = _cartItems.isEmpty || _isLoading || _selectedLatitude == null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData, 
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cartItems.isEmpty
                    ? const Center(
                        child: Text('Keranjang Anda masih kosong.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      )
                    : ListView.builder(
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          final itemTotalPrice = item.perfume.price * item.quantity;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. GAMBAR PRODUK
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.perfume.image,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 70, height: 70, color: Colors.grey[200],
                                            child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // 2. DETAIL NAMA & HARGA
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.perfume.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Harga Satuan: Rp ${NumberFormat("#,##0", "id_ID").format(item.perfume.price)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          // Harga Sub-Total Item
                                          Text(
                                            'Sub-total: Rp ${NumberFormat("#,##0", "id_ID").format(itemTotalPrice)}',
                                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.purple, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // 3. KONTROL KUANTITAS & HAPUS
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        // Tombol Hapus Penuh
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                                          onPressed: () => _removeItem(item),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(height: 10),
                                        // Kontrol Kuantitas
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Tombol KURANG
                                            InkWell(
                                              onTap: () => _updateQuantity(item, item.quantity - 1),
                                              child: const Icon(Icons.remove, color: Colors.red, size: 20),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            ),
                                            // Tombol TAMBAH
                                            InkWell(
                                              onTap: () => _updateQuantity(item, item.quantity + 1),
                                              child: const Icon(Icons.add, color: Colors.green, size: 20),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          Card(
            elevation: 4,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                // 1. HEADER MATA UANG
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.currency_exchange, color: Colors.purple, size: 18), 
                          SizedBox(width: 8),
                          Text('Total dalam Mata Uang', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), 
                        ],
                      ),
                      DropdownButton<String>(
                        value: _selectedCurrency,
                        items: ['IDR', 'USD', 'EUR', 'JPY', 'SGD'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12)), 
                          );
                        }).toList(),
                        onChanged: _rates == null ? null : (newValue) {
                          setState(() {
                            _selectedCurrency = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                Divider(height: 1, color: Colors.grey.shade300),
                
                // 2. WAKTU OPERASIONAL
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waktu Toko Global (WIB, WITA, WIT)', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87) 
                      ),
                      const SizedBox(height: 4),
                      ..._buildTimeRows(),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.grey.shade300),
                
                // 3. PEMILIHAN LOKASI PENGIRIMAN
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lokasi Pengiriman', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        // Memanggil MapSelectionScreen
                        onTap: _cartItems.isEmpty ? null : _selectDeliveryLocation, 
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 24, 
                              color: _selectedLatitude == null ? Colors.red : Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _deliveryAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _selectedLatitude == null ? Colors.grey.shade600 : Colors.black,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BAGIAN TOTAL BELANJA DAN TOMBOL CHECKOUT
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Belanja:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      _isLoading ? "Memuat..." : _getConvertedPrice(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Beli via WhatsApp', style: TextStyle(fontSize: 18)),
                    // Tombol dinonaktifkan jika keranjang kosong ATAU lokasi belum dipilih
                    onPressed: isCheckoutDisabled ? null : _launchWhatsApp,
                    style: ElevatedButton.styleFrom(backgroundColor: isCheckoutDisabled ? Colors.grey : Colors.green, foregroundColor: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}