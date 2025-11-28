// map_selection_screen.dart (VERSI PERBAIKAN AKHIR)

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:geolocator/geolocator.dart'; // <<< BARU

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  // Koordinat awal (Jakarta, Indonesia)
  static const LatLng _initialCenter = LatLng(-6.2000, 106.8166);
  LatLng _selectedLocation = _initialCenter;
  String _currentAddress = "Menentukan lokasi...";
  
  // State baru untuk Geolocator
  bool _isLocating = true;
  String? _locationError;
  
  // MapController untuk mengontrol peta
  final MapController _mapController = MapController(); 
  
  // Controller untuk fitur pencarian
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Panggil fungsi lokasi terkini saat layar dibuka
    _determinePosition(); 
  }
  
  // --- FUNGSI 1: MENDAPATKAN LOKASI TERKINI (GEOLOCATOR) ---
  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah layanan GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) {
        setState(() {
          _isLocating = false;
          _locationError = 'Layanan lokasi dinonaktifkan.';
        });
      }
      return;
    }

    // Cek dan minta izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if(mounted) {
          setState(() {
            _isLocating = false;
            _locationError = 'Izin lokasi ditolak.';
          });
        }
        return;
      }
    }
    
    // Jika semua OK, ambil posisi
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _selectedLocation = currentLatLng;
          _isLocating = false;
          _locationError = null;
        });
        // Pindahkan peta ke lokasi baru
        _mapController.move(currentLatLng, 15.0); 
        _getAddressFromLatLng(currentLatLng);
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _isLocating = false;
          _locationError = 'Gagal mendapatkan lokasi: ${e.toString()}';
        });
      }
    }
  }

  // --- FUNGSI 2: MENDAPATKAN ALAMAT DARI KOORDINAT (REVERSE GEOCODING) ---
  Future<void> _getAddressFromLatLng(LatLng point) async {
    setState(() {
      _currentAddress = "Mencari alamat...";
    });
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude, 
        point.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _currentAddress = 
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
        });
      } else {
        setState(() {
          _currentAddress = "Alamat tidak ditemukan (Koordinat: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Gagal mengambil alamat: $e";
        });
      }
    }
  }
  
  // --- FUNGSI 3: PENCARIAN LOKASI (FORWARD GEOCODING) ---
  void _searchLocation(String query) async {
    if (query.isEmpty) return;
    
    try {
      setState(() => _currentAddress = "Mencari lokasi untuk '$query'...");
      
      // Menggunakan locationFromAddress dari package geocoding
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng newPoint = LatLng(location.latitude, location.longitude);
        
        if (mounted) {
          setState(() {
            _selectedLocation = newPoint;
          });
          _mapController.move(newPoint, 15.0); // Pindahkan peta
          _getAddressFromLatLng(newPoint); // Perbarui alamat di panel bawah
        }
      } else {
        if (mounted) {
          setState(() => _currentAddress = "Pencarian gagal: Alamat tidak ditemukan.");
        }
      }
      FocusScope.of(context).unfocus(); // Sembunyikan keyboard setelah pencarian
    } catch (e) {
        if (mounted) {
          setState(() => _currentAddress = "Error saat mencari: ${e.toString()}");
        }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Pengiriman'),
        actions: [
          // Tombol untuk memuat ulang atau kembali ke lokasi terkini
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _determinePosition, 
            tooltip: 'Lokasi Terkini',
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. PETA
          FlutterMap(
            mapController: _mapController, // Gunakan MapController
            options: MapOptions(
              // Lokasi awal akan diatur oleh MapController
              initialCenter: _selectedLocation, 
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                // Saat peta diklik, perbarui lokasi yang dipilih
                setState(() {
                  _selectedLocation = point;
                });
                _getAddressFromLatLng(point);
              },
            ),
            children: [
              // Tile Layer OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.arunika', 
              ),
              // Marker untuk lokasi yang dipilih
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: _selectedLocation,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // 2. SEARCH BAR (Fitur Pencarian)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari alamat atau tempat...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _searchLocation(_searchController.text),
                    ),
                  ),
                  onSubmitted: _searchLocation, // Pencarian saat menekan enter
                ),
              ),
            ),
          ),
          
          // 3. PEMBERITAHUAN LOKASI TERKINI / ERROR
          if (_isLocating) 
            const Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Chip(
                  label: Text('Mencari lokasi terkini...'),
                  backgroundColor: Colors.blueAccent,
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            )
          else if (_locationError != null)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Chip(
                  label: Text(_locationError!),
                  backgroundColor: Colors.redAccent,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          
          // 4. Informasi Alamat & Tombol Konfirmasi
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lokasi yang Dipilih:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(_currentAddress, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Konfirmasi Lokasi Ini'),
                      onPressed: () {
                        // Kembalikan data lengkap ke layar sebelumnya
                        Navigator.of(context).pop({
                          'latitude': _selectedLocation.latitude.toString(),
                          'longitude': _selectedLocation.longitude.toString(),
                          'address': _currentAddress,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}