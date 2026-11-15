import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class WifiDialog extends StatelessWidget {
  const WifiDialog({
    super.key,
    required this.restaurantName,
    required this.wifiPassword,
    this.wifiSsid,
  });

  final String restaurantName;
  final String wifiPassword;
  final String? wifiSsid;

  static Future<void> show(
    BuildContext context, {
    required String restaurantName,
    required String wifiPassword,
    String? wifiSsid,
  }) {
    return showDialog<void>(
      context: context,
      builder: (c) => WifiDialog(
        restaurantName: restaurantName,
        wifiPassword: wifiPassword,
        wifiSsid: wifiSsid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFC99232);
    const ink = Color(0xFF071A31);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1D6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.wifi_rounded, color: saffron, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest Wi-Fi',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      Text(
                        restaurantName,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (wifiSsid != null && wifiSsid!.isNotEmpty) ...[
              Text(
                'NETWORK NAME (SSID)',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                wifiSsid!,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              'WI-FI PASSWORD',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6DED2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      wifiPassword,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy password',
                    icon: const Icon(Icons.copy_rounded, color: saffron),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: wifiPassword));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Wi-Fi password copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: saffron,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: wifiPassword));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wi-Fi password copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy Password & Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
