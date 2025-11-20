// File: main.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// =========================================================================
/// SERVICE: FileService – util dasar untuk file handling
/// =========================================================================

class FileService {
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
      if (await file.exists()) {
        return await file.readAsString();
      }
      return "";
    } catch (e) {
      return "";
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
    final Directory dir = await documentsDirectory;
    final File file = File(path.join(dir.path, fileName));
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// =========================================================================
/// SERVICE: DirectoryService – util directory management
/// =========================================================================

class DirectoryService {
  final FileService _fileService = FileService();

  Future<Directory> createDirectory(String dirName) async {
    final Directory appDir = await _fileService.documentsDirectory;
    final Directory newDir = Directory(path.join(appDir.path, dirName));
    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }
    return newDir;
  }

  Future<List<FileSystemEntity>> listFiles(String dirName) async {
    final Directory dir = await createDirectory(dirName);
    return dir.list().toList();
  }

  Future<void> deleteDirectory(String dirName) async {
    final Directory appDir = await _fileService.documentsDirectory;
    final Directory dir = Directory(path.join(appDir.path, dirName));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

/// =========================================================================
/// SERVICE: NoteService – simpan setiap note di file JSON
/// =========================================================================

class NoteService {
  final DirectoryService _dirService = DirectoryService();
  final String _notesDir = 'notes';

  Future<void> saveNote({
    required String title,
    required String content,
  }) async {
    // 1. Pastikan direktori 'notes' ada
    final Directory notesDir = await _dirService.createDirectory(_notesDir);
    
    // 2. Buat nama file unik (timestamp)
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.json';
    final File file = File(path.join(notesDir.path, fileName));
    
    // 3. Buat data catatan
    final Map<String, dynamic> noteData = {
      'title': title,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    // 4. Tulis data ke file
    await file.writeAsString(jsonEncode(noteData));
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    // 1. Dapatkan semua file dari direktori 'notes'
    final Directory notesDir = await _dirService.createDirectory(_notesDir);
    final List<FileSystemEntity> files = await notesDir.list().toList();
    
    List<Map<String, dynamic>> notes = [];
    
    // 2. Iterasi dan baca setiap file JSON
    for (var entity in files) {
      if (entity is File && entity.path.endsWith('.json')) {
        final File file = entity;
        final String content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        
        // Tambahkan path file untuk keperluan penghapusan
        data['file_path'] = file.path; 
        notes.add(data);
      }
    }
    
    // 3. Urutkan dari yang terbaru berdasarkan created_at
    notes.sort(
      (a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()),
    );
    
    return notes;
  }
  
  // Fungsi helper untuk menghapus file berdasarkan path lengkap
  Future<void> deleteNoteByPath(String filePath) async {
    final File file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// =========================================================================
/// UI: Flutter Notes App
/// =========================================================================

void main() {
  runApp(NotesApp());
}

class NotesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notes (Local File)',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: NotesPage(),
    ); // MaterialApp
  }
}

// =========================================================================
// UI: NotesPage - Menampilkan daftar catatan
// =========================================================================

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteService _noteService = NoteService();
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final List<Map<String, dynamic>> notes = await _noteService.getAllNotes();
    setState(() => _notes = notes);
  }

  Future<void> _addNote() async {
    // Pindah ke halaman AddNotePage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNotePage()),
    );
    
    // Jika AddNotePage mengembalikan true (catatan berhasil disimpan), muat ulang
    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _deleteNote(String filePath) async {
    await _noteService.deleteNoteByPath(filePath);
    _loadNotes(); // Muat ulang daftar setelah menghapus
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Notes')),
      body: _notes.isEmpty
          ? Center(child: Text('Belum ada catatan.'))
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    title: Text(note['title']),
                    subtitle: Text(
                      note['content'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteNote(note['file_path']),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteDetailPage(note: note),
                      ),
                    ), // MaterialPageRoute
                  ), // ListTile
                ); // Card
              },
            ), // ListView.builder
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: Icon(Icons.add),
      ), // FloatingActionButton
    ); // Scaffold
  }
}


// =========================================================================
// UI: AddNotePage – form untuk menulis note baru
// =========================================================================

class AddNotePage extends StatefulWidget {
  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final NoteService _noteService = NoteService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Isi semua field dulu!')),
      );
      return;
    }

    await _noteService.saveNote(
      title: _titleController.text,
      content: _contentController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Catatan disimpan!')),
    );
    
    // Kembali ke halaman NotesPage dan kirimkan 'true' sebagai sinyal pemuatan ulang
    Navigator.pop(context, true); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Catatan Baru')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Judul'),
            ), // TextField
            SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'Isi Catatan'),
                maxLines: null, // Memungkinkan banyak baris
                expands: true, // Memungkinkan TextField mengambil semua ruang yang tersedia
                textAlignVertical: TextAlignVertical.top,
              ), // TextField
            ), // Expanded
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Simpan'),
              onPressed: _saveNote,
            ), // ElevatedButton.icon
          ],
        ), // Column
      ), // Padding
    ); // Scaffold
  }
}

// =========================================================================
// UI: NoteDetailPage – menampilkan isi note
// =========================================================================

class NoteDetailPage extends StatelessWidget {
  final Map<String, dynamic> note;

  const NoteDetailPage({required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(note['title'] ?? 'Note')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Text(note['content'] ?? ''),
      ), // Padding
    ); // Scaffold
  }
}