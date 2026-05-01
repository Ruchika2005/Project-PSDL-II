import 'package:flutter/material.dart';

enum CategoryType { expense, income }

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final CategoryType type;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.toARGB32(),
      'type': type.name,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: IconData(map['icon'] ?? Icons.category.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(map['color'] ?? Colors.teal.toARGB32()),
      type: CategoryType.values.firstWhere((e) => e.name == map['type']),
    );
  }
  static IconData getIconForName(String name) {
    final n = name.trim().toLowerCase();
    if (n.contains('food') || n.contains('eat') || n.contains('restaurant') || n.contains('dinner') || n.contains('lunch')) return Icons.restaurant;
    if (n.contains('transport') || n.contains('bus') || n.contains('train') || n.contains('taxi') || n.contains('fuel') || n.contains('petrol')) return Icons.directions_bus;
    if (n.contains('shop') || n.contains('buy') || n.contains('mall') || n.contains('fashion')) return Icons.shopping_bag;
    if (n.contains('salary') || n.contains('pay') || n.contains('work') || n.contains('income')) return Icons.work;
    if (n.contains('health') || n.contains('med') || n.contains('doctor') || n.contains('hospital') || n.contains('pharmacy')) return Icons.medical_services;
    if (n.contains('entertainment') || n.contains('movie') || n.contains('game') || n.contains('fun')) return Icons.movie;
    if (n.contains('bill') || n.contains('rent') || n.contains('utilit') || n.contains('electric') || n.contains('wifi')) return Icons.receipt;
    if (n.contains('grocery') || n.contains('market') || n.contains('fruit') || n.contains('milk')) return Icons.local_grocery_store;
    if (n.contains('invest') || n.contains('stock') || n.contains('crypto') || n.contains('mutual')) return Icons.trending_up;
    if (n.contains('education') || n.contains('school') || n.contains('college') || n.contains('book')) return Icons.school;
    if (n.contains('stationary') || n.contains('stationery') || n.contains('pen') || n.contains('study') || n.contains('pencil') || n.contains('exam')) return Icons.edit_note;
    if (n.contains('gift') || n.contains('present') || n.contains('birth')) return Icons.card_giftcard;
    if (n.contains('travel') || n.contains('flight') || n.contains('trip') || n.contains('hotel') || n.contains('tour')) return Icons.flight;
    if (n.contains('fitness') || n.contains('gym') || n.contains('workout') || n.contains('exercise') || n.contains('yoga')) return Icons.fitness_center;
    if (n.contains('home') || n.contains('house') || n.contains('maintenance') || n.contains('furniture')) return Icons.home;
    if (n.contains('car') || n.contains('auto') || n.contains('bike') || n.contains('vehicle')) return Icons.directions_car;
    if (n.contains('loan') || n.contains('debt') || n.contains('emi')) return Icons.account_balance;
    if (n.contains('sub') || n.contains('ott') || n.contains('streaming') || n.contains('premium')) return Icons.subscriptions;
    if (n.contains('mobile') || n.contains('phone') || n.contains('data') || n.contains('sim')) return Icons.smartphone;
    return Icons.category;
  }

  static Color getColorForName(String name) {
    final n = name.trim().toLowerCase();
    if (n.contains('food')) return Colors.orange;
    if (n.contains('transport')) return Colors.blue;
    if (n.contains('shopping')) return Colors.pink;
    if (n.contains('salary')) return Colors.green;
    if (n.contains('health')) return Colors.red;
    if (n.contains('entertainment')) return Colors.purple;
    if (n.contains('bill')) return Colors.amber;
    if (n.contains('grocery')) return Colors.lightGreen;
    if (n.contains('invest')) return Colors.teal;
    if (n.contains('education')) return Colors.indigo;
    if (n.contains('stationary') || n.contains('stationery')) return Colors.brown;
    if (n.contains('fitness')) return Colors.blueGrey;
    if (n.contains('home')) return Colors.deepOrange;
    if (n.contains('car') || n.contains('auto')) return Colors.cyan;
    return Colors.teal;
  }
}
