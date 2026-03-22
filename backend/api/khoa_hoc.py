"""
Khoa Hoc API Blueprint - Quản lý khóa học LMS
GET /api/khoa-hoc/                        - Danh sách khóa học của lớp HP
GET /api/khoa-hoc/<id>                    - Chi tiết khóa học
GET /api/khoa-hoc/<id>/chuong            - Danh sách chương/module
GET /api/khoa-hoc/<id>/hoc-lieu          - Danh sách học liệu
"""
import logging
from flask import Blueprint, request, g
from middleware.auth_middleware import yeu_cau_dang_nhap
from utils.response import APIResponse
from repositories.base_repository import BaseRepository

logger = logging.getLogger(__name__)
khoa_hoc_bp = Blueprint('khoa_hoc', __name__, url_prefix='/api/khoa-hoc')


class KhoaHocRepository(BaseRepository):

    def lay_ds_khoa_hoc(self, ma_truong: int = None, ma_tai_khoan_nh: int = None,
                         ma_tai_khoan_gv: int = None) -> list:
        where_parts, params = ["kh.TrangThai <> 'LuuTru'"], []
        
        if ma_tai_khoan_nh:
            where_parts.append("""
                EXISTS (SELECT 1 FROM DangKyHocPhan dk 
                        INNER JOIN HoSoNguoiHoc hs ON hs.MaHoSoNH = dk.MaHoSoNH
                        WHERE dk.MaLopHP = kh.MaLopHP 
                          AND hs.MaTKNguoiHoc = ? AND dk.TrangThai = 'DaDangKy')""")
            params.append(ma_tai_khoan_nh)
        elif ma_tai_khoan_gv:
            where_parts.append("""
                EXISTS (SELECT 1 FROM GiangVien_LopHocPhan gv
                        INNER JOIN HoSoGiangVien hsgv ON hsgv.MaHoSoGV = gv.MaHoSoGV
                        WHERE gv.MaLopHP = kh.MaLopHP 
                          AND hsgv.MaTaiKhoanGV = ? AND gv.ConHieuLuc = 1)""")
            params.append(ma_tai_khoan_gv)
        
        where = " AND ".join(where_parts)
        sql = f"""
            SELECT kh.MaKhoaHocLMS, kh.TenKhoaHoc, kh.MoTaKhoaHoc, kh.AnhBia,
                   kh.TrangThai, kh.NgayTao,
                   lhp.MaLopHP, lhp.MaLopHPCode, lhp.TenLop,
                   hp.TenHocPhan, hp.SoTinChi,
                   hk.TenHocKy,
                   hsgv.HoTen AS TenGiangVien,
                   (SELECT COUNT(*) FROM ChuongHoc ch WHERE ch.MaKhoaHocLMS = kh.MaKhoaHocLMS) AS SoChuong,
                   (SELECT COUNT(*) FROM HocLieu hl WHERE hl.MaKhoaHocLMS = kh.MaKhoaHocLMS) AS SoHocLieu
            FROM KhoaHocLMS kh
            INNER JOIN LopHocPhan lhp ON lhp.MaLopHP = kh.MaLopHP
            INNER JOIN HocPhan hp ON hp.MaHocPhan = lhp.MaHocPhan
            INNER JOIN HocKy hk ON hk.MaHocKy = lhp.MaHocKy
            INNER JOIN HoSoGiangVien hsgv ON hsgv.MaHoSoGV = kh.NguoiTao
            WHERE {where}
            ORDER BY hk.TenHocKy DESC, hp.TenHocPhan
        """
        return self._execute_query(sql, tuple(params) if params else None)

    def lay_chi_tiet_khoa_hoc(self, ma_khoa_hoc: int) -> dict | None:
        sql = """
            SELECT kh.MaKhoaHocLMS, kh.TenKhoaHoc, kh.MoTaKhoaHoc, kh.AnhBia,
                   kh.TrangThai, kh.NgayTao, kh.NgayCapNhat,
                   lhp.MaLopHP, lhp.MaLopHPCode, lhp.TenLop, lhp.TrangThai AS TrangThaiLop,
                   hp.TenHocPhan, hp.MaHocPhanCode, hp.SoTinChi, hp.SoTietLyThuyet,
                   hk.TenHocKy,
                   hsgv.HoTen AS TenGiangVien, hsgv.HocVi, hsgv.ChucVu
            FROM KhoaHocLMS kh
            INNER JOIN LopHocPhan lhp ON lhp.MaLopHP = kh.MaLopHP
            INNER JOIN HocPhan hp ON hp.MaHocPhan = lhp.MaHocPhan
            INNER JOIN HocKy hk ON hk.MaHocKy = lhp.MaHocKy
            INNER JOIN HoSoGiangVien hsgv ON hsgv.MaHoSoGV = kh.NguoiTao
            WHERE kh.MaKhoaHocLMS = ?
        """
        rows = self._execute_query(sql, (ma_khoa_hoc,))
        return rows[0] if rows else None

    def lay_chuong_hoc(self, ma_khoa_hoc: int) -> list:
        sql = """
            SELECT ch.MaChuong, ch.MaChuongCha, ch.TenChuong, ch.MoTa,
                   ch.ThuTu, ch.SoTuan, ch.HienThi,
                   (SELECT COUNT(*) FROM HocLieu hl WHERE hl.MaChuong = ch.MaChuong) AS SoHocLieu
            FROM ChuongHoc ch
            WHERE ch.MaKhoaHocLMS = ?
            ORDER BY ch.ThuTu, ch.MaChuong
        """
        return self._execute_query(sql, (ma_khoa_hoc,))

    def lay_hoc_lieu(self, ma_khoa_hoc: int, ma_chuong: int = None) -> list:
        where = "WHERE hl.MaKhoaHocLMS = ? AND hl.HienThi = 1"
        params = [ma_khoa_hoc]
        if ma_chuong:
            where += " AND hl.MaChuong = ?"
            params.append(ma_chuong)
        sql = f"""
            SELECT hl.MaHocLieu, hl.MaChuong, hl.TieuDe, hl.LoaiHocLieu,
                   hl.DuongDanFile, hl.ThoiLuongGiay, hl.CoPhuDe,
                   hl.ChoPhepTai, hl.ThuTu, hl.LuotXem, hl.NgayTao,
                   ch.TenChuong,
                   cdr.MaCLOCode, cdr.MoTa AS MoTaCLO
            FROM HocLieu hl
            LEFT JOIN ChuongHoc ch ON ch.MaChuong = hl.MaChuong
            LEFT JOIN ChuanDauRaHocPhan cdr ON cdr.MaCDRHP = hl.MaCDRHP
            {where}
            ORDER BY hl.MaChuong, hl.ThuTu
        """
        return self._execute_query(sql, tuple(params))

    def cap_nhat_luot_xem(self, ma_hoc_lieu: int):
        sql = "UPDATE HocLieu SET LuotXem = LuotXem + 1 WHERE MaHocLieu = ?"
        self._execute_non_query(sql, (ma_hoc_lieu,))


