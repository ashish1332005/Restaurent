import 'package:flutter/material.dart';
import '../widgets/admin_ui.dart';
import '../widgets/cart/action_cards.dart';
import '../widgets/cart/cart_header.dart';
import '../widgets/cart/cart_item_card.dart';
import '../widgets/cart/checkout_bottom_bar.dart';
import '../widgets/cart/offer_progress_card.dart';
import '../widgets/cart/order_instructions_section.dart';
import '../widgets/cart/order_summary_card.dart';
import '../widgets/cart/order_type_selector.dart';

class AdminCartScreen extends StatelessWidget {
  const AdminCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                adminPageHorizontalPadding(context),
                adminPageVerticalPadding(context),
                adminPageHorizontalPadding(context),
                140,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminPageHeader(
                      eyebrow: 'ORDER DESK',
                      title: 'Handle live billing with less friction.',
                      subtitle:
                          'Review items, apply offers, and keep checkout actions visible for the counter team.',
                    ),
                    const SizedBox(height: 24),
                    const CartHeader(),
                    const OfferProgressCard(),
                    const SizedBox(height: 24),
                    AdminPanel(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const OrderTypeSelector(),
                          const SizedBox(height: 24),
                          const CartItemCard(
                            title: 'Margherita Pizza',
                            price: '\u20B9299',
                            quantity: 1,
                            modifiers: ['Medium', 'Classic Crust'],
                            imageUrl:
                                'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?q=80&w=400&auto=format&fit=crop',
                          ),
                          const CartItemCard(
                            title: 'Paneer Tikka Burger',
                            price: '\u20B9179',
                            quantity: 1,
                            modifiers: ['Regular'],
                            imageUrl:
                                'https://images.unsplash.com/photo-1550547660-d9450f859349?q=80&w=400&auto=format&fit=crop',
                          ),
                          const CartItemCard(
                            title: 'Creamy Alfredo Pasta',
                            price: '\u20B9249',
                            quantity: 1,
                            modifiers: ['Regular'],
                            imageUrl:
                                'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?q=80&w=400&auto=format&fit=crop',
                          ),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: AddMoreItemsCard(),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: ApplyCouponCard(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const OrderSummaryCard(),
                    const SizedBox(height: 24),
                    const OrderInstructionsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CheckoutBottomBar(),
        ),
      ],
    );
  }
}
