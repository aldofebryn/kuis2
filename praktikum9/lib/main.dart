// File: main.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// =========================================================================
/// MAIN APP
/// =========================================================================

void main() {
  runApp(PokeApp());
}

class PokeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeAPI Demo',
      theme: ThemeData(primarySwatch: Colors.red),
      home: PokemonPage(),
    ); // MaterialApp
  }
}

/// =========================================================================
/// UI: PokemonPage (StatefulWidget)
/// =========================================================================

class PokemonPage extends StatefulWidget {
  @override
  _PokemonPageState createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  // Variabel state
  Map<String, dynamic>? pokemonData;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    // otomatis ambil data saat pertama kali
    fetchPokemon(); 
  }

  // Fungsi untuk mengambil data Pokémon dari PokeAPI
  Future<void> fetchPokemon() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://pokeapi.co/api/v2/pokemon/ditto'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() {
          // Decode JSON body dan simpan ke pokemonData
          pokemonData = jsonDecode(response.body);
        });
      } else {
        setState(() {
          error = 'Gagal memuat data. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Widget helper untuk menampilkan kartu Pokémon
  Widget _buildPokemonCard() {
    // Ambil data dengan aman menggunakan null-aware access.
    // Properti 'sprites' adalah nested object.
    final name = pokemonData?['name'] ?? '-';
    final id = pokemonData?['id'] ?? '-';
    final height = pokemonData?['height'] ?? '-';
    final weight = pokemonData?['weight'] ?? '-';

    // Ambil URL sprite, gunakan placeholder jika tidak ada
    final sprite = pokemonData?['sprites']?['front_default'] ??
        'https://via.placeholder.com/150';

    return Card(
      margin: const EdgeInsets.all(20),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gambar Pokémon
            Image.network(sprite, width: 150, height: 150),
            const SizedBox(height: 10),
            
            // Nama Pokémon
            Text(
              name.toString().toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ), // TextStyle
            ),
            const SizedBox(height: 8),
            
            // Detail
            Text('ID: $id'),
            Text('Height: $height'),
            Text('Weight: $weight'),
          ],
        ), // Column
      ), // Padding
    ); // Card
  }


  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      content = Center(child: Text(error!));
    } else if (pokemonData != null) {
      content = Center(child: _buildPokemonCard());
    } else {
      content = const Center(child: Text('Tekan refresh untuk memuat data.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('PokeAPI - Ditto')),
      body: content,
      floatingActionButton: FloatingActionButton(
        onPressed: fetchPokemon,
        tooltip: 'Refresh Data',
        child: const Icon(Icons.refresh),
      ), // FloatingActionButton
    ); // Scaffold
  }
}