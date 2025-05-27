gptApi = '${dotenv.env["APIKEY"]}'

#入口函数：flutter通过此函数传入命令
def mainTextCode(code):
    intermediate_code = code
    if intermediate_code:
        exec(intermediate_code)

#数据清洗函数：清洗GPT返回的数据，移除多余部分
def wash_data(gpt_result):
    gpt_result = gpt_result.replace("```", "")
    if gpt_result.startswith("json"):
        gpt_result = gpt_result[4:]
    temp_result = gpt_result
    if temp_result.startswith("json"):
        temp_result = temp_result[4:]
    if not (gpt_result.__contains__('restaurant_name') and gpt_result.__contains__('date') and
            gpt_result.__contains__('subtotal') and gpt_result.__contains__('total') and
            gpt_result.__contains__('tax')):
        print('invalid data')
        return
    print(gpt_result)

import sqlite3
import json
from sqlite3 import Error
import os

# 数据库路径
DB_PATH = "/data/data/com.example.bill_buddy_test/app_flutter/data.db"

# 创建数据库连接
def create_connection():
    conn = None
    try:
        if not os.path.exists(DB_PATH):
            open(DB_PATH, 'w').close()
        conn = sqlite3.connect(DB_PATH)
        create_tables(conn)
    except Error as e:
        print(e)
    return conn

# 创建表
def create_tables(conn):
    try:
        cursor = conn.cursor()

        # 创建bills表，新增order_detail字段 (TEXT类型存储JSON)
        cursor.execute('''CREATE TABLE IF NOT EXISTS bills (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            uid TEXT NOT NULL,
                            date TEXT NOT NULL,
                            split BOOLEAN NOT NULL,
                            restaurant_name TEXT NOT NULL,
                            subtotal REAL NOT NULL,
                            tax REAL NOT NULL,
                            total REAL NOT NULL,
                            order_detail TEXT);''')  # 新增字段

        # 创建bill_items表（无变化）
        cursor.execute('''CREATE TABLE IF NOT EXISTS bill_items (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            uid TEXT NOT NULL,
                            date TEXT NOT NULL,
                            restaurant_name TEXT NOT NULL,
                            dish_name TEXT NOT NULL,
                            price REAL NOT NULL);''')

        conn.commit()
    except Error as e:
        print(f"创建表时出错: {e}")

# 检查数据是否已经存在
def check_if_exists(cursor, table, uid, date, restaurant_name, subtotal, tax, total=None, dish_name=None, price=None, order_detail=None):
    if table == 'bills':
        cursor.execute('''SELECT 1 FROM bills WHERE uid=? AND date=? AND restaurant_name=? AND subtotal=? AND tax=? AND total=? AND order_detail=?''',
                       (uid, date, restaurant_name, subtotal, tax, total, order_detail))  # 添加order_detail检查
    elif table == 'bill_items' and dish_name is not None and price is not None:
        cursor.execute('''SELECT 1 FROM bill_items WHERE uid=? AND date=? AND restaurant_name=? AND dish_name=? AND price=?''',
                       (uid, date, restaurant_name, dish_name, price))
    result = cursor.fetchone()
    return result is not None

