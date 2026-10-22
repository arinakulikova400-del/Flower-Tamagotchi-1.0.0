import 'package:flutter/material.dart';

class ShopButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const ShopButton({
    super.key,
    required this.onTap,
    this.size = 55,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: const Color.fromARGB(255, 59, 117, 62),
        heroTag: 'shop',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.storefront, size: 28, color: Colors.white),
      ),
    );
  }
}