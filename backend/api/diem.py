"""
Diem API Blueprint - Quản lý điểm số
GET /api/diem/cua-toi                     - Điểm của sinh viên đang đăng nhập
GET /api/diem/lop/<ma_lop_hp>            - Bảng điểm lớp (GV/Admin)
GET /api/diem/tong-hop/<ma_ho_so_sv>     - Bảng điểm tổng hợp toàn khóa
"""
import logging
from flask import Blueprint, request, g
from middleware.auth_middleware import yeu_cau_dang_nhap
from utils.response import APIResponse
from repositories.base_repository import BaseRepository

logger = logging.getLogger(__name__)
diem_bp = Blueprint('diem', __name__, url_prefix='/api/diem')


class DiemRepository(BaseRepository):

    def lay_diem_cua_nguoi_hoc(self, ma_tai_khoan_nh: int, 
                                 ma_hoc_ky: int = None) -> list:
        """Lấy điểm tất cả môn của một người học"""
        where = "WHERE hs.MaTKNguoiHoc = ?"
        params = [ma_tai_khoan_nh]
        if ma_hoc_ky:
            where += " AND lhp.MaHocKy = ?"
            params.append(ma_hoc_ky)
        sql = f"""
            SELECT sdc.MaChiTietDiem, sdc.MaDauDiem, sdc.Diem, sdc.DaKhoaDiem,
                   dd.TenDauDiem, dd.TrongSo, dd.LoaiDauDiem,
                   lhp.MaLopHP, lhp.MaLopHPCode,
                   hp.TenHocPhan, hp.MaHocPhanCode, hp.SoTinChi,
                   hk.TenHocKy,
                   sdb.DiemTongKetHP, sdb.DiemChu, sdb.DiemHe4,
                   sdb.TrangThai AS TrangThaiDiem
            FROM SoDiemChiTiet sdc
            INNER JOIN DauDiemDanhGia dd ON dd.MaDauDiem = sdc.MaDauDiem
            INNER JOIN SoDiemBangTong sdb ON sdb.MaSoDB = sdc.MaSoDB
            INNER JOIN SoDiem sd ON sd.MaSoDiem = sdb.MaSoDiem
            INNER JOIN LopHocPhan lhp ON lhp.MaLopHP = sd.MaLopHP
            INNER JOIN HocPhan hp ON hp.MaHocPhan = lhp.MaHocPhan
            INNER JOIN HocKy hk ON hk.MaHocKy = lhp.MaHocKy
            INNER JOIN HoSoNguoiHoc hs ON hs.MaHoSoNH = sdb.MaHoSoNH
            {where}
            ORDER BY hk.TenHocKy DESC, hp.TenHocPhan, dd.TrongSo DESC
        """
        return self._execute_query(sql, tuple(params))

    def lay_bang_diem_lop(self, ma_lop_hp: int) -> list:
        """Bảng điểm toàn lớp (dành cho GV và Admin)"""
        sql = """
            SELECT hs.MaHoSoNH, hs.MaKyHieu, hs.HoTen, hs.GioiTinh,
                   sdb.DiemTongKetHP, sdb.DiemChu, sdb.DiemHe4,
                   sdb.TrangThai AS TrangThaiDiem, sdb.DaKhoaDiem,
                   lhc.TenLop,
                   (SELECT dd2.TenDauDiem + ':' + CAST(ISNULL(sdc2.Diem, -1) AS NVARCHAR)
                    FROM DauDiemDanhGia dd2
                    LEFT JOIN SoDiemChiTiet sdc2 ON sdc2.MaDauDiem = dd2.MaDauDiem 
                         AND sdc2.MaSoDB = sdb.MaSoDB
                    WHERE dd2.MaSoDiem = sd.MaSoDiem
                    ORDER BY dd2.TrongSo DESC
                    FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)') AS TomTatDiem
            FROM SoDiem sd
            INNER JOIN SoDiemBangTong sdb ON sdb.MaSoDiem = sd.MaSoDiem
            INNER JOIN HoSoNguoiHoc hs ON hs.MaHoSoNH = sdb.MaHoSoNH
            LEFT JOIN HoSoCapHoc ch ON ch.MaHoSoNH = hs.MaHoSoNH AND ch.LaNguoiHocHienTai = 1
            LEFT JOIN LopHanhChinh lhc ON lhc.MaLopHC = (SELECT TOP 1 MaLopHC FROM LopHanhChinh WHERE MaNganh = ch.MaNganh)
            WHERE sd.MaLopHP = ?
            ORDER BY hs.HoTen
        """
        return self._execute_query(sql, (ma_lop_hp,))

    def lay_bang_diem_tong_hop(self, ma_ho_so_nh: int) -> dict:
        """Bảng điểm toàn khóa học (GPA, tín chỉ tích lũy)"""
        sql = """
            SELECT 
                COUNT(DISTINCT lhp.MaHocPhan) AS SoMonDaHoc,
                SUM(CASE WHEN sdb.DiemHe4 >= 1.0 THEN hp.SoTinChi ELSE 0 END) AS TinChiTichLuy,
                SUM(hp.SoTinChi) AS TongTinChiDangKy,
                CAST(
                    SUM(sdb.DiemHe4 * hp.SoTinChi) * 1.0 / 
                    NULLIF(SUM(CASE WHEN sdb.DiemHe4 IS NOT NULL THEN hp.SoTinChi ELSE 0 END), 0) 
                AS DECIMAL(4,2)) AS GPA,
                COUNT(CASE WHEN sdb.DiemHe4 < 1.0 THEN 1 END) AS SoMonTruot,
                COUNT(CASE WHEN sdb.DiemChu = 'A' OR sdb.DiemChu = 'A+' THEN 1 END) AS SoMonGioiXuat
            FROM SoDiemBangTong sdb
            INNER JOIN SoDiem sd ON sd.MaSoDiem = sdb.MaSoDiem
            INNER JOIN LopHocPhan lhp ON lhp.MaLopHP = sd.MaLopHP
            INNER JOIN HocPhan hp ON hp.MaHocPhan = lhp.MaHocPhan
            WHERE sdb.MaHoSoNH = ? AND sdb.DaKhoaDiem = 1
        """
        rows = self._execute_query(sql, (ma_ho_so_nh,))
        return rows[0] if rows else {}


