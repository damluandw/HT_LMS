"""
BaseRepository - Lớp DAO cơ sở
Cung cấp các phương thức CRUD chung cho tất cả repositories
"""
import logging
from typing import Optional
from database.connection import db

logger = logging.getLogger(__name__)


class BaseRepository:
    """
    Lớp Repository cơ sở.
    Mỗi Repository con kế thừa lớp này để tái sử dụng kết nối DB.
    """
    
    def __init__(self):
        self._db = db
    
    def _execute_query(self, sql: str, params: tuple = None) -> list[dict]:
        """
        Thực thi câu SQL SELECT và trả về danh sách dict.
        
        Args:
            sql: Câu SQL query
            params: Tuple các tham số để tránh SQL Injection
        Returns:
            List of dicts với key là tên cột
        """
        with self._db.get_connection() as conn:
            cursor = conn.cursor()
            try:
                if params:
                    cursor.execute(sql, params)
                else:
                    cursor.execute(sql)
                
                columns = [col[0] for col in cursor.description]
                rows = cursor.fetchall()
                return [dict(zip(columns, row)) for row in rows]
            except Exception as e:
                logger.error(f"Lỗi query SQL: {e}\nSQL: {sql}")
                raise
    
    def _execute_scalar(self, sql: str, params: tuple = None):
        """Thực thi query và trả về giá trị đơn (scalar)"""
        with self._db.get_connection() as conn:
            cursor = conn.cursor()
            try:
                if params:
                    cursor.execute(sql, params)
                else:
                    cursor.execute(sql)
                row = cursor.fetchone()
                return row[0] if row else None
            except Exception as e:
                logger.error(f"Lỗi scalar query: {e}")
                raise
    
    def _execute_non_query(self, sql: str, params: tuple = None) -> int:
        """
        Thực thi INSERT/UPDATE/DELETE.
        Returns: rowcount (số dòng bị ảnh hưởng)
        """
        with self._db.get_connection() as conn:
            cursor = conn.cursor()
            try:
                if params:
                    cursor.execute(sql, params)
                else:
                    cursor.execute(sql)
                conn.commit()
                return cursor.rowcount
            except Exception as e:
                conn.rollback()
                logger.error(f"Lỗi non-query SQL: {e}")
                raise
    
    def _execute_insert_get_id(self, sql: str, params: tuple = None) -> int:
        """
        Thực thi INSERT và trả về IDENTITY (ID vừa tạo).
        SQL phải kết thúc bằng: SELECT SCOPE_IDENTITY()
        """
        with self._db.get_connection() as conn:
            cursor = conn.cursor()
            try:
                if params:
                    cursor.execute(sql, params)
                else:
                    cursor.execute(sql)
                row = cursor.fetchone()
                conn.commit()
                return int(row[0]) if row and row[0] else None
            except Exception as e:
                conn.rollback()
                logger.error(f"Lỗi insert get ID: {e}")
                raise
    
    def _execute_transaction(self, queries: list[tuple]) -> bool:
        """
        Thực thi nhiều câu SQL trong một transaction.
        
        Args:
            queries: List of (sql, params) tuples
        Returns: True nếu thành công, False nếu thất bại
        """
        with self._db.get_connection() as conn:
            cursor = conn.cursor()
            try:
                for sql, params in queries:
                    cursor.execute(sql, params)
                conn.commit()
                return True
            except Exception as e:
                conn.rollback()
                logger.error(f"Lỗi transaction: {e}")
                return False
