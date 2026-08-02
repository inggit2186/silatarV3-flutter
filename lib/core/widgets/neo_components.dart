import 'package:flutter/material.dart';
import '../theme/neo_mirai_theme.dart';
import '../utils/responsive.dart';

class NeoButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final Color? color;

  const NeoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? NeoMiraiColors.gold;
    final buttonHeight = Responsive.buttonHeight(52);

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: buttonHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
            ),
          ),
          child: _buildChild(buttonColor),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: NeoMiraiColors.rice,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(14)),
          ),
        ),
        child: _buildChild(NeoMiraiColors.rice),
      ),
    );
  }

  Widget _buildChild(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Responsive.iconSize(20)),
          SizedBox(width: Responsive.spacing(8)),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Chakra Petch',
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Chakra Petch',
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class NeoTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool enabled;
  final FocusNode? focusNode;

  const NeoTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: NeoMiraiColors.ink,
                  fontSize: Responsive.fontSize(12),
                ),
          ),
          SizedBox(height: Responsive.spacing(6)),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          focusNode: focusNode,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: Responsive.fontSize(14),
              ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: Responsive.fontSize(14),
              color: NeoMiraiColors.ash,
            ),
            filled: true,
            fillColor: NeoMiraiColors.rice,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(18),
              vertical: Responsive.spacing(14),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: Responsive.iconSize(20), color: NeoMiraiColors.inkSoft)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class NeoPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const NeoPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.onChanged,
  });

  @override
  State<NeoPasswordField> createState() => _NeoPasswordFieldState();
}

class _NeoPasswordFieldState extends State<NeoPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: NeoMiraiColors.ink,
                  fontSize: Responsive.fontSize(12),
                ),
          ),
          SizedBox(height: Responsive.spacing(6)),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: TextInputType.visiblePassword,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: Responsive.fontSize(14),
              ),
          decoration: InputDecoration(
            hintText: widget.hint ?? 'Masukkan password',
            hintStyle: TextStyle(
              fontSize: Responsive.fontSize(14),
              color: NeoMiraiColors.ash,
            ),
            filled: true,
            fillColor: NeoMiraiColors.rice,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(18),
              vertical: Responsive.spacing(14),
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: Responsive.iconSize(20),
              color: NeoMiraiColors.inkSoft,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: Responsive.iconSize(20),
                color: NeoMiraiColors.inkSoft,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class NeoDivider extends StatelessWidget {
  final String? text;

  const NeoDivider({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return Divider(height: 24, color: NeoMiraiColors.line);
    }

    return Row(
      children: [
        Expanded(child: Divider(color: NeoMiraiColors.line)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(14)),
          child: Text(
            text!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: NeoMiraiColors.ash,
                  fontSize: Responsive.fontSize(11),
                ),
          ),
        ),
        Expanded(child: Divider(color: NeoMiraiColors.line)),
      ],
    );
  }
}

class NeoSocialButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const NeoSocialButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = Responsive.buttonHeight(50);

    return SizedBox(
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(14)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Responsive.iconSize(22)),
            SizedBox(width: Responsive.spacing(8)),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: Responsive.fontSize(13),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
