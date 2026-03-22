"""
Tiện ích tạo và xác thực JWT Token
Hỗ trợ 3 loại tài khoản: SinhVien / GiangVien / NhanVien
"""
import jwt
import logging
from datetime import datetime, timedelta, timezone
from config import get_config

logger = logging.getLogger(__name__)
config = get_config()


class JWTHelper:
    """Lớp hỗ trợ tạo và xác thực JWT Token"""
    
    SECRET_KEY = config.JWT_SECRET_KEY
    ALGORITHM = "HS256"
    
    # Loại tài khoản hợp lệ
    LOAI_NGUOI_HOC  = "NguoiHoc"
    LOAI_GIANG_VIEN = "GiangVien"
    LOAI_NHAN_VIEN  = "NhanVien"
    
    @staticmethod
    def tao_access_token(ma_tai_khoan: int, loai_tai_khoan: str, 
                          vai_tro_code: str = None, ma_truong: int = None,
                          ho_ten: str = None) -> str:
        """
        Tạo Access Token JWT cho người dùng đã đăng nhập.
        
        Args:
            ma_tai_khoan: ID tài khoản (MaTKNguoiHoc / GV / NV)
            loai_tai_khoan: 'NguoiHoc' | 'GiangVien' | 'NhanVien'
            vai_tro_code: Mã vai trò (SuperAdmin, GiangVien, NguoiHoc...)
            ma_truong: ID trường học
            ho_ten: Họ tên đầy đủ
        """
        gio_het_han = config.JWT_EXPIRATION_HOURS
        payload = {
            "sub": str(ma_tai_khoan),
            "loai": loai_tai_khoan,
            "vai_tro": vai_tro_code,
            "ma_truong": ma_truong,
            "ho_ten": ho_ten,
            "iat": datetime.now(timezone.utc),
            "exp": datetime.now(timezone.utc) + timedelta(hours=gio_het_han),
            "type": "access"
        }
        return jwt.encode(payload, JWTHelper.SECRET_KEY, algorithm=JWTHelper.ALGORITHM)
    
    @staticmethod
    def tao_refresh_token(ma_tai_khoan: int, loai_tai_khoan: str) -> str:
        """Tạo Refresh Token (thời hạn dài hơn Access Token)"""
        ngay_het_han = config.JWT_REFRESH_EXPIRATION_DAYS
        payload = {
            "sub": str(ma_tai_khoan),
            "loai": loai_tai_khoan,
            "iat": datetime.now(timezone.utc),
            "exp": datetime.now(timezone.utc) + timedelta(days=ngay_het_han),
            "type": "refresh"
        }
        return jwt.encode(payload, JWTHelper.SECRET_KEY, algorithm=JWTHelper.ALGORITHM)
    
    @staticmethod
    def giai_ma_token(token: str) -> dict | None:
        """
        Giải mã và xác thực JWT Token.
        Returns: payload dict hoặc None nếu token không hợp lệ
        """
        try:
            payload = jwt.decode(
                token,
                JWTHelper.SECRET_KEY,
                algorithms=[JWTHelper.ALGORITHM]
            )
            return payload
        except jwt.ExpiredSignatureError:
            logger.warning("Token đã hết hạn")
            return None
        except jwt.InvalidTokenError as e:
            logger.warning(f"Token không hợp lệ: {e}")
            return None
    
    @staticmethod
    def lay_token_tu_header(authorization_header: str) -> str | None:
        """
        Lấy token từ Authorization header.
        Format: "Bearer <token>"
        """
        if not authorization_header:
            return None
        parts = authorization_header.split(' ')
        if len(parts) == 2 and parts[0].lower() == 'bearer':
            return parts[1]
        return None
