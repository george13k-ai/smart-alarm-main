import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/constants/app_constants.dart';

class ShakeGameScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const ShakeGameScreen({super.key, required this.onSuccess});

  @override
  State<ShakeGameScreen> createState() => _ShakeGameScreenState();
}

class _ShakeGameScreenState extends State<ShakeGameScreen>
    with SingleTickerProviderStateMixin {
  int _shakeCount = 0;
  StreamSubscription<AccelerometerEvent>? _subscription;
  double _lastMagnitude = 0;
  bool _inShake = false;

  late AnimationController _anim;
  late Animation<double> _offsetAnim;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _offsetAnim = Tween(begin: -8.0, end: 8.0).animate(_anim);

    _subscription = accelerometerEventStream().listen(_onAccelerometer);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final delta = (magnitude - _lastMagnitude).abs();
    _lastMagnitude = magnitude;

    if (delta > AppConstants.shakeThreshold && !_inShake) {
      _inShake = true;
      _anim.forward(from: 0).then((_) => _anim.reverse());

      setState(() {
        _shakeCount++;
      });

      if (_shakeCount >= AppConstants.shakeCountRequired) {
        _subscription?.cancel();
        widget.onSuccess(); // устанавливает gameResolved = true
        if (mounted) Navigator.of(context).pop(true); // закрываем сами себя
        return;
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        _inShake = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (_shakeCount / AppConstants.shakeCountRequired).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.deepOrange.shade900,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Встряхни телефон!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_shakeCount / ${AppConstants.shakeCountRequired}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            valueColor: const AlwaysStoppedAnimation(
                                Colors.orangeAccent),
                            backgroundColor: Colors.white24,
                          ),
                          AnimatedBuilder(
                            animation: _offsetAnim,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(_offsetAnim.value, 0),
                              child: child,
                            ),
                            child: const Icon(
                              Icons.phone_android,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Двигай телефон резко из стороны в сторону',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
