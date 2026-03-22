import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from database.connection import db
import pyodbc

def check_data():
    try:
        with db.get_connection() as conn:
            cursor = conn.cursor()
            # Check a record with Vietnamese name
            cursor.execute("SELECT HoTen FROM HoSoNguoiHoc WHERE TenDangNhap = 'nguoihoc'") # This might fail if joined
            # Actually use a simple query
            cursor.execute("SELECT TOP 1 HoTen FROM HoSoNguoiHoc")
            row = cursor.fetchone()
            if row:
                print(f"Dữ liệu đọc được: {row[0]}")
                # Check if it contains replacement characters or looks like Mojibake
                name = row[0]
                try:
                    name.encode('ascii')
                    print("Dữ liệu chỉ chứa ASCII (có thể đã bị mất dấu)")
                except UnicodeEncodeError:
                    print("Dữ liệu có chứa ký tự non-ASCII.")
            else:
                print("Không tìm thấy dữ liệu.")
    except Exception as e:
        print(f"Lỗi: {e}")

if __name__ == '__main__':
    check_data()
