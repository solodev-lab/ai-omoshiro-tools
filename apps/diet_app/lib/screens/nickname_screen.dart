import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NicknameScreen extends StatefulWidget {
  final void Function(String nickname) onNicknameSet;

  const NicknameScreen({super.key, required this.onNicknameSet});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final nickname = _controller.text.trim();
    if (nickname.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
    widget.onNicknameSet(nickname);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fitness_center,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'ダイエット管理',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'まずはニックネームを入力してください',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'ニックネーム',
                  hintText: '例：たろう',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                onChanged: (value) {
                  setState(() {
                    _isValid = value.trim().isNotEmpty;
                  });
                },
                onSubmitted: (_) => _isValid ? _saveNickname() : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isValid ? _saveNickname : null,
                  child: const Text(
                    'はじめる',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
