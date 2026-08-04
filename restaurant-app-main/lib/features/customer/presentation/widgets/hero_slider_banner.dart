import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/customer_cart_provider.dart';
import '../../domain/models/customer_menu_item.dart';

class HeroSliderBanner extends StatefulWidget {
  const HeroSliderBanner({
    super.key,
    required this.onOrderNowTap,
    required this.onOfferTap,
    required this.featuredItems,
    required this.vegOnly,
    this.integrated = false,
  });

  final VoidCallback onOrderNowTap;
  final VoidCallback onOfferTap;
  final List<CustomerMenuItem> featuredItems;
  final bool vegOnly;
  final bool integrated;

  @override
  State<HeroSliderBanner> createState() => _HeroSliderBannerState();
}

class _HeroSliderBannerState extends State<HeroSliderBanner> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  List<_SpotlightSlide> get _slides {
    if (widget.featuredItems.isEmpty) {
      return [
        _SpotlightSlide.offer(
          badge: widget.vegOnly ? 'Veg mode' : 'Non-veg mode',
          title: widget.vegOnly ? 'Fresh veg picks' : 'Bold non-veg picks',
          subtitle: widget.vegOnly
              ? 'Switch through curated vegetarian dishes built for lighter cravings.'
              : 'Switch through protein-rich dishes built for stronger cravings.',
          imageUrl:
              'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=1000&auto=format&fit=crop',
          highlight: widget.vegOnly ? 'Veg only' : 'Non-veg only',
          ctaLabel: 'Browse Menu',
          accent: widget.vegOnly
              ? const Color(0xFF1FA971)
              : const Color(0xFFB91C1C),
        ),
      ];
    }

    final primaryItem = widget.featuredItems.first;
    final secondaryItem = widget.featuredItems.length > 1
        ? widget.featuredItems[1]
        : widget.featuredItems.first;

    return [
      _SpotlightSlide.dish(
        badge: widget.vegOnly ? 'Veg spotlight' : 'Non-veg spotlight',
        title: primaryItem.title,
        subtitle: widget.vegOnly
            ? 'Fresh vegetarian favorite with quick prep and full flavor.'
            : 'High-protein crowd pick with bold seasoning and fast service.',
        imageUrl: primaryItem.imageUrl,
        highlight: formatPrice(primaryItem.price),
        ctaLabel: 'Order Now',
        accent: widget.vegOnly
            ? const Color(0xFF1FA971)
            : const Color(0xFFEF4444),
      ),
      _SpotlightSlide.offer(
        badge: widget.vegOnly ? 'Veg deal' : 'Non-veg deal',
        title: widget.vegOnly
            ? '20% off on veg specials'
            : 'Combo savings on non-veg picks',
        subtitle: widget.vegOnly
            ? 'Use WELCOME20 to unlock lighter veg cravings above Rs. 299.'
            : 'Use FEAST20 and unlock stronger non-veg combo value above Rs. 399.',
        imageUrl: widget.vegOnly
            ? 'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?q=80&w=1000&auto=format&fit=crop'
            : 'https://images.unsplash.com/photo-1526367790999-0150786686a2?q=80&w=1000&auto=format&fit=crop',
        highlight: widget.vegOnly ? 'WELCOME20' : 'FEAST20',
        ctaLabel: 'Claim Offer',
        accent: widget.vegOnly
            ? const Color(0xFF0F766E)
            : const Color(0xFFB91C1C),
      ),
      _SpotlightSlide.dish(
        badge: 'Popular now',
        title: secondaryItem.title,
        subtitle: widget.vegOnly
            ? 'A top vegetarian comfort pick that keeps repeat orders coming back.'
            : 'A best-selling non-veg option built for richer cravings and bigger appetite.',
        imageUrl: secondaryItem.imageUrl,
        highlight: formatPrice(secondaryItem.price),
        ctaLabel: 'Add Fast',
        accent: widget.vegOnly
            ? const Color(0xFFCA8A04)
            : const Color(0xFF2563EB),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    _startAutoSlide();
  }

  @override
  void didUpdateWidget(covariant HeroSliderBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vegOnly != widget.vegOnly ||
        oldWidget.featuredItems != widget.featuredItems) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients || _slides.length <= 1) {
        return;
      }

      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;
    final bannerHeight = width < 340
        ? 220.0
        : compact
        ? 224.0
        : 230.0;

    return Container(
      color: const Color(0xFF10245B),
      child: Column(
        children: [
          SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: _slides.length,
              onPageChanged: (value) {
                setState(() {
                  _currentPage = value;
                });
              },
              itemBuilder: (context, index) {
                final slide = _slides[index];

                return _SpotlightCard(
                  slide: slide,
                  compact: compact,
                  integrated: widget.integrated,
                  onTap: slide.type == _SpotlightType.offer
                      ? widget.onOfferTap
                      : widget.onOrderNowTap,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _buildIndicator(
                  isActive: index == _currentPage,
                  integrated: widget.integrated,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildIndicator({required bool isActive, required bool integrated}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      height: 6,
      width: isActive ? 18 : 6,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryColor
            : integrated
            ? Colors.white.withValues(alpha: 0.32)
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({
    required this.slide,
    required this.compact,
    required this.integrated,
    required this.onTap,
  });

  final _SpotlightSlide slide;
  final bool compact;
  final bool integrated;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tight = width < 340;
        final contentPadding = tight
            ? 18.0
            : compact
            ? 20.0
            : 24.0;
        final contentMaxWidth = width - (contentPadding * 2);
        final titleFontSize = tight
            ? 21.0
            : compact
            ? 23.0
            : 28.0;

        return ClipRRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  slide.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFF10245B),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white54,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.88),
                        Colors.black.withValues(alpha: 0.58),
                        slide.accent.withValues(alpha: 0.16),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: contentMaxWidth.clamp(140.0, 300.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slide.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                            height: 1.02,
                          ),
                        ),
                        SizedBox(height: tight ? 12 : 16),
                        TextButton.icon(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: tight ? 12 : 14,
                              vertical: tight ? 8 : 10,
                            ),
                            minimumSize: Size(
                              tight ? 112 : 124,
                              tight ? 34 : 38,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.10,
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_forward_rounded,
                            size: tight ? 14 : 16,
                          ),
                          label: Text(
                            slide.ctaLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: tight ? 12 : 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _SpotlightType { dish, offer }

class _SpotlightSlide {
  const _SpotlightSlide._({
    required this.type,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.highlight,
    required this.ctaLabel,
    required this.accent,
  });

  const _SpotlightSlide.dish({
    required String badge,
    required String title,
    required String subtitle,
    required String imageUrl,
    required String highlight,
    required String ctaLabel,
    required Color accent,
  }) : this._(
         type: _SpotlightType.dish,
         badge: badge,
         title: title,
         subtitle: subtitle,
         imageUrl: imageUrl,
         highlight: highlight,
         ctaLabel: ctaLabel,
         accent: accent,
       );

  const _SpotlightSlide.offer({
    required String badge,
    required String title,
    required String subtitle,
    required String imageUrl,
    required String highlight,
    required String ctaLabel,
    required Color accent,
  }) : this._(
         type: _SpotlightType.offer,
         badge: badge,
         title: title,
         subtitle: subtitle,
         imageUrl: imageUrl,
         highlight: highlight,
         ctaLabel: ctaLabel,
         accent: accent,
       );

  final _SpotlightType type;
  final String badge;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String highlight;
  final String ctaLabel;
  final Color accent;
}
