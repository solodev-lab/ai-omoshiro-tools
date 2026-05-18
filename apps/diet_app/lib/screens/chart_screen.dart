import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weight_record.dart';

class ChartScreen extends StatefulWidget {
  final List<WeightRecord> records;
  final double? goalWeight;
  final DateTime? goalDate;
  final String? bgPath;

  const ChartScreen({
    super.key,
    required this.records,
    this.goalWeight,
    this.goalDate,
    this.bgPath,
  });

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int? _selectedMemoIndex;

  @override
  Widget build(BuildContext context) {
    final sorted = List<WeightRecord>.from(widget.records)
      ..sort((a, b) => a.date.compareTo(b.date));

    final last30 = sorted.length > 30 ? sorted.sublist(sorted.length - 30) : sorted;

    final weights = last30.map((r) => r.weight).toList();
    var minWeight = weights.reduce((a, b) => a < b ? a : b) - 1;
    var maxWeight = weights.reduce((a, b) => a > b ? a : b) + 1;

    // 目標体重がグラフ範囲外なら広げる
    if (widget.goalWeight != null) {
      if (widget.goalWeight! < minWeight) minWeight = widget.goalWeight! - 1;
      if (widget.goalWeight! > maxWeight) maxWeight = widget.goalWeight! + 1;
    }

    final firstWeight = last30.first.weight;
    final lastWeight = last30.last.weight;
    final diff = lastWeight - firstWeight;

    final hasChartBg = widget.bgPath != null && File(widget.bgPath!).existsSync();

    return Stack(
      children: [
        if (hasChartBg)
          Positioned.fill(
            child: Image.file(
              File(widget.bgPath!),
              fit: BoxFit.cover,
            ),
          ),
        Scaffold(
      backgroundColor: hasChartBg ? Colors.transparent : null,
      appBar: AppBar(
        title: const Text('体重推移グラフ'),
        backgroundColor: hasChartBg
            ? Theme.of(context).colorScheme.inversePrimary.withAlpha(160)
            : Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        color: hasChartBg ? Colors.white.withAlpha(128) : null,
        child: Column(
          children: [
            // サマリー
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: '開始',
                      value: '${firstWeight.toStringAsFixed(1)} kg',
                    ),
                    _StatItem(
                      label: '現在',
                      value: '${lastWeight.toStringAsFixed(1)} kg',
                    ),
                    _StatItem(
                      label: '変化',
                      value: '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} kg',
                      color: diff > 0
                          ? Colors.red
                          : diff < 0
                              ? Colors.blue
                              : Colors.grey,
                    ),
                    if (widget.goalWeight != null)
                      _StatItem(
                        label: '目標まで',
                        value: '${(lastWeight - widget.goalWeight!).toStringAsFixed(1)} kg',
                        color: lastWeight <= widget.goalWeight! ? Colors.green : Colors.orange,
                      ),
                    if (widget.goalDate != null)
                      _StatItem(
                        label: '残り',
                        value: '${widget.goalDate!.difference(DateTime.now()).inDays}日',
                        color: Colors.deepPurple,
                      ),
                  ],
                ),
              ),
            ),
            // メモ表示エリア
            if (_selectedMemoIndex != null && last30[_selectedMemoIndex!].memo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.note, size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${DateFormat('M/d').format(last30[_selectedMemoIndex!].date)}: ${last30[_selectedMemoIndex!].memo}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _selectedMemoIndex = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // グラフ
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: minWeight,
                  maxY: maxWeight,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (last30.length / 5).ceilToDouble().clamp(1, 10),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= last30.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('M/d').format(last30[index].date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  // 目標体重の点線
                  extraLinesData: widget.goalWeight != null
                      ? ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: widget.goalWeight!,
                              color: Colors.orange,
                              strokeWidth: 2,
                              dashArray: [8, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                labelResolver: (_) => '目標 ${widget.goalWeight!.toStringAsFixed(1)}kg',
                              ),
                            ),
                          ],
                        )
                      : null,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        last30.length,
                        (i) => FlSpot(i.toDouble(), last30[i].weight),
                      ),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final hasMemo = last30[index].memo != null;
                          if (hasMemo) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: Colors.amber,
                              strokeWidth: 2,
                              strokeColor: Colors.amber.shade700,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.green,
                            strokeWidth: 1,
                            strokeColor: Colors.green.shade700,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withAlpha(30),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchCallback: (event, response) {
                      if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                        final index = response.lineBarSpots!.first.x.toInt();
                        if (event is FlTapUpEvent && last30[index].memo != null) {
                          setState(() {
                            _selectedMemoIndex = index;
                          });
                        }
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final record = last30[spot.x.toInt()];
                          final memoSuffix = record.memo != null ? '\n📝' : '';
                          return LineTooltipItem(
                            '${DateFormat('M/d').format(record.date)}\n${record.weight.toStringAsFixed(1)} kg$memoSuffix',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '最新${last30.length}件のデータを表示',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'メモあり',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (widget.goalWeight != null) ...[
                  const SizedBox(width: 12),
                  Container(width: 16, height: 2, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '目標',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
