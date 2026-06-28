import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'game_tracker_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  final ctrlNama = TextEditingController();
  final ctrlPass = TextEditingController();
  final ctrlKonf = TextEditingController();

  @override
  void dispose() {
    ctrlNama.dispose();
    ctrlPass.dispose();
    ctrlKonf.dispose();
    super.dispose();
  }

  void _handleAuth() async {
    final db = DbHelper();
    String user = ctrlNama.text.trim(), pass = ctrlPass.text.trim();
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua field wajib diisi!'), backgroundColor: Colors.red));
      return;
    }

    if (isLogin) {
      if (await db.checkLogin(user, pass)) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GameTrackerPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username/Password salah!'), backgroundColor: Colors.red));
      }
    } else {
      if (pass != ctrlKonf.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak cocok!'), backgroundColor: Colors.red));
        return;
      }
      if (await db.register(user, pass)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrasi berhasil! Silakan login.'), backgroundColor: Colors.green));
        setState(() { isLogin = true; ctrlPass.clear(); ctrlKonf.clear(); });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal registrasi. Username mungkin sudah dipakai.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.sports_esports, size: 80, color: Colors.red[700]),
                const SizedBox(height: 20),
                Text(isLogin ? 'Login GameTracker' : 'Daftar Akun Baru', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[700])),
                const SizedBox(height: 30),
                TextField(controller: ctrlNama, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                const SizedBox(height: 20),
                TextField(controller: ctrlPass, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())),
                if (!isLogin) ...[
                  const SizedBox(height: 20),
                  TextField(controller: ctrlKonf, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi Password', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder())),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleAuth,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text(isLogin ? 'MASUK' : 'DAFTAR', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                  child: Text(isLogin ? 'Belum punya akun? Registrasi' : 'Sudah punya akun? Login', style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}