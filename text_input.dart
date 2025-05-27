import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  TextEditingController controller;
  String labelText;
  double marginLeft;
  double marginRight;
  Function(String text)? onChange;
  Function(PointerDownEvent event)? onTapOutSide;
  TextInput({
    required this.controller,
    this.labelText='',
    this.marginLeft=20,
    this.marginRight=20,
    this.onChange,
    this.onTapOutSide,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: marginLeft,right: marginRight,top: 5,bottom: 5),
      child: TextField(
        onTapOutside: onTapOutSide,
        onChanged: onChange,
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          filled: true,  // 启用背景填充
          fillColor: Theme.of(context).colorScheme.surfaceVariant, // 背景颜色（根据主题）
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),  // 圆角边框
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,  // 边框颜色
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),  // 圆角边框
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,  // 焦点时的边框颜色
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),  // 圆角边框
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.onSurface,  // 默认边框颜色
            ),
          ),
        ),
      )
    );
  }
}