import 'dart:convert';// json解码用的
import 'dart:io';  // 文件读写用的
import 'package:image_picker/image_picker.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:bill_buddy_test/api_key.dart';

/// 定义账单数据结构
class OrderData {
  String restaurantName;
  DateTime dateTime;
  List<Map<String, String>> dishes;
  double subTotal;
  double tax;
  double total;

  OrderData({// 构造函数（初始化）
    required this.restaurantName,
    required this.dateTime,
    required this.dishes,
    required this.subTotal,
    required this.tax,
    required this.total,
  });


factory OrderData.fromJsonString(String jsonString) {
  final Map<String, dynamic> jsonMap = jsonDecode(jsonString);// 转成dart map对象方便后面存储

  String restaurant = jsonMap['restaurant_name'] ?? 'UnKnown';
  DateTime date = DateTime.tryParse(jsonMap['date'] ?? '') ?? DateTime.now();

  double parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double subtotal = parseDouble(jsonMap['subtotal']);
  double tax = parseDouble(jsonMap['tax']);
  double total = parseDouble(jsonMap['total']);

  List<Map<String, String>> dishes = [];
  if (jsonMap['items'] != null && jsonMap['items'] is List) {
    for (var item in jsonMap['items']) {
      if (item is Map && item.containsKey('food_name') && item.containsKey('price')) {
        dishes.add({item['food_name']: item['price'].toString()});
      }
    }
  }

  return OrderData(
    restaurantName: restaurant,
    dateTime: date,
    dishes: dishes,
    subTotal: subtotal,
    tax: tax,
    total: total,
  );
}
}
/// 用于上传图片并发送给 GPT 接口的函数
Future<String> handleImage(XFile xfile) async {
  String response=''; // 初始化响应字符串
  File file = File(xfile.path); // 从XFile创建File对象
  String base64Image = base64Encode(file.readAsBytesSync()); // 将图片转换为Base64
  var openaiApiKey = gptApi; // 获取OpenAI API key
  final client = OpenAIClient(apiKey: openaiApiKey); // 创建OpenAI客户端
  
  // 最多尝试5次请求
  for (int i = 0; i < 5; i++) {
    try {
      // 创建聊天完成请求
      final res = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.model(
            ChatCompletionModels.gpt4o, // 使用GPT-4o模型
          ),
          messages: [
            // 系统消息
            ChatCompletionMessage.system(
              content: 'You are a helpful assistant.', // 系统提示
            ),
            // 用户消息
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts(
                [
                  // 文本部分
                  ChatCompletionMessageContentPart.text(
                    text: prompt, // 用户的提示文本
                  ),
                  // 图片部分
                  ChatCompletionMessageContentPart.image(
                    imageUrl: ChatCompletionMessageImageUrl(
                      url: 'data:image/png;base64,$base64Image', // Base64编码的图片URL
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      // 打印响应内容
      print(res.choices.first.message.content);
      // 获取响应内容，若为空则返回'Invalid'
      response = res.choices.first.message.content ?? 'Invalid';
      break; // 成功后退出循环
    } catch(e) {
      print('e: $e'); // 打印错误信息
      continue; // 出错后继续下一次尝试
    }
  }
  return response; // 返回最终响应
}
