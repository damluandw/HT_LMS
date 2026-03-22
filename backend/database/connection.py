"""
Lớp quản lý kết nối SQL Server
Sử dụng pyodbc với Windows Authentication (Trusted_Connection)
Pattern: Singleton để quản lý connection pool
"""
import pyodbc
import logging
from threading import Lock
from config import get_config

logger = logging.getLogger(__name__)


class DatabaseConnection:
    """
    Lớp Singleton quản lý kết nối đến SQL Server.
    Sử dụng Windows Authentication qua Trusted_Connection.
    """
    _instance = None
    _lock = Lock()
    
    def __new__(cls):
        """Đảm bảo chỉ tạo một instance duy nhất (Singleton)"""
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
        self._config = get_config()
        self._connection_string = self._config.DB_CONNECTION_STRING
        self._initialized = True
        logger.info(f"DatabaseConnection khởi tạo với server: {self._config.DB_SERVER}")
    
    def get_connection(self) -> pyodbc.Connection:
        """
        Tạo và trả về một kết nối mới đến SQL Server.
        Mỗi request nên sử dụng kết nối riêng và đóng sau khi xong.
        """
        try:
            conn = pyodbc.connect(self._connection_string, autocommit=False)
            conn.setdecoding(pyodbc.SQL_CHAR, encoding='utf-8')
            conn.setdecoding(pyodbc.SQL_WCHAR, encoding='utf-16le')
            conn.setencoding(encoding='utf-16le')
            return conn
        except pyodbc.Error as e:
            logger.error(f"Lỗi kết nối SQL Server: {e}")
            raise DatabaseError(f"Không thể kết nối đến cơ sở dữ liệu: {str(e)}")
    
    def test_connection(self) -> bool:
        """Kiểm tra kết nối đến SQL Server"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT 1 AS ket_qua")
                row = cursor.fetchone()
                logger.info("Kết nối SQL Server thành công!")
                return row is not None
        except Exception as e:
            logger.error(f"Kiểm tra kết nối thất bại: {e}")
            return False


class DatabaseError(Exception):
    """Exception tùy chỉnh cho lỗi cơ sở dữ liệu"""
    pass


# Instance toàn cục (Singleton)
db = DatabaseConnection()
