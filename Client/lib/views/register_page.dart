import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xiwu/services/auth_service.dart';

class RegisterPage extends StatelessWidget {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册惜物')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: '手机号', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: '昵称', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '密码', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await Get.find<AuthService>().register(
                    _phoneController.text, 
                    _passwordController.text,
                    _nicknameController.text,
                  );
                  if (success) {
                    Get.offAllNamed('/home');
                  }
                },
                child: const Text('注册'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
