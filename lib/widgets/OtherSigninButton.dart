// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

class OtherLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;

  const OtherLoginButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: 60,
              color: iconColor ?? Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}