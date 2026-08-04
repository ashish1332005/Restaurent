import '../domain/models/customer_menu_item.dart';

const popularCustomerMenuItems = [
  CustomerMenuItem(
    id: 'margherita-pizza',
    title: 'Margherita Pizza',
    category: 'Pizza',
    description: 'Classic delight with 100% real mozzarella cheese',
    price: 299.0,
    imageUrl:
        'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?q=80&w=400&auto=format&fit=crop',
    isVeg: true,
    defaultModifiers: ['Medium', 'Classic Crust'],
  ),
  CustomerMenuItem(
    id: 'paneer-tikka-burger',
    title: 'Paneer Tikka Burger',
    category: 'Burgers',
    description: 'Grilled paneer with spicy tikka sauce',
    price: 179.0,
    imageUrl:
        'https://images.unsplash.com/photo-1550547660-d9450f859349?q=80&w=400&auto=format&fit=crop',
    isVeg: true,
    defaultModifiers: ['Regular'],
  ),
  CustomerMenuItem(
    id: 'creamy-alfredo-pasta',
    title: 'Creamy Alfredo Pasta',
    category: 'Italian',
    description: 'Creamy white sauce with herbs and vegetables',
    price: 249.0,
    imageUrl:
        'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?q=80&w=400&auto=format&fit=crop',
    isVeg: true,
    defaultModifiers: ['Regular'],
  ),
  CustomerMenuItem(
    id: 'veg-thali',
    title: 'Royal Veg Thali',
    category: 'Thali',
    description: 'North Indian comfort platter with sabzi, dal, rice and roti',
    price: 199.0,
    imageUrl:
        'https://images.unsplash.com/photo-1613292443284-8d10ef9383fe?q=80&w=400&auto=format&fit=crop',
    isVeg: true,
    defaultModifiers: ['Regular'],
  ),
  CustomerMenuItem(
    id: 'garden-salad',
    title: 'Garden Crunch Salad',
    category: 'Salad',
    description: 'Fresh greens, olives, corn and herbed dressing',
    price: 169.0,
    imageUrl:
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop',
    isVeg: true,
    defaultModifiers: ['Regular'],
  ),
  CustomerMenuItem(
    id: 'lava-cake',
    title: 'Chocolate Lava Cake',
    category: 'Desserts',
    description: 'Warm chocolate-centered dessert for quick sweet cravings',
    price: 129.0,
    imageUrl:
        'https://images.unsplash.com/photo-1551024506-0bccd828d307?q=80&w=400&auto=format&fit=crop',
    isVeg: true,
    defaultModifiers: ['Single serve'],
  ),
  CustomerMenuItem(
    id: 'pepperoni-pizza',
    title: 'Pepperoni Blast Pizza',
    category: 'Pizza',
    description: 'Loaded with pepperoni, cheese and smoky tomato sauce',
    price: 379.0,
    imageUrl:
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=400&auto=format&fit=crop',
    isVeg: false,
    defaultModifiers: ['Medium', 'Thin Crust'],
  ),
  CustomerMenuItem(
    id: 'smoked-chicken-burger',
    title: 'Smoked Chicken Burger',
    category: 'Burgers',
    description: 'Juicy chicken patty with chipotle mayo and lettuce',
    price: 229.0,
    imageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=400&auto=format&fit=crop',
    isVeg: false,
    defaultModifiers: ['Regular'],
  ),
  CustomerMenuItem(
    id: 'chicken-alfredo-pasta',
    title: 'Chicken Alfredo Pasta',
    category: 'Italian',
    description: 'Creamy alfredo pasta finished with grilled chicken strips',
    price: 319.0,
    imageUrl:
        'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?q=80&w=400&auto=format&fit=crop',
    isVeg: false,
    defaultModifiers: ['Regular'],
  ),
  CustomerMenuItem(
    id: 'tandoori-chicken-platter',
    title: 'Tandoori Chicken Platter',
    category: 'Grill',
    description: 'Charred chicken pieces served with mint chutney and onions',
    price: 289.0,
    imageUrl:
        'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?q=80&w=400&auto=format&fit=crop',
    isVeg: false,
    defaultModifiers: ['Half'],
  ),
  CustomerMenuItem(
    id: 'chicken-biryani-bowl',
    title: 'Chicken Biryani Bowl',
    category: 'Biryani',
    description: 'Fragrant basmati rice layered with spiced chicken pieces',
    price: 259.0,
    imageUrl:
        'https://images.unsplash.com/photo-1547592180-85f173990554?q=80&w=400&auto=format&fit=crop',
    isVeg: false,
    defaultModifiers: ['Regular'],
  ),
];

const customerTopCategories = [
  'Pizza',
  'Burgers',
  'Italian',
  'Desserts',
  'Salad',
  'Thali',
  'Grill',
  'Biryani',
];
