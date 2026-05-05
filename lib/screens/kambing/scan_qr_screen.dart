import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/kambing_model.dart';
import '../../providers/kambing_provider.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});
  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);

    final raw = barcode!.rawValue!;

    // Extract token from URL or raw value
    String token = raw;
    if (raw.contains('/kambing/scan/')) {
      token = raw.split('/kambing/scan/').last;
    } else if (raw.contains('/kambing/getdetail/')) {
      // Legacy QR format - try to get by ID
      final id = int.tryParse(raw.split('/kambing/getdetail/').last);
      if (id != null) {
        _showResult(null, legacyId: id);
        return;
      }
    }

    final provider = context.read<KambingProvider>();
    final kambing = await provider.scanQr(token);
    if (!mounted) return;

    if (kambing != null) {
      _showResult(kambing);
    } else {
      SnackbarHelper.showError(context, provider.error ?? 'QR tidak valid');
      setState(() => _isProcessing = false);
    }
  }

  void _showResult(KambingModel? kambing, {int? legacyId}) {
    if (kambing == null && legacyId != null) {
      // Navigate to detail by ID directly
      context.push('/kambing/$legacyId');
      setState(() => _isProcessing = false);
      return;
    }

    if (kambing == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.pets, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(kambing.namaKambing,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${kambing.jenisKambing} • ${kambing.kelamin}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _KondisiBadge(kambing.kondisi),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/kambing/${kambing.kambingId}');
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Lihat Detail'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isProcessing = false);
              },
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: const Text('Scan Lagi'),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() => _isProcessing = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Kambing'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: _controller.switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay scan area
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryLight, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Spacer(),
                  Container(height: 2, color: AppColors.primaryLight),
                  const Spacer(),
                ],
              ),
            ),
          ),
          // Bottom hint
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Arahkan kamera ke QR Code kambing',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            ),
        ],
      ),
    );
  }
}

class _KondisiBadge extends StatelessWidget {
  final String kondisi;
  const _KondisiBadge(this.kondisi);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (kondisi.toLowerCase()) {
      case 'sakit': color = AppColors.sakit; break;
      case 'dalam perawatan': color = AppColors.perawatan; break;
      default: color = AppColors.sehat;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(kondisi, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
