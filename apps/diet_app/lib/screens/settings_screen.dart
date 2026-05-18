import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _goalWeightController = TextEditingController();
  final _nicknameController = TextEditingController();
  DateTime? _goalDate;
  String? _homeBgPath;
  String? _chartBgPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _goalWeightController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _nicknameController.text = prefs.getString('nickname') ?? '';
    final goalWeight = prefs.getDouble('goal_weight');
    if (goalWeight != null) {
      _goalWeightController.text = goalWeight.toStringAsFixed(1);
    }
    final goalDateStr = prefs.getString('goal_date');
    if (goalDateStr != null) {
      _goalDate = DateTime.tryParse(goalDateStr);
    }
    _homeBgPath = prefs.getString('home_bg_path');
    _chartBgPath = prefs.getString('chart_bg_path');
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ニックネームを入力してください')),
      );
      return;
    }
    await prefs.setString('nickname', nickname);

    final goalWeight = double.tryParse(_goalWeightController.text);
    if (goalWeight != null && goalWeight > 0 && goalWeight < 300) {
      await prefs.setDouble('goal_weight', goalWeight);
    } else if (_goalWeightController.text.trim().isEmpty) {
      await prefs.remove('goal_weight');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正しい目標体重を入力してください')),
      );
      return;
    }

    if (_goalDate != null) {
      await prefs.setString('goal_date', _goalDate!.toIso8601String());
    } else {
      await prefs.remove('goal_date');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定を保存しました')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickGoalDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _goalDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('ja'),
      cancelText: 'キャンセル',
    );
    if (date != null) {
      setState(() => _goalDate = date);
    }
  }

  Future<void> _pickBackgroundImage(String key) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
    if (image == null) return;

    // アプリ内にコピーして保存
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${key}_bg.jpg';
    final savedPath = p.join(appDir.path, fileName);
    await File(image.path).copy(savedPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${key}_bg_path', savedPath);

    setState(() {
      if (key == 'home') {
        _homeBgPath = savedPath;
      } else {
        _chartBgPath = savedPath;
      }
    });
  }

  Future<void> _removeBackgroundImage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('${key}_bg_path');
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await prefs.remove('${key}_bg_path');
    }

    setState(() {
      if (key == 'home') {
        _homeBgPath = null;
      } else {
        _chartBgPath = null;
      }
    });
  }

  Widget _bgPreview(String? path, String label, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickBackgroundImage(key),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
              image: path != null && File(path).existsSync()
                  ? DecorationImage(
                      image: FileImage(File(path)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: path == null || !File(path).existsSync()
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 36, color: Colors.grey),
                        SizedBox(height: 4),
                        Text('タップして画像を選択', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        if (path != null && File(path).existsSync())
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _removeBackgroundImage(key),
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('背景を削除'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ニックネーム
          Text('プロフィール', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              labelText: 'ニックネーム',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 32),

          // 目標設定
          Text('目標設定', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _goalWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '目標体重 (kg)',
              hintText: '55.0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.flag),
            ),
          ),
          const SizedBox(height: 16),

          // 目標日
          Text('目標達成日（任意）', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickGoalDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _goalDate != null
                              ? DateFormat('yyyy年M月d日').format(_goalDate!)
                              : '未設定',
                          style: TextStyle(
                            fontSize: 16,
                            color: _goalDate != null ? null : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_goalDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _goalDate = null),
                ),
            ],
          ),
          if (_goalDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'あと${_goalDate!.difference(DateTime.now()).inDays}日',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 32),

          // 背景設定
          Text('背景画像', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _bgPreview(_homeBgPath, 'ホーム画面', 'home'),
          const SizedBox(height: 16),
          _bgPreview(_chartBgPath, 'グラフ画面', 'chart'),
          const SizedBox(height: 32),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _save,
              child: const Text('保存する', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
