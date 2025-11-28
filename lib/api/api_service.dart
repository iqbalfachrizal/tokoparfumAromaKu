import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:arunika/models/perfume.dart';

class ApiService {
  // -----------------------
  // API Key (Pastikan valid)
  // -----------------------
  final String _weatherApiKey = '85913f240e56747ec7a6779f8bdaf022';
  final String _currencyApiKey = '393ba081046187a146374d4f';

  final String _fakeStoreApiBaseUrl =
      'https://my-json-server.typicode.com/iqbalfachrizal/fakeapiparfum/parfums';

  // ===========================================================
  // GET: Data Parfum (dari API saya di GitHub)
  // ===========================================================
  Future<List<Perfume>> getPerfumes() async {
    try {
      final response = await http.get(Uri.parse(_fakeStoreApiBaseUrl));

      if (response.statusCode == 200) {
        // Decode JSON list
        List<dynamic> jsonList = json.decode(response.body);

        // Mapping ke model Perfume
        return jsonList.map((json) => Perfume.fromMap(json)).toList();
      } else {
        throw Exception(
            'Gagal memuat parfum. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server parfum: ${e.toString()}');
    }
  }

  // ===========================================================
  // GET: Cuaca (API OpenWeather)
  // ===========================================================
  Future<String> getWeather(double lat, double lon) async {
    if (_weatherApiKey.isEmpty) {
      return 'API Key Cuaca belum diatur';
    }

    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_weatherApiKey&units=metric&lang=id';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String weatherMain = data['weather'][0]['description'];
        double temp = data['main']['temp'];
        return 'Cuaca: $weatherMain ($temp°C)';
      }
      return 'Gagal mendapatkan data cuaca.';
    } catch (e) {
      return 'Gagal terhubung ke server cuaca.';
    }
  }

  // ===========================================================
  // GET: Nilai Tukar Mata Uang (ExchangeRate API)
  // ===========================================================
  Future<Map<String, dynamic>?> getExchangeRates() async {
    if (_currencyApiKey.isEmpty) {
      return null;
    }

    final url =
        'https://v6.exchangerate-api.com/v6/$_currencyApiKey/latest/IDR';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body)['conversion_rates'];
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
