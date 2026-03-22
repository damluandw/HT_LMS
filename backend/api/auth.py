"""
Auth API Blueprint - Các endpoint xác thực
POST /api/auth/dang-nhap
POST /api/auth/lam-moi-token
POST /api/auth/dang-xuat
GET  /api/auth/toi       (thông tin người dùng hiện tại)
"""
import logging
from flask import Blueprint, request, g
from services.auth_service import AuthService
from middleware.auth_middleware import yeu_cau_dang_nhap
from utils.response import APIResponse

logger = logging.getLogger(__name__)

# Tạo Blueprint
auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')
auth_service = AuthService()


@auth_bp.route('/dang-nhap', methods=['POST'])
def dang_nhap():
    """
    Endpoint đăng nhập
    Body JSON: { ten_dang_nhap, mat_khau, loai_tai_khoan }
    loai_tai_khoan: 'NguoiHoc' | 'GiangVien' | 'NhanVien'
    """
    data = request.get_json(silent=True)
    if not data:
        return APIResponse.loi("Dữ liệu không hợp lệ")
    
    ten_dang_nhap = data.get('ten_dang_nhap', '').strip()
    mat_khau = data.get('mat_khau', '')
    loai_tai_khoan = data.get('loai_tai_khoan', '').strip()
    
    # Validate đầu vào
    if not ten_dang_nhap:
        return APIResponse.loi("Vui lòng nhập tên đăng nhập")
    if not mat_khau:
        return APIResponse.loi("Vui lòng nhập mật khẩu")
    if loai_tai_khoan not in ('NguoiHoc', 'GiangVien', 'NhanVien'):
        return APIResponse.loi("Loại tài khoản không hợp lệ")
    
    # Lấy IP client
    ip = request.environ.get('HTTP_X_REAL_IP', request.remote_addr)
    
    # Gọi service đăng nhập
    ket_qua = auth_service.dang_nhap(ten_dang_nhap, mat_khau, loai_tai_khoan, ip)
    
    if not ket_qua['success']:
        return APIResponse.loi(ket_qua['message'], status_code=401)
    
    return APIResponse.thanh_cong({
        "access_token": ket_qua['access_token'],
        "refresh_token": ket_qua['refresh_token'],
        "user_info": ket_qua['user_info']
    }, ket_qua['message'])


@auth_bp.route('/lam-moi-token', methods=['POST'])
def lam_moi_token():
    """
    Làm mới Access Token bằng Refresh Token
    Body JSON: { refresh_token }
    """
    data = request.get_json(silent=True)
    if not data or not data.get('refresh_token'):
        return APIResponse.loi("Vui lòng cung cấp refresh_token")
    
    ket_qua = auth_service.lam_moi_token(data['refresh_token'])
    if not ket_qua['success']:
        return APIResponse.loi(ket_qua['message'], status_code=401)
    
    return APIResponse.thanh_cong({"access_token": ket_qua['access_token']})


@auth_bp.route('/toi', methods=['GET'])
@yeu_cau_dang_nhap
def lay_thong_tin_ban_than():
    """Lấy thông tin người dùng hiện đang đăng nhập"""
    return APIResponse.thanh_cong({
        "ma_tai_khoan": g.ma_tai_khoan,
        "loai_tai_khoan": g.loai_tai_khoan,
        "vai_tro": g.vai_tro,
        "ma_truong": g.ma_truong,
        "ho_ten": g.ho_ten,
    })


@auth_bp.route('/dang-xuat', methods=['POST'])
@yeu_cau_dang_nhap
def dang_xuat():
    """
    Đăng xuất - phía client cần xóa token khỏi localStorage
    Server chỉ ghi nhật ký
    """
    from repositories.auth_repository import AuthRepository
    repo = AuthRepository()
    repo.ghi_nhat_ky_he_thong(
        g.loai_tai_khoan, g.ma_tai_khoan, 'DangXuat', True,
        request.environ.get('HTTP_X_REAL_IP', request.remote_addr),
        "Đăng xuất thành công"
    )
    return APIResponse.thanh_cong(message="Đăng xuất thành công")


@auth_bp.route('/kiem-tra', methods=['GET'])
def kiem_tra_health():
    """Health check endpoint"""
    from database.connection import db
    db_ok = db.test_connection()
    return APIResponse.thanh_cong({
        "server": "HT_LMS Backend",
        "version": "1.0.0",
        "database": "connected" if db_ok else "error"
    }, "Server đang hoạt động")
