// File: main.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// =========================================================================
/// SERVICE: FileService – operasi dasar baca/tulis file JSON
/// =========================================================================

class FileService {
  // Helper untuk mendapatkan direktori dokumen aplikasi
  Future<Directory> get documentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  // Simpan data ke file (sebagai String)
  Future<File> writeFile(String fileName, String content) async {
    final Directory dir = await documentsDirectory;
    final File file = File(path.join(dir.path, fileName));
    return file.writeAsString(content);
  }

  // Baca data dari file (sebagai String)
  Future<String> readFile(String fileName) async {
    try {
      final Directory dir = await documentsDirectory;
      final File file = File(path.join(dir.path, fileName));
      // Cek apakah file ada sebelum mencoba membacanya
      if (await file.exists()) {
        return await file.readAsString();
      }
      return ""; // Kembalikan string kosong jika file tidak ada
    } catch (e) {
      return ""; // Kembalikan string kosong jika terjadi error
    }
  }

  // Simpan object sebagai JSON
  Future<File> writeJson(String fileName, Map<String, dynamic> json) async {
    final String content = jsonEncode(json);
    return writeFile(fileName, content);
  }

  // Baca JSON dari file
  Future<Map<String, dynamic>> readJson(String fileName) async {
    try {
      final String content = await readFile(fileName);
      if (content.isEmpty) return {}; // Jika konten kosong, kembalikan Map kosong
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return {}; // Kembalikan Map kosong jika decoding gagal
    }
  }

  // Cek apakah file ada
  Future<bool> fileExists(String fileName) async {
    final Directory dir = await documentsDirectory;
    final File file = File(path.join(dir.path, fileName));
    return file.exists();
  }
  
  // Hapus file
  Future<void> deleteFile(String fileName) async {
    try {
      final Directory dir = await documentsDirectory;
      final File file = File(path.join(dir.path, fileName));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
}

/// =========================================================================
/// SERVICE: UserDataService – untuk menyimpan dan membaca user data
/// =========================================================================

class UserDataService {
  final FileService _fileService = FileService();
  final String _fileName = 'user_data.json';

  Future<void> saveUserData({
    required String name,
    required String email,
    int? age,
  }) async {
    final Map<String, dynamic> userData = {
      'name': name,
      'email': email,
      'age': age ?? 0, // Set 0 jika age null
      'last_update': DateTime.now().toIso8601String(),
    };
    await _fileService.writeJson(_fileName, userData);
  }

  Future<Map<String, dynamic>?> readUserData() async {
    final bool exists = await _fileService.fileExists(_fileName);
    if (!exists) return null;

    final Map<String, dynamic> data = await _fileService.readJson(_fileName);
    return data.isNotEmpty ? data : null;
  }

  Future<void> deleteUserData() async {
    await _fileService.deleteFile(_fileName);
  }

  Future<bool> hasUserData() async {
    return await _fileService.fileExists(_fileName);
  }
}

/// =========================================================================
/// MAIN APP
/// =========================================================================

void main() {
  // Inisialisasi Service untuk diakses oleh app (opsional, tapi disarankan)
  final UserDataService _userService = UserDataService(); 
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Data JSON Demo',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: UserProfilePage(),
    ); // MaterialApp
  }
}

/// =========================================================================
/// UI: UserProfilePage
/// =========================================================================

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final UserDataService _userService = UserDataService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  Map<String, dynamic>? _savedData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Memuat data user dari file JSON
  Future<void> _loadUserData() async {
    final data = await _userService.readUserData();
    setState(() {
      _savedData = data;
      
      // Isi form jika data ada
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
      } else {
        // Kosongkan form jika tidak ada data
        _nameController.text = '';
        _emailController.text = '';
        _ageController.text = '';
      }
    });
  }

  // Simpan data ke file JSON
  Future<void> _saveUserData() async {
    await _userService.saveUserData(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      // Parse usia ke int, jika gagal akan menjadi null
      age: int.tryParse(_ageController.text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Data berhasil disimpan')),
    );

    await _loadUserData(); // Muat ulang data untuk memperbarui tampilan
  }

  // Hapus file JSON
  Future<void> _deleteUserData() async {
    await _userService.deleteUserData();
    setState(() {
      _savedData = null;
    });

    // Kosongkan form setelah dihapus
    _nameController.text = '';
    _emailController.text = '';
    _ageController.text = '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🗑️ Data user dihapus')),
    );
  }
  
  // Widget helper untuk menampilkan 1 baris data
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ), // Row
    ); // Padding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profil User (File JSON)')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Penting untuk Align data
          children: <Widget>[
            // === FORM INPUT ===
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
            ), // TextField
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ), // TextField
            SizedBox(height: 10),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: 'Usia',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ), // TextField
            SizedBox(height: 20),

            // === BUTTONS ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text('Simpan'),
                  onPressed: _saveUserData,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text('Hapus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: _deleteUserData,
                ),
              ],
            ), // Row
            SizedBox(height: 30),
            Divider(),

            // === TAMPILAN DATA YANG DISIMPAN ===
            _savedData == null
                ? Text(
                    'Belum ada data tersimpan.',
                    style: TextStyle(color: Colors.grey),
                  ) // Text
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Tersimpan:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ), // TextStyle
                      ), // Text
                      SizedBox(height: 8),
                      _buildDataRow('Nama', _savedData!['name']),
                      _buildDataRow('Email', _savedData!['email']),
                      _buildDataRow('Usia', _savedData!['age']?.toString() ?? '-'),
                      _buildDataRow('Update Terakhir', _savedData!['last_update']),
                    ],
                  ), // Column
          ],
        ), // Column
      ), // SingleChildScrollView
    ); // Scaffold
  }
}