# 传入JSON字符串解析并插入数据到bills表
def save_to_bills(bill_json):
    try:
        conn = None
        data = json.loads(bill_json)
        conn = create_connection()
        cursor = conn.cursor()

        # 检查bills表中是否已存在相同数据（包含order_detail）
        order_detail_json = json.dumps(data.get('order_detail', {}))  # 将order_detail转为JSON字符串，默认为空字典
        if check_if_exists(cursor, 'bills', data['uid'], data['date'], data['restaurant_name'],
                           data['subtotal'], data['tax'], data['total'], order_detail_json):
            print('Already Saved Once')
            return

        # 如果不存在，插入数据
        cursor.execute('''INSERT INTO bills (uid, date, split, restaurant_name, subtotal, tax, total, order_detail)
                          VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
                       (data['uid'], data['date'], data['split'], data['restaurant_name'],
                        data['subtotal'], data['tax'], data['total'], order_detail_json))
        conn.commit()

        # 成功后打印插入的数据
        print(json.dumps({
            "uid": data['uid'],
            "date": data['date'],
            "split": data['split'],
            "restaurant_name": data['restaurant_name'],
            "subtotal": data['subtotal'],
            "tax": data['tax'],
            "total": data['total'],
            "order_detail": data.get('order_detail', {})  # 返回解析后的order_detail
        }))
    except Error as e:
        print(f"插入bills数据时出错: {e}")
    finally:
        if conn:
            conn.close()

# 传入JSON字符串解析并插入数据到bill_items表（无变化）
def save_to_bill_items(bill_items_json):
    try:
        conn = None
        data = json.loads(bill_items_json)
        conn = create_connection()
        cursor = conn.cursor()

        if check_if_exists(cursor, 'bill_items', data['uid'], data['date'], data['restaurant_name'],
                           None, None, None, data['dish_name'], data['price']):
            print('Already Saved Once')
            return

        cursor.execute('''INSERT INTO bill_items (uid, date, restaurant_name, dish_name, price)
                          VALUES (?, ?, ?, ?, ?)''',
                       (data['uid'], data['date'], data['restaurant_name'], data['dish_name'], data['price']))
        conn.commit()

        bill_items_output = {
            "uid": data['uid'],
            "date": data['date'],
            "restaurant_name": data['restaurant_name'],
            "dish_name": data['dish_name'],
            "price": data['price']
        }
        print(json.dumps(bill_items_output))
    except Error as e:
        print(f"插入bill_items数据时出错: {e}")
    finally:
        if conn:
            conn.close()

# 查询函数：根据UID返回bills表和bill_items表的数据（包含order_detail）
def get_bill_through_uid(uid):
    try:
        conn = None
        conn = create_connection()
        cursor = conn.cursor()

        # 查询bills表
        cursor.execute("SELECT * FROM bills WHERE uid=?", (uid,))
        bills_data = cursor.fetchall()

        # 格式化为JSON并打印
        bills_json = []
        for row in bills_data:
            # 解析order_detail（存储为JSON字符串）
            order_detail = json.loads(row[8]) if row[8] else {}
            bills_json.append({
                "id": row[0],
                "uid": row[1],
                "date": row[2],
                "split": row[3],
                "restaurant_name": row[4],
                "subtotal": row[5],
                "tax": row[6],
                "total": row[7],
                "order_detail": order_detail  # 添加order_detail字段
            })

        print(json.dumps({"bills": bills_json}))
    except Error as e:
        print(f"查询时出错: {e}")
    finally:
        if conn:
            conn.close()

def get_all_items():
    try:
        conn = None
        conn = create_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM bill_items")
        bill_items_data = cursor.fetchall()

        bill_items_json = []
        for row in bill_items_data:
            bill_items_json.append({
                "id": row[0],
                "uid": row[1],
                "date": row[2],
                "restaurant_name": row[3],
                "dish_name": row[4],
                "price": row[5]
            })

        print(json.dumps(bill_items_json))
    except Error as e:
        print(f"查询时出错: {e}")
    finally:
        if conn:
            conn.close()

def get_bill_item_through_uid(uid):
    """Query bill_items table by UID and print the results as a JSON string"""
    try:
        conn = None
        conn = create_connection()
        cursor = conn.cursor()

        # Query bill_items table
        cursor.execute("SELECT * FROM bill_items WHERE uid=?", (uid,))
        bill_items_data = cursor.fetchall()

        # Format results as a list of dictionaries
        bill_items_json = []
        for row in bill_items_data:
            bill_items_json.append({
                "id": row[0],
                "uid": row[1],
                "date": row[2],
                "restaurant_name": row[3],
                "dish_name": row[4],
                "price": row[5]
            })

        # Print the JSON string
        print(json.dumps(bill_items_json))
    except Error as e:
        print(f"查询时出错: {e}")
    finally:
        if conn:
            conn.close()

def get_all_bills():
    if not os.path.exists(BILLS_FILE):
        return json.dumps([])
    with open(BILLS_FILE, "r") as f:
        data = json.load(f)
        return json.dumps(data)

# 随机字符串生成工具
import random
import string
def generate_random_string():
    characters = string.ascii_letters + string.digits
    random_string = ''.join(random.choice(characters) for _ in range(16))
    print(random_string)