import 'package:flutter/material.dart';

enum MenuFlowSubView {
  overview,
  categoriesList,
  addItem,
  editItem,
  itemDetails,
  bulkSelection,
  categoryItems,
  reorderCategories,
  menuSettings,
}

class MenuFlowScreen extends StatefulWidget {
  const MenuFlowScreen({super.key});

  @override
  State<MenuFlowScreen> createState() => _MenuFlowScreenState();
}

class _MenuFlowScreenState extends State<MenuFlowScreen> {
  MenuFlowSubView _currentSubView = MenuFlowSubView.overview;

  Map<String, dynamic> _activeItem = {
    'id': '1',
    'name': 'Paneer Butter Masala',
    'category': 'Main Course',
    'price': 240,
    'isVeg': true,
    'isBestseller': true,
    'available': true,
    'addedOn': '12 Mar 2024, 10:30 AM',
    'updatedOn': '18 May 2024, 04:15 PM',
    'salesMonth': 128,
    'description':
        'Cottage cheese cooked in rich and creamy tomato gravy with mild spices.',
    'image':
        'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=500&q=80',
  };

  String _selectedCategoryTitle = 'Main Course';
  final Set<String> _bulkSelectedIds = {'1', '2', '3'};

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Main Course', 'count': 32, 'icon': Icons.dinner_dining_rounded},
    {'name': 'Starters', 'count': 18, 'icon': Icons.ramen_dining_rounded},
    {'name': 'Beverages', 'count': 16, 'icon': Icons.local_bar_rounded},
    {'name': 'Desserts', 'count': 10, 'icon': Icons.icecream_rounded},
    {'name': 'Breads', 'count': 8, 'icon': Icons.bakery_dining_rounded},
    {'name': 'Others', 'count': 6, 'icon': Icons.fastfood_rounded},
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {
      'id': '1',
      'name': 'Paneer Butter Masala',
      'category': 'Main Course',
      'price': 240,
      'isVeg': true,
      'isBestseller': true,
      'available': true,
      'addedOn': '12 Mar 2024, 10:30 AM',
      'updatedOn': '18 May 2024, 04:15 PM',
      'salesMonth': 128,
      'description':
          'Cottage cheese cooked in rich and creamy tomato gravy with mild spices.',
      'image':
          'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=500&q=80',
    },
    {
      'id': '2',
      'name': 'Chicken Biryani',
      'category': 'Main Course',
      'price': 280,
      'isVeg': false,
      'isBestseller': true,
      'available': true,
      'addedOn': '10 Feb 2024, 11:15 AM',
      'updatedOn': '15 May 2024, 02:20 PM',
      'salesMonth': 210,
      'description':
          'Fragrant basmati rice layered with tender marinated chicken and aromatics.',
      'image':
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80',
    },
    {
      'id': '3',
      'name': 'Veg Manchurian',
      'category': 'Starters',
      'price': 180,
      'isVeg': true,
      'isBestseller': false,
      'available': true,
      'addedOn': '05 Jan 2024, 09:00 AM',
      'updatedOn': '01 May 2024, 06:10 PM',
      'salesMonth': 95,
      'description':
          'Crispy fried vegetable balls tossed in spicy soy garlic sauce.',
      'image':
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500&q=80',
    },
    {
      'id': '4',
      'name': 'Dal Tadka',
      'category': 'Main Course',
      'price': 160,
      'isVeg': true,
      'isBestseller': false,
      'available': true,
      'addedOn': '15 Mar 2024, 12:30 PM',
      'updatedOn': '12 May 2024, 01:00 PM',
      'salesMonth': 140,
      'description': 'Yellow lentils tempered with garlic, cumin, and ghee.',
      'image':
          'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500&q=80',
    },
    {
      'id': '5',
      'name': 'Cold Coffee',
      'category': 'Beverages',
      'price': 120,
      'isVeg': true,
      'isBestseller': false,
      'available': false,
      'addedOn': '20 Apr 2024, 04:00 PM',
      'updatedOn': '18 May 2024, 05:00 PM',
      'salesMonth': 60,
      'description':
          'Rich blended coffee with cold milk and vanilla ice cream.',
      'image':
          'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=500&q=80',
    },
  ];

  // Design Tokens
  static const Color _orange = Color(0xFFFF4D0A);
  static const Color _bgLight = Color(0xFFFAFAFB);
  static const Color _cardBg = Colors.white;
  static const Color _borderSoft = Color(0xFFE8EDF3);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF687385);
  static const Color _green = Color(0xFF16A34A);

  static final List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  void _navigateToDetail(Map<String, dynamic> item) {
    setState(() {
      _activeItem = item;
      _currentSubView = MenuFlowSubView.itemDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgLight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildCurrentSubView(),
      ),
    );
  }

  Widget _buildCurrentSubView() {
    switch (_currentSubView) {
      case MenuFlowSubView.overview:
        return _buildScreen1Overview();
      case MenuFlowSubView.categoriesList:
        return _buildScreen2CategoriesList();
      case MenuFlowSubView.addItem:
        return _buildScreen3AddItem();
      case MenuFlowSubView.editItem:
        return _buildScreen4EditItem();
      case MenuFlowSubView.itemDetails:
        return _buildScreen5ItemDetails();
      case MenuFlowSubView.bulkSelection:
        return _buildScreen7BulkSelection();
      case MenuFlowSubView.categoryItems:
        return _buildScreen8CategoryItems();
      case MenuFlowSubView.reorderCategories:
        return _buildScreen9ReorderCategories();
      case MenuFlowSubView.menuSettings:
        return _buildScreen10MenuSettings();
    }
  }

  Widget _actionIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSoft),
        boxShadow: _cardShadow,
      ),
      child: IconButton(
        icon: Icon(icon, color: _textDark, size: 20),
        onPressed: onTap,
      ),
    );
  }

  // ================= 1. MENU OVERVIEW (Uncrowded & Clean) =================
  Widget _buildScreen1Overview() {
    return SingleChildScrollView(
      key: const ValueKey('MenuScreen1'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  _actionIconButton(
                    Icons.settings_outlined,
                    () => setState(
                      () => _currentSubView = MenuFlowSubView.menuSettings,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _actionIconButton(
                    Icons.notifications_none_rounded,
                    () => _showToast('No new notifications'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: _textMuted, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search menu items...',
                      hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: _textDark,
                    size: 20,
                  ),
                  onPressed: _showMenuFiltersModal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3 Stat Cards Strip
          Row(
            children: [
              Expanded(
                child: _spaciousMiniStatTile(
                  'Total Items',
                  '124',
                  const Color(0xFF2563EB),
                  const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _spaciousMiniStatTile(
                  'Categories',
                  '12',
                  const Color(0xFF7C3AED),
                  const Color(0xFFF5F3FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _spaciousMiniStatTile(
                  'Unavailable',
                  '8',
                  const Color(0xFFDC2626),
                  const Color(0xFFFEF2F2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Categories Header & Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: -0.3,
                ),
              ),
              TextButton(
                onPressed: () => setState(
                  () => _currentSubView = MenuFlowSubView.categoriesList,
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: _orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: _categories.map((cat) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryTitle = cat['name'];
                    _currentSubView = MenuFlowSubView.categoryItems;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderSoft),
                    boxShadow: _cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          color: _orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cat['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${cat['count']} items',
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 26),

          // Items Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'All Menu Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(
                      () => _currentSubView = MenuFlowSubView.bulkSelection,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EDF3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Select Bulk',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () =>
                    setState(() => _currentSubView = MenuFlowSubView.addItem),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Add Item',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ..._menuItems.map((item) => _buildCleanMenuItemCard(item)),
        ],
      ),
    );
  }

  Widget _spaciousMiniStatTile(
    String label,
    String count,
    Color accent,
    Color bgTint,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderSoft),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanMenuItemCard(Map<String, dynamic> item) {
    final isVeg = item['isVeg'] as bool;
    final isBestseller = (item['isBestseller'] ?? false) as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderSoft),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              item['image'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: const Color(0xFFE8EDF3),
                child: const Icon(Icons.fastfood, color: _textMuted),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToDetail(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isVeg
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isVeg ? 'Veg' : 'Non-Veg',
                          style: TextStyle(
                            color: isVeg ? _green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isBestseller) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Bestseller',
                            style: TextStyle(
                              color: Color(0xFFEA580C),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ ${item['price']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Switch(
            value: item['available'],
            activeThumbColor: _green,
            onChanged: (val) {
              setState(() => item['available'] = val);
            },
          ),
        ],
      ),
    );
  }

  // ================= 2. CATEGORIES LIST =================
  Widget _buildScreen2CategoriesList() {
    return SingleChildScrollView(
      key: const ValueKey('MenuScreen2'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIconButton(
                Icons.arrow_back_rounded,
                () =>
                    setState(() => _currentSubView = MenuFlowSubView.overview),
              ),
              const SizedBox(width: 12),
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              _actionIconButton(
                Icons.reorder_rounded,
                () => setState(
                  () => _currentSubView = MenuFlowSubView.reorderCategories,
                ),
              ),
              const SizedBox(width: 8),
              _actionIconButton(
                Icons.add_rounded,
                () => _showToast('Add category dialog'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ..._categories.map((cat) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderSoft),
                boxShadow: _cardShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator_rounded, color: _textMuted),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: _orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _textDark,
                          ),
                        ),
                        Text(
                          '${cat['count']} items',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: _textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedCategoryTitle = cat['name'];
                        _currentSubView = MenuFlowSubView.categoryItems;
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= 3. ADD MENU ITEM =================
  Widget _buildScreen3AddItem() {
    String type = 'Veg';
    bool available = true;

    return StatefulBuilder(
      key: const ValueKey('MenuScreen3'),
      builder: (ctx, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _actionIconButton(
                    Icons.arrow_back_rounded,
                    () => setState(
                      () => _currentSubView = MenuFlowSubView.overview,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Menu Item',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Item Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _borderSoft),
                  boxShadow: _cardShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: _textMuted,
                      size: 30,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add Photo',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Item Name *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter item name',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Category *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: 'Main Course',
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c['name'] as String,
                        child: Text(c['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (val) {},
              ),
              const SizedBox(height: 16),

              const Text(
                'Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: type == 'Veg'
                            ? const Color(0xFFF0FDF4)
                            : Colors.white,
                        side: BorderSide(
                          color: type == 'Veg' ? _green : _borderSoft,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => setLocalState(() => type = 'Veg'),
                      child: Text(
                        'Veg',
                        style: TextStyle(
                          color: type == 'Veg' ? _green : _textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: type == 'Non-Veg'
                            ? const Color(0xFFFEF2F2)
                            : Colors.white,
                        side: BorderSide(
                          color: type == 'Non-Veg' ? Colors.red : _borderSoft,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => setLocalState(() => type = 'Non-Veg'),
                      child: Text(
                        'Non-Veg',
                        style: TextStyle(
                          color: type == 'Non-Veg' ? Colors.red : _textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Price *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '₹ Enter price',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Description (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter item description',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Availability',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Row(
                    children: [
                      Text(
                        available ? 'Available' : 'Unavailable',
                        style: const TextStyle(color: _textMuted, fontSize: 13),
                      ),
                      Switch(
                        value: available,
                        activeThumbColor: _green,
                        onChanged: (val) =>
                            setLocalState(() => available = val),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _currentSubView = MenuFlowSubView.overview);
                    _showToast('Item saved successfully!');
                  },
                  child: const Text(
                    'Save Item',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  // ================= 4. EDIT MENU ITEM =================
  Widget _buildScreen4EditItem() {
    final item = _activeItem;

    return SingleChildScrollView(
      key: const ValueKey('MenuScreen4'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIconButton(
                Icons.arrow_back_rounded,
                () => setState(
                  () => _currentSubView = MenuFlowSubView.itemDetails,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Menu Item',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              _actionIconButton(
                Icons.delete_outline_rounded,
                () => _showToast('Delete item tapped'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  item['image'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.75),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Change', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          const Text(
            'Item Name *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item['name'],
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Category *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: item['category'],
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: _categories
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c['name'] as String,
                    child: Text(c['name'] as String),
                  ),
                )
                .toList(),
            onChanged: (val) {},
          ),
          const SizedBox(height: 16),

          const Text(
            'Price *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: '₹ ${item['price']}',
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Description (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item['description'],
            maxLines: 3,
            decoration: InputDecoration(
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                setState(() => _currentSubView = MenuFlowSubView.itemDetails);
                _showToast('Item updated!');
              },
              child: const Text(
                'Update Item',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 5. ITEM DETAILS =================
  Widget _buildScreen5ItemDetails() {
    final item = _activeItem;
    final isVeg = item['isVeg'] as bool;

    return SingleChildScrollView(
      key: const ValueKey('MenuScreen5'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIconButton(
                Icons.arrow_back_rounded,
                () =>
                    setState(() => _currentSubView = MenuFlowSubView.overview),
              ),
              const SizedBox(width: 12),
              const Text(
                'Item Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              _actionIconButton(Icons.more_vert_rounded, () {}),
            ],
          ),
          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              item['image'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['category'],
                      style: const TextStyle(color: _textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.circle, color: _green, size: 10),
                  const SizedBox(width: 6),
                  const Text(
                    'Available',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isVeg
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isVeg ? 'Veg' : 'Non-Veg',
                  style: TextStyle(
                    color: isVeg ? _green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Bestseller',
                  style: TextStyle(
                    color: Color(0xFFEA580C),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          _detailRow('Price', '₹ ${item['price']}'),
          _detailRow('Category', item['category']),
          _detailRow('Type', isVeg ? 'Veg' : 'Non-Veg'),
          _detailRow('Added on', item['addedOn'] ?? '12 Mar 2024, 10:30 AM'),
          _detailRow(
            'Updated on',
            item['updatedOn'] ?? '18 May 2024, 04:15 PM',
          ),
          const Divider(height: 32),

          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            item['description'],
            style: const TextStyle(
              color: _textMuted,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales (This Month)',
                style: TextStyle(color: _textMuted, fontSize: 14),
              ),
              Text(
                '${item['salesMonth'] ?? 128}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: _borderSoft),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => setState(
                    () => _currentSubView = MenuFlowSubView.editItem,
                  ),
                  child: const Text(
                    'Edit Item',
                    style: TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _currentSubView = MenuFlowSubView.overview);
                    _showToast('Item deleted');
                  },
                  child: const Text(
                    'Delete Item',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 14)),
          Text(
            val,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ================= 6. MENU FILTERS MODAL =================
  void _showMenuFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String filterCat = 'All';
        String filterType = 'All';
        String filterAvail = 'All';

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            filterCat = 'All';
                            filterType = 'All';
                            filterAvail = 'All';
                          });
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: filterCat,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items:
                        [
                              'All',
                              'Main Course',
                              'Starters',
                              'Beverages',
                              'Desserts',
                            ]
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: (v) =>
                        setModalState(() => filterCat = v ?? 'All'),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['All', 'Veg', 'Non-Veg'].map((t) {
                      final isSel = filterType == t;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(t),
                            selected: isSel,
                            selectedColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : _textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) =>
                                setModalState(() => filterType = t),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Availability',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['All', 'Available', 'Unavailable'].map((a) {
                      final isSel = filterAvail == a;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(a),
                            selected: isSel,
                            selectedColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : _textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            onSelected: (val) =>
                                setModalState(() => filterAvail = a),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: _borderSoft),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: _textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showToast('Filters applied!');
                          },
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= 7. BULK SELECTION & ACTIONS =================
  Widget _buildScreen7BulkSelection() {
    return SingleChildScrollView(
      key: const ValueKey('MenuScreen7'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_bulkSelectedIds.length} Selected',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _currentSubView = MenuFlowSubView.overview),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ..._menuItems.map((item) {
            final isChecked = _bulkSelectedIds.contains(item['id']);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isChecked ? _orange : _borderSoft,
                  width: isChecked ? 1.5 : 1.0,
                ),
                boxShadow: _cardShadow,
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: _orange,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _bulkSelectedIds.add(item['id']);
                        } else {
                          _bulkSelectedIds.remove(item['id']);
                        }
                      });
                    },
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '₹ ${item['price']}',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: item['available'],
                    activeThumbColor: _green,
                    onChanged: (v) {},
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _borderSoft),
              boxShadow: _cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bulk Actions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _bulkActionIcon(
                      Icons.check_circle_outline_rounded,
                      'Make Available',
                      _green,
                      () => _showToast('Bulk available updated'),
                    ),
                    _bulkActionIcon(
                      Icons.remove_circle_outline_rounded,
                      'Make Unavailable',
                      _orange,
                      () => _showToast('Bulk unavailable updated'),
                    ),
                    _bulkActionIcon(
                      Icons.folder_open_rounded,
                      'Change Category',
                      Colors.purple,
                      () => _showToast('Category dialog'),
                    ),
                    _bulkActionIcon(
                      Icons.delete_outline_rounded,
                      'Delete Items',
                      Colors.red,
                      () => _showToast('Items deleted'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulkActionIcon(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ================= 8. CATEGORY SPECIFIC ITEMS =================
  Widget _buildScreen8CategoryItems() {
    final title = _selectedCategoryTitle;
    final items = _menuItems
        .where((i) => (i['category'] as String) == title)
        .toList();

    return SingleChildScrollView(
      key: const ValueKey('MenuScreen8'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _actionIconButton(
                Icons.arrow_back_rounded,
                () =>
                    setState(() => _currentSubView = MenuFlowSubView.overview),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    '${items.length} items',
                    style: const TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              _actionIconButton(Icons.edit_outlined, () {}),
            ],
          ),
          const SizedBox(height: 18),

          ...items.map((it) => _buildCleanMenuItemCard(it)),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () =>
                  setState(() => _currentSubView = MenuFlowSubView.addItem),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add Item',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 9. REORDER CATEGORIES =================
  Widget _buildScreen9ReorderCategories() {
    return SingleChildScrollView(
      key: const ValueKey('MenuScreen9'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _actionIconButton(
                    Icons.arrow_back_rounded,
                    () => setState(
                      () => _currentSubView = MenuFlowSubView.categoriesList,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Reorder Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(
                    () => _currentSubView = MenuFlowSubView.categoriesList,
                  );
                  _showToast('Order saved!');
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: _orange, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Drag and drop to reorder categories',
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
          const SizedBox(height: 18),

          ..._categories.map((cat) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderSoft),
                boxShadow: _cardShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_rounded, color: _textMuted),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: _orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    cat['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= 10. MENU SETTINGS =================
  Widget _buildScreen10MenuSettings() {
    bool showImages = true;
    bool showDesc = true;

    return StatefulBuilder(
      key: const ValueKey('MenuScreen10'),
      builder: (ctx, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _actionIconButton(
                    Icons.arrow_back_rounded,
                    () => setState(
                      () => _currentSubView = MenuFlowSubView.overview,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Menu Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _settingTile(
                Icons.dashboard_customize_outlined,
                'Display Settings',
                'Choose how menu is displayed',
              ),
              _settingTile(Icons.currency_rupee_rounded, 'Currency', '₹ INR'),
              _settingTile(
                Icons.receipt_long_outlined,
                'Tax Settings',
                'Inclusive of tax',
              ),

              const Divider(height: 28),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.image_outlined, color: _textDark),
                title: const Text(
                  'Show Food Images',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                value: showImages,
                activeThumbColor: _green,
                onChanged: (v) => setLocalState(() => showImages = v),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.description_outlined,
                  color: _textDark,
                ),
                title: const Text(
                  'Show Item Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                value: showDesc,
                activeThumbColor: _green,
                onChanged: (v) => setLocalState(() => showDesc = v),
              ),

              const Divider(height: 28),

              _settingTile(
                Icons.notifications_active_outlined,
                'Low Stock Alert',
                'When item stock is low',
              ),
              _settingTile(
                Icons.qr_code_scanner_rounded,
                'Menu QR Preview',
                'Preview how menu looks for customers',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _settingTile(IconData icon, String title, String sub) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFE8EDF3),
        child: Icon(icon, color: _textDark, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(color: _textMuted, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: _textMuted,
        size: 22,
      ),
      onTap: () {},
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        backgroundColor: _textDark,
      ),
    );
  }
}
