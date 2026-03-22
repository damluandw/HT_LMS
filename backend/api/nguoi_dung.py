"""
Nguoi Dung API Blueprint - Quản lý người dùng (SV, GV, NV)
GET    /api/users/sinh-vien         - Danh sách sinh viên (có phân trang, lọc)
GET    /api/users/sinh-vien/<id>    - Chi tiết sinh viên
POST   /api/users/sinh-vien         - Tạo sinh viên mới
PUT    /api/users/sinh-vien/<id>    - Cập nhật sinh viên
GET    /api/users/giang-vien        - Danh sách giảng viên
GET    /api/users/giang-vien/<id>   - Chi tiết giảng viên
POST   /api/users/giang-vien        - Tạo giảng viên mới
GET    /api/users/nhan-vien         - Danh sách nhân viên
GET    /api/users/nhan-vien/<id>    - Chi tiết nhân viên
"""
import logging
from flask import Blueprint, request, g
from middleware.auth_middleware import yeu_cau_dang_nhap, yeu_cau_nhan_vien, yeu_cau_giang_vien
from utils.response import APIResponse
from utils.password import PasswordHelper
from repositories.base_repository import BaseRepository

logger = logging.getLogger(__name__)

nguoi_dung_bp = Blueprint('nguoi_dung', __name__, url_prefix='/api/users')


