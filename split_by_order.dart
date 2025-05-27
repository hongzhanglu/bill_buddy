import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:bill_buddy_test/functions.dart';
import '../functions.dart';
import '../widgets/button.dart';
import '../widgets/text_input.dart';

// SplitByOrder 页面：按订单分账
class SplitByOrder extends StatefulWidget {
  XFile xfile; // 传入的图片文件
  SplitByOrder({
    super.key,
    required this.xfile,
  });

  @override
  State<SplitByOrder> createState() => _SplitByOrderState();
}

class _SplitByOrderState extends State<SplitByOrder> {
  late String uid; // 唯一标识符
  bool _isSavingToDB = false; // 保存到数据库的状态
  bool _isLoading = true; // 加载状态
  String _response = ''; // 图片处理响应
  late OrderData orderData; // 订单数据
  TextEditingController _resName = TextEditingController(); // 餐厅名称控制器
  TextEditingController _total = TextEditingController(); // 总金额控制器
  TextEditingController _subtotal = TextEditingController(); // 小计控制器
  TextEditingController _tax = TextEditingController(); // 税额控制器
  List<TextEditingController> dishPriceControllers = []; // 菜品价格控制器列表
  List<TextEditingController> dishControllers = []; // 菜品名称控制器列表
  List<Map<String, String>> _dishes = []; // 菜品列表
  DateTime _dateTime = DateTime.now(); // 订单日期

  @override
  void initState() {
    super.initState();
    _dealImage(); // 处理图片
    initUid(); // 初始化UID
  }

  // 初始化UID
  void initUid() async {
    Map result = await Chaquopy.executeCode('generate_random_string()');
    uid = result['textOutputOrError'].toString().replaceAll('\n', '');
    print(result);
  }

  // 将数据存储到数据库
  Future<void> storeToDB(double total, Map<String, double> userCosts) async {
    _isSavingToDB = true;
    setState(() {});

    String buildStoreBills;
    String buildStoreBillItems;
    // 构建账单JSON
    buildStoreBills = jsonEncode({
      "uid": uid,
      "date": _dateTime.toString(),
      "split": true, // 表示按订单分账
      "restaurant_name": _resName.text,
      "subtotal": _subtotal.text,
      "tax": _tax.text,
      "total": total,
      "order_detail": userCosts, // 用户分账详情
    });
    buildStoreBills = buildStoreBills.replaceAll('\n', '').replaceAll('"', '\\"');
    print(buildStoreBills);
    Map result = await Chaquopy.executeCode('save_to_bills("$buildStoreBills")');
    print(result);

    // 存储每个菜品项
    for (var item in _dishes) {
      item.forEach((key, value) async {
        buildStoreBillItems = jsonEncode({
          "uid": uid,
          "date": orderData.dateTime.toString().substring(0, 10),
          "restaurant_name": orderData.restaurantName,
          "dish_name": key,
          "price": value,
        });
        buildStoreBillItems = buildStoreBillItems.replaceAll('\n', '').replaceAll('"', '\\"');
        result = await Chaquopy.executeCode('save_to_bill_items("$buildStoreBillItems")');
        print(result);
      });
    }
    _isSavingToDB = false;
    setState(() {});
    return;
  }

  // 处理图片并提取订单数据
  void _dealImage() async {
    _response = await handleImage(widget.xfile); // 调用外部函数处理图片
    _response = _response.replaceAll('\n', '').replaceAll('"', '\\"');
    Map result = await Chaquopy.executeCode('wash_data("$_response")'); // 数据清洗
    print(result);
    _response = result['textOutputOrError'];
    orderData = OrderData.fromJsonString(_response); // 解析订单数据
    _resName.text = orderData.restaurantName;
    _total.text = orderData.total.toString();
    _subtotal.text = orderData.subTotal.toString();
    _tax.text = orderData.tax.toString();
    _dateTime = orderData.dateTime;
    _dishes = orderData.dishes;
    _isLoading = false;
    setState(() {});
  }

