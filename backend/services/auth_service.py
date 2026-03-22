"""
AuthService - Business Logic xác thực và phân quyền
Xử lý đăng nhập cho 3 loại tài khoản, tạo JWT, kiểm tra quyền
"""
import logging
from utils.password import PasswordHelper
from utils.jwt_helper import JWTHelper
from repositories.auth_repository import AuthRepository

logger = logging.getLogger(__name__)

# Số lần đăng nhập sai tối đa trước khi khóa tài khoản
MAX_FAILED_ATTEMPTS = 5


class AuthService:
    """Service xử lý xác thực người dùng"""
    
    def __init__(self):
        self._repo = AuthRepository()
    
    def dang_nhap(self, ten_dang_nhap: str, mat_khau: str, 
                   loai_tai_khoan: str, ip: str = None) -> dict:
        """
        Xử lý đăng nhập cho tất cả loại tài khoản.
        
        Args:
            ten_dang_nhap: Tên đăng nhập hoặc email
            mat_khau: Mật khẩu nhập vào
            loai_tai_khoan: 'NguoiHoc' | 'GiangVien' | 'NhanVien'
            ip: Địa chỉ IP client
        
        Returns:
            dict với keys: success, access_token, refresh_token, user_info, message
        """
        loai = loai_tai_khoan.strip()
        ten = ten_dang_nhap.strip()
        
        # ── 1. Lấy tài khoản theo loại ──────────────────────────────────────
        tai_khoan = None
        ho_so = None
        ma_tai_khoan = None
        
        if loai == JWTHelper.LOAI_NGUOI_HOC: # Ensure LOAI_SINH_VIEN Constant is also updated if needed
            tai_khoan = self._repo.lay_tai_khoan_nh_theo_ten_dang_nhap(ten)
            if tai_khoan:
                ma_tai_khoan = tai_khoan.MaTKNguoiHoc
                ho_so = self._repo.lay_ho_so_nh_theo_tai_khoan(ma_tai_khoan)
                
        elif loai == JWTHelper.LOAI_GIANG_VIEN:
            tai_khoan = self._repo.lay_tai_khoan_gv_theo_ten_dang_nhap(ten)
            if tai_khoan:
                ma_tai_khoan = tai_khoan.MaTaiKhoanGV
                ho_so = self._repo.lay_ho_so_gv_theo_tai_khoan(ma_tai_khoan)
                
        elif loai == JWTHelper.LOAI_NHAN_VIEN:
            tai_khoan = self._repo.lay_tai_khoan_nv_theo_ten_dang_nhap(ten)
            if tai_khoan:
                ma_tai_khoan = tai_khoan.MaTaiKhoanNV
                ho_so = self._repo.lay_ho_so_nv_theo_tai_khoan(ma_tai_khoan)
        else:
            return {"success": False, "message": "Loại tài khoản không hợp lệ"}
        
        # ── 2. Kiểm tra tài khoản tồn tại ───────────────────────────────────
        if not tai_khoan:
            self._repo.ghi_nhat_ky_he_thong(loai, 0, 'DangNhap', False, ip,
                                              f"Không tìm thấy: {ten}")
            return {"success": False, "message": "Tên đăng nhập hoặc mật khẩu không đúng"}
        
        # ── 3. Kiểm tra tài khoản bị khóa ───────────────────────────────────
        if tai_khoan.la_bi_khoa():
            return {"success": False, "message": "Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên"}
        
        # ── 4. Xác thực mật khẩu ────────────────────────────────────────────
        mat_khau_dung = PasswordHelper.verify_password(
            mat_khau, tai_khoan.MatKhauHash, tai_khoan.Salt
        )
        if not mat_khau_dung:
            self._repo.ghi_nhat_ky_he_thong(loai, ma_tai_khoan, 'DangNhap', False, ip,
                                              "Sai mật khẩu")
            return {"success": False, "message": "Tên đăng nhập hoặc mật khẩu không đúng"}
        
        # ── 5. Lấy vai trò (chỉ NhanVien mới có nhiều vai trò) ───────────────
        vai_tro_codes = []
        if loai == JWTHelper.LOAI_NHAN_VIEN:
            vai_tros = self._repo.lay_vai_tro_nhan_vien(ma_tai_khoan)
            vai_tro_codes = [vt.MaVaiTroCode for vt in vai_tros]
        
        vai_tro_chinh = vai_tro_codes[0] if vai_tro_codes else loai
        
        # ── 6. Lấy họ tên từ hồ sơ ──────────────────────────────────────────
        ho_ten = ""
        if ho_so:
            ho_ten = ho_so.HoTen
        
        # ── 7. Tạo JWT token ─────────────────────────────────────────────────
        access_token = JWTHelper.tao_access_token(
            ma_tai_khoan=ma_tai_khoan,
            loai_tai_khoan=loai,
            vai_tro_code=vai_tro_chinh,
            ma_truong=tai_khoan.MaTruong,
            ho_ten=ho_ten
        )
        refresh_token = JWTHelper.tao_refresh_token(ma_tai_khoan, loai)
        
        # ── 8. Cập nhật lần đăng nhập cuối ───────────────────────────────────
        self._repo.cap_nhat_lan_dang_nhap_cuoi(loai, ma_tai_khoan)
        self._repo.ghi_nhat_ky_he_thong(loai, ma_tai_khoan, 'DangNhap', True, ip,
                                          "Đăng nhập thành công")
        
        # ── 9. Xây dựng thông tin người dùng trả về ──────────────────────────
        user_info = tai_khoan.to_dict()
        user_info['loai_tai_khoan'] = loai
        user_info['vai_tro_codes'] = vai_tro_codes if vai_tro_codes else [loai]
        if ho_so:
            user_info['ho_so'] = ho_so.to_dict()
        
        return {
            "success": True,
            "message": "Đăng nhập thành công",
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user_info": user_info
        }
    
    def xac_thuc_token(self, token: str) -> dict | None:
        """
        Xác thực JWT token từ request.
        Returns: payload dict hoặc None nếu không hợp lệ
        """
        return JWTHelper.giai_ma_token(token)
    
    def lam_moi_token(self, refresh_token: str) -> dict:
        """
        Tạo Access Token mới từ Refresh Token.
        Returns: dict với keys: success, access_token, message
        """
        payload = JWTHelper.giai_ma_token(refresh_token)
        if not payload or payload.get('type') != 'refresh':
            return {"success": False, "message": "Refresh token không hợp lệ hoặc đã hết hạn"}
        
        ma_tai_khoan = int(payload['sub'])
        loai = payload['loai']
        
        # Lấy lại thông tin người dùng để tạo token mới
        ma_truong = None
        
        if loai == JWTHelper.LOAI_NGUOI_HOC:
            tk = self._repo.lay_tai_khoan_nh_theo_id(ma_tai_khoan)
            if tk:
                ma_truong = tk.MaTruong
            ho_so = self._repo.lay_ho_so_nh_theo_tai_khoan(ma_tai_khoan)
            if ho_so:
                ho_ten = ho_so.HoTen
        elif loai == JWTHelper.LOAI_GIANG_VIEN:
            tk = self._repo.lay_tai_khoan_gv_theo_id(ma_tai_khoan)
            if tk:
                ma_truong = tk.MaTruong
            ho_so = self._repo.lay_ho_so_gv_theo_tai_khoan(ma_tai_khoan)
            if ho_so:
                ho_ten = ho_so.HoTen
        elif loai == JWTHelper.LOAI_NHAN_VIEN:
            tk = self._repo.lay_tai_khoan_nv_theo_id(ma_tai_khoan)
            if tk:
                ma_truong = tk.MaTruong
            ho_so = self._repo.lay_ho_so_nv_theo_tai_khoan(ma_tai_khoan)
            if ho_so:
                ho_ten = ho_so.HoTen
            vai_tros = self._repo.lay_vai_tro_nhan_vien(ma_tai_khoan)
            if vai_tros:
                vai_tro = vai_tros[0].MaVaiTroCode
        
        new_token = JWTHelper.tao_access_token(ma_tai_khoan, loai, vai_tro, ma_truong, ho_ten)
        return {"success": True, "access_token": new_token}
