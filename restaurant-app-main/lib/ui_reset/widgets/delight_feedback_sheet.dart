import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/animations/flutterfx/bouncy_tap.dart';
import '../../core/animations/flutterfx/celebrate_particles.dart';

class DelightFeedbackSheet extends StatefulWidget {
  const DelightFeedbackSheet({
    super.key,
    required this.restaurantName,
    this.googleReviewUrl,
    required this.onSubmitFeedback,
  });

  final String restaurantName;
  final String? googleReviewUrl;
  final Future<void> Function({
    required int overallRating,
    required int foodRating,
    required int serviceRating,
    required int ambianceRating,
    required String comment,
  }) onSubmitFeedback;

  static Future<void> show(
    BuildContext context, {
    required String restaurantName,
    String? googleReviewUrl,
    required Future<void> Function({
      required int overallRating,
      required int foodRating,
      required int serviceRating,
      required int ambianceRating,
      required String comment,
    }) onSubmitFeedback,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => DelightFeedbackSheet(
        restaurantName: restaurantName,
        googleReviewUrl: googleReviewUrl,
        onSubmitFeedback: onSubmitFeedback,
      ),
    );
  }

  @override
  State<DelightFeedbackSheet> createState() => _DelightFeedbackSheetState();
}

class _DelightFeedbackSheetState extends State<DelightFeedbackSheet> {
  int _overallRating = 5;
  int _foodRating = 5;
  int _serviceRating = 5;
  int _ambianceRating = 5;
  final _commentController = TextEditingController();
  final GlobalKey<CelebrateParticlesState> _celebrateKey = GlobalKey();

  bool _submitted = false;
  bool _submitting = false;

  static const saffron = Color(0xFFC99232);
  static const ink = Color(0xFF071A31);
  static const leaf = Color(0xFF237A59);

  final List<String> _emojiReactions = const [
    '😡 Terrible',
    '😕 Poor',
    '🙂 Good',
    '😃 Very Good',
    '🤩 Outstanding!',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmitFeedback(
        overallRating: _overallRating,
        foodRating: _foodRating,
        serviceRating: _serviceRating,
        ambianceRating: _ambianceRating,
        comment: _commentController.text.trim(),
      );
      if (mounted) {
        setState(() => _submitted = true);
        _celebrateKey.currentState?.blast();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return CelebrateParticles(
      key: _celebrateKey,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_submitted) ...[
                // Submitted Celebration Screen
                const Icon(Icons.favorite_rounded, color: Color(0xFFE53935), size: 54),
                const SizedBox(height: 12),
                Text(
                  'Thank You So Much! ❤️',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your valuable feedback helps us serve you better each time at ${widget.restaurantName}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 18),
                if (_overallRating >= 4 && widget.googleReviewUrl != null && widget.googleReviewUrl!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFD7BC)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🌟 Help Our Local Restaurant Grow! 🌟',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Since you loved our food, could you please post your 5-star review on Google Maps? It takes only 10 seconds and means the world to our chefs!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        BouncyTap(
                          onTap: () async {
                            final uri = Uri.tryParse(widget.googleReviewUrl!);
                            if (uri != null) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x334285F4),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Post Review on Google Maps ⭐',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                BouncyTap(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Feedback Form
                Text(
                  'How was your dining today?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                Text(
                  widget.restaurantName,
                  style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // Overall Star Rating
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return BouncyTap(
                        onTap: () => setState(() => _overallRating = star),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            star <= _overallRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber.shade700,
                            size: 38,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _emojiReactions[(_overallRating - 1).clamp(0, 4)],
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: saffron,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Category Micro Ratings
                _microRatingRow('🍽️ Food & Taste', _foodRating, (r) => setState(() => _foodRating = r)),
                _microRatingRow('🛎️ Staff & Service', _serviceRating, (r) => setState(() => _serviceRating = r)),
                _microRatingRow('✨ Cleanliness & Ambiance', _ambianceRating, (r) => setState(() => _ambianceRating = r)),
                const SizedBox(height: 14),

                // Comment input
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: _overallRating >= 4
                        ? 'Tell us what you loved most about the dishes!'
                        : 'Please tell our manager what went wrong so we can fix it...',
                    hintStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE6DED2)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                BouncyTap(
                  onTap: _submitting ? null : _submit,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: saffron,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33C99232),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Submit Feedback',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _microRatingRow(String title, int currentRating, void Function(int rating) onRate) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                final star = index + 1;
                return BouncyTap(
                  onTap: () => onRate(star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      star <= currentRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
}
