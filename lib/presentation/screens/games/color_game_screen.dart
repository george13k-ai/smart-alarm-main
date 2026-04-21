import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class ColorGameScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const ColorGameScreen({super.key, required this.onSuccess});

  @override
  State<ColorGameScreen> createState() => _ColorGameScreenState();
}

class _ColorGameScreenState extends State<ColorGameScreen> {
  static const _palette = [
    (color: Color(0xFFE53935), name: 'КРАСНЫЙ'),
    (color: Color(0xFF43A047), name: 'ЗЕЛЁНЫЙ'),
    (color: Color(0xFF1E88E5), name: 'СИНИЙ'),
    (color: Color(0xFFFFB300), name: 'ЖЁЛТЫЙ'),
  ];

  final _rnd = Random();
  int _correct = 0;
  late int _targetIdx;
  late List<int> _order;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _nextRound();
  }

  void _nextRound() {
    _targetIdx = _rnd.nextInt(_palette.length);
    _order = List.generate(_palette.length, (i) => i)..shuffle(_rnd);
    _showError = false;
  }

  void _onTap(int colorIdx) {
    if (colorIdx == _targetIdx) {
      final next = _correct + 1;
      if (next >= AppConstants.colorTapsRequired) {
        widget.onSuccess();
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _correct = next;
        _nextRound();
      });
    } else {
      setState(() => _showError = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showError = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _correct / AppConstants.colorTapsRequired;
    final target = _palette[_targetIdx];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1035),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text(
            '$_correct / ${AppConstants.colorTapsRequired}',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor:
                    const AlwaysStoppedAnimation(Colors.purpleAccent),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const Spacer(),
              const Text(
                'Нажми:',
                style: TextStyle(color: Colors.white54, fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                target.name,
                style: TextStyle(
                  color: target.color,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              SizedBox(
                height: 28,
                child: _showError
                    ? const Text(
                        'Не то! Попробуй снова',
                        style:
                            TextStyle(color: Colors.redAccent, fontSize: 14),
                      )
                    : null,
              ),
              const Spacer(),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: _order.map((idx) {
                  final c = _palette[idx];
                  return GestureDetector(
                    onTap: () => _onTap(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: c.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: c.color.withOpacity(0.45),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
