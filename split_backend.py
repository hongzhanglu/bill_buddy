'''
import cv2
import pytesseract
from PIL import Image
import os

image = Image.open("image_1.jpg")

text = pytesseract.image_to_string(image, lang='eng')
file = open('ocr_text.txt',mode='w')
file.writelines(text)
file.close()
'''

'''
# 读取图片
image_path = "image_1.jpg"
image = cv2.imread(image_path)

# 1. 转换为灰度图
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# 2. 去噪（高斯模糊）
#gray = cv2.GaussianBlur(gray, (3, 3), 0)

# 3. 二值化（提高对比度）
gray = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]

# 4. 保存处理后的图片（可选）
cv2.imwrite("processed_image.jpg", gray)

# 5. 使用 pytesseract 进行 OCR 识别
custom_config = r'--oem 3 --psm 6'  # 选择最佳 OCR 引擎模式和页面分割模式
text = pytesseract.image_to_string(gray, lang='eng', config=custom_config)

# 6. 将结果写入文本文件
with open("ocr_text.txt", "w", encoding="utf-8") as file:
    file.write(text)

print("OCR 识别完成，结果已保存至 ocr_text.txt")
'''
'''
bill_data = {
    "date": "2025-02-22",
    "split_method": "By Food",
    "restaurant_name": "Casa Club Neptuno",
    "subtotal": 2180.80,
    "tax": 392.54,
    "total": 2791.42,
    "items": [
        {"food_name": "Jgo Chinola", "price": 140.80},
        {"food_name": "Jgo Lim. Frozen", "price": 340.00},
        {"food_name": "Coca Cola", "price": 100.00}
    ]
}
'''
import cv2
import pytesseract
from PIL import Image
import numpy as np
import sqlite3
from openai import OpenAI
import io
import json
import os
import base64



image_path = "image_1.jpg"

prompt = '''解析这张账单，并以如以下 JSON 格式返回, 请直接返回 JSON，不要包含任何额外说明或代码块格式。(only return JSON type)：
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
        ]
        '''


def encode_image(image_path):
    with open(image_path,"rb") as image_file:
        return  base64.b64encode(image_file.read()).decode("utf-8")

base64_image = encode_image(image_path)

try:
    chat_completion = client.chat.completions.create(
    model="gpt-4o",
    max_tokens=500,
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "type":"text",
                    "text":prompt
                },
                {
                    "type":"image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{base64_image}"
                    }
                }
            ]
        }
    ])
    print(chat_completion.choices[0].message.content)
    print("\n")
   # bill_data = chat_completion.choices[0].message.content
except Exception as e:
    print(f"An error happened: {e}")

bill_data = json.loads(chat_completion.choices[0].message.content)

# 连接 SQLite 数据库（如果文件不存在，会自动创建）
conn = sqlite3.connect("bills.db")
cursor = conn.cursor()

# 创建账单表 (bills)
cursor.execute('''
CREATE TABLE IF NOT EXISTS bills (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,  
    split_method TEXT NOT NULL,  
    restaurant_name TEXT NOT NULL,  
    subtotal REAL NOT NULL, 
    tax REAL NOT NULL, 
    total REAL NOT NULL  
)
''')

# 创建账单菜品表 (bill_items)
cursor.execute('''
CREATE TABLE IF NOT EXISTS bill_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL, 
    restaurant_name TEXT NOT NULL,  
    food_name TEXT NOT NULL,  
    price REAL NOT NULL  
)
''')

print("SQLite 数据库已创建，包含 bills 和 bill_items 两张表！")

# 插入账单数据
cursor.execute('''
INSERT INTO bills (date, split_method, restaurant_name, subtotal, tax, total)
VALUES (?, ?, ?, ?, ?, ?)
''', (bill_data["date"], bill_data["split_method"], bill_data["restaurant_name"], bill_data["subtotal"], bill_data["tax"], bill_data["total"]))

# 获取账单 ID（自增的）
bill_id = cursor.lastrowid

# 插入账单菜品数据
for item in bill_data["items"]:
    cursor.execute('''
    INSERT INTO bill_items (date, restaurant_name, food_name, price)
    VALUES (?, ?, ?, ?)
    ''', (bill_data["date"], bill_data["restaurant_name"], item["food_name"], item["price"]))

# 提交并关闭连接
conn.commit()
conn.close()

print("账单数据已存入 SQLite！")

# 连接 SQLite 数据库（如果文件不存在，会自动创建）
conn = sqlite3.connect("bills.db")
cursor = conn.cursor()

# 查询 bill_items 表中的 food_name 和 price
cursor.execute("SELECT food_name, price FROM bill_items")
bill_items = cursor.fetchall()

# 查询 bills 表中的 split_method, total, tax
cursor.execute("SELECT split_method, total, tax FROM bills")
bills_info = cursor.fetchall()

# 查询 food_name 为 "Jgo Chinola" 的 bill_items 记录
cursor.execute("SELECT food_name, price FROM bill_items WHERE food_name = ?", ("Jgo Chinola",))
test_bill_items = cursor.fetchall()

# 关闭数据库连接
conn.close()

# 打印 bill_items 数据
print("Bill Items:")
for food_name, price in bill_items:
    print(f"Food: {food_name}, Price: {price}")

# 打印 bills 数据
print("\nBills Information:")
for split_method, total, tax in bills_info:
    print(f"Split Method: {split_method}, Total: {total}, Tax: {tax}")

print("\n")

for food_name, price in test_bill_items:
    print(f"Food: {food_name}, Price: {price}")
