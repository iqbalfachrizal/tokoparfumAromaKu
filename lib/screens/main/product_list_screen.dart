import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:arunika/api/api_service.dart';
import 'package:arunika/models/perfume.dart';
import 'package:arunika/screens/main/product_detail_screen.dart';
import 'package:arunika/services/location_service.dart';
import 'package:intl/intl.dart'; 

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  List<Perfume> _allPerfumes = [];
  List<Perfume> _displayedPerfumes = [];
  bool _isLoading = true;
  String _weatherInfo = 'Mendapatkan data cuaca...';
  String _recommendationText = ''; 

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _searchController.addListener(_filterPerfumes);
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _weatherInfo = 'Mendapatkan data cuaca...';
      _recommendationText = ''; 
    });
    
    await Future.wait([
      _fetchLocationAndWeather(),
      _fetchProducts(),
    ]);
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchProducts() async {
    try {
      final perfumes = await _apiService.getPerfumes();
      setState(() {
        _allPerfumes = perfumes;
        _displayedPerfumes = perfumes;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchLocationAndWeather() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      String weather = await _apiService.getWeather(position.latitude, position.longitude);
      
      String recommendation = ""; 
      String weatherLower = weather.toLowerCase(); 

      if(weatherLower.contains("cerah") || weatherLower.contains("panas")) {
        recommendation = "Rekomendasi: Coba cari parfum 'fresh' atau 'citrus'!";
      } else if (weatherLower.contains("hujan") || weatherLower.contains("dingin")) {
        recommendation = "Rekomendasi: Coba cari parfum 'woody' atau 'spicy'!";
      } else if (weatherLower.contains("awan") || weatherLower.contains("mendung")) {
        recommendation = "Rekomendasi: Parfum 'floral' atau 'woody' pilihan pas!";
      }

      setState(() {
        _weatherInfo = weather; 
        _recommendationText = recommendation; 
      });
    } catch (e) {
      setState(() {
        _weatherInfo = 'Gagal mendapatkan info cuaca.';
        _recommendationText = 'Coba refresh untuk rekomendasi.';
      });
    }
  }

  void _filterPerfumes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _displayedPerfumes = _allPerfumes.where((perfume) {
        final nameMatch = perfume.name.toLowerCase().contains(query);
        final categoryMatch = perfume.category.toLowerCase().contains(query);
        final tagMatch = perfume.tags.any((tag) => tag.toLowerCase().contains(query)); 

        return nameMatch || categoryMatch || tagMatch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: RefreshIndicator(
          onRefresh: _fetchAllData,
          child: Column(
            children: [
              // Header dengan Gradien
              Container(
                width: double.infinity,
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'arunika',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Weather Info Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _weatherInfo,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_recommendationText.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _recommendationText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Search Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari parfum...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Products Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _displayedPerfumes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Produk tidak ditemukan',
                                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.65,
                            ),
                            itemCount: _displayedPerfumes.length,
                            itemBuilder: (context, index) {
                              final perfume = _displayedPerfumes[index];
                              return _buildPerfumeCard(perfume);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagChips(List<String> tags) {
    final tagsToShow = tags.take(2).toList();
    
    return Wrap(
      spacing: 4.0,
      runSpacing: 2.0,
      children: tagsToShow.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.deepPurple.shade400],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          tag,
          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      )).toList(),
    );
  }

  Widget _buildPerfumeCard(Perfume perfume) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Colors.purple.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(perfume: perfume),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.purple.shade50,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Image.network(
                    perfume.image,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, color: Colors.grey, size: 40);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfume.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildTagChips(perfume.tags),
                    const SizedBox(height: 6),
                    Text(
                      perfume.category,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rp ${NumberFormat("#,##0", "id_ID").format(perfume.price)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
