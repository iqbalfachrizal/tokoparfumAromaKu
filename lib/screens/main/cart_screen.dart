import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aromaku/models/cart_item.dart';
import 'package:aromaku/models/perfume.dart';
import 'package:aromaku/services/session_manager.dart';
import 'package:aromaku/db/database_helper.dart';
import 'package:aromaku/api/api_service.dart';
import 'package:aromaku/services/notification_service.dart'; 
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

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

  // Variabel untuk Timer
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _loadData();
    _startTimer(); // <-- Mulai Timer
  }

  @override
  void dispose() {
    _timer?.cancel(); // <-- Hentikan Timer saat Widget ditutup
    super.dispose();
  }
  
  // --- FUNGSI UNTUK MEMULAI TIMER ---
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Panggil setState setiap 1 detik untuk memperbarui waktu
      if(mounted) {
        setState(() {});
      }
    });
  }
  // ------------------------------------

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

  Future<void> _launchWhatsApp() async {
    if (_userId == null) return;
    
    const String waNumber = "6285600924354"; 
    String message = "Halo Admin AromaKu, saya ingin memesan:\n\n";
    for (var item in _cartItems) {
      message += "✅ ${item.perfume.name} (Qty: ${item.quantity})\n";
    }
    message += "\nTotal: ${_getConvertedPrice()} ($_selectedCurrency)";
    
    final String waUrl = "https://wa.me/$waNumber?text=${Uri.encodeComponent(message)}";

    try {
      
      // 1. TAMPILKAN NOTIFIKASI INSTAN
      await _notificationService.showInstantNotification(
        1,
        'Terima Kasih',
        'Mohon segera konfirmasi ke owner by wa untuk selanjutnya',
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
  
  // --- FUNGSI UNTUK DISPLAY WAKTU INDIVIDUAL ---
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
  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding DIKURANGI LAGI
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.currency_exchange, color: Colors.purple, size: 18), // Ukuran ikon DIKURANGI
                          SizedBox(width: 8),
                          Text('Total dalam Mata Uang', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), // Ukuran font DIKURANGI
                        ],
                      ),
                      DropdownButton<String>(
                        value: _selectedCurrency,
                        items: ['IDR', 'USD', 'EUR', 'JPY', 'SGD'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12)), // Ukuran font DIKURANGI
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
                
                // 2. PEMISAH
                Divider(height: 1, color: Colors.grey.shade300),
                
                // 3. WAKTU OPERASIONAL
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waktu Toko Global (WIB, WITA, WIT)', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87) // Ukuran font DIKURANGI
                      ),
                      const SizedBox(height: 4),
                      ..._buildTimeRows(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- BAGIAN TOTAL BELANJA
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
                    onPressed: _cartItems.isEmpty || _isLoading ? null : _launchWhatsApp,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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