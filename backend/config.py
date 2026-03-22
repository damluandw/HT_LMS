"""
Cấu hình ứng dụng HT_LMS
Sử dụng python-dotenv để đọc biến môi trường từ file .env
"""
import os
from dotenv import load_dotenv

# Đọc biến môi trường từ file .env
load_dotenv()


class Config:
    """Cấu hình cơ sở cho ứng dụng Flask"""
    
    # Flask
    SECRET_KEY = os.getenv('SECRET_KEY', 'HT_LMS_Default_Secret_Key')
    DEBUG = os.getenv('FLASK_DEBUG', 'True').lower() == 'true'
    
    # Kết nối SQL Server
    DB_SERVER = os.getenv('DB_SERVER', r'DESKTOP-CRFJV4A\SQL2022')
    DB_NAME = os.getenv('DB_NAME', 'HT_LMS')
    DB_DRIVER = os.getenv('DB_DRIVER', 'ODBC Driver 17 for SQL Server')
    DB_TRUSTED_CONNECTION = os.getenv('DB_TRUSTED_CONNECTION', 'yes')
    
    # Connection string cho pyodbc (Windows Authentication)
    DB_CONNECTION_STRING = (
        f"DRIVER={{{DB_DRIVER}}};"
        f"SERVER={DB_SERVER};"
        f"DATABASE={DB_NAME};"
        f"Trusted_Connection={DB_TRUSTED_CONNECTION};"
    )
    
    # JWT
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'HT_LMS_JWT_Default_Key')
    JWT_EXPIRATION_HOURS = int(os.getenv('JWT_EXPIRATION_HOURS', 8))
    JWT_REFRESH_EXPIRATION_DAYS = int(os.getenv('JWT_REFRESH_EXPIRATION_DAYS', 30))
    
    # CORS
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*').split(',')
    
    # Upload
    UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 
                                  os.getenv('UPLOAD_FOLDER', 'uploads'))
    MAX_CONTENT_LENGTH = int(os.getenv('MAX_CONTENT_LENGTH', 52428800))  # 50MB


class DevelopmentConfig(Config):
    """Cấu hình môi trường phát triển"""
    DEBUG = True
    FLASK_ENV = 'development'


class ProductionConfig(Config):
    """Cấu hình môi trường production"""
    DEBUG = False
    FLASK_ENV = 'production'


# Map cấu hình theo môi trường
config_map = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}


def get_config():
    """Lấy cấu hình theo biến môi trường FLASK_ENV"""
    env = os.getenv('FLASK_ENV', 'development')
    return config_map.get(env, DevelopmentConfig)
