import 'package:flutter/material.dart';//flutter提供的ui组件

class Button extends StatelessWidget { //定义button类，StatelessWidget是无状态，不会随用户交互而更新
  final Function() onTap;
  final Widget childWidget; // 允许传入自定义子组件
  Button({super.key,required this.onTap, required this.childWidget, }); //button构造函数，

  @override //表示重写父类 StatelessWidget 中的 build 方法
  Widget build(BuildContext context) {//定义组件的 UI 构建逻辑，每次 Flutter 需要绘制组件时都会调用它。
    return GestureDetector(
      onTap: onTap,
      child: Container(//布局组件，设置大小，颜色等
        width: MediaQuery.of(context).size.width * 0.7,// 60% 屏幕宽度
        height: 70,  
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),//边框圆角
          border: Border.all(color: Colors.blueGrey),//边框颜色
          //color: Colors.blue, //背景颜色
        ),
        alignment: Alignment.center, // 让子组件居中(字体)
        child: childWidget, // 显示传入的组件
      ),
    );
  }
}