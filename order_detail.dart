import 'dart:convert';
import 'package:intl/intl.dart'; // 用于格式化日期和货币
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/material.dart';

// 账单类
class Bill {
  final int id; // 账单ID
  final String uid; // 唯一标识符
  final DateTime date; // 日期
  final int split; // 分账方式（0: 等额，1: 按订单）
  final String restaurantName; // 餐厅名称
  final double subtotal; // 小计
  final double tax; // 税额
  final double total; // 总金额
  final Map<String, dynamic> orderDetail; // 分账详情

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
      orderDetail: json['order_detail'] as Map<String, dynamic> ?? {}, // 默认空Map
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

// 包含账单列表的容器类
class BillData {
  final List<Bill> bills; // 账单列表

  BillData({required this.bills});

  // 从JSON创建BillData对象
  factory BillData.fromJson(Map<String, dynamic> json) {
    final billsList = json['bills'] as List<dynamic>;
    final bills = billsList.map((billJson) => Bill.fromJson(billJson)).toList();
    return BillData(bills: bills);
  }

  // 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'bills': bills.map((bill) => bill.toJson()).toList(),
    };
  }
}

// 菜品类
class BillItem {
  final int id; // 菜品ID
  final String uid; // 唯一标识符
  final DateTime date; // 日期
  final String restaurantName; // 餐厅名称
  final String dishName; // 菜品名称
  final double price; // 价格

  BillItem({
    required this.id,
    required this.uid,
    required this.date,
    required this.restaurantName,
    required this.dishName,
    required this.price,
  });

  // 从JSON创建BillItem对象
  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] as int,
      uid: json['uid'] as String,
      date: DateTime.parse(json['date'] as String),
      restaurantName: json['restaurant_name'] as String,
      dishName: json['dish_name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}

// 订单详情页面
class OrderDetail extends StatefulWidget {
  final String uid; // 账单唯一标识符
  OrderDetail({
    super.key,
    required this.uid,
  });

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  BillData? billData; // 账单数据
  List<BillItem>? billItems; // 菜品列表
  bool isLoading = true; // 加载状态

  @override
  void initState() {
    super.initState();
    getBill(widget.uid); // 获取账单
    getBillItems(widget.uid); // 获取菜品
  }

  // 通过UID获取账单数据
  void getBill(String uid) async {
    try {
      Map result = await Chaquopy.executeCode("get_bill_through_uid(\"$uid\")");
      String jsonString = result['textOutputOrError'].toString().replaceAll('\n', '');
      print(jsonString);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        billData = BillData.fromJson(jsonData);
      });
    } catch (e) {
      print('Error parsing bill JSON: $e');
    }
  }

  // 通过UID获取菜品数据
  void getBillItems(String uid) async {
    try {
      Map result = await Chaquopy.executeCode("get_bill_item_through_uid(\"$uid\")");
      String jsonString = result['textOutputOrError'].toString().replaceAll('\n', '');
      print(jsonString);
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        billItems = jsonData.map((item) => BillItem.fromJson(item)).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error parsing bill items JSON: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context), // 返回上一页
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // 加载中显示进度条
          : billData == null || billData!.bills.isEmpty
          ? const Center(child: Text('No bill data available')) // 无数据提示
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 餐厅信息卡片
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      billData!.bills[0].restaurantName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(billData!.bills[0].date)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 菜品列表卡片
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Items Ordered',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (billItems != null && billItems!.isNotEmpty)
                      ...billItems!.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.dishName,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(item.price),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ))
                    else
                      const Text(
                        'No items available',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 分账方式和付款详情卡片
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Split Method: ${billData!.bills[0].split == 0 ? 'Equal Share' : 'Split By Order'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (billData!.bills[0].split == 1) // 按订单分账
                      ...billData!.bills[0].orderDetail.entries.map((entry) {
                        if (entry.key == "Me") {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'My Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(entry.value),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(entry.value),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                    if (billData!.bills[0].split == 0) // 等额分账
                      ...billData!.bills[0].orderDetail.entries.map((entry) {
                        if (entry.key == "Me") {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'My Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(entry.value),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(entry.value),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                    const Divider(),
                    _buildAmountRow('Subtotal', billData!.bills[0].subtotal), // 小计行
                    _buildAmountRow('Tax', billData!.bills[0].tax), // 税额行
                    _buildAmountRow('Total', billData!.bills[0].total, isTotal: true), // 总金额行
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建金额行UI
  Widget _buildAmountRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[700],
            ),
          ),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount),
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}