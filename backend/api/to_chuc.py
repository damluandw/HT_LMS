"""
To Chuc API Blueprint - Quản lý cơ cấu tổ chức trường
GET /api/org/truong           - Danh sách trường
GET /api/org/khoa             - Danh sách khoa
GET /api/org/bo-mon           - Danh sách bộ môn
GET /api/org/nganh            - Danh sách ngành
GET /api/org/lop-hanh-chinh   - Danh sách lớp hành chính
"""
import logging
from flask import Blueprint, request, g
from middleware.auth_middleware import yeu_cau_dang_nhap
from utils.response import APIResponse
from repositories.base_repository import BaseRepository

logger = logging.getLogger(__name__)

to_chuc_bp = Blueprint('to_chuc', __name__, url_prefix='/api/org')


class ToChucRepository(BaseRepository):
    
    def lay_ds_truong(self) -> list:
        sql = """
            SELECT MaTruong, TenTruong, TenVietTat, MaTruongCode, 
                   Logo, DiaChi, Website, DienThoai, Email, ConHieuLuc
            FROM Truong WHERE ConHieuLuc = 1 ORDER BY TenTruong
        """
        return self._execute_query(sql)
    
    def lay_ds_khoa(self, ma_truong: int = None) -> list:
        params = []
        where = "WHERE k.ConHieuLuc = 1"
        if ma_truong:
            where += " AND k.MaTruong = ?"
            params.append(ma_truong)
        sql = f"""
            SELECT k.MaKhoa, k.MaTruong, k.TenKhoa, k.MaKhoaCode, k.MoTa,
                   t.TenTruong,
                   (SELECT COUNT(*) FROM BoMon bm WHERE bm.MaKhoa = k.MaKhoa AND bm.ConHieuLuc = 1) AS SoBoMon
            FROM Khoa k
            LEFT JOIN Truong t ON t.MaTruong = k.MaTruong
            {where}
            ORDER BY k.TenKhoa
        """
        return self._execute_query(sql, tuple(params) if params else None)
    
    def lay_ds_bo_mon(self, ma_khoa: int = None) -> list:
        params = []
        where = "WHERE bm.ConHieuLuc = 1"
        if ma_khoa:
            where += " AND bm.MaKhoa = ?"
            params.append(ma_khoa)
        sql = f"""
            SELECT bm.MaBoMon, bm.MaKhoa, bm.TenBoMon, bm.MaBoMonCode, bm.MoTa,
                   k.TenKhoa, t.TenTruong,
                   (SELECT COUNT(*) FROM Nganh n WHERE n.MaBoMon = bm.MaBoMon AND n.ConHieuLuc = 1) AS SoNganh
            FROM BoMon bm
            LEFT JOIN Khoa k ON k.MaKhoa = bm.MaKhoa
            LEFT JOIN Truong t ON t.MaTruong = k.MaTruong
            {where}
            ORDER BY bm.TenBoMon
        """
        return self._execute_query(sql, tuple(params) if params else None)
    
    def lay_ds_nganh(self, ma_bo_mon: int = None) -> list:
        params = []
        where = "WHERE n.ConHieuLuc = 1"
        if ma_bo_mon:
            where += " AND n.MaBoMon = ?"
            params.append(ma_bo_mon)
        sql = f"""
            SELECT n.MaNganh, n.MaBoMon, n.TenNganh, n.MaNganhCode,
                   n.TongTinChi, n.ThoiGianDaoTaoNam, n.TrinhDo,
                   bm.TenBoMon, k.TenKhoa
            FROM Nganh n
            LEFT JOIN BoMon bm ON bm.MaBoMon = n.MaBoMon
            LEFT JOIN Khoa k ON k.MaKhoa = bm.MaKhoa
            {where}
            ORDER BY n.TenNganh
        """
        return self._execute_query(sql, tuple(params) if params else None)
    
    def lay_ds_lop_hanh_chinh(self, ma_nganh: int = None, ma_khoa: int = None) -> list:
        params = []
        where_parts = ["lhc.TrangThai = 'HoatDong'"]
        if ma_nganh:
            where_parts.append("lhc.MaNganh = ?")
            params.append(ma_nganh)
        if ma_khoa:
            where_parts.append("bm.MaKhoa = ?")
            params.append(ma_khoa)
        where = "WHERE " + " AND ".join(where_parts)
        sql = f"""
            SELECT lhc.MaLopHC, lhc.MaNganh, lhc.TenLop, lhc.MaLopCode,
                   lhc.NienKhoa, lhc.SiSoToiDa,
                   n.TenNganh, k.TenKhoa,
                   (SELECT COUNT(*) FROM HoSoNguoiHoc hs 
                    WHERE hs.MaTKNguoiHoc IS NOT NULL
                   ) AS SiSoHienTai
            FROM LopHanhChinh lhc
            LEFT JOIN Nganh n ON n.MaNganh = lhc.MaNganh
            LEFT JOIN BoMon bm ON bm.MaBoMon = n.MaBoMon
            LEFT JOIN Khoa k ON k.MaKhoa = bm.MaKhoa
            {where}
            ORDER BY lhc.NienKhoa DESC, lhc.TenLop
        """
        return self._execute_query(sql, tuple(params) if params else None)

    # --- CRUD METHODS ---
    def tao_khoa(self, data: dict) -> int:
        sql = """
            SET NOCOUNT ON;
            INSERT INTO Khoa (MaTruong, TenKhoa, MaKhoaCode, MoTa, ConHieuLuc)
            VALUES (?, ?, ?, ?, 1);
            SELECT SCOPE_IDENTITY();
        """
        return self._execute_insert_get_id(sql, (data.get('ma_truong'), data.get('ten_khoa'), data.get('ma_khoa_code'), data.get('mo_ta')))

    def cap_nhat_khoa(self, ma_khoa: int, data: dict):
        sql = "UPDATE Khoa SET TenKhoa=?, MaKhoaCode=?, MoTa=? WHERE MaKhoa=?"
        self._execute_non_query(sql, (data.get('ten_khoa'), data.get('ma_khoa_code'), data.get('mo_ta'), ma_khoa))

    def xoa_khoa(self, ma_khoa: int):
        self._execute_non_query("UPDATE Khoa SET ConHieuLuc = 0 WHERE MaKhoa = ?", (ma_khoa,))

    def tao_bo_mon(self, data: dict) -> int:
        sql = """
            SET NOCOUNT ON;
            INSERT INTO BoMon (MaKhoa, TenBoMon, MaBoMonCode, MoTa, ConHieuLuc)
            VALUES (?, ?, ?, ?, 1);
            SELECT SCOPE_IDENTITY();
        """
        return self._execute_insert_get_id(sql, (data.get('ma_khoa'), data.get('ten_bo_mon'), data.get('ma_bo_mon_code'), data.get('mo_ta')))

    def cap_nhat_bo_mon(self, ma_bo_mon: int, data: dict):
        sql = "UPDATE BoMon SET TenBoMon=?, MaBoMonCode=?, MoTa=? WHERE MaBoMon=?"
        self._execute_non_query(sql, (data.get('ten_bo_mon'), data.get('ma_bo_mon_code'), data.get('mo_ta'), ma_bo_mon))

    def xoa_bo_mon(self, ma_bo_mon: int):
        self._execute_non_query("UPDATE BoMon SET ConHieuLuc = 0 WHERE MaBoMon = ?", (ma_bo_mon,))

    def tao_nganh(self, data: dict) -> int:
        sql = """
            SET NOCOUNT ON;
            INSERT INTO Nganh (MaBoMon, TenNganh, MaNganhCode, TongTinChi, ThoiGianDaoTaoNam, TrinhDo, ConHieuLuc)
            VALUES (?, ?, ?, ?, ?, ?, 1);
            SELECT SCOPE_IDENTITY();
        """
        return self._execute_insert_get_id(sql, (
            data.get('ma_bo_mon'), data.get('ten_nganh'), data.get('ma_nganh_code'),
            data.get('tong_tin_chi'), data.get('thoi_gian_dao_tao_nam'), data.get('trinh_do')
        ))

    def cap_nhat_nganh(self, ma_nganh: int, data: dict):
        sql = "UPDATE Nganh SET TenNganh=?, MaNganhCode=?, TongTinChi=?, ThoiGianDaoTaoNam=?, TrinhDo=? WHERE MaNganh=?"
        self._execute_non_query(sql, (
            data.get('ten_nganh'), data.get('ma_nganh_code'), data.get('tong_tin_chi'),
            data.get('thoi_gian_dao_tao_nam'), data.get('trinh_do'), ma_nganh
        ))

    def xoa_nganh(self, ma_nganh: int):
        self._execute_non_query("UPDATE Nganh SET ConHieuLuc = 0 WHERE MaNganh = ?", (ma_nganh,))

    def tao_lop_hanh_chinh(self, data: dict) -> int:
        sql = """
            SET NOCOUNT ON;
            INSERT INTO LopHanhChinh (MaNganh, TenLop, MaLopCode, NienKhoa, SiSoToiDa, TrangThai)
            VALUES (?, ?, ?, ?, ?, 'HoatDong');
            SELECT SCOPE_IDENTITY();
        """
        return self._execute_insert_get_id(sql, (
            data.get('ma_nganh'), data.get('ten_lop'), data.get('ma_lop_code'),
            data.get('nien_khoa'), data.get('si_so_toi_da')
        ))

    def cap_nhat_lop_hanh_chinh(self, ma_lop: int, data: dict):
        sql = "UPDATE LopHanhChinh SET TenLop=?, MaLopCode=?, NienKhoa=?, SiSoToiDa=?, TrangThai=? WHERE MaLopHC=?"
        self._execute_non_query(sql, (
            data.get('ten_lop'), data.get('ma_lop_code'), data.get('nien_khoa'),
            data.get('si_so_toi_da'), data.get('trang_thai', 'HoatDong'), ma_lop
        ))

    def xoa_lop_hanh_chinh(self, ma_lop: int):
        self._execute_non_query("UPDATE LopHanhChinh SET TrangThai = 'DaXoa' WHERE MaLopHC = ?", (ma_lop,))