class NguoiDungRepository(BaseRepository):
    """Repository quản lý người dùng"""
    
    def lay_ds_nguoi_hoc(self, ma_truong: int = None, ma_lop: int = None,
                          tu_khoa: str = None, trang: int = 1, 
                          so_ban_ghi: int = 20) -> tuple[list, int]:
        """Lấy danh sách người học có phân trang"""
        offset = (trang - 1) * so_ban_ghi
        where_clauses = ["1=1"]
        params = []
        
        if ma_truong:
            where_clauses.append("tk.MaTruong = ?")
            params.append(ma_truong)
        # if ma_lop:
        #     where_clauses.append("ch.MaLopHanhChinh = ?") # Update if needed
        #     params.append(ma_lop)
        if tu_khoa:
            where_clauses.append("(hs.HoTen LIKE ? OR hs.MaKyHieu LIKE ? OR tk.Email LIKE ?)")
            kw = f"%{tu_khoa}%"
            params.extend([kw, kw, kw])
        
        where = " AND ".join(where_clauses)
        
        count_sql = f"""
            SELECT COUNT(*) FROM TaiKhoanNguoiHoc tk
            INNER JOIN HoSoNguoiHoc hs ON hs.MaTKNguoiHoc = tk.MaTKNguoiHoc
            WHERE {where}
        """
        total = self._execute_scalar(count_sql, tuple(params) if params else None)
        
        sql = f"""
            SELECT tk.MaTKNguoiHoc, tk.Email, tk.TrangThai, tk.NgayTao,
                   hs.MaHoSoNH, hs.MaKyHieu, hs.HoTen, hs.GioiTinh, 
                   hs.HinhAnh, ch.NienKhoa, ch.TrangThaiHocTap,
                   n.TenNganh, lhc.TenLop, k.TenKhoa
            FROM TaiKhoanNguoiHoc tk
            INNER JOIN HoSoNguoiHoc hs ON hs.MaTKNguoiHoc = tk.MaTKNguoiHoc
            LEFT JOIN HoSoCapHoc ch ON ch.MaHoSoNH = hs.MaHoSoNH AND ch.LaNguoiHocHienTai = 1
            LEFT JOIN Nganh n ON n.MaNganh = ch.MaNganh
            LEFT JOIN LopHanhChinh lhc ON lhc.MaLopHC = (SELECT TOP 1 MaLopHC FROM LopHanhChinh WHERE MaNganh = ch.MaNganh)
            LEFT JOIN BoMon bm ON bm.MaBoMon = n.MaBoMon
            LEFT JOIN Khoa k ON k.MaKhoa = bm.MaKhoa
            WHERE {where}
            ORDER BY hs.MaKyHieu
            OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
        """
        params.extend([offset, so_ban_ghi])
        rows = self._execute_query(sql, tuple(params))
        return rows, total or 0
    
    def lay_chi_tiet_nguoi_hoc(self, ma_tai_khoan: int) -> dict | None:
        """Lấy chi tiết một người học"""
        sql = """
            SELECT tk.MaTKNguoiHoc, tk.TenDangNhap, tk.Email, tk.SoDienThoai,
                   tk.TrangThai, tk.NgayTao, tk.LanDangNhapCuoi,
                   hs.MaHoSoNH, hs.MaKyHieu, hs.HoTen, hs.Ho, hs.Ten,
                   hs.NgaySinh, hs.GioiTinh, hs.HinhAnh, hs.DanToc,
                   hs.DiaChiThuongTru, hs.TinhThanh, ch.NienKhoa,
                   ch.TrangThaiHocTap, ch.HinhThucDaoTao,
                   ch.MaNganh,
                   n.TenNganh, lhc.TenLop, k.TenKhoa, t.TenTruong
            FROM TaiKhoanNguoiHoc tk
            INNER JOIN HoSoNguoiHoc hs ON hs.MaTKNguoiHoc = tk.MaTKNguoiHoc
            LEFT JOIN HoSoCapHoc ch ON ch.MaHoSoNH = hs.MaHoSoNH AND ch.LaNguoiHocHienTai = 1
            LEFT JOIN Nganh n ON n.MaNganh = ch.MaNganh
            LEFT JOIN LopHanhChinh lhc ON lhc.MaLopHC = (SELECT TOP 1 MaLopHC FROM LopHanhChinh WHERE MaNganh = ch.MaNganh)
            LEFT JOIN BoMon bm ON bm.MaBoMon = n.MaBoMon
            LEFT JOIN Khoa k ON k.MaKhoa = bm.MaKhoa
            LEFT JOIN Truong t ON t.MaTruong = tk.MaTruong
            WHERE tk.MaTKNguoiHoc = ?
        """
        rows = self._execute_query(sql, (ma_tai_khoan,))
        return rows[0] if rows else None

    def tao_nguoi_hoc(self, ma_truong: int, data: dict) -> int:
        from utils.password import PasswordHelper
        mat_khau_hash, salt = PasswordHelper.hash_password(data.get('mat_khau', '123456'))
        
        ten_dang_nhap = data.get('ten_dang_nhap')
        email = data.get('email')
        so_dien_thoai = data.get('so_dien_thoai')
        
        # KT ton tai
        exist = self._execute_query("SELECT 1 FROM TaiKhoanNguoiHoc WHERE TenDangNhap = ?", (ten_dang_nhap,))
        if exist: raise ValueError("Tên đăng nhập đã tồn tại")
        
        sql_tk = """
            SET NOCOUNT ON;
            INSERT INTO TaiKhoanNguoiHoc (MaTruong, TenDangNhap, MatKhauHash, Salt, Email, SoDienThoai, TrangThai, NgayTao) 
            VALUES (?, ?, ?, ?, ?, ?, 'HoatDong', GETDATE());
            SELECT SCOPE_IDENTITY();
        """
        ma_ky_hieu = data.get('ma_ky_hieu') or data.get('ma_nguoi_hoc')
        ho = data.get('ho')
        ten = data.get('ten')
        ho_ten = data.get('ho_ten', '')
        if ho_ten and (not ho or not ten):
            parts = ho_ten.strip().split()
            if len(parts) > 1:
                ho = " ".join(parts[:-1])
                ten = parts[-1]
            else:
                ten = ho_ten
                ho = ""

        try:
            sql_hs = """
                INSERT INTO HoSoNguoiHoc (MaTKNguoiHoc, MaKyHieu, HoTen, Ho, Ten, NgaySinh, GioiTinh, MaNganh, MaLopHanhChinh)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            ma_nganh = data.get('ma_nganh')
            ma_lop_hc = data.get('ma_lop_hc')

            self._execute_non_query(sql_hs, (
                ma_tk, ma_ky_hieu, ho_ten, ho, ten, 
                data.get('ngay_sinh'), data.get('gioi_tinh', 'Nam'),
                ma_nganh, ma_lop_hc
            ))
            
            # Tạo HoSoCapHoc để SV hiển thị được trong các danh sách
            ma_hs = self._execute_scalar("SELECT MaHoSoNH FROM HoSoNguoiHoc WHERE MaTKNguoiHoc = ?", (ma_tk,))
            if ma_hs:
                sql_cap = """
                    INSERT INTO HoSoCapHoc (MaHoSoNH, MaCapHoc, MaTruong, MaKyHieuCapHoc, MaNganh, MaLopHanhChinh, NienKhoa, TrangThaiHocTap, LaNguoiHocHienTai)
                    VALUES (?, 1, ?, ?, ?, ?, ?, 'DangHoc', 1)
                """
                self._execute_non_query(sql_cap, (
                    ma_hs, ma_truong, ma_ky_hieu, ma_nganh, ma_lop_hc, data.get('nien_khoa', 'K2024')
                ))
        except Exception as e:
            logger.exception(f"Lỗi khi lưu hồ sơ người học: {e}")
            raise
            
        return ma_tk

    def cap_nhat_nguoi_hoc(self, ma_tai_khoan: int, data: dict):
        sql_tk = "UPDATE TaiKhoanNguoiHoc SET Email = ?, SoDienThoai = ?, TrangThai = ? WHERE MaTKNguoiHoc = ?"
        self._execute_non_query(sql_tk, (data.get('email'), data.get('so_dien_thoai'), data.get('trang_thai', 'HoatDong'), ma_tai_khoan))
        
        sql_hs = """
            UPDATE HoSoNguoiHoc SET MaKyHieu=?, HoTen=?, Ho=?, Ten=?, NgaySinh=?, GioiTinh=?, MaNganh=?, MaLopHanhChinh=?, NienKhoa=?
            WHERE MaTKNguoiHoc=?
        """
        # Note: mapping MaLopHanhChinh if provided
        ma_lop = data.get('ma_lop_hc')
        self._execute_non_query(sql_hs, (
            data.get('ma_ky_hieu'), data.get('ho_ten'), data.get('ho'), data.get('ten'), 
            data.get('ngay_sinh'), data.get('gioi_tinh', 'Nam'), 
            data.get('ma_nganh'), ma_lop, data.get('nien_khoa'),
            ma_tai_khoan
        ))
        
        # Update HoSoCapHoc if needed (e.g. TrangThaiHocTap)
        if data.get('trang_thai_hoc_tap') or data.get('ma_lop_hc'):
            sql_cap = "UPDATE HoSoCapHoc SET TrangThaiHocTap = ?, MaLopHanhChinh = ? WHERE MaHoSoNH = (SELECT MaHoSoNH FROM HoSoNguoiHoc WHERE MaTKNguoiHoc = ?) AND LaNguoiHocHienTai = 1"
            self._execute_non_query(sql_cap, (data.get('trang_thai_hoc_tap', 'DangHoc'), ma_lop, ma_tai_khoan))

    def xoa_nguoi_hoc(self, ma_tai_khoan: int):
        # Soft delete by deactivating
        self._execute_non_query("UPDATE TaiKhoanNguoiHoc SET TrangThai = 'DaXoa' WHERE MaTKNguoiHoc = ?", (ma_tai_khoan,))

    def cap_nhat_trang_thai_nh(self, ma_tai_khoan: int, trang_thai: str):
        self._execute_non_query("UPDATE TaiKhoanNguoiHoc SET TrangThai = ? WHERE MaTKNguoiHoc = ?", (trang_thai, ma_tai_khoan))


    def lay_ds_giang_vien(self, ma_truong: int = None, ma_bo_mon: int = None,
                           tu_khoa: str = None, trang: int = 1,
                           so_ban_ghi: int = 20) -> tuple[list, int]:
        """Lấy danh sách giảng viên"""
        offset = (trang - 1) * so_ban_ghi
        where_clauses = ["1=1"]
        params = []
        
        if ma_truong:
            where_clauses.append("tk.MaTruong = ?")
            params.append(ma_truong)
        if ma_bo_mon:
            where_clauses.append("hs.MaBoMon = ?")
            params.append(ma_bo_mon)
        if tu_khoa:
            where_clauses.append("(hs.HoTen LIKE ? OR hs.MaGiangVien LIKE ? OR tk.Email LIKE ?)")
            kw = f"%{tu_khoa}%"
            params.extend([kw, kw, kw])
        
        where = " AND ".join(where_clauses)
        
        count_sql = f"""
            SELECT COUNT(*) FROM TaiKhoanGiangVien tk
            INNER JOIN HoSoGiangVien hs ON hs.MaTaiKhoanGV = tk.MaTaiKhoanGV
            WHERE {where}
        """
        total = self._execute_scalar(count_sql, tuple(params) if params else None)
        
        sql = f"""
            SELECT tk.MaTaiKhoanGV, tk.Email, tk.TrangThai,
                   hs.MaHoSoGV, hs.MaGiangVien, hs.HoTen, hs.GioiTinh,
                   hs.HinhAnh, hs.HocHam, hs.HocVi, hs.ChucVu, hs.TrangThai AS TrangThaiGV,
                   bm.TenBoMon, k.TenKhoa
            FROM TaiKhoanGiangVien tk
            INNER JOIN HoSoGiangVien hs ON hs.MaTaiKhoanGV = tk.MaTaiKhoanGV
            LEFT JOIN BoMon bm ON bm.MaBoMon = hs.MaBoMon
            LEFT JOIN Khoa k ON k.MaKhoa = bm.MaKhoa
            WHERE {where}
            ORDER BY hs.HoTen
            OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
        """
        params.extend([offset, so_ban_ghi])
        rows = self._execute_query(sql, tuple(params))
        return rows, total or 0
    
    def lay_ds_nhan_vien(self, ma_truong: int = None, loai_nv: str = None,
                          tu_khoa: str = None, trang: int = 1,
                          so_ban_ghi: int = 20) -> tuple[list, int]:
        """Lấy danh sách nhân viên"""
        offset = (trang - 1) * so_ban_ghi
        where_clauses = ["1=1"]
        params = []
        
        if ma_truong:
            where_clauses.append("tk.MaTruong = ?")
            params.append(ma_truong)
        if loai_nv:
            where_clauses.append("hs.LoaiNhanVien = ?")
            params.append(loai_nv)
        if tu_khoa:
            where_clauses.append("(hs.HoTen LIKE ? OR hs.MaNhanVien LIKE ?)")
            kw = f"%{tu_khoa}%"
            params.extend([kw, kw])
        
        where = " AND ".join(where_clauses)
        
        count_sql = f"""
            SELECT COUNT(*) FROM TaiKhoanNhanVien tk
            INNER JOIN HoSoNhanVien hs ON hs.MaTaiKhoanNV = tk.MaTaiKhoanNV
            WHERE {where}
        """
        total = self._execute_scalar(count_sql, tuple(params) if params else None)
        
        sql = f"""
            SELECT tk.MaTaiKhoanNV, tk.Email, tk.TrangThai,
                   hs.MaHoSoNV, hs.MaNhanVien, hs.HoTen,
                   hs.DonViCongTac, hs.ChucVu, hs.LoaiNhanVien, hs.HinhAnh,
                   (SELECT STRING_AGG(vt.TenVaiTro, ', ')
                    FROM VaiTroNhanVien vtnv
                    INNER JOIN VaiTro vt ON vt.MaVaiTro = vtnv.MaVaiTro
                    WHERE vtnv.MaTaiKhoanNV = tk.MaTaiKhoanNV AND vtnv.ConHieuLuc = 1
                   ) AS DanhSachVaiTro
            FROM TaiKhoanNhanVien tk
            INNER JOIN HoSoNhanVien hs ON hs.MaTaiKhoanNV = tk.MaTaiKhoanNV
            WHERE {where}
            ORDER BY hs.HoTen
            OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
        """
        params.extend([offset, so_ban_ghi])
        rows = self._execute_query(sql, tuple(params))
        return rows, total or 0

    def tao_giang_vien(self, ma_truong: int, data: dict) -> int:
        from utils.password import PasswordHelper
        mat_khau_hash, salt = PasswordHelper.hash_password(data.get('mat_khau', '123456'))
        ten_dang_nhap = data.get('ten_dang_nhap')
        exist = self._execute_query("SELECT 1 FROM TaiKhoanGiangVien WHERE TenDangNhap = ?", (ten_dang_nhap,))
        if exist: raise ValueError("Tên đăng nhập đã tồn tại")
        
        sql_tk = """
            SET NOCOUNT ON;
            INSERT INTO TaiKhoanGiangVien (MaTruong, TenDangNhap, MatKhauHash, Salt, Email, SoDienThoai, TrangThai, NgayTao) 
            VALUES (?, ?, ?, ?, ?, ?, 'HoatDong', GETDATE());
            SELECT SCOPE_IDENTITY();
        """
        ma_tk = self._execute_insert_get_id(sql_tk, (ma_truong, ten_dang_nhap, mat_khau_hash, salt, data.get('email'), data.get('so_dien_thoai')))
        
        sql_hs = """
            INSERT INTO HoSoGiangVien (MaTaiKhoanGV, MaGiangVien, HoTen, Ho, Ten, NgaySinh, GioiTinh, 
                                       HocHam, HocVi, ChucVu, MaBoMon, TrangThai)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        self._execute_non_query(sql_hs, (
            ma_tk, data.get('ma_giang_vien'), data.get('ho_ten'), data.get('ho'), data.get('ten'), 
            data.get('ngay_sinh'), data.get('gioi_tinh', 'Nam'), data.get('hoc_ham'), 
            data.get('hoc_vi'), data.get('chuc_vu'), data.get('ma_bo_mon'), data.get('trang_thai', 'DangCongTac')
        ))
        return ma_tk

    def cap_nhat_giang_vien(self, ma_tai_khoan: int, data: dict):
        sql_tk = "UPDATE TaiKhoanGiangVien SET Email = ?, SoDienThoai = ?, TrangThai = ? WHERE MaTaiKhoanGV = ?"
        self._execute_non_query(sql_tk, (data.get('email'), data.get('so_dien_thoai'), data.get('trang_thai', 'HoatDong'), ma_tai_khoan))
        
        sql_hs = """
            UPDATE HoSoGiangVien SET MaGiangVien=?, HoTen=?, Ho=?, Ten=?, NgaySinh=?, GioiTinh=?, 
                                     HocHam=?, HocVi=?, ChucVu=?, MaBoMon=?, TrangThai=?
            WHERE MaTaiKhoanGV=?
        """
        self._execute_non_query(sql_hs, (
            data.get('ma_giang_vien'), data.get('ho_ten'), data.get('ho'), data.get('ten'),
            data.get('ngay_sinh'), data.get('gioi_tinh', 'Nam'),
            data.get('hoc_ham'), data.get('hoc_vi'), data.get('chuc_vu'), 
            data.get('ma_bo_mon'), data.get('trang_thai_hs', 'DangCongTac'),
            ma_tai_khoan
        ))

    def xoa_giang_vien(self, ma_tai_khoan: int):
        self._execute_non_query("UPDATE TaiKhoanGiangVien SET TrangThai = 'DaXoa' WHERE MaTaiKhoanGV = ?", (ma_tai_khoan,))
        self._execute_non_query("UPDATE HoSoGiangVien SET TrangThai = 'DaNghiVi' WHERE MaTaiKhoanGV = ?", (ma_tai_khoan,))

    def cap_nhat_trang_thai_gv(self, ma_tai_khoan: int, trang_thai: str):
        self._execute_non_query("UPDATE TaiKhoanGiangVien SET TrangThai = ? WHERE MaTaiKhoanGV = ?", (trang_thai, ma_tai_khoan))


    def tao_nhan_vien(self, ma_truong: int, data: dict) -> int:
        from utils.password import PasswordHelper
        mat_khau_hash, salt = PasswordHelper.hash_password(data.get('mat_khau', '123456'))
        ten_dang_nhap = data.get('ten_dang_nhap')
        exist = self._execute_query("SELECT 1 FROM TaiKhoanNhanVien WHERE TenDangNhap = ?", (ten_dang_nhap,))
        if exist: raise ValueError("Tên đăng nhập đã tồn tại")
        
        sql_tk = """
            SET NOCOUNT ON;
            INSERT INTO TaiKhoanNhanVien (MaTruong, TenDangNhap, MatKhauHash, Salt, Email, SoDienThoai, TrangThai, NgayTao) 
            VALUES (?, ?, ?, ?, ?, ?, 'HoatDong', GETDATE());
            SELECT SCOPE_IDENTITY();
        """
        ma_tk = self._execute_insert_get_id(sql_tk, (ma_truong, ten_dang_nhap, mat_khau_hash, salt, data.get('email'), data.get('so_dien_thoai')))
        
        sql_hs = """
            INSERT INTO HoSoNhanVien (MaTaiKhoanNV, MaNhanVien, HoTen, Ho, Ten, NgaySinh, GioiTinh, 
                                      DonViCongTac, ChucVu, LoaiNhanVien, TrangThai)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        self._execute_non_query(sql_hs, (
            ma_tk, data.get('ma_nhan_vien'), data.get('ho_ten'), data.get('ho'), data.get('ten'), 
            data.get('ngay_sinh'), data.get('gioi_tinh', 'Nam'), data.get('don_vi_cong_tac'), 
            data.get('chuc_vu'), data.get('loai_nhan_vien'), data.get('trang_thai', 'DangCongTac')
        ))
        return ma_tk

    def cap_nhat_nhan_vien(self, ma_tai_khoan: int, data: dict):
        sql_tk = "UPDATE TaiKhoanNhanVien SET Email = ?, SoDienThoai = ?, TrangThai = ? WHERE MaTaiKhoanNV = ?"
        self._execute_non_query(sql_tk, (data.get('email'), data.get('so_dien_thoai'), data.get('trang_thai_tk', 'HoatDong'), ma_tai_khoan))
        
        sql_hs = """
            UPDATE HoSoNhanVien SET MaNhanVien=?, HoTen=?, Ho=?, Ten=?, NgaySinh=?, GioiTinh=?, 
                                    DonViCongTac=?, ChucVu=?, LoaiNhanVien=?, TrangThai=?
            WHERE MaTaiKhoanNV=?
        """
        self._execute_non_query(sql_hs, (
            data.get('ma_nhan_vien'), data.get('ho_ten'), data.get('ho'), data.get('ten'), 
            data.get('ngay_sinh'), data.get('gioi_tinh', 'Nam'), 
            data.get('don_vi_cong_tac'), data.get('chuc_vu'), data.get('loai_nhan_vien'), data.get('trang_thai_hs', 'DangCongTac'),
            ma_tai_khoan
        ))

    def xoa_nhan_vien(self, ma_tai_khoan: int):
        self._execute_non_query("UPDATE TaiKhoanNhanVien SET TrangThai = 'DaXoa' WHERE MaTaiKhoanNV = ?", (ma_tai_khoan,))
        self._execute_non_query("UPDATE HoSoNhanVien SET TrangThai = 'NghiViec' WHERE MaTaiKhoanNV = ?", (ma_tai_khoan,))

    def cap_nhat_trang_thai_nv(self, ma_tai_khoan: int, trang_thai: str):
        self._execute_non_query("UPDATE TaiKhoanNhanVien SET TrangThai = ? WHERE MaTaiKhoanNV = ?", (trang_thai, ma_tai_khoan))


# Khởi tạo repository
repo = NguoiDungRepository()


# ── NGƯỜI HỌC ENDPOINTS ───────────────────────────────────────────────────────

@nguoi_dung_bp.route('/nguoi-hoc', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_nguoi_hoc():
    """Lấy danh sách người học có phân trang và lọc"""
    trang = int(request.args.get('trang', 1))
    so_ban_ghi = min(int(request.args.get('so_ban_ghi', 20)), 100)
    tu_khoa = request.args.get('tu_khoa', '').strip()
    ma_lop = request.args.get('ma_lop', type=int)
    
    ma_truong = g.ma_truong
    
    ds, tong = repo.lay_ds_nguoi_hoc(ma_truong, ma_lop, tu_khoa, trang, so_ban_ghi)
    
    # Chuyển Decimal/datetime thành string
    data = []
    for r in ds:
        item = dict(r)
        for k, v in item.items():
            if hasattr(v, 'isoformat'):
                item[k] = v.isoformat()
        data.append(item)
    
    return APIResponse.phan_trang(data, tong, trang, so_ban_ghi)


@nguoi_dung_bp.route('/nguoi-hoc/<int:ma_tai_khoan>', methods=['GET'])
@yeu_cau_dang_nhap
def chi_tiet_nguoi_hoc(ma_tai_khoan: int):
    """Lấy chi tiết một người học"""
    # NH chỉ xem hồ sơ bản thân
    if g.loai_tai_khoan == 'NguoiHoc' and g.ma_tai_khoan != ma_tai_khoan:
        return APIResponse.khong_co_quyen()
    
    data = repo.lay_chi_tiet_nguoi_hoc(ma_tai_khoan)
    if not data:
        return APIResponse.khong_tim_thay("Không tìm thấy người học")
    
    item = dict(data)
    for k, v in item.items():
        if hasattr(v, 'isoformat'):
            item[k] = v.isoformat()
    
    return APIResponse.thanh_cong(item)


@nguoi_dung_bp.route('/nguoi-hoc', methods=['POST'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def tao_nguoi_hoc():
    data = request.get_json(silent=True)
    if not data or not data.get('ten_dang_nhap') or not data.get('ho_ten'):
        return APIResponse.loi("Dữ liệu không hợp lệ")
    
    try:
        ma_tk = repo.tao_nguoi_hoc(g.ma_truong, data)
        return APIResponse.thanh_cong({"ma_tai_khoan": ma_tk}, "Tạo người học thành công")
    except ValueError as e:
        return APIResponse.loi(str(e))
    except Exception as e:
        logger.error(f"Lỗi tạo NH: {e}")
        return APIResponse.loi("Lỗi hệ thống khi tạo người học")

@nguoi_dung_bp.route('/nguoi-hoc/<int:id>', methods=['PUT'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def cap_nhat_nguoi_hoc(id: int):
    data = request.get_json(silent=True)
    if not data:
        return APIResponse.loi("Dữ liệu không hợp lệ")
    try:
        repo.cap_nhat_nguoi_hoc(id, data)
        return APIResponse.thanh_cong(message="Cập nhật thành công")
    except Exception as e:
        logger.error(f"Lỗi cập nhật NH: {e}")
        return APIResponse.loi("Lỗi hệ thống khi cập nhật người học")

@nguoi_dung_bp.route('/nguoi-hoc/<int:id>', methods=['DELETE'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def xoa_nguoi_hoc(id: int):
    try:
        repo.xoa_nguoi_hoc(id)
        return APIResponse.thanh_cong(message="Xóa người học thành công")
    except Exception as e:
        return APIResponse.loi("Lỗi khi xóa người học")



# ── GIẢNG VIÊN ENDPOINTS ─────────────────────────────────────────────────────

@nguoi_dung_bp.route('/giang-vien', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_giang_vien():
    """Lấy danh sách giảng viên"""
    trang = int(request.args.get('trang', 1))
    so_ban_ghi = min(int(request.args.get('so_ban_ghi', 20)), 100)
    tu_khoa = request.args.get('tu_khoa', '').strip()
    ma_bo_mon = request.args.get('ma_bo_mon', type=int)
    
    ds, tong = repo.lay_ds_giang_vien(g.ma_truong, ma_bo_mon, tu_khoa, trang, so_ban_ghi)
    
    data = []
    for r in ds:
        item = dict(r)
        for k, v in item.items():
            if hasattr(v, 'isoformat'):
                item[k] = v.isoformat()
        data.append(item)
    
    return APIResponse.phan_trang(data, tong, trang, so_ban_ghi)

@nguoi_dung_bp.route('/giang-vien/<int:id>', methods=['GET'])
@yeu_cau_dang_nhap
def chi_tiet_giang_vien(id: int):
    sql = """
        SELECT tk.MaTaiKhoanGV, tk.TenDangNhap, tk.Email, tk.SoDienThoai, tk.TrangThai, tk.NgayTao,
                hs.MaHoSoGV, hs.HoTen, hs.MaGiangVien, hs.HocHam, hs.HocVi, hs.ChucVu,
                hs.MaBoMon, bm.TenBoMon, k.TenKhoa
        FROM TaiKhoanGiangVien tk
        INNER JOIN HoSoGiangVien hs ON hs.MaTaiKhoanGV = tk.MaTaiKhoanGV
        LEFT JOIN BoMon bm ON bm.MaBoMon = hs.MaBoMon
        LEFT JOIN Khoa k ON k.MaKhoa = bm.MaKhoa
        WHERE tk.MaTaiKhoanGV = ?
    """
    rows = repo._execute_query(sql, (id,))
    if not rows: return APIResponse.khong_tim_thay()
    item = dict(rows[0])
    for k, v in item.items():
        if hasattr(v, 'isoformat'): item[k] = v.isoformat()
    return APIResponse.thanh_cong(item)

@nguoi_dung_bp.route('/giang-vien', methods=['POST'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def tao_giang_vien():
    data = request.get_json(silent=True)
    if not data or not data.get('ten_dang_nhap') or not data.get('ho_ten'):
        return APIResponse.loi("Dữ liệu không hợp lệ")
    try:
        ma_tk = repo.tao_giang_vien(g.ma_truong, data)
        return APIResponse.thanh_cong({"ma_tai_khoan": ma_tk}, "Tạo giảng viên thành công")
    except ValueError as e: return APIResponse.loi(str(e))
    except Exception as e:
        logger.error(f"Lỗi tạo GV: {e}")
        return APIResponse.loi("Lỗi hệ thống khi tạo giảng viên")

@nguoi_dung_bp.route('/giang-vien/<int:id>', methods=['PUT'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def cap_nhat_giang_vien(id: int):
    data = request.get_json(silent=True)
    if not data: return APIResponse.loi("Dữ liệu không hợp lệ")
    try:
        repo.cap_nhat_giang_vien(id, data)
        return APIResponse.thanh_cong(message="Cập nhật giảng viên thành công")
    except Exception as e:
        logger.error(f"Lỗi cập nhật GV: {e}")
        return APIResponse.loi("Lỗi hệ thống")

@nguoi_dung_bp.route('/giang-vien/<int:id>', methods=['DELETE'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def xoa_giang_vien(id: int):
    try:
        repo.xoa_giang_vien(id)
        return APIResponse.thanh_cong(message="Xóa giảng viên thành công")
    except Exception as e:
        return APIResponse.loi("Lỗi khi xóa giảng viên")


# ── NHÂN VIÊN ENDPOINTS ──────────────────────────────────────────────────────

@nguoi_dung_bp.route('/nhan-vien', methods=['GET'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def danh_sach_nhan_vien():
    """Lấy danh sách nhân viên (chỉ Admin)"""
    trang = int(request.args.get('trang', 1))
    so_ban_ghi = min(int(request.args.get('so_ban_ghi', 20)), 100)
    tu_khoa = request.args.get('tu_khoa', '').strip()
    loai_nv = request.args.get('loai_nv', '').strip()
    
    ds, tong = repo.lay_ds_nhan_vien(g.ma_truong, loai_nv or None, tu_khoa, trang, so_ban_ghi)
    
    data = []
    for r in ds:
        item = dict(r)
        for k, v in item.items():
            if hasattr(v, 'isoformat'):
                item[k] = v.isoformat()
        data.append(item)
    
    return APIResponse.phan_trang(data, tong, trang, so_ban_ghi)

@nguoi_dung_bp.route('/nhan-vien/<int:id>', methods=['GET'])
@yeu_cau_dang_nhap
def chi_tiet_nhan_vien_route(id: int):
    sql = """
        SELECT tk.MaTaiKhoanNV, tk.TenDangNhap, tk.Email, tk.SoDienThoai, tk.TrangThai, tk.NgayTao,
                hs.MaHoSoNV, hs.HoTen, hs.MaNhanVien, hs.DonViCongTac, hs.ChucVu, hs.LoaiNhanVien
        FROM TaiKhoanNhanVien tk
        INNER JOIN HoSoNhanVien hs ON hs.MaTaiKhoanNV = tk.MaTaiKhoanNV
        WHERE tk.MaTaiKhoanNV = ?
    """
    rows = repo._execute_query(sql, (id,))
    if not rows: return APIResponse.khong_tim_thay()
    item = dict(rows[0])
    for k, v in item.items():
        if hasattr(v, 'isoformat'): item[k] = v.isoformat()
    return APIResponse.thanh_cong(item)

@nguoi_dung_bp.route('/nhan-vien', methods=['POST'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def tao_nhan_vien():
    data = request.get_json(silent=True)
    if not data or not data.get('ten_dang_nhap') or not data.get('ho_ten'):
        return APIResponse.loi("Dữ liệu không hợp lệ")
    try:
        ma_tk = repo.tao_nhan_vien(g.ma_truong, data)
        return APIResponse.thanh_cong({"ma_tai_khoan": ma_tk}, "Tạo nhân viên thành công")
    except ValueError as e: return APIResponse.loi(str(e))
    except Exception as e:
        logger.error(f"Lỗi tạo NV: {e}")
        return APIResponse.loi("Lỗi hệ thống khi tạo nhân viên")

@nguoi_dung_bp.route('/nhan-vien/<int:id>', methods=['PUT'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def cap_nhat_nhan_vien(id: int):
    data = request.get_json(silent=True)
    if not data: return APIResponse.loi("Dữ liệu không hợp lệ")
    try:
        repo.cap_nhat_nhan_vien(id, data)
        return APIResponse.thanh_cong(message="Cập nhật nhân viên thành công")
    except Exception as e:
        logger.error(f"Lỗi cập nhật NV: {e}")
        return APIResponse.loi("Lỗi hệ thống")

@nguoi_dung_bp.route('/nhan-vien/<int:id>', methods=['DELETE'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def xoa_nhan_vien(id: int):
    try:
        repo.xoa_nhan_vien(id)
        return APIResponse.thanh_cong(message="Xóa nhân viên thành công")
    except Exception as e:
        return APIResponse.loi("Lỗi khi xóa nhân viên")


@nguoi_dung_bp.route('/doi-mat-khau', methods=['PUT'])
@yeu_cau_dang_nhap
def doi_mat_khau():
    """Đổi mật khẩu của chính mình"""
    data = request.get_json(silent=True)
    if not data:
        return APIResponse.loi("Dữ liệu không hợp lệ")
    
    mat_khau_cu = data.get('mat_khau_cu', '')
    mat_khau_moi = data.get('mat_khau_moi', '')
    
    if not mat_khau_cu or not mat_khau_moi:
        return APIResponse.loi("Vui lòng nhập đầy đủ mật khẩu cũ và mới")
    
    # Kiểm tra độ mạnh mật khẩu mới
    hop_le, thong_bao = PasswordHelper.is_strong_password(mat_khau_moi)
    if not hop_le:
        return APIResponse.loi(thong_bao)
    
    from repositories.auth_repository import AuthRepository
    auth_repo = AuthRepository()
    
    loai = g.loai_tai_khoan
    ma = g.ma_tai_khoan
    
    # Lấy hash hiện tại để xác minh mật khẩu cũ
    if loai == 'NguoiHoc':
        tk = auth_repo.lay_tai_khoan_nh_theo_ten_dang_nhap("")
    elif loai == 'GiangVien':
        from repositories.base_repository import BaseRepository
        base = BaseRepository()
        rows = base._execute_query(
            "SELECT MatKhauHash, Salt FROM TaiKhoanGiangVien WHERE MaTaiKhoanGV = ?", (ma,))
        if not rows:
            return APIResponse.khong_tim_thay()
        tk_data = rows[0]
    elif loai == 'NhanVien':
        from repositories.base_repository import BaseRepository
        base = BaseRepository()
        rows = base._execute_query(
            "SELECT MatKhauHash, Salt FROM TaiKhoanNhanVien WHERE MaTaiKhoanNV = ?", (ma,))
        if not rows:
            return APIResponse.khong_tim_thay()
        tk_data = rows[0]
    
    # Lấy hash + salt trực tiếp theo loại
    table_map = {
        'NguoiHoc':  ('TaiKhoanNguoiHoc',  'MaTKNguoiHoc'),
        'GiangVien': ('TaiKhoanGiangVien', 'MaTaiKhoanGV'),
        'NhanVien':  ('TaiKhoanNhanVien',  'MaTaiKhoanNV'),
    }
    table, pk = table_map[loai]
    from repositories.base_repository import BaseRepository
    base = BaseRepository()
    rows = base._execute_query(
        f"SELECT MatKhauHash, Salt FROM {table} WHERE {pk} = ?", (ma,))
    if not rows:
        return APIResponse.khong_tim_thay()
    
    hash_cu = rows[0]['MatKhauHash']
    salt_cu = rows[0]['Salt']
    
    if not PasswordHelper.verify_password(mat_khau_cu, hash_cu, salt_cu):
        return APIResponse.loi("Mật khẩu cũ không đúng")
    
    # Tạo hash mới
    hash_moi, salt_moi = PasswordHelper.hash_password(mat_khau_moi)
    sql = f"""
        UPDATE {table} SET MatKhauHash = ?, Salt = ?, 
        NgayDoiMatKhau = GETDATE(), NgayCapNhat = GETDATE()
        WHERE {pk} = ?
    """
    base._execute_non_query(sql, (hash_moi, salt_moi, ma))
    
    return APIResponse.thanh_cong(message="Đổi mật khẩu thành công")

@nguoi_dung_bp.route('/profile', methods=['GET'])
@yeu_cau_dang_nhap
def get_own_profile():
    """Lấy thông tin profile đầy đủ của bản thân"""
    loai = g.loai_tai_khoan
    id = g.ma_tai_khoan
    
    if loai == 'NguoiHoc':
        data = repo.lay_chi_tiet_nguoi_hoc(id)
    elif loai == 'GiangVien':
        # Need to implement this repository method or similar
        sql = """
            SELECT tk.MaTaiKhoanGV, tk.TenDangNhap, tk.Email, tk.SoDienThoai, tk.TrangThai, tk.NgayTao,
                   hs.HoTen, hs.MaGiangVien, hs.HocHam, hs.HocVi, hs.ChucVu,
                   bm.TenBoMon, k.TenKhoa
            FROM TaiKhoanGiangVien tk
            INNER JOIN HoSoGiangVien hs ON hs.MaTaiKhoanGV = tk.MaTaiKhoanGV
            LEFT JOIN BoMon bm ON bm.MaBoMon = hs.MaBoMon
            LEFT JOIN Khoa k ON k.MaKhoa = bm.MaKhoa
            WHERE tk.MaTaiKhoanGV = ?
        """
        rows = repo._execute_query(sql, (id,))
        data = rows[0] if rows else None
    else: # NhanVien
        sql = """
            SELECT tk.MaTaiKhoanNV, tk.TenDangNhap, tk.Email, tk.SoDienThoai, tk.TrangThai, tk.NgayTao,
                   hs.HoTen, hs.MaNhanVien, hs.DonViCongTac, hs.ChucVu, hs.LoaiNhanVien
            FROM TaiKhoanNhanVien tk
            INNER JOIN HoSoNhanVien hs ON hs.MaTaiKhoanNV = tk.MaTaiKhoanNV
            WHERE tk.MaTaiKhoanNV = ?
        """
        rows = repo._execute_query(sql, (id,))
        data = rows[0] if rows else None
        
    if not data:
        return APIResponse.khong_tim_thay()
    
    item = dict(data)
    for k, v in item.items():
        if hasattr(v, 'isoformat'):
            item[k] = v.isoformat()
            
    return APIResponse.thanh_cong(item)

