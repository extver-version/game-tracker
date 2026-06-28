import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_page.dart';

class GameTrackerPage extends StatefulWidget {
  const GameTrackerPage({super.key});
  @override State<GameTrackerPage> createState() => _GameTrackerPageState();
}

class _GameTrackerPageState extends State<GameTrackerPage> {
  final String apiUrl = "http://192.168.1.5/game_api/api.php";
  
  List<dynamic> _games = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final res = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        setState(() {
          _games = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() { _errorMessage = "Gagal memuat data dari server"; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _errorMessage = "Koneksi ke server gagal. Pastikan Laragon menyala."; _isLoading = false; });
    }
  }

  Future<void> _addGame(String judul, String rating, String platform) async {
    try {
      final res = await http.post(
        Uri.parse(apiUrl), 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode({"judul": judul, "rating": rating, "platform": platform})
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        await _fetchGames(); 
      } else {
        throw Exception(data['message'] ?? "Server menolak data");
      }
    } catch (e) {
      throw Exception("Gagal menyimpan data: $e");
    }
  }

  Future<void> _deleteGame(dynamic id) async {
    try {
      final res = await http.delete(Uri.parse("$apiUrl?id=$id")).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        await _fetchGames(); 
      }
    } catch (e) {
      throw Exception("Gagal menghapus data.");
    }
  }

  void _showAddForm() {
    final ctrlJudul = TextEditingController();
    final ctrlRating = TextEditingController();
    String platform = "PC";
    final platforms = ["PC", "Mobile", "Console (PS/Xbox)", "Nintendo", "Emulator"];

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, 
            top: 20, left: 20, right: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 15),
              const Text("Tambah Game", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(controller: ctrlJudul, decoration: const InputDecoration(labelText: "Judul Game", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: ctrlRating, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Rating (1-10)", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                value: platform, 
                decoration: const InputDecoration(labelText: "Platform", border: OutlineInputBorder()),
                items: platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), 
                onChanged: (v) => setSt(() => platform = v!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: () async {
                    if (ctrlJudul.text.isEmpty || ctrlRating.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data tidak boleh kosong!"), backgroundColor: Colors.red)); 
                      return;
                    }
                    try {
                      await _addGame(ctrlJudul.text, ctrlRating.text, platform);
                      Navigator.pop(context); 
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Game berhasil ditambahkan!"), backgroundColor: Colors.green));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                    }
                  }, 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)), 
                  child: const Text("Simpan Game")
                )
              )
            ]
          ),
        );
      }),
    );
  }

  @override 
  Widget build(BuildContext context) {
    // Hitung rata-rata rating dari list yang ada di state
    double avgRating = 0;
    if (_games.isNotEmpty) {
      int total = _games.fold(0, (sum, g) => sum + (int.tryParse(g['rating'].toString()) ?? 0));
      avgRating = total / _games.length;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
        ),
        title: const Text("Game Tracker", style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.red, 
        foregroundColor: Colors.white,
        actions: [
          // Tombol Refresh Manual (Opsional, biar gampang kalau mau refresh)
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchGames)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_errorMessage, textAlign: TextAlign.center)))
          : Column(
              children: [
                Container(
                  width: double.infinity, color: Colors.red, padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Card(
                    elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text("Statistik Koleksi Kamu", style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statCard("Total Game", "${_games.length}", Icons.sports_esports), 
                              _statCard("Rata-rata Rating", avgRating.toStringAsFixed(1), Icons.star)
                            ],
                          ),
                        ]
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _games.isEmpty 
                    ? const Center(child: Text("Belum ada game yang dicatat."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16), 
                        itemCount: _games.length,
                        itemBuilder: (_, i) {
                          var g = _games[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              leading: CircleAvatar(backgroundColor: Colors.red[100], child: const Icon(Icons.gamepad, color: Colors.red)),
                              title: Text(g['judul'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Platform: ${g['platform']}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 18),
                                  Text(g['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 15),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red), 
                                    onPressed: () async { 
                                      bool? confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctxDialog) => AlertDialog(
                                          title: const Text("Hapus Game?"),
                                          content: Text("Yakin ingin menghapus '${g['judul']}'?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctxDialog, false), child: const Text("Batal")),
                                            TextButton(onPressed: () => Navigator.pop(ctxDialog, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await _deleteGame(g['id']); 
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Game berhasil dihapus"), backgroundColor: Colors.green));
                                        }
                                      }
                                    }
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ]
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddForm, 
        backgroundColor: Colors.red, 
        foregroundColor: Colors.white, 
        icon: const Icon(Icons.add), 
        label: const Text("Tambah")
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.red, size: 24),
        const SizedBox(height: 5),
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red[700]))
      ]
    );
  }
}