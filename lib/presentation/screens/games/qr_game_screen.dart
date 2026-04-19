import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrGameScreen extends StatefulWidget {
  final String savedCode;
  final VoidCallback onSuccess;

  const QrGameScreen({
    super.key,
    required this.savedCode,
    required this.onSuccess,
  });

  @override
  State<QrGameScreen> createState() => _QrGameScreenState();
}

class _QrGameScreenState extends State<QrGameScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _matched = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_matched) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      if (widget.savedCode.isEmpty || raw == widget.savedCode) {
        // Если код не задан — любой QR подходит
        setState(() => _matched = true);
        _controller.stop();
        Future.delayed(const Duration(milliseconds: 500), widget.onSuccess);
        return;
      } else {
        setState(() => _errorMessage = 'Неверный QR-код, попробуй снова');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const Text('Сканируй QR-код'),
          actions: [
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, state, __) => IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_off
                      : Icons.flash_on,
                  color: Colors.white,
                ),
                onPressed: _controller.toggleTorch,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Сканер на весь экран
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),

            // Оверлей с рамкой
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _matched ? Colors.green : Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Статус
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (_matched)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Верно! Будильник выключен',
                          style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  if (_errorMessage != null && !_matched)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (!_matched && _errorMessage == null)
                    const Text(
                      'Наведи камеру на QR-код',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
