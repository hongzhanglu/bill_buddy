import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:bill_buddy_test/functions.dart';
import '../widgets/button.dart';
import '../widgets/text_input.dart';

class EqualShare extends StatefulWidget {
  XFile xfile;
  EqualShare({super.key, required this.xfile});

  @override
  State<EqualShare> createState() => _EqualShareState();
}

class _EqualShareState extends State<EqualShare> {
  late String uid;
  bool _isLoading = true;
  String _response = '';
  bool _isSavingToDB = false;
  late OrderData orderData;
  TextEditingController _resName = TextEditingController();
  TextEditingController _total = TextEditingController();
  TextEditingController _subtotal = TextEditingController();
  TextEditingController _tax = TextEditingController();
  List<TextEditingController> dishPriceControllers = [];
  List<TextEditingController> dishControllers = [];
  List<Map<String, String>> _dishes = [];
  DateTime _dateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dealImage();
    initUid();
  }

  void initUid() async {
    Map result = await Chaquopy.executeCode('generate_random_string()');
    uid = result['textOutputOrError'].toString().replaceAll('\n', '');
    print(result);
  }

  void _recalculateTotals() {
    double subtotal = 0.0;
    for (var item in _dishes) {
      String priceStr = item.values.first;
      subtotal += double.tryParse(priceStr) ?? 0;
    }

    double originalSubtotal = double.tryParse(orderData.subTotal.toString()) ?? 0;
    double originalTax = double.tryParse(orderData.tax.toString()) ?? 0;
    double estimatedTaxRate = originalSubtotal > 0 ? originalTax / originalSubtotal : 0.07;

    double tax = subtotal * estimatedTaxRate;
    double total = subtotal + tax;

    _subtotal.text = subtotal.toStringAsFixed(2);
    _tax.text = tax.toStringAsFixed(2);
    _total.text = total.toStringAsFixed(2);
  }

  Future<void> storeToDB(double total, int peopleCount) async {
    _isSavingToDB = true;
    setState(() {});

    double meShare = total / peopleCount;
    double othersShare = total * (peopleCount - 1) / peopleCount;
    Map<String, double> orderDetail = {
      "Me": double.parse(meShare.toStringAsFixed(2)),
      "Others": double.parse(othersShare.toStringAsFixed(2)),
    };

    String buildStoreBills = jsonEncode({
      "uid": uid,
      "date": _dateTime.toString(),
      "split": false,
      "restaurant_name": _resName.text,
      "subtotal": _subtotal.text,
      "tax": _tax.text,
      "total": total,
      "order_detail": orderDetail,
    }).replaceAll('\n', '').replaceAll('"', '\\"');

    await Chaquopy.executeCode('save_to_bills("$buildStoreBills")');

    for (var item in _dishes) {
      item.forEach((key, value) async {
        String buildStoreBillItems = jsonEncode({
          "uid": uid,
          "date": orderData.dateTime.toString().substring(0, 10),
          "restaurant_name": orderData.restaurantName,
          "dish_name": key,
          "price": value,
        }).replaceAll('\n', '').replaceAll('"', '\\"');
        await Chaquopy.executeCode('save_to_bill_items("$buildStoreBillItems")');
      });
    }

    _isSavingToDB = false;
    setState(() {});
  }

  void _dealImage() async {
    _response = await handleImage(widget.xfile);
    _response = _response.replaceAll('\n', '').replaceAll('"', '\\"');
    Map result = await Chaquopy.executeCode('wash_data("$_response")');
    _response = result['textOutputOrError'];
    orderData = OrderData.fromJsonString(_response);
    _resName.text = orderData.restaurantName;
    _total.text = orderData.total.toString();
    _subtotal.text = orderData.subTotal.toString();
    _tax.text = orderData.tax.toString();
    _dateTime = orderData.dateTime;
    _dishes = orderData.dishes;
    _isLoading = false;
    setState(() {});
  }

  List<Widget> dishesList() {
    dishControllers = [];
    dishPriceControllers = [];
    List<Widget> dishList = [];

    for (var mapItem in _dishes) {
      int index = _dishes.indexOf(mapItem);
      mapItem.forEach((key, value) {
        dishPriceControllers.add(TextEditingController(text: value));
        dishControllers.add(TextEditingController(text: key));
        dishList.add(
          Container(
            margin: EdgeInsets.only(left: 5, top: 5),
            child: Row(
              children: [
                Container(
                  width: 130,
                  child: TextInput(
                    onChange: (txt) {
                      _dishes.removeAt(index);
                      _dishes.insert(index, {txt: value});
                    },
                    onTapOutSide: (e) => setState(() {}),
                    marginRight: 5,
                    controller: dishControllers[index],
                  ),
                ),
                Expanded(
                  child: TextInput(
                    onChange: (txt) {
                      mapItem[key] = txt;
                      _recalculateTotals();
                    },
                    onTapOutSide: (e) => setState(() {}),
                    marginLeft: 5,
                    marginRight: 10,
                    controller: dishPriceControllers[index],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    dishPriceControllers.removeAt(index);
                    dishControllers.removeAt(index);
                    _dishes.removeAt(index);
                    _recalculateTotals();
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Text('Please Check the Order',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
                SizedBox(height: 15),
                TextInput(controller: _resName, labelText: 'Restaurant'),
                GestureDetector(
                  onTap: () async {
                    _dateTime = await showDatePicker(
                          context: context,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          initialDate: orderData.dateTime,
                        ) ??
                        _dateTime;
                    setState(() {});
                  },
                  child: Container(
                    padding: EdgeInsets.all(15),
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded),
                        SizedBox(width: 8),
                        Text(_dateTime.toString().substring(0, 10)),
                      ],
                    ),
                  ),
                ),
                ...dishesList(),
                ListTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        TextEditingController dishName = TextEditingController();
                        TextEditingController price = TextEditingController();
                        return AlertDialog(
                          title: Text('Add New Items'),
                          content: Row(
                            children: [
                              Expanded(
                                child: TextInput(
                                  controller: dishName,
                                  labelText: 'Food',
                                  marginRight: 5,
                                ),
                              ),
                              Expanded(
                                child: TextInput(
                                  controller: price,
                                  labelText: 'Price',
                                  marginLeft: 5,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                if (dishName.text.isEmpty ||
                                    double.tryParse(price.text) == null) {
                                  Fluttertoast.showToast(msg: 'Input is invalid, check please.');
                                  return;
                                }
                                _dishes.add({dishName.text: price.text});
                                _recalculateTotals();
                                setState(() {});
                                Navigator.pop(context);
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  leading: Icon(Icons.add),
                  title: Text('Add New Items'),
                ),
                TextInput(controller: _subtotal, labelText: 'Subtotal'),
                TextInput(controller: _tax, labelText: 'Tax'),
                TextInput(controller: _total, labelText: 'Total'),
                SizedBox(height: 20),
                Button(
                  onTap: () {
                    if (double.tryParse(_subtotal.text) == null ||
                        double.tryParse(_tax.text) == null ||
                        double.tryParse(_total.text) == null) {
                      Fluttertoast.showToast(msg: 'Err: Some Number Wrongly Set to Text.');
                      return;
                    }
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
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        TextEditingController number = TextEditingController();
                        TextEditingController tipRate = TextEditingController();
                        return StatefulBuilder(
                          builder: (BuildContext context, setState) {
                            return AlertDialog(
                              title: Text('Set Tip and Member'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                 // TextInput(controller: tipRate, labelText: 'Tip Rate(%)'),
                                 // TextInput(controller: number, labelText: 'People Count'),
                                 TextInput(
                                    controller: tipRate,
                                    labelText: 'Tip Rate(%)',
                                    onChange: (txt) => setState(() {}),
                                  ),
                                  TextInput(
                                    controller: number,
                                    labelText: 'People Count',
                                    onChange: (txt) => setState(() {}),
                                  ),

                                  if (double.tryParse(tipRate.text) != null &&
                                      double.tryParse(number.text) != null)
                                    Text(
                                        'Total: ${(totalFee * (1 + double.parse(tipRate.text) * 0.01)).toStringAsFixed(2)}'),
                                  if (double.tryParse(tipRate.text) != null &&
                                      double.tryParse(number.text) != null)
                                    Text(
                                        'Average: ${(totalFee * (1 + double.parse(tipRate.text) * 0.01) / double.parse(number.text)).toStringAsFixed(2)}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    if (double.tryParse(tipRate.text) != null &&
                                        double.tryParse(number.text) != null) {
                                      double finalTotal =
                                          totalFee * (1 + double.parse(tipRate.text) / 100);
                                      int peopleCount = int.parse(number.text);
                                      await storeToDB(finalTotal, peopleCount);
                                      Fluttertoast.showToast(msg: 'Successfully Stored');
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: _isSavingToDB
                                      ? CircularProgressIndicator()
                                      : Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  childWidget: Text('Submit'),
                ),
                SizedBox(height: 30),
              ],
            ),
    );
  }
}
