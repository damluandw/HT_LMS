"""
AuthMiddleware - Decorator xác thực JWT và phân quyền
Sử dụng làm decorator cho các route cần đăng nhập
"""
import logging
from functools import wraps
from flask import request, g
from utils.jwt_helper import JWTHelper
from utils.response import APIResponse

logger = logging.getLogger(__name__)


def yeu_cau_dang_nhap(f):
    """
    Decorator: Yêu cầu người dùng đã đăng nhập (có JWT hợp lệ).
    Đặt thông tin người dùng vào flask.g để route có thể sử dụng.
    
    Sử dụng: @yeu_cau_dang_nhap
    Truy cập trong route: g.user_payload
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        token = JWTHelper.lay_token_tu_header(auth_header)
        
        if not token:
            return APIResponse.chua_xac_thuc("Vui lòng đăng nhập để tiếp tục")
        
        payload = JWTHelper.giai_ma_token(token)
        if not payload:
            return APIResponse.chua_xac_thuc("Token không hợp lệ hoặc đã hết hạn")
        
        if payload.get('type') != 'access':
            return APIResponse.chua_xac_thuc("Token loại không hợp lệ")
        
        # Lưu thông tin vào flask.g để các handler sử dụng
        g.user_payload = payload
        g.ma_tai_khoan = int(payload['sub'])
        g.loai_tai_khoan = payload['loai']
        g.vai_tro = payload.get('vai_tro', '')
        g.ma_truong = payload.get('ma_truong')
        g.ho_ten = payload.get('ho_ten', '')
        return f(*args, **kwargs)
    return decorated


def yeu_cau_vai_tro(*vai_tro_codes: str):
    """
    Decorator factory: Yêu cầu người dùng có một trong các vai trò được chỉ định.
    
    Sử dụng: @yeu_cau_vai_tro('SuperAdmin', 'PhongDaoTao')
    """
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            # Phải kết hợp với @yeu_cau_dang_nhap
            if not hasattr(g, 'vai_tro'):
                return APIResponse.chua_xac_thuc()
            
            vai_tro_hien_tai = g.vai_tro
            loai_tai_khoan = g.loai_tai_khoan
            
            # SuperAdmin luôn có quyền
            if vai_tro_hien_tai == 'SuperAdmin':
                return f(*args, **kwargs)
            
            # Kiểm tra vai trò theo loại tài khoản
            allowed = list(vai_tro_codes)
            
            # Cho phép SinhVien truy cập route SinhVien
            if 'SinhVien' in allowed and loai_tai_khoan == 'SinhVien':
                return f(*args, **kwargs)
            
            # Cho phép GiangVien truy cập route GiangVien
            if 'GiangVien' in allowed and loai_tai_khoan == 'GiangVien':
                return f(*args, **kwargs)
            
            if vai_tro_hien_tai in allowed:
                return f(*args, **kwargs)
            
            return APIResponse.khong_co_quyen(
                f"Yêu cầu một trong các vai trò: {', '.join(vai_tro_codes)}"
            )
        return decorated
    return decorator


def yeu_cau_nhan_vien(f):
    """Decorator: Chỉ cho phép NhanVien (Admin, Phòng đào tạo...)"""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not hasattr(g, 'loai_tai_khoan'):
            return APIResponse.chua_xac_thuc()
        if g.loai_tai_khoan != 'NhanVien':
            return APIResponse.khong_co_quyen("Chức năng chỉ dành cho nhân viên quản lý")
        return f(*args, **kwargs)
    return decorated


def yeu_cau_giang_vien(f):
    """Decorator: Chỉ cho phép GiangVien hoặc NhanVien"""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not hasattr(g, 'loai_tai_khoan'):
            return APIResponse.chua_xac_thuc()
        if g.loai_tai_khoan not in ('GiangVien', 'NhanVien'):
            return APIResponse.khong_co_quyen("Chức năng chỉ dành cho giảng viên")
        return f(*args, **kwargs)
    return decorated
