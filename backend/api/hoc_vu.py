"""
Hoc Vu API Blueprint - Quản lý học vụ
GET /api/hoc-vu/hoc-ky                   - Danh sách học kỳ
GET /api/hoc-vu/lop-hoc-phan             - Danh sách lớp học phần
GET /api/hoc-vu/lop-hoc-phan/<id>        - Chi tiết lớp học phần (danh sách SV)
GET /api/hoc-vu/dang-ky                  - Đăng ký học phần của SV đăng nhập
GET /api/hoc-vu/thoi-khoa-bieu           - Thời khoá biểu của người dùng
"""
import logging
from flask import Blueprint, request, g
from middleware.auth_middleware import yeu_cau_dang_nhap
from utils.response import APIResponse
from repositories.base_repository import BaseRepository

logger = logging.getLogger(__name__)
hoc_vu_bp = Blueprint('hoc_vu', __name__, url_prefix='/api/hoc-vu')


class HocVuRepository(BaseRepository):

    def lay_ds_hoc_ky(self, ma_truong: int = None) -> list:
        sql = """
            SELECT hk.MaHocKy, hk.MaNamHoc, hk.TenHocKy, hk.ThuTu,
                   hk.NgayBatDau, hk.NgayKetThuc, hk.LaHocKyHienTai, hk.TrangThai,
                   nh.TenNamHoc
            FROM HocKy hk
            INNER JOIN NamHoc nh ON nh.MaNamHoc = hk.MaNamHoc
            WHERE (? IS NULL OR nh.MaTruong = ?)
            ORDER BY nh.TenNamHoc DESC, hk.ThuTu
        """
        return self._execute_query(sql, (ma_truong, ma_truong))

    def lay_ds_lop_hoc_phan(self, ma_hoc_ky: int = None, ma_hoc_phan: int = None,
                              ma_giang_vien: int = None, tu_khoa: str = None,
                              trang: int = 1, so_ban_ghi: int = 20) -> tuple[list, int]:
        offset = (trang - 1) * so_ban_ghi
        where_parts = ["1=1"]
        params = []

        if ma_hoc_ky:
            where_parts.append("lhp.MaHocKy = ?")
            params.append(ma_hoc_ky)
        if ma_hoc_phan:
            where_parts.append("lhp.MaHocPhan = ?")
            params.append(ma_hoc_phan)
        if ma_giang_vien:
            where_parts.append("""
                EXISTS (SELECT 1 FROM GiangVien_LopHocPhan gvlhp 
                        WHERE gvlhp.MaLopHP = lhp.MaLopHP AND gvlhp.MaHoSoGV = ?)""")
            params.append(ma_giang_vien)
        if tu_khoa:
            where_parts.append("(hp.TenHocPhan LIKE ? OR lhp.MaLopHPCode LIKE ?)")
            kw = f"%{tu_khoa}%"
            params.extend([kw, kw])

        where = " AND ".join(where_parts)

        count_sql = f"""
            SELECT COUNT(*) FROM LopHocPhan lhp
            INNER JOIN HocPhan hp ON hp.MaHocPhan = lhp.MaHocPhan
            WHERE {where}
        """
        total = self._execute_scalar(count_sql, tuple(params) if params else None)

        sql = f"""
            SELECT lhp.MaLopHP, lhp.MaLopHPCode, lhp.TenLop, lhp.TrangThai,
                   lhp.SiSoToiDa, lhp.LoaiLop, lhp.DaDuaRaDiem,
                   hp.MaHocPhan, hp.TenHocPhan, hp.MaHocPhanCode, hp.SoTinChi,
                   hk.TenHocKy, hk.MaHocKy,
                   (SELECT COUNT(*) FROM DangKyHocPhan dk 
                    WHERE dk.MaLopHP = lhp.MaLopHP AND dk.TrangThai = 'DaDangKy') AS SiSoHienTai,
                   (SELECT STRING_AGG(hsgv.HoTen, ', ')
                    FROM GiangVien_LopHocPhan gvlhp
                    INNER JOIN HoSoGiangVien hsgv ON hsgv.MaHoSoGV = gvlhp.MaHoSoGV
                    WHERE gvlhp.MaLopHP = lhp.MaLopHP AND gvlhp.ConHieuLuc = 1
                   ) AS DanhSachGiangVien
            FROM LopHocPhan lhp
            INNER JOIN HocPhan hp ON hp.MaHocPhan = lhp.MaHocPhan
            INNER JOIN HocKy hk ON hk.MaHocKy = lhp.MaHocKy
            WHERE {where}
            ORDER BY hk.TenHocKy DESC, hp.TenHocPhan
            OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
        """
        params.extend([offset, so_ban_ghi])
        rows = self._execute_query(sql, tuple(params))
        return rows, total or 0

    def lay_nguoi_hoc_trong_lop(self, ma_lop_hp: int) -> list:
        sql = """
            SELECT dk.MaDangKy, dk.TrangThai AS TrangThaiDK, dk.LoaiDangKy,
                   hs.MaHoSoNH, hs.MaKyHieu, hs.HoTen, hs.GioiTinh, hs.HinhAnh,
                   n.TenNganh, lhc.TenLop
            FROM DangKyHocPhan dk
            INNER JOIN HoSoNguoiHoc hs ON hs.MaHoSoNH = dk.MaHoSoNH
            LEFT JOIN Nganh n ON n.MaNganh = hs.MaNganh
            LEFT JOIN LopHanhChinh lhc ON lhc.MaLopHC = hs.MaLopHanhChinh
            WHERE dk.MaLopHP = ? AND dk.TrangThai = 'DaDangKy'
            ORDER BY hs.HoTen
        """
        return self._execute_query(sql, (ma_lop_hp,))

    def lay_lop_hoc_phan_cua_sinh_vien(self, ma_ho_so_sv: int, 
                                         ma_hoc_ky: int = None) -> list:
        where = "WHERE dk.MaHoSoNH = ? AND dk.TrangThai = 'DaDangKy'"
        params = [ma_ho_so_nh]
        if ma_hoc_ky:
            where += " AND lhp.MaHocKy = ?"
            params.append(ma_hoc_ky)
        sql = f"""
            SELECT dk.MaDangKy, dk.LoaiDangKy,
                   lhp.MaLopHP, lhp.MaLopHPCode, lhp.TenLop,
                   hp.TenHocPhan, hp.MaHocPhanCode, hp.SoTinChi,
                   hk.TenHocKy,
                   (SELECT STRING_AGG(hsgv.HoTen, ', ')
                    FROM GiangVien_LopHocPhan gvlhp
                    INNER JOIN HoSoGiangVien hsgv ON hsgv.MaHoSoGV = gvlhp.MaHoSoGV
                    WHERE gvlhp.MaLopHP = lhp.MaLopHP AND gvlhp.ConHieuLuc = 1
                   ) AS GiangVienDay
            FROM DangKyHocPhan dk
            INNER JOIN LopHocPhan lhp ON lhp.MaLopHP = dk.MaLopHP
            INNER JOIN HocPhan hp ON hp.MaHocPhan = lhp.MaHocPhan
            INNER JOIN HocKy hk ON hk.MaHocKy = lhp.MaHocKy
            {where}
            ORDER BY hp.TenHocPhan
        """
        return self._execute_query(sql, tuple(params))

    def lay_lop_hoc_phan_cua_giang_vien(self, ma_ho_so_gv: int, 
                                          ma_hoc_ky: int = None) -> list:
        where = "WHERE gvlhp.MaHoSoGV = ? AND gvlhp.ConHieuLuc = 1"
        params = [ma_ho_so_gv]
        if ma_hoc_ky:
            where += " AND lhp.MaHocKy = ?"
            params.append(ma_hoc_ky)
        sql = f"""
            SELECT gvlhp.VaiTroDayHoc,
                   lhp.MaLopHP, lhp.MaLopHPCode, lhp.TenLop, lhp.TrangThai,
                   hp.TenHocPhan, hp.MaHocPhanCode, hp.SoTinChi,
                   hk.TenHocKy,
                   (SELECT COUNT(*) FROM DangKyHocPhan dk 
                    WHERE dk.MaLopHP = lhp.MaLopHP AND dk.TrangThai = 'DaDangKy') AS SiSo
            FROM GiangVien_LopHocPhan gvlhp
            INNER JOIN LopHocPhan lhp ON lhp.MaLopHP = gvlhp.MaLopHP
            INNER JOIN HocPhan hp ON hp.MaHocPhan = lhp.MaHocPhan
            INNER JOIN HocKy hk ON hk.MaHocKy = lhp.MaHocKy
            {where}
            ORDER BY hk.TenHocKy DESC, hp.TenHocPhan
        """
        return self._execute_query(sql, tuple(params))

    def tao_hoc_ky(self, data: dict) -> int:
        sql = """
            SET NOCOUNT ON;
            INSERT INTO HocKy (MaNamHoc, TenHocKy, ThuTu, NgayBatDau, NgayKetThuc, LaHocKyHienTai, TrangThai)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            SELECT SCOPE_IDENTITY();
        """
        return self._execute_insert_get_id(sql, (
            data.get('ma_nam_hoc'), data.get('ten_hoc_ky'), data.get('thu_tu'),
            data.get('ngay_bat_dau'), data.get('ngay_ket_thuc'), data.get('la_hien_tai', 0), data.get('trang_thai', 'SapToChuc')
        ))

    def cap_nhat_hoc_ky(self, ma_hk: int, data: dict):
        sql = """
            UPDATE HocKy SET TenHocKy=?, ThuTu=?, NgayBatDau=?, NgayKetThuc=?, LaHocKyHienTai=?, TrangThai=?
            WHERE MaHocKy=?
        """
        self._execute_non_query(sql, (
            data.get('ten_hoc_ky'), data.get('thu_tu'), data.get('ngay_bat_dau'),
            data.get('ngay_ket_thuc'), data.get('la_hien_tai', 0), data.get('trang_thai'), ma_hk
        ))

    def xoa_hoc_ky(self, ma_hk: int):
        self._execute_non_query("DELETE FROM HocKy WHERE MaHocKy = ?", (ma_hk,))

    def tao_lop_hoc_phan(self, data: dict) -> int:
        sql = """
            SET NOCOUNT ON;
            INSERT INTO LopHocPhan (MaHocPhan, MaHocKy, MaLopHPCode, TenLop, SiSoToiDa, TrangThai, LoaiLop)
            VALUES (?, ?, ?, ?, ?, 'DangMoDangKy', 'LyThuyet');
            SELECT SCOPE_IDENTITY();
        """
        return self._execute_insert_get_id(sql, (
            data.get('ma_hoc_phan'), data.get('ma_hoc_ky'), data.get('ma_lop_code'),
            data.get('ten_lop'), data.get('si_so_toi_da')
        ))

    def cap_nhat_lop_hoc_phan(self, ma_lhp: int, data: dict):
        sql = """
            UPDATE LopHocPhan SET MaHocPhan=?, MaHocKy=?, MaLopHPCode=?, TenLop=?, SiSoToiDa=?, TrangThai=?, LoaiLop=?
            WHERE MaLopHP=?
        """
        self._execute_non_query(sql, (
            data.get('ma_hoc_phan'), data.get('ma_hoc_ky'), data.get('ma_lop_hp_code'), 
            data.get('ten_lop_hp'), data.get('si_so_toi_da'),
            data.get('trang_thai'), data.get('loai_lop', 'ChinhQuy'), ma_lhp
        ))
        
        # Update instructor assignment if provided
        if data.get('ma_giang_vien'):
            # Check if exists
            exists = self._execute_query("SELECT 1 FROM GiangVien_LopHocPhan WHERE MaLopHP = ?", (ma_lhp,))
            if exists:
                self._execute_non_query("UPDATE GiangVien_LopHocPhan SET MaHoSoGV = ? WHERE MaLopHP = ?", (data.get('ma_giang_vien'), ma_lhp))
            else:
                self._execute_non_query("INSERT INTO GiangVien_LopHocPhan (MaLopHP, MaHoSoGV) VALUES (?, ?)", (ma_lhp, data.get('ma_giang_vien')))

    def xoa_lop_hoc_phan(self, ma_lhp: int):
        self._execute_non_query("DELETE FROM LopHocPhan WHERE MaLopHP = ?", (ma_lhp,))

    def lay_ds_hoc_phan(self, tu_khoa: str = None) -> list:
        sql = "SELECT * FROM HocPhan WHERE 1=1"
        params = []
        if tu_khoa:
            sql += " AND (TenHocPhan LIKE ? OR MaHocPhanCode LIKE ?)"
            kw = f"%{tu_khoa}%"
            params.extend([kw, kw])
        sql += " ORDER BY TenHocPhan"
        return self._execute_query(sql, tuple(params) if params else None)

    def tao_hoc_phan(self, data: dict) -> int:
        sql = """
            SET NOCOUNT ON;
            INSERT INTO HocPhan (TenHocPhan, MaHocPhanCode, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MoTa)
            VALUES (?, ?, ?, ?, ?, ?);
            SELECT SCOPE_IDENTITY();
        """
        return self._execute_insert_get_id(sql, (
            data.get('ten_hp'), data.get('ma_hp_code'), data.get('so_tc'),
            data.get('tiet_lt'), data.get('tiet_th'), data.get('mo_ta')
        ))

    def cap_nhat_hoc_phan(self, ma_hp: int, data: dict):
        sql = """
            UPDATE HocPhan SET TenHocPhan=?, MaHocPhanCode=?, SoTinChi=?, SoTietLyThuyet=?, SoTietThucHanh=?, MoTa=?
            WHERE MaHocPhan=?
        """
        self._execute_non_query(sql, (
            data.get('ten_hp'), data.get('ma_hp_code'), data.get('so_tc'),
            data.get('tiet_lt'), data.get('tiet_th'), data.get('mo_ta'), ma_hp
        ))

    def xoa_hoc_phan(self, ma_hp: int):
        self._execute_non_query("DELETE FROM HocPhan WHERE MaHocPhan = ?", (ma_hp,))




