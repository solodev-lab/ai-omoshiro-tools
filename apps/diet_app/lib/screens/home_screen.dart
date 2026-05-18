import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';
import 'chart_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String nickname;

  const HomeScreen({super.key, required this.nickname});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weightController = TextEditingController();
  final _memoController = TextEditingController();
  late final ConfettiController _confettiController;
  List<WeightRecord> _records = [];
  DateTime _selectedDate = DateTime.now();
  double _currentWeight = 60.0;
  double? _goalWeight;
  DateTime? _goalDate;
  String _nickname = '';
  String? _homeBgPath;
  String? _chartBgPath;

  @override
  void initState() {
    super.initState();
    _nickname = widget.nickname;
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadAll();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _memoController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    // 記録読み込み
    final jsonStr = prefs.getString('weight_records');
    if (jsonStr != null) {
      _records = WeightRecord.decodeList(jsonStr);
      _records.sort((a, b) => b.date.compareTo(a.date));
      if (_records.isNotEmpty) {
        _currentWeight = _records.first.weight;
      }
    }
    _weightController.text = _currentWeight.toStringAsFixed(1);

    // 目標読み込み
    _goalWeight = prefs.getDouble('goal_weight');
    final goalDateStr = prefs.getString('goal_date');
    if (goalDateStr != null) {
      _goalDate = DateTime.tryParse(goalDateStr);
    }
    _nickname = prefs.getString('nickname') ?? widget.nickname;
    _homeBgPath = prefs.getString('home_bg_path');
    _chartBgPath = prefs.getString('chart_bg_path');

    setState(() {});
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weight_records', WeightRecord.encodeList(_records));
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ja'),
      cancelText: 'キャンセル',
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _adjustWeight(double delta) {
    final current = double.tryParse(_weightController.text) ?? _currentWeight;
    final newWeight = (current + delta).clamp(1.0, 300.0);
    setState(() {
      _currentWeight = double.parse(newWeight.toStringAsFixed(1));
      _weightController.text = _currentWeight.toStringAsFixed(1);
    });
  }

  Future<void> _addRecord() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0 || weight > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正しい体重を入力してください')),
      );
      return;
    }

    final record = WeightRecord(
      date: _selectedDate,
      weight: weight,
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
    );

    setState(() {
      _records.removeWhere((r) =>
          r.date.year == _selectedDate.year &&
          r.date.month == _selectedDate.month &&
          r.date.day == _selectedDate.day);
      _records.add(record);
      _records.sort((a, b) => b.date.compareTo(a.date));
      _currentWeight = weight;
    });

    await _saveRecords();
    _memoController.clear();

    if (mounted) {
      // 目標達成チェック
      if (_goalWeight != null && weight <= _goalWeight!) {
        _confettiController.play();
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('🎉 目標達成！', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'おめでとうございます！',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '${weight.toStringAsFixed(1)} kg\n目標 ${_goalWeight!.toStringAsFixed(1)} kg を達成しました！',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('やったー！'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('記録しました！')),
        );
      }
    }
  }

  Future<void> _deleteRecord(int index) async {
    setState(() {
      _records.removeAt(index);
    });
    await _saveRecords();
  }

  Future<void> _editMemo(int index) async {
    final record = _records[index];
    String memoText = record.memo ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(DateFormat('M/d (E)', 'ja').format(record.date)),
          content: TextFormField(
            initialValue: memoText,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'メモ',
              hintText: 'メモを入力...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => memoText = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, memoText),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _records[index] = WeightRecord(
          date: record.date,
          weight: record.weight,
          memo: result.trim().isEmpty ? null : result.trim(),
        );
      });
      await _saveRecords();
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (result == true) {
      _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd (E)', 'ja');
    final today = DateFormat('M月d日', 'ja').format(DateTime.now());

    final hasHomeBg = _homeBgPath != null && File(_homeBgPath!).existsSync();

    return Stack(
      children: [
        // 背景画像
        if (hasHomeBg)
          Positioned.fill(
            child: Image.file(
              File(_homeBgPath!),
              fit: BoxFit.cover,
            ),
          ),
        Scaffold(
      backgroundColor: hasHomeBg ? Colors.transparent : null,
      appBar: AppBar(
        title: Text('$_nicknameさんの記録'),
        backgroundColor: hasHomeBg
            ? Theme.of(context).colorScheme.inversePrimary.withAlpha(160)
            : Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'グラフ',
            onPressed: _records.length >= 2
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChartScreen(
                          records: _records,
                          goalWeight: _goalWeight,
                          goalDate: _goalDate,
                          bgPath: _chartBgPath,
                        ),
                      ),
                    );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // 目標表示
          if (_goalWeight != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: hasHomeBg ? Colors.green.shade50.withAlpha(180) : Colors.green.shade50,
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '目標: ${_goalWeight!.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'あと ${(_currentWeight - _goalWeight!).toStringAsFixed(1)} kg',
                    style: TextStyle(
                      color: _currentWeight <= _goalWeight! ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_goalDate != null) ...[
                    const Spacer(),
                    Text(
                      '残り${_goalDate!.difference(DateTime.now()).inDays}日',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          // 入力エリア
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasHomeBg
                  ? Colors.white.withAlpha(160)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '今日は $today',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    // 日付選択（矢印 + カレンダー）
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                            });
                          },
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('M/d (E)', 'ja').format(_selectedDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _selectedDate.isBefore(DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                          ))
                              ? () {
                                  setState(() {
                                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                                  });
                                }
                              : null,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 体重表示（大きく）
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Icon(Icons.monitor_weight, size: 28, color: Colors.green),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                final parsed = double.tryParse(value);
                                if (parsed != null) {
                                  _currentWeight = parsed;
                                }
                              },
                            ),
                          ),
                          const Text(
                            'kg',
                            style: TextStyle(fontSize: 20, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // +/- ボタン
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AdjustButton(label: '-1', onTap: () => _adjustWeight(-1)),
                          const SizedBox(width: 8),
                          _AdjustButton(label: '-0.5', onTap: () => _adjustWeight(-0.5)),
                          const SizedBox(width: 8),
                          _AdjustButton(label: '-0.1', onTap: () => _adjustWeight(-0.1)),
                          const SizedBox(width: 16),
                          _AdjustButton(label: '+0.1', onTap: () => _adjustWeight(0.1), isPlus: true),
                          const SizedBox(width: 8),
                          _AdjustButton(label: '+0.5', onTap: () => _adjustWeight(0.5), isPlus: true),
                          const SizedBox(width: 8),
                          _AdjustButton(label: '+1', onTap: () => _adjustWeight(1), isPlus: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // メモ
                TextField(
                  controller: _memoController,
                  decoration: InputDecoration(
                    labelText: 'メモ（任意）',
                    hintText: '食べすぎた...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.note),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _addRecord,
                    icon: const Icon(Icons.add),
                    label: const Text('記録する', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          // 記録一覧
          Expanded(
            child: _records.isEmpty
                ? const Center(
                    child: Text(
                      '記録がありません\n体重を入力してみましょう！',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _records.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      final diff = index < _records.length - 1
                          ? record.weight - _records[index + 1].weight
                          : null;

                      return Dismissible(
                        key: Key(record.date.toIso8601String()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteRecord(index),
                        child: ListTile(
                          onTap: () => _editMemo(index),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              record.weight.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(dateFormat.format(record.date)),
                          subtitle: record.memo != null
                              ? Text(record.memo!)
                              : Text('タップしてメモを追加', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          trailing: diff != null
                              ? Text(
                                  '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    color: diff > 0
                                        ? Colors.red
                                        : diff < 0
                                            ? Colors.blue
                                            : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
        // 紙吹雪（全面表示）
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 20,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPlus;

  const _AdjustButton({
    required this.label,
    required this.onTap,
    this.isPlus = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPlus ? Colors.red.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPlus ? Colors.red.shade200 : Colors.blue.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isPlus ? Colors.red.shade700 : Colors.blue.shade700,
          ),
        ),
      ),
    );
  }
}
