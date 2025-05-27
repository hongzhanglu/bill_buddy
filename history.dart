import 'dart:convert';
import 'package:bill_buddy_test/pages/order_detail.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 用于格式化日期和货币

// Bill 类：表示账单数据
class Bill {
  final int id; // 账单ID
  final String uid; // 唯一标识符
  final DateTime date; // 账单日期
  final int split; // 分账人数
  final String restaurantName; // 餐厅名称
  final double subtotal; // 小计
  final double tax; // 税额
  final double total; // 总金额
  final Map<String, dynamic> orderDetail; // 订单详情

  Bill({
    required this.id,
    required this.uid,
    required this.date,
    required this.split,
    required this.restaurantName,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.orderDetail,
  });

  // 从JSON创建Bill对象
  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as int,
      uid: json['uid'] as String,
      date: DateTime.parse(json['date'] as String),
      split: json['split'] as int,
      restaurantName: json['restaurant_name'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      orderDetail: json['order_detail'] as Map<String, dynamic> ?? {},
    );
  }

  // 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'date': date.toIso8601String(),
      'split': split,
      'restaurant_name': restaurantName,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'order_detail': orderDetail,
    };
  }
}

// OrderItem 类：表示订单项
class OrderItem {
  final int id; // 订单项ID
  final String uid; // 唯一标识符
  final String date; // 日期
  final String restaurantName; // 餐厅名称
  final String dishName; // 菜品名称
  final double price; // 价格

  OrderItem({
    required this.id,
    required this.uid,
    required this.date,
    required this.restaurantName,
    required this.dishName,
    required this.price,
  });

  // 从JSON创建OrderItem对象
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      uid: json['uid'] as String,
      date: json['date'] as String,
      restaurantName: json['restaurant_name'] as String,
      dishName: json['dish_name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  // 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'date': date,
      'restaurant_name': restaurantName,
      'dish_name': dishName,
      'price': price,
    };
  }
}

// History 页面：显示账单历史
class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Bill> bills = []; // 账单列表
  bool isLoading = true; // 加载状态
  double totalMeSpent = 0.0; // “我”的总花费

  @override
  void initState() {
    super.initState();
    getDataBase(); // 初始化时获取数据
  }

  // 解析账单JSON字符串
  List<Bill> parseBills(String jsonString) {
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    final List<dynamic> billsList = jsonData['bills'] as List<dynamic>;
    return billsList.map((json) => Bill.fromJson(json as Map<String, dynamic>)).toList();
  }

  // 解析订单项JSON字符串
  List<OrderItem> parseOrderItems(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => OrderItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  // 从数据库获取数据
  void getDataBase() async {
    Map itemsResult = await Chaquopy.executeCode("get_all_items()"); // 获取所有订单项
    try {
      String itemsJsonString = itemsResult['textOutputOrError'].toString().replaceAll('\n', '');
      print(itemsJsonString);
      List<OrderItem> orderItems = parseOrderItems(itemsJsonString);

      Set<String> uniqueUids = orderItems.map((item) => item.uid).toSet(); // 获取唯一UID集合

      for (String uid in uniqueUids) {
        Map billResult = await Chaquopy.executeCode("get_bill_through_uid(\"$uid\")"); // 根据UID获取账单
        String billJsonString = billResult['textOutputOrError'].toString().replaceAll('\n', '');
        print(billJsonString);
        List<Bill> fetchedBills = parseBills(billJsonString);
        bills.addAll(fetchedBills); // 添加账单到列表
      }

      // 按日期排序（最新优先）并去重
      bills.sort((a, b) => b.date.compareTo(a.date));
      bills = bills.toSet().toList();

      // 计算“我”的总花费
      totalMeSpent = bills.fold(0.0, (sum, bill) {
        final meAmount = bill.orderDetail['Me'] as num?;
        return sum + (meAmount?.toDouble() ?? 0.0);
      });

      print('Total bills: ${bills.length}');
      print('Total spent by Me: \$${totalMeSpent.toStringAsFixed(2)}');
    } catch (e) {
      print('Error parsing JSON: $e'); // 打印解析错误
    }
    isLoading = false; // 加载完成
    setState(() {}); // 更新UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : bills.isEmpty
                    ? const Center(child: Text('No History for Now.'))
                    : ListView.builder(
                        itemCount: bills.length,
                        itemBuilder: (context, index) {
                          final bill = bills[index];
                          return ListTile(
                            title: Text(bill.restaurantName),
                            trailing: Text(
                              DateFormat('MMM dd, yyyy').format(bill.date),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => OrderDetail(uid: bill.uid),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
          // 这个 Container 保持总是存在
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Spent by Me:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(totalMeSpent),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}