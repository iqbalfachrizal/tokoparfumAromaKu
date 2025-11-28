import 'package:arunika/models/perfume.dart';

class CartItem {
  final Perfume perfume;
  int quantity;

  CartItem({required this.perfume, this.quantity = 1});
}