  // 生成菜品列表UI
  List<Widget> dishesList() {
    dishControllers = [];
    dishPriceControllers = [];
    List<Widget> dishList = [];
    for (var mapItem in _dishes) {
      int index = _dishes.indexOf(mapItem);
      mapItem.forEach((key, value) {
        dishPriceControllers.add(TextEditingController());
        dishControllers.add(TextEditingController());
        dishPriceControllers[dishPriceControllers.length - 1].text = value.toString();
        dishControllers[dishControllers.length - 1].text = key.toString();
        dishList.add(
          Container(
            margin: EdgeInsets.only(left: 5, top: 5),
            child: Row(
              children: [
                Container(
                  width: 130,
                  child: TextInput(
                    onChange: (txt) {
                      Future.delayed(Duration(milliseconds: 200));
                      _dishes.removeAt(index);
                      _dishes.insert(index, {txt: value}); // 更新菜品名称
                    },
                    onTapOutSide: (e) {
                      setState(() {});
                    },
                    marginRight: 5,
                    controller: dishControllers[index],
                  ),
                ),
                Expanded(
                  child: TextInput(
                    onChange: (txt) {
                      mapItem.remove(key);
                      mapItem.addAll({key: txt}); // 更新价格
                    },
                    onTapOutSide: (e) {
                      setState(() {});
                    },
                    marginLeft: 5,
                    marginRight: 10,
                    controller: dishPriceControllers[index],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    dishPriceControllers.removeAt(index);
                    dishControllers.removeAt(index);
                    _dishes.removeAt(index); // 删除菜品
                    setState(() {});
                  },
                  icon: Icon(Icons.delete_rounded),
                ),
              ],
            ),
          ),
        );
      });
    }
    return dishList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(), // 加载中显示进度条
        )
            : ListView(
          children: [
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Text(
                  'Please Check the Order',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 15),
                TextInput(controller: _resName, labelText: 'Restaurant'), // 餐厅输入框
                GestureDetector(
                  onTap: () async {
                    _dateTime = await showDatePicker( // 选择日期
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      initialDate: orderData.dateTime
                    ) ??
                        _dateTime;
                    setState(() {});
                  },
                  child: Container(
                    padding: EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
                    margin: EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded),
                        Text(' ${_dateTime.toString().substring(0, 10)}'),
                      ],
                    ),
                  ),
                ),
              ] +
                  dishesList() + // 动态菜品列表
                  [
                    ListTile(
                      onTap: () {
                        // 验证输入并弹出分账对话框
                        if (double.tryParse(_subtotal.text) != null &&
                            double.tryParse(_tax.text) != null &&
                            double.tryParse(_total.text) != null) {
                          for (var item in dishPriceControllers) {
                            if (double.tryParse(item.text) == null) {
                              Fluttertoast.showToast(msg: 'Err: Some Number Wrongly Set to Text.');
                              return;
                            }
                          }
                          for (var item in dishControllers) {
                            if (item.text.isEmpty) {
                              Fluttertoast.showToast(msg: 'Err: Don\'t leave blank in form.');
                              return;
                            }
                          }
                          if (_resName.text.isEmpty) {
                            Fluttertoast.showToast(msg: 'Err: Don\'t leave blank in form.');
                            return;
                          }

                          double totalFee = double.parse(_total.text);
                          Map<String, List<String>> dishAssignments = {};
                          List<TextEditingController> nameControllers = [];

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              TextEditingController numberController = TextEditingController();
                              TextEditingController tipRateController = TextEditingController();

                              return StatefulBuilder(
                                builder: (BuildContext context, void Function(void Function()) setState) {
                                  Map<String, double> userCosts = {};
                                  Map<String, List<String>> userOrderDetails = {};

                                  // 计算每个人的费用
                                  void calculateCosts() {
                                    userCosts.clear();
                                    userOrderDetails.clear();
                                    double tipRate = double.tryParse(tipRateController.text) ?? 0;
                                    double totalDishPrice =
                                    _dishes.fold(0, (sum, dish) => sum + double.parse(dish.values.first));

                                    for (var nameCtrl in nameControllers) {
                                      userCosts[nameCtrl.text] = 0;
                                      userOrderDetails[nameCtrl.text] = [];
                                    }

                                    for (var dish in _dishes) {
                                      String dishName = dish.keys.first;
                                      double price = double.parse(dish.values.first);
                                      List<String> assignedPeople = dishAssignments[dishName] ?? [];

                                      if (assignedPeople.isNotEmpty) {
                                        double perPersonCost = price / assignedPeople.length;
                                        for (var person in assignedPeople) {
                                          userCosts[person] = (userCosts[person] ?? 0) + perPersonCost;
                                          userOrderDetails[person]
                                              ?.add("$dishName - \$${perPersonCost.toStringAsFixed(2)}");
                                        }
                                      }
                                    }

                                    double tipAmount = totalFee * (tipRate / 100);
                                    double totalWithoutTip = userCosts.values.fold(0, (sum, cost) => sum + cost);

                                    if (totalWithoutTip > 0) {
                                      for (var person in userCosts.keys) {
                                        double proportion = userCosts[person]! / totalWithoutTip;
                                        double tipShare = proportion * tipAmount;
                                        userCosts[person] = userCosts[person]! + tipShare;
                                        userOrderDetails[person]?.add("Tip - \$${tipShare.toStringAsFixed(2)}");
                                      }
                                    }

                                    setState(() {});
                                  }

                                  return AlertDialog(
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          if (double.tryParse(tipRateController.text) != null &&
                                              int.tryParse(numberController.text) != null) {
                                            await storeToDB(
                                              totalFee *
                                                  (1 + (double.tryParse(tipRateController.text) ?? 0) / 100),
                                              userCosts, // 保存用户分账信息
                                            );
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                    title: Text('Set Tip, Name, and Assign Dishes'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          TextInput(
                                            onChange: (txt) {
                                              int? num = int.tryParse(txt);
                                              if (num != null && num > 0) {
                                                setState(() {
                                                  nameControllers =
                                                      List.generate(num, (index) => TextEditingController());
                                                  dishAssignments.clear();
                                                });
                                              }
                                            },
                                            controller: numberController,
                                            labelText: 'People Count', // 人数输入框
                                          ),
                                          TextInput(
                                            onChange: (txt) {
                                              setState(() {
                                                calculateCosts();
                                              });
                                            },
                                            controller: tipRateController,
                                            labelText: 'Tip Rate(%)', // 小费百分比输入框
                                          ),
                                          if (nameControllers.isNotEmpty)
                                            Column(
                                              children: List.generate(nameControllers.length, (index) {
                                                return TextInput(
                                                  controller: nameControllers[index],
                                                  labelText: 'Person ${index + 1} Name', // 人员名称输入框
                                                  onChange: (txt) {
                                                    setState(() {
                                                      calculateCosts();
                                                    });
                                                  },
                                                );
                                              }),
                                            ),
                                          if (nameControllers.isNotEmpty) ..._dishes.map((dish) {
                                            String dishName = dish.keys.first;
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(dishName, style: TextStyle(fontWeight: FontWeight.bold)),
                                                ...nameControllers.map((ctrl) {
                                                  return CheckboxListTile(
                                                    title: Text(ctrl.text.isEmpty ? 'Unnamed' : ctrl.text),
                                                    value: dishAssignments[dishName]?.contains(ctrl.text) ?? false,
                                                    onChanged: (bool? selected) {
                                                      setState(() {
                                                        if (selected == true) {
                                                          dishAssignments
                                                              .putIfAbsent(dishName, () => [])
                                                              .add(ctrl.text);
                                                        } else {
                                                          dishAssignments[dishName]?.remove(ctrl.text);
                                                        }
                                                        calculateCosts();
                                                      });
                                                    },
                                                  );
                                                }).toList(),
                                              ],
                                            );
                                          }).toList(),
                                          Divider(),
                                          Text("Final Bill Breakdown:",
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          if (userCosts.isNotEmpty)
                                            Column(
                                              children: userCosts.entries.map((entry) {
                                                return Container(
                                                  padding: EdgeInsets.all(8),
                                                  margin: EdgeInsets.symmetric(vertical: 4),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                                                      ...userOrderDetails[entry.key]!.map((item) => Text(item)),
                                                      Text(
                                                        'Total: \$${entry.value.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold, color: Colors.green),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          Divider(),
                                          Text(
                                            'Final Total: \$${(totalFee * (1 + (double.tryParse(tipRateController.text) ?? 0) / 100)).toStringAsFixed(2)}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        } else {
                          Fluttertoast.showToast(msg: 'Err: Some Number Wrongly Set to Text.');
                          return;
                        }
                      },
                      leading: Icon(Icons.add),
                      title: Text('Add New Items'), // 添加新菜品按钮

                    ),
                    TextInput(controller: _subtotal, labelText: 'Subtotal'), // 小计输入框
                    TextInput(controller: _tax, labelText: 'Tax'), // 税额输入框
                    TextInput(controller: _total, labelText: 'Total'), // 总金额输入框
                    SizedBox(height: 20),
                    Button(
                      onTap: () {
                        // 验证输入并弹出分账对话框
                        if (double.tryParse(_subtotal.text) != null &&
                            double.tryParse(_tax.text) != null &&
                            double.tryParse(_total.text) != null) {
                          for (var item in dishPriceControllers) {
                            if (double.tryParse(item.text) == null) {
                              Fluttertoast.showToast(msg: 'Err: Some Number Wrongly Set to Text.');
                              return;
                            }
                          }
                          for (var item in dishControllers) {
                            if (item.text.isEmpty) {
                              Fluttertoast.showToast(msg: 'Err: Don\'t leave blank in form.');
                              return;
                            }
                          }
                          if (_resName.text.isEmpty) {
                            Fluttertoast.showToast(msg: 'Err: Don\'t leave blank in form.');
                            return;
                          }

                          double totalFee = double.parse(_total.text);
                          Map<String, List<String>> dishAssignments = {};
                          List<TextEditingController> nameControllers = [];

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              TextEditingController numberController = TextEditingController();
                              TextEditingController tipRateController = TextEditingController();

                              return StatefulBuilder(
                                builder: (BuildContext context, void Function(void Function()) setState) {
                                  Map<String, double> userCosts = {};
                                  Map<String, List<String>> userOrderDetails = {};

                                  // 计算每个人的费用
                                  void calculateCosts() {
                                    userCosts.clear();
                                    userOrderDetails.clear();
                                    double tipRate = double.tryParse(tipRateController.text) ?? 0;
                                    double totalDishPrice =
                                    _dishes.fold(0, (sum, dish) => sum + double.parse(dish.values.first));

                                    for (var nameCtrl in nameControllers) {
                                      if (nameCtrl.text.isNotEmpty) {
                                        userCosts[nameCtrl.text] = 0;
                                        userOrderDetails[nameCtrl.text] = [];
                                      }
                                    }

                                    for (var dish in _dishes) {
                                      String dishName = dish.keys.first;
                                      double price = double.parse(dish.values.first);
                                      List<String> assignedPeople = dishAssignments[dishName] ?? [];

                                      if (assignedPeople.isNotEmpty) {
                                        double perPersonCost = price / assignedPeople.length;
                                        for (var person in assignedPeople) {
                                          if (person.isNotEmpty) {
                                            userCosts[person] = (userCosts[person] ?? 0) + perPersonCost;
                                            userOrderDetails[person]
                                                ?.add("$dishName - \$${perPersonCost.toStringAsFixed(2)}");
                                          }
                                        }
                                      }
                                    }

                                    double tipAmount = totalFee * (tipRate / 100);
                                    double totalWithoutTip = userCosts.values.fold(0, (sum, cost) => sum + cost);

                                    if (totalWithoutTip > 0) {
                                      for (var person in userCosts.keys) {
                                        double proportion = userCosts[person]! / totalWithoutTip;
                                        double tipShare = proportion * tipAmount;
                                        userCosts[person] = userCosts[person]! + tipShare;
                                        userOrderDetails[person]?.add("Tip - \$${tipShare.toStringAsFixed(2)}");
                                      }
                                    }
                                  }

                                  calculateCosts();

                                  return AlertDialog(
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          if (_isSavingToDB == false) {
                                            if (double.tryParse(tipRateController.text) != null &&
                                                int.tryParse(numberController.text) != null) {
                                              await storeToDB(
                                                totalFee *
                                                    (1 + (double.tryParse(tipRateController.text) ?? 0) / 100),
                                                userCosts, // 保存用户分账信息
                                              );
                                              Fluttertoast.showToast(msg: 'Successfully Stored.');
                                              Navigator.pop(context);
                                            }
                                          }
                                        },
                                        child: _isSavingToDB ? CircularProgressIndicator() : Text('OK'),
                                      ),
                                    ],
                                    title: Text('Set Tip, Name, and Assign Dishes'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          TextInput(
                                            onChange: (txt) {
                                              int? num = int.tryParse(txt);
                                              if (num != null && num > 0) {
                                                setState(() {
                                                  nameControllers =
                                                      List.generate(num, (index) => TextEditingController());
                                                  dishAssignments.clear();
                                                  calculateCosts();
                                                });
                                              }
                                            },
                                            controller: numberController,
                                            labelText: 'People Count', // 人数输入框
                                          ),
                                          TextInput(
                                            onChange: (txt) {
                                              setState(() {
                                                calculateCosts();
                                              });
                                            },
                                            controller: tipRateController,
                                            labelText: 'Tip Rate(%)', // 小费百分比输入框
                                          ),
                                          if (nameControllers.isNotEmpty)
                                            Column(
                                              children: List.generate(nameControllers.length, (index) {
                                                return TextInput(
                                                  controller: nameControllers[index],
                                                  labelText: 'Person ${index + 1} Name', // 人员名称输入框
                                                  onChange: (txt) {
                                                    setState(() {
                                                      calculateCosts();
                                                    });
                                                  },
                                                );
                                              }),
                                            ),
                                          if (nameControllers.isNotEmpty) ..._dishes.map((dish) {
                                            String dishName = dish.keys.first;
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(dishName, style: TextStyle(fontWeight: FontWeight.bold)),
                                                ...nameControllers.map((ctrl) {
                                                  return CheckboxListTile(
                                                    title: Text(ctrl.text.isEmpty ? 'Unnamed' : ctrl.text),
                                                    value: dishAssignments[dishName]?.contains(ctrl.text) ?? false,
                                                    onChanged: (bool? selected) {
                                                      setState(() {
                                                        if (selected == true) {
                                                          dishAssignments
                                                              .putIfAbsent(dishName, () => [])
                                                              .add(ctrl.text);
                                                        } else {
                                                          dishAssignments[dishName]?.remove(ctrl.text);
                                                        }
                                                        calculateCosts();
                                                      });
                                                    },
                                                  );
                                                }).toList(),
                                              ],
                                            );
                                          }).toList(),
                                          Divider(),
                                          Text("Final Bill Breakdown:",
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Column(
                                            children: userCosts.entries.map((entry) {
                                              return Container(
                                                padding: EdgeInsets.all(8),
                                                margin: EdgeInsets.symmetric(vertical: 4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      entry.key.isEmpty ? 'Unnamed' : entry.key,
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    ...(userOrderDetails[entry.key] ?? []).map((item) => Text(item)),
                                                    Text(
                                                      'Total: \$${entry.value.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                          fontWeight: FontWeight.bold, color: Colors.green),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          Divider(),
                                          Text(
                                            'Final Total: \$${(totalFee * (1 + (double.tryParse(tipRateController.text) ?? 0) / 100)).toStringAsFixed(2)}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        } else {
                          Fluttertoast.showToast(msg: 'Err: Some Number Wrongly Set to Text.');
                          return;
                        }
                      },
                      childWidget: Text('Submit'), // 提交按钮
                    ),
                    SizedBox(height: 20),
                  ],
            ),
          ],
        ),
      ),
    );
  }
}