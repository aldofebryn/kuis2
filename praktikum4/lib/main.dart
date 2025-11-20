import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Sudah diwakili oleh PreferenceService
import 'package:intl/intl.dart'; // untuk format tanggal

// Asumsikan PreferenceService berada di file terpisah, impor jika perlu
import 'preference_service.dart';

void main() async {
  // Pastikan binding Flutter sudah diinisialisasi
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi PreferenceService sebelum menjalankan aplikasi
  final prefs = PreferenceService();
  await prefs.init();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ProfilePage(),
    ); // MaterialApp
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Ambil instance PreferenceService yang sudah diinisialisasi
  final PreferenceService _prefs = PreferenceService();
  
  // Controller untuk input form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Variabel untuk menampung data yang dimuat dan ditampilkan di bawah form
  String? _savedName;
  String? _savedEmail;
  String? _lastUpdated; // Sudah diformat String

  @override
  void initState() {
    super.initState();
    // Muat data saat state diinisialisasi
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Inisialisasi _prefs.init() sudah dilakukan di main, 
    // tapi kode di gambar juga memanggilnya di sini.
    await _prefs.init(); 
    
    // Gunakan setState untuk memperbarui UI setelah data dimuat
    setState(() {
      // Isi controller dengan data yang tersimpan, jika ada.
      // Jika null, gunakan string kosong agar tidak crash
      _nameController.text = _prefs.getString('user_name') ?? '';
      _emailController.text = _prefs.getString('user_email') ?? '';

      // Simpan data untuk ditampilkan
      _savedName = _prefs.getString('user_name');
      _savedEmail = _prefs.getString('user_email');

      // Ambil timestamp update terakhir
      final int? lastUpdateMillis = _prefs.getInt('last_update');
      if (lastUpdateMillis != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
        // Format tanggal menggunakan package intl
        _lastUpdated = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      } else {
        _lastUpdated = null;
      }
    });
  }

  Future<void> _saveUserData() async {
    // Simpan data dari controller ke SharedPreferences
    await _prefs.setString('user_name', _nameController.text);
    await _prefs.setString('user_email', _emailController.text);
    // Simpan waktu saat ini dalam milidetik sejak Epoch
    await _prefs.setInt('last_update', DateTime.now().millisecondsSinceEpoch);

    // Muat ulang data untuk memperbarui tampilan di bawah form
    await _loadUserData();

    // Tampilkan SnackBar untuk konfirmasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Input form
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ), // TextField
            SizedBox(height: 10), // Tambahkan sedikit jarak antar TextField
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ), // TextField
            
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveUserData,
              child: Text('Save'),
            ),
            
            Divider(height: 40),

            // Data yang disimpan
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Data Tersimpan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ), // TextStyle
                  ), // Text
                  SizedBox(height: 8),
                  Text('Nama: ${_savedName ?? '-'}'),
                  Text('Email: ${_savedEmail ?? '-'}'),
                  // Tampilkan tanggal terakhir diupdate yang sudah diformat
                  Text('Terakhir diperbarui: ${_lastUpdated ?? '-'}'), 
                ],
              ), // Column
            ), // Align
          ],
        ), // Column
      ), // Padding
    ); // Scaffold
  }
}