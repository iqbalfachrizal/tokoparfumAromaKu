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

  String _deliveryAddress = "Pilih lokasi pengiriman...";
  String? _selectedLatitude;
  String? _selectedLongitude;

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

  Future<void> _selectDeliveryLocation() async {
    if (_cartItems.isEmpty) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MapSelectionScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      if (mounted) {
        setState(() {
          _deliveryAddress = result['address'] ?? "Lokasi Tidak Dikenal";
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

  Future<void> _launchWhatsApp() async {
    if (_userId == null) return;
    
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
    
    final String mapsUrl = 
      "https://www.google.com/maps/search/?api=1&query=$_selectedLatitude,$_selectedLongitude";
    
    message += "\n\nAlamat Kirim:\n $_deliveryAddress";
    message += "\nLink Maps (Klik untuk navigasi):\n $mapsUrl"; 

    final String waUrl = "https://wa.me/$waNumber?text=${Uri.encodeComponent(message)}";

    try {
      await _notificationService.showInstantNotification(
        1,
        'Terima Kasih',
        'Pesanan telah dibuat. Mohon segera konfirmasi ke owner via WhatsApp.',
      );
      
      await _dbHelper.clearCart(_userId!);
      _loadData(); 

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
        color = Colors.deepPurple;
      } else {
        icon = Icons.flag_circle;
        color = Colors.purple.shade600;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0), 
        child: Row(
          children: [
            Icon(icon, size: 16, color: color), 
            const SizedBox(width: 8), 
            Text('$zone:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800)), 
            const Spacer(),
            Text(time, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isCheckoutDisabled = _cartItems.isEmpty || _isLoading || _selectedLatitude == null;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header dengan Gradien
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade400,
                    Colors.deepPurple.shade600,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Keranjang Saya',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Keranjang Anda masih kosong',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            final itemTotalPrice = item.perfume.price * item.quantity;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.purple.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.shade100,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        color: Colors.white,
                                        child: Image.network(
                                          item.perfume.image,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 80, height: 80, color: Colors.grey[200],
                                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.perfume.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Harga: Rp ${NumberFormat("#,##0", "id_ID").format(item.perfume.price)}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Total: Rp ${NumberFormat("#,##0", "id_ID").format(itemTotalPrice)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                                          onPressed: () => _removeItem(item),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.purple.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () => _updateQuantity(item, item.quantity - 1),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  child: const Icon(Icons.remove, color: Colors.red, size: 18),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(
                                                  '${item.quantity}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.deepPurple,
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () => _updateQuantity(item, item.quantity + 1),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  child: const Icon(Icons.add, color: Colors.green, size: 18),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.currency_exchange, color: Colors.purple.shade600, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Mata Uang',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedCurrency,
                                dropdownColor: Colors.deepPurple.shade400,
                                underline: const SizedBox(),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                items: ['IDR', 'USD', 'EUR', 'JPY', 'SGD'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: _rates == null ? null : (newValue) {
                                  setState(() {
                                    _selectedCurrency = newValue!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        Divider(height: 24, color: Colors.grey.shade300),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.purple.shade600, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Waktu Global',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._buildTimeRows(),
                          ],
                        ),

                        Divider(height: 24, color: Colors.grey.shade300),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.purple.shade600, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Lokasi Pengiriman',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _cartItems.isEmpty ? null : _selectDeliveryLocation,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _selectedLatitude == null
                                        ? [Colors.grey.shade200, Colors.grey.shade300]
                                        : [Colors.green.shade100, Colors.green.shade200],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedLatitude == null ? Colors.red.shade200 : Colors.green.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedLatitude == null ? Icons.wrong_location : Icons.location_on,
                                      size: 24,
                                      color: _selectedLatitude == null ? Colors.red : Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _deliveryAddress,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: _selectedLatitude == null ? Colors.grey.shade700 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.shade50,
                          Colors.deepPurple.shade100,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Belanja:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _isLoading ? "Memuat..." : _getConvertedPrice(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCheckoutDisabled
                                  ? [Colors.grey.shade400, Colors.grey.shade500]
                                  : [Colors.green.shade400, Colors.green.shade600],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: isCheckoutDisabled
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.green.shade200,
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat, size: 24),
                            label: const Text(
                              'Beli via WhatsApp',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            onPressed: isCheckoutDisabled ? null : _launchWhatsApp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