repo = HocVuRepository()


def _normalize(rows: list) -> list:
    """Chuyển datetime/date thành string"""
    result = []
    for r in rows:
        item = dict(r)
        for k, v in item.items():
            if hasattr(v, 'isoformat'):
                item[k] = v.isoformat()
        result.append(item)
    return result


@hoc_vu_bp.route('/hoc-ky', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_hoc_ky():
    data = repo.lay_ds_hoc_ky(g.ma_truong)
    return APIResponse.thanh_cong(_normalize(data))


@hoc_vu_bp.route('/lop-hoc-phan', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_lop_hoc_phan():
    trang = int(request.args.get('trang', 1))
    so_bn = min(int(request.args.get('so_ban_ghi', 20)), 100)
    ma_hoc_ky = request.args.get('ma_hoc_ky', type=int)
    ma_hoc_phan = request.args.get('ma_hoc_phan', type=int)
    tu_khoa = request.args.get('tu_khoa', '')
    
    # Giảng viên chỉ xem lớp của mình
    ma_gv = None
    if g.loai_tai_khoan == 'GiangVien':
        from repositories.base_repository import BaseRepository
        base = BaseRepository()
        rows = base._execute_query(
            "SELECT MaHoSoGV FROM HoSoGiangVien WHERE MaTaiKhoanGV = ?",
            (g.ma_tai_khoan,))
        if rows:
            ma_gv = rows[0]['MaHoSoGV']
    
    ds, tong = repo.lay_ds_lop_hoc_phan(ma_hoc_ky, ma_hoc_phan, ma_gv, tu_khoa, trang, so_bn)
    return APIResponse.phan_trang(_normalize(ds), tong, trang, so_bn)


@hoc_vu_bp.route('/lop-hoc-phan/<int:ma_lop_hp>/nguoi-hoc', methods=['GET'])
@yeu_cau_dang_nhap
def nguoi_hoc_trong_lop(ma_lop_hp: int):
    data = repo.lay_nguoi_hoc_trong_lop(ma_lop_hp)
    return APIResponse.thanh_cong(_normalize(data))


@hoc_vu_bp.route('/cua-toi', methods=['GET'])
@yeu_cau_dang_nhap
def lop_cua_toi():
    """Lấy danh sách lớp học phần của người dùng hiện tại"""
    ma_hoc_ky = request.args.get('ma_hoc_ky', type=int)
    
    if g.loai_tai_khoan == 'NguoiHoc':
        from repositories.base_repository import BaseRepository
        base = BaseRepository()
        rows = base._execute_query(
            "SELECT MaHoSoNH FROM HoSoNguoiHoc WHERE MaTKNguoiHoc = ?",
            (g.ma_tai_khoan,))
        if not rows:
            return APIResponse.khong_tim_thay("Không tìm thấy hồ sơ người học")
        ma_hs = rows[0]['MaHoSoNH']
        data = repo.lay_lop_hoc_phan_cua_nguoi_hoc(ma_hs, ma_hoc_ky)
        
    elif g.loai_tai_khoan == 'GiangVien':
        from repositories.base_repository import BaseRepository
        base = BaseRepository()
        rows = base._execute_query(
            "SELECT MaHoSoGV FROM HoSoGiangVien WHERE MaTaiKhoanGV = ?",
            (g.ma_tai_khoan,))
        if not rows:
            return APIResponse.khong_tim_thay("Không tìm thấy hồ sơ giảng viên")
        ma_gv = rows[0]['MaHoSoGV']
        data = repo.lay_lop_hoc_phan_cua_giang_vien(ma_gv, ma_hoc_ky)
    else:
        ds, tong = repo.lay_ds_lop_hoc_phan(ma_hoc_ky, trang=1, so_ban_ghi=50)
        return APIResponse.thanh_cong(_normalize(ds))
    
    
    return APIResponse.thanh_cong(_normalize(data))

from middleware.auth_middleware import yeu_cau_nhan_vien

@hoc_vu_bp.route('/hoc-ky', methods=['POST'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def tao_hoc_ky():
    data = request.get_json()
    id = repo.tao_hoc_ky(data)
    return APIResponse.thanh_cong({"ma_hoc_ky": id}, "Tạo học kỳ thành công")

@hoc_vu_bp.route('/hoc-ky/<int:id>', methods=['GET', 'PUT', 'DELETE'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def detail_update_xoa_hk(id: int):
    if request.method == 'GET':
        data = repo._execute_query("SELECT * FROM HocKy WHERE MaHocKy = ?", (id,))
        if not data: return APIResponse.khong_tim_thay()
        return APIResponse.thanh_cong(dict(data[0]))
    if request.method == 'DELETE':
        repo.xoa_hoc_ky(id)
        return APIResponse.thanh_cong(message="Xóa thành công")
    data = request.get_json()
    repo.cap_nhat_hoc_ky(id, data)
    return APIResponse.thanh_cong(message="Cập nhật thành công")

@hoc_vu_bp.route('/lop-hoc-phan', methods=['POST'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def tao_lop_hoc_phan():
    data = request.get_json()
    id = repo.tao_lop_hoc_phan(data)
    return APIResponse.thanh_cong({"ma_lop": id}, "Tạo lớp thành công")

@hoc_vu_bp.route('/lop-hoc-phan/<int:id>', methods=['GET', 'PUT', 'DELETE'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def detail_update_xoa_lhp(id: int):
    if request.method == 'GET':
        data = repo._execute_query("SELECT * FROM LopHocPhan WHERE MaLopHP = ?", (id,))
        if not data: return APIResponse.khong_tim_thay()
        return APIResponse.thanh_cong(dict(data[0]))
    if request.method == 'DELETE':
        repo.xoa_lop_hoc_phan(id)
        return APIResponse.thanh_cong(message="Xóa thành công")
    data = request.get_json()
    repo.cap_nhat_lop_hoc_phan(id, data)
    return APIResponse.thanh_cong(message="Cập nhật thành công")

@hoc_vu_bp.route('/hoc-phan', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_hoc_phan():
    tu_khoa = request.args.get('tu_khoa', '')
    data = repo.lay_ds_hoc_phan(tu_khoa)
    return APIResponse.thanh_cong(_normalize(data))

@hoc_vu_bp.route('/hoc-phan', methods=['POST'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def tao_hoc_phan():
    data = request.get_json()
    id = repo.tao_hoc_phan(data)
    return APIResponse.thanh_cong({"ma_hoc_phan": id}, "Tạo học phần thành công")

@hoc_vu_bp.route('/hoc-phan/<int:id>', methods=['GET', 'PUT', 'DELETE'])
@yeu_cau_dang_nhap
@yeu_cau_nhan_vien
def detail_update_xoa_hp(id: int):
    if request.method == 'GET':
        data = repo._execute_query("SELECT * FROM HocPhan WHERE MaHocPhan = ?", (id,))
        if not data: return APIResponse.khong_tim_thay()
        return APIResponse.thanh_cong(dict(data[0]))
    if request.method == 'DELETE':
        repo.xoa_hoc_phan(id)
        return APIResponse.thanh_cong(message="Xóa thành công")
    data = request.get_json()
    repo.cap_nhat_hoc_phan(id, data)
    return APIResponse.thanh_cong(message="Cập nhật thành công")


