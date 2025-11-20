// File: main.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// =========================================================================
/// MAIN APP & API CONFIG
/// =========================================================================

void main() {
  runApp(WireMockApp());
}

class WireMockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WireMock Cloud Demo',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: UserPage(),
    ); // MaterialApp
  }
}

class ApiConfig {
  static const String baseUrl = 'https://your-wiremock-cloud-instance.wiremockapi.cloud'; // Ganti sesuai WireMock kamu
  static const String usersEndpoint = '/users';
  // Konfigurasi ini berasal dari gambar sebelumnya, meskipun tidak semua terpakai di sini.
  static const int timeoutSeconds = 10; 

  static Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

/// =========================================================================
/// UI: USER PAGE
/// =========================================================================

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  List<dynamic> users = [];
  bool isLoading = false;
  String? errorMessage;
  String? postMessage; // Tambahkan ini untuk menampilkan hasil POST

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // /////////////////////////////////////////////////////////////////////////
  // GET users
  // /////////////////////////////////////////////////////////////////////////
  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}');

    try {
      final response = await http.get(
        url,
        headers: ApiConfig.headers,
      ).timeout(const Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => users = data);
      } else {
        setState(() => errorMessage = 'Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
    } finally {
      // Pastikan isLoading diatur ke false, terlepas dari keberhasilan atau kegagalan
      setState(() => isLoading = false);
    }
  }

  // /////////////////////////////////////////////////////////////////////////
  // POST new user
  // /////////////////////////////////////////////////////////////////////////
  Future<void> addUser() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama & Email tidak boleh kosong!')),
      );
      return;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}');
    final body = jsonEncode({'name': name, 'email': email});

    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: body,
      ).timeout(const Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Asumsi respons POST mengembalikan JSON dengan field 'message'
        final Map<String, dynamic> result = jsonDecode(response.body);
        
        setState(() {
          postMessage = result['message'] ?? 'User berhasil ditambahkan!';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(postMessage!)),
        );
        
        _nameController.clear();
        _emailController.clear();
        fetchUsers(); // Muat ulang daftar setelah berhasil POST
      } else {
        setState(() {
          postMessage = 'Gagal menambah user (${response.statusCode})';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(postMessage!)),
        );
      }
    } catch (e) {
      setState(() => postMessage = 'Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(postMessage!)),
      );
    }
  }

  // /////////////////////////////////////////////////////////////////////////
  // BUILD METHOD
  // /////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WireMock Cloud - Users')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input form
            const Text('Tambah Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ), // TextField
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ), // TextField
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tambah User'),
              onPressed: addUser,
            ), // ElevatedButton.icon
            
            const SizedBox(height: 20),
            // Message container (Hasil POST)
            if (postMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  postMessage!,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Text(
              'Daftar User',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),

            // Data list (Listview)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : users.isEmpty
                          ? const Center(child: Text('Belum ada data.'))
                          : ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return ListTile(
                                  leading: CircleAvatar(child: Text('${user['id']}')),
                                  title: Text(user['name'] ?? ''),
                                  subtitle: Text(user['email'] ?? ''),
                                );
                              },
                            ),
            ), // Expanded
          ],
        ), // Column
      ), // Padding
      floatingActionButton: FloatingActionButton(
        onPressed: fetchUsers,
        child: const Icon(Icons.refresh),
      ), // FloatingActionButton
    ); // Scaffold
  }
}