repo = ToChucRepository()


@to_chuc_bp.route('/truong', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_truong():
    data = repo.lay_ds_truong()
    return APIResponse.thanh_cong([dict(r) for r in data])


@to_chuc_bp.route('/khoa', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_khoa():
    ma_truong = request.args.get('ma_truong', g.ma_truong, type=int)
    data = repo.lay_ds_khoa(ma_truong)
    return APIResponse.thanh_cong([dict(r) for r in data])


@to_chuc_bp.route('/bo-mon', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_bo_mon():
    ma_khoa = request.args.get('ma_khoa', type=int)
    data = repo.lay_ds_bo_mon(ma_khoa)
    return APIResponse.thanh_cong([dict(r) for r in data])


@to_chuc_bp.route('/nganh', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_nganh():
    ma_bo_mon = request.args.get('ma_bo_mon', type=int)
    data = repo.lay_ds_nganh(ma_bo_mon)
    return APIResponse.thanh_cong([dict(r) for r in data])


@to_chuc_bp.route('/lop-hanh-chinh', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_lop_hanh_chinh():
    ma_nganh = request.args.get('ma_nganh', type=int)
    ma_khoa = request.args.get('ma_khoa', type=int)
    data = repo.lay_ds_lop_hanh_chinh(ma_nganh, ma_khoa)
    return APIResponse.thanh_cong([dict(r) for r in data])

from middleware.auth_middleware import yeu_cau_nhan_vien

@to_chuc_bp.route('/khoa', methods=['POST'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def tao_khoa():
    data = request.get_json()
    try:
        if not data.get('ma_truong'): data['ma_truong'] = g.ma_truong
        id = repo.tao_khoa(data)
        return APIResponse.thanh_cong({"ma_khoa": id}, "Tạo khoa thành công")
    except Exception as e: return APIResponse.loi(str(e))

@to_chuc_bp.route('/khoa/<int:id>', methods=['GET', 'PUT', 'DELETE'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def detail_update_xoa_khoa(id: int):
    if request.method == 'GET':
        data = repo._execute_query("SELECT * FROM Khoa WHERE MaKhoa = ?", (id,))
        if not data: return APIResponse.khong_tim_thay()
        return APIResponse.thanh_cong(dict(data[0]))
    if request.method == 'DELETE':
        repo.xoa_khoa(id)
        return APIResponse.thanh_cong(message="Xóa khoa thành công")
    data = request.get_json()
    repo.cap_nhat_khoa(id, data)
    return APIResponse.thanh_cong(message="Cập nhật khoa thành công")

@to_chuc_bp.route('/bo-mon', methods=['POST'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def tao_bo_mon():
    data = request.get_json()
    try:
        id = repo.tao_bo_mon(data)
        return APIResponse.thanh_cong({"ma_bo_mon": id}, "Tạo bộ môn thành công")
    except Exception as e: return APIResponse.loi(str(e))

@to_chuc_bp.route('/bo-mon/<int:id>', methods=['GET', 'PUT', 'DELETE'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def detail_update_xoa_bo_mon(id: int):
    if request.method == 'GET':
        data = repo._execute_query("SELECT * FROM BoMon WHERE MaBoMon = ?", (id,))
        if not data: return APIResponse.khong_tim_thay()
        return APIResponse.thanh_cong(dict(data[0]))
    if request.method == 'DELETE':
        repo.xoa_bo_mon(id)
        return APIResponse.thanh_cong(message="Xóa bộ môn thành công")
    data = request.get_json()
    repo.cap_nhat_bo_mon(id, data)
    return APIResponse.thanh_cong(message="Cập nhật thành công")

@to_chuc_bp.route('/nganh', methods=['POST'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def tao_nganh():
    data = request.get_json()
    id = repo.tao_nganh(data)
    return APIResponse.thanh_cong({"ma_nganh": id}, "Tạo ngành công thành công")

@to_chuc_bp.route('/nganh/<int:id>', methods=['GET', 'PUT', 'DELETE'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def detail_update_xoa_nganh(id: int):
    if request.method == 'GET':
        data = repo._execute_query("SELECT * FROM Nganh WHERE MaNganh = ?", (id,))
        if not data: return APIResponse.khong_tim_thay()
        return APIResponse.thanh_cong(dict(data[0]))
    if request.method == 'DELETE':
        repo.xoa_nganh(id)
        return APIResponse.thanh_cong(message="Xóa ngành công thành công")
    data = request.get_json()
    repo.cap_nhat_nganh(id, data)
    return APIResponse.thanh_cong(message="Cập nhật thành công")

@to_chuc_bp.route('/lop-hanh-chinh', methods=['POST'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def tao_lop_hanh_chinh():
    data = request.get_json()
    id = repo.tao_lop_hanh_chinh(data)
    return APIResponse.thanh_cong({"ma_lop": id}, "Tạo lớp thành công")

@to_chuc_bp.route('/lop-hanh-chinh/<int:id>', methods=['GET', 'PUT', 'DELETE'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def detail_update_xoa_lop(id: int):
    if request.method == 'GET':
        data = repo._execute_query("SELECT * FROM LopHanhChinh WHERE MaLopHC = ?", (id,))
        if not data: return APIResponse.khong_tim_thay()
        return APIResponse.thanh_cong(dict(data[0]))
    if request.method == 'DELETE':
        repo.xoa_lop_hanh_chinh(id)
        return APIResponse.thanh_cong(message="Xóa lớp thành công")
    data = request.get_json()
    repo.cap_nhat_lop_hanh_chinh(id, data)
    return APIResponse.thanh_cong(message="Cập nhật thành công")

