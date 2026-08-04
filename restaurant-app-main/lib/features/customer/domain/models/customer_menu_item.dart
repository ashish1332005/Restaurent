class CustomerMenuItem {
  const CustomerMenuItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isVeg,
    this.defaultModifiers = const [],
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final double price;
  final String imageUrl;
  final bool isVeg;
  final List<String> defaultModifiers;
}
