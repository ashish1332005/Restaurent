import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/customer_qr_session_provider.dart';
import '../widgets/customer_ui.dart';

class CustomerScannerScreen extends ConsumerStatefulWidget {
  const CustomerScannerScreen({super.key});

  @override
  ConsumerState<CustomerScannerScreen> createState() =>
      _CustomerScannerScreenState();
}

class _CustomerScannerScreenState extends ConsumerState<CustomerScannerScreen> {
  late final MobileScannerController _controller;
  bool _handledScan = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF111827), Color(0xFF020617)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Scan Table QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const CustomerBadgeChip(
                        label: 'Phone camera',
                        icon: Icons.camera_alt_outlined,
                        color: Color(0xFF5EEAD4),
                        backgroundColor: Color(0x2214B8A6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.white70),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Table par laga QR scan karo. App table identify karke menu khol degi; CCTV ki zaroorat nahi hai.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                MobileScanner(
                                  controller: _controller,
                                  onDetect: _onDetect,
                                  errorBuilder: (context, error) =>
                                      _buildCameraError(error),
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(36),
                                    border: Border.all(
                                      color: AppTheme.primaryColor,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 210,
                                    height: 2,
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 18,
                                  right: 18,
                                  bottom: 18,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'QR ko frame ke andar rakho',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomerSectionCard(
                    title: 'Scanner actions',
                    subtitle: 'Flash/camera controls aur testing shortcut.',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _controller.toggleTorch,
                                icon: const Icon(Icons.flash_on_rounded),
                                label: const Text('Flash'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _controller.switchCamera,
                                icon: const Icon(Icons.cameraswitch_rounded),
                                label: const Text('Camera'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildActionTile(
                          icon: Icons.table_restaurant_outlined,
                          title: 'Table QR format',
                          subtitle:
                              'Plain 05, URL ?table=05, /qr/table/05, ya JSON tableNo sab supported.',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _openTableMenu(
                              tableNo: '05',
                              restaurantName: 'Sharma Restaurant',
                              primaryColorHex: '#FF4D0A',
                            ),
                            child: const Text('Demo: Use Table 05 QR'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    return Container(
      color: const Color(0xFF111827),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Camera open nahi ho paaya',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            error.errorDetails?.message ??
                'Camera permission allow karo aur dobara try karo.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handledScan) return;
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .firstOrNull;

    if (rawValue == null) return;

    final payload = _QrTablePayload.tryParse(rawValue);
    if (payload == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Ye restaurant table QR nahi lag raha.'),
          ),
        );
      return;
    }

    _handledScan = true;
    _controller.stop();
    _openTableMenu(
      tableNo: payload.tableNo,
      restaurantName: payload.restaurantName,
      logoUrl: payload.logoUrl,
      primaryColorHex: payload.primaryColorHex,
    );
  }

  void _openTableMenu({
    required String tableNo,
    String restaurantName = 'Sharma Restaurant',
    String logoUrl = '',
    String primaryColorHex = '#FF4D0A',
  }) {
    ref
        .read(customerQrSessionProvider.notifier)
        .startTableSession(
          tableNo: tableNo,
          restaurantName: restaurantName,
          logoUrl: logoUrl,
          primaryColorHex: primaryColorHex,
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Table $tableNo identified. Opening menu.')),
      );
    context.go('/customer/menu');
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrTablePayload {
  const _QrTablePayload({
    required this.tableNo,
    required this.restaurantName,
    required this.logoUrl,
    required this.primaryColorHex,
  });

  final String tableNo;
  final String restaurantName;
  final String logoUrl;
  final String primaryColorHex;

  static _QrTablePayload? tryParse(String rawValue) {
    final value = rawValue.trim();
    final jsonPayload = _tryParseJson(value);
    if (jsonPayload != null) return jsonPayload;

    final uriPayload = _tryParseUri(value);
    if (uriPayload != null) return uriPayload;

    final directTable = _cleanTableCode(value);
    if (directTable != null) {
      return _QrTablePayload(
        tableNo: directTable,
        restaurantName: 'Sharma Restaurant',
        logoUrl: '',
        primaryColorHex: '#FF4D0A',
      );
    }
    return null;
  }

  static _QrTablePayload? _tryParseJson(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      final tableNo = _cleanTableCode(
        '${decoded['tableNo'] ?? decoded['table'] ?? decoded['tableCode'] ?? ''}',
      );
      if (tableNo == null) return null;
      return _QrTablePayload(
        tableNo: tableNo,
        restaurantName:
            '${decoded['restaurantName'] ?? decoded['restaurant'] ?? 'Sharma Restaurant'}',
        logoUrl: '${decoded['logoUrl'] ?? decoded['logo'] ?? ''}',
        primaryColorHex:
            '${decoded['primaryColorHex'] ?? decoded['primaryColor'] ?? '#FF4D0A'}',
      );
    } catch (_) {
      return null;
    }
  }

  static _QrTablePayload? _tryParseUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    final queryTable =
        uri.queryParameters['table'] ??
        uri.queryParameters['tableNo'] ??
        uri.queryParameters['tableCode'] ??
        uri.queryParameters['tableId'];
    final pathTable = uri.pathSegments.isEmpty ? null : uri.pathSegments.last;
    final tableNo = _cleanTableCode(queryTable ?? pathTable ?? '');
    if (tableNo == null) return null;

    return _QrTablePayload(
      tableNo: tableNo,
      restaurantName:
          uri.queryParameters['restaurantName'] ??
          uri.queryParameters['restaurant'] ??
          'Sharma Restaurant',
      logoUrl:
          uri.queryParameters['logoUrl'] ?? uri.queryParameters['logo'] ?? '',
      primaryColorHex:
          uri.queryParameters['primaryColor'] ??
          uri.queryParameters['primaryColorHex'] ??
          '#FF4D0A',
    );
  }

  static String? _cleanTableCode(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final match = RegExp(
      r'(?:table|tbl|t)?\s*[-_:]?\s*([a-zA-Z0-9]{1,8})$',
      caseSensitive: false,
    ).firstMatch(value);
    return match?.group(1)?.toUpperCase();
  }
}