repo = DiemRepository()


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


@diem_bp.route('/cua-toi', methods=['GET'])
@yeu_cau_dang_nhap
def diem_cua_toi():
    """Điểm của người học đang đăng nhập"""
    if g.loai_tai_khoan != 'NguoiHoc':
        return APIResponse.khong_co_quyen("Chỉ dành cho người học")
    ma_hoc_ky = request.args.get('ma_hoc_ky', type=int)
    data = repo.lay_diem_cua_nguoi_hoc(g.ma_tai_khoan, ma_hoc_ky)
    return APIResponse.thanh_cong(_normalize(data))


@diem_bp.route('/lop/<int:ma_lop_hp>', methods=['GET'])
@yeu_cau_dang_nhap
def bang_diem_lop(ma_lop_hp: int):
    """Bảng điểm lớp (GV/Admin)"""
    if g.loai_tai_khoan == 'NguoiHoc':
        return APIResponse.khong_co_quyen()
    data = repo.lay_bang_diem_lop(ma_lop_hp)
    return APIResponse.thanh_cong(_normalize(data))


@diem_bp.route('/tong-hop', methods=['GET'])
@yeu_cau_dang_nhap
def bang_diem_tong_hop():
    """Bảng điểm tổng hợp và GPA"""
    if g.loai_tai_khoan != 'NguoiHoc':
        return APIResponse.khong_co_quyen("Chỉ dành cho người học")
    from repositories.base_repository import BaseRepository
    base = BaseRepository()
    rows = base._execute_query(
        "SELECT MaHoSoNH FROM HoSoNguoiHoc WHERE MaTKNguoiHoc = ?",
        (g.ma_tai_khoan,))
    if not rows:
        return APIResponse.khong_tim_thay()
    ma_ho_so_nh = rows[0]['MaHoSoNH']
    data = repo.lay_bang_diem_tong_hop(ma_ho_so_nh)
    return APIResponse.thanh_cong(_normalize(data))