repo = KhoaHocRepository()


def _normalize(rows) -> list:
    if isinstance(rows, dict):
        item = dict(rows)
        for k, v in item.items():
            if hasattr(v, 'isoformat'):
                item[k] = v.isoformat()
        return item
    result = []
    for r in rows:
        item = dict(r)
        for k, v in item.items():
            if hasattr(v, 'isoformat'):
                item[k] = v.isoformat()
        result.append(item)
    return result


@khoa_hoc_bp.route('/', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_khoa_hoc():
    ma_nh = g.ma_tai_khoan if g.loai_tai_khoan == 'NguoiHoc' else None
    ma_gv = g.ma_tai_khoan if g.loai_tai_khoan == 'GiangVien' else None
    data = repo.lay_ds_khoa_hoc(g.ma_truong, ma_nh, ma_gv)
    return APIResponse.thanh_cong(_normalize(data))


@khoa_hoc_bp.route('/<int:ma_khoa_hoc>', methods=['GET'])
@yeu_cau_dang_nhap
def chi_tiet_khoa_hoc(ma_khoa_hoc: int):
    data = repo.lay_chi_tiet_khoa_hoc(ma_khoa_hoc)
    if not data:
        return APIResponse.khong_tim_thay("Không tìm thấy khóa học")
    return APIResponse.thanh_cong(_normalize(data))


@khoa_hoc_bp.route('/<int:ma_khoa_hoc>/chuong', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_chuong(ma_khoa_hoc: int):
    data = repo.lay_chuong_hoc(ma_khoa_hoc)
    return APIResponse.thanh_cong(_normalize(data))


@khoa_hoc_bp.route('/<int:ma_khoa_hoc>/hoc-lieu', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_hoc_lieu(ma_khoa_hoc: int):
    ma_chuong = request.args.get('ma_chuong', type=int)
    data = repo.lay_hoc_lieu(ma_khoa_hoc, ma_chuong)
    return APIResponse.thanh_cong(_normalize(data))


@khoa_hoc_bp.route('/hoc-lieu/<int:ma_hoc_lieu>/xem', methods=['POST'])
@yeu_cau_dang_nhap
def ghi_luot_xem(ma_hoc_lieu: int):
    """Ghi nhận lượt xem học liệu"""
    repo.cap_nhat_luot_xem(ma_hoc_lieu)
    return APIResponse.thanh_cong(message="Đã ghi nhận")
