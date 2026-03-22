"""
Tiện ích mã hóa và xác thực mật khẩu
Sử dụng bcrypt cho bảo mật cao
"""
import bcrypt
import secrets
import hashlib
import logging

logger = logging.getLogger(__name__)


class PasswordHelper:
    """Lớp hỗ trợ mã hóa và xác thực mật khẩu"""
    
    ROUNDS = 12  # Số vòng bcrypt (càng cao càng an toàn, càng chậm)
    
    @staticmethod
    def generate_salt() -> str:
        """Tạo salt ngẫu nhiên"""
        return secrets.token_hex(32)
    
    @staticmethod
    def hash_password(plain_password: str, salt: str = None) -> tuple[str, str]:
        """
        Mã hóa mật khẩu với bcrypt.
        Returns: (hash_string, salt_string)
        """
        if salt is None:
            salt = PasswordHelper.generate_salt()
        
        # Kết hợp salt vào password trước khi hash
        combined = f"{plain_password}{salt}".encode('utf-8')
        hashed = bcrypt.hashpw(combined, bcrypt.gensalt(rounds=PasswordHelper.ROUNDS))
        return hashed.decode('utf-8'), salt
    
    @staticmethod
    def verify_password(plain_password: str, hashed_password: str, salt: str) -> bool:
        """
        Xác thực mật khẩu người dùng nhập với hash trong DB.
        Returns: True nếu đúng, False nếu sai
        """
        try:
            combined = f"{plain_password}{salt}".encode('utf-8')
            return bcrypt.checkpw(combined, hashed_password.encode('utf-8'))
        except Exception as e:
            logger.error(f"Lỗi xác thực mật khẩu: {e}")
            return False
    
    @staticmethod
    def is_strong_password(password: str) -> tuple[bool, str]:
        """
        Kiểm tra độ mạnh của mật khẩu.
        Returns: (is_valid, message)
        """
        if len(password) < 8:
            return False, "Mật khẩu phải có ít nhất 8 ký tự"
        if not any(c.isupper() for c in password):
            return False, "Mật khẩu phải có ít nhất 1 chữ hoa"
        if not any(c.islower() for c in password):
            return False, "Mật khẩu phải có ít nhất 1 chữ thường"
        if not any(c.isdigit() for c in password):
            return False, "Mật khẩu phải có ít nhất 1 chữ số"
        return True, "Mật khẩu hợp lệ"
