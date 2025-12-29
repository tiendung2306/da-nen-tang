import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_boilerplate/providers/auth_provider.dart';
import 'package:flutter_boilerplate/pages/auth/landing_page.dart'; // Import LandingPage

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userInfo = authProvider.userInfo;
    final orangeColor = const Color(0xFFF26F21);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Center(
          child: Text('Thông Tin Tài Khoản', style: TextStyle(color: Colors.black)),
        ),
      ),
      body: userInfo == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFF0F0F0),
                    child: Text('Avatar', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 32),

                  _buildInfoTextField(
                    label: 'Tên tài khoản',
                    value: userInfo.fullName,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTextField(
                    label: 'Email',
                    value: userInfo.email,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTextField(
                    label: 'Số điện thoại',
                    value: '0123456789', // Placeholder
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () { /* TODO: Implement change password */ },
                      child: const Text('Đổi mật khẩu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // --- NAVIGATION FIX: Manually navigate after logout ---
                        Provider.of<AuthProvider>(context, listen: false).logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LandingPage()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Text('Đăng xuất', style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTextField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
      ],
    );
  }
}
