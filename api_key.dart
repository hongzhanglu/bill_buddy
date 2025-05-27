import 'package:flutter_dotenv/flutter_dotenv.dart';
const String prompt= '''解析这张账单，并以如以下 JSON 格式返回, 请直接返回 JSON，不要包含任何额外说明或代码块格式。(only return JSON type)：
        "date": "today's date",
        "split_method": "By Food",
        "restaurant_name": "Restaurant's name",
        "subtotal": 2180.80,
        "tax": 392.54,
        "total": 2791.42,
        "items": [
            {"food_name": "Jgo Chinola", "price": 140.80},
            {"food_name": "Jgo Lim. Frozen", "price": 340.00},
            {"food_name": "Coca Cola", "price": 100.00},
            {"food_name": "Chicken Quesa", "price": 545.00},
            {"food_name": "Croquet Pesc", "price": 445.00},
            {"food_name": "Shrimp Tie Salad", "price": 610.00}
        ]''';
String gptApi='${dotenv.env["APIKEY"]}';