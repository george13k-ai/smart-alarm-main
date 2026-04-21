import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class MathGameScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const MathGameScreen({super.key, required this.onSuccess});

  @override
  State<MathGameScreen> createState() => _MathGameScreenState();
}

class _MathGameScreenState extends State<MathGameScreen> {
  final _random = Random();
  int _solved = 0;
  late _MathProblem _current;
  final _answerController = TextEditingController();
  String? _errorText;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _current = _generateProblem();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  _MathProblem _generateProblem() {
    final difficulty = _solved + 1;
    final maxNum = 10 * difficulty;

    final a = _random.nextInt(maxNum) + 1;
    final b = _random.nextInt(maxNum) + 1;
    final ops = ['+', '-', '*'];
    final op = ops[_random.nextInt(difficulty > 2 ? 3 : 2)];

    int answer;
    switch (op) {
      case '+':
        answer = a + b;
      case '-':
        answer = a - b;
      case '*':
        answer = a * b;
      default:
        answer = a + b;
    }

    return _MathProblem(a: a, b: b, op: op, answer: answer);
  }

  void _checkAnswer() {
    final input = _answerController.text.trim();
    final parsed = int.tryParse(input);
    if (parsed == null) {
      setState(() => _errorText = 'Введите число');
      return;
    }

    if (parsed == _current.answer) {
      final nextSolved = _solved + 1;
      final completed = nextSolved >= AppConstants.mathProblemsRequired;

      _answerController.clear();
      setState(() {
        _errorText = null;
        _solved = nextSolved;
        _showSuccess = true;
      });

      if (completed) {
        widget.onSuccess(); // устанавливает gameResolved = true в _openGame
        // Закрываем экран своим контекстом через 300 мс (даём увидеть чекмарк)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.of(context).pop(true);
        });
        return;
      }

      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _showSuccess = false;
          _current = _generateProblem();
        });
      });
    } else {
      setState(() => _errorText = 'Неверно, попробуй снова');
      _answerController.selectAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTask =
        (_solved + 1).clamp(1, AppConstants.mathProblemsRequired);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.indigo.shade900,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text(
            'Задача $currentTask из ${AppConstants.mathProblemsRequired}',
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LinearProgressIndicator(
                value: _solved / AppConstants.mathProblemsRequired,
                backgroundColor: Colors.white24,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 48),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showSuccess
                    ? const Icon(
                        Icons.check_circle,
                        key: ValueKey('check'),
                        color: Colors.greenAccent,
                        size: 80,
                      )
                    : Text(
                        '${_current.a} ${_current.op} ${_current.b} = ?',
                        key: ValueKey(_current.hashCode),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _answerController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Ответ',
                  hintStyle: const TextStyle(color: Colors.white38),
                  errorText: _errorText,
                  errorStyle: const TextStyle(color: Colors.orangeAccent),
                ),
                onSubmitted: (_) => _checkAnswer(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.greenAccent.shade700,
                ),
                onPressed: _checkAnswer,
                child: const Text(
                  'Ответить',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MathProblem {
  final int a;
  final int b;
  final String op;
  final int answer;

  const _MathProblem({
    required this.a,
    required this.b,
    required this.op,
    required this.answer,
  });
}

extension on TextEditingController {
  void selectAll() {
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}
