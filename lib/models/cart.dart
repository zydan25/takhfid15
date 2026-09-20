import 'product.dart';

class CartItem {
  final Product product;
  final String size;
  final ProductColor color;
  int quantity;

  CartItem({
    required this.product,
    required this.size,
    required this.color,
    this.quantity = 1,
  });
}
