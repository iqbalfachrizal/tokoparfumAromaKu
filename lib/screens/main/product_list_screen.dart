import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aromaku/api/api_service.dart';
import 'package:aromaku/models/perfume.dart';
import 'package:aromaku/screens/main/product_detail_screen.dart';
import 'package:aromaku/services/location_service.dart';
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
      appBar: AppBar(
        title: const Text('AromaKu'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllData,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.purple.withOpacity(0.1),
              child: Column( 
                children: [
                  Text(
                    _weatherInfo, 
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)
                  ),
                  if (_recommendationText.isNotEmpty) 
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        _recommendationText, 
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.deepPurple, fontStyle: FontStyle.italic)
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Cari (nama, kategori, atau tag cth: fresh)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _displayedPerfumes.isEmpty
                      ? const Center(child: Text('Produk tidak ditemukan.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
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
    );
  }

  Widget _buildTagChips(List<String> tags) {
    final tagsToShow = tags.take(2).toList();
    
    return Wrap(
      spacing: 4.0, 
      runSpacing: 2.0,
      children: tagsToShow.map((tag) => Chip(
        label: Text(tag, style: const TextStyle(fontSize: 10, color: Colors.white)),
        backgroundColor: Colors.purple.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      )).toList(),
    );
  }

  Widget _buildPerfumeCard(Perfume perfume) {
    return Card( 
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(perfume: perfume),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8.0),
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
              padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perfume.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildTagChips(perfume.tags),
                  const SizedBox(height: 4),
                  Text(
                    perfume.category,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${NumberFormat("#,##0", "id_ID").format(perfume.price)}', 
                    style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 16),
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