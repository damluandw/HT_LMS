"""
Bai Tap & Thi API Blueprint
GET  /api/bai-tap/                        - Danh sách bài kiểm tra
GET  /api/bai-tap/<id>                    - Chi tiết bài kiểm tra
GET  /api/bai-tap/<id>/de-bai            - Câu hỏi khi làm bài (SV)
POST /api/bai-tap/<id>/nop               - Nộp bài
GET  /api/bai-tap/ket-qua/<id>           - Xem kết quả bài nộp
"""
import logging
from flask import Blueprint, request, g
from datetime import datetime
from middleware.auth_middleware import yeu_cau_dang_nhap
from utils.response import APIResponse
from repositories.base_repository import BaseRepository

logger = logging.getLogger(__name__)
bai_tap_bp = Blueprint('bai_tap', __name__, url_prefix='/api/bai-tap')


class BaiTapRepository(BaseRepository):

    def lay_ds_bai_kiem_tra(self, ma_lop_hp: int = None, 
                              ma_tai_khoan_nh: int = None) -> list:
        where_parts = ["bkt.TrangThai <> 'BanNhap'"]
        params = []
        
        if ma_lop_hp:
            where_parts.append("bkt.MaLopHP = ?")
            params.append(ma_lop_hp)
        
        if ma_tai_khoan_nh:
            # Chỉ hiện bài tập của lớp NH đã đăng ký
            where_parts.append("""
                EXISTS (SELECT 1 FROM DangKyHocPhan dk
                        INNER JOIN HoSoNguoiHoc hs ON hs.MaHoSoNH = dk.MaHoSoNH
                        WHERE dk.MaLopHP = bkt.MaLopHP 
                          AND hs.MaTKNguoiHoc = ? AND dk.TrangThai = 'DaDangKy')""")
            params.append(ma_tai_khoan_nh)
        
        where = " AND ".join(where_parts)
        sql = f"""
            SELECT bkt.MaBaiKT, bkt.TieuDe, bkt.MoTa, bkt.LoaiBaiKT,
                   bkt.ThoiGianLamBaiPhut, bkt.NgayBatDau, bkt.NgayKetThuc,
                   bkt.TrangThai, bkt.TongDiem, bkt.SoLanLamToiDa,
                   bkt.HienThiDapAn, bkt.TroLaiSauNopPhut,
                   lhp.MaLopHP, lhp.TenLop,
                   hp.TenHocPhan
            FROM BaiKiemTra bkt
            INNER JOIN LopHocPhan lhp ON lhp.MaLopHP = bkt.MaLopHP
            INNER JOIN HocPhan hp ON hp.MaHocPhan = lhp.MaHocPhan
            WHERE {where}
            ORDER BY bkt.NgayBatDau DESC
        """
        return self._execute_query(sql, tuple(params) if params else None)

    def lay_cau_hoi_bai_kiem_tra(self, ma_bai_kt: int, 
                                   ma_tai_khoan_nh: int = None) -> list:
        """Lấy câu hỏi cho NH làm bài (không có đáp án) Bound to check logic if needed"""
        sql = """
            SELECT bkcq.MaBaiKT_CQ, bkcq.ThuTu, bkcq.Diem,
                   ch.MaCauHoi, ch.NoiDungCauHoi, ch.LoaiCauHoi, ch.HinhAnh,
                   ch.DoKho, ch.MoiLanXaoTron,
                   (SELECT ch2.MaDapAn, ch2.NoiDungDapAn, ch2.DapAnHinhAnh
                    FROM DapAn ch2 WHERE ch2.MaCauHoi = ch.MaCauHoi
                    ORDER BY ch2.ThuTu
                    FOR JSON PATH) AS DanhSachDapAn
            FROM BaiKT_CauHoi bkcq
            INNER JOIN CauHoi ch ON ch.MaCauHoi = bkcq.MaCauHoi
            WHERE bkcq.MaBaiKT = ?
            ORDER BY bkcq.ThuTu
        """
        return self._execute_query(sql, (ma_bai_kt,))

    def lay_ket_qua_nop_bai(self, ma_bai_kt: int, 
                              ma_tai_khoan_nh: int) -> dict | None:
        sql = """
            SELECT nb.MaNopBai, nb.LanNop, nb.ThoiGianBatDau, nb.ThoiGianNop,
                   nb.TrangThai, nb.TongDiemDat, nb.TyLeDungPhanTram,
                   nb.DaChinhSua,
                   bkt.TongDiem, bkt.TieuDe
            FROM NopBai nb
            INNER JOIN BaiKiemTra bkt ON bkt.MaBaiKT = nb.MaBaiKT
            INNER JOIN HoSoNguoiHoc hs ON hs.MaHoSoNH = nb.MaHoSoNH
            WHERE nb.MaBaiKT = ? AND hs.MaTKNguoiHoc = ?
            ORDER BY nb.LanNop DESC
        """
        rows = self._execute_query(sql, (ma_bai_kt, ma_tai_khoan_sv))
        return rows[0] if rows else None

    def nop_bai(self, ma_bai_kt: int, ma_ho_so_nh: int, 
                 danh_sach_tra_loi: list, thoi_gian_bat_dau) -> dict:
        """Lưu bài nộp và tính điểm tự động (câu hỏi trắc nghiệm)"""
        # Tính số lần nộp
        lan_nop_sql = """
            SELECT ISNULL(MAX(LanNop), 0) + 1 
            FROM NopBai WHERE MaBaiKT = ? AND MaHoSoNH = ?
        """
        lan_nop = self._execute_scalar(lan_nop_sql, (ma_bai_kt, ma_ho_so_nh))
        
        # Lấy đáp án đúng để tự chấm
        dap_an_sql = """
            SELECT bkcq.MaCauHoi, bkcq.Diem, da.MaDapAn, da.LaDapAnDung
            FROM BaiKT_CauHoi bkcq
            INNER JOIN DapAn da ON da.MaCauHoi = bkcq.MaCauHoi
            WHERE bkcq.MaBaiKT = ? AND da.LaDapAnDung = 1
        """
        dap_an_dung = self._execute_query(dap_an_sql, (ma_bai_kt,))
        
        # Tính điểm
        bai_kt_sql = "SELECT TongDiem FROM BaiKiemTra WHERE MaBaiKT = ?"
        tong_diem = self._execute_scalar(bai_kt_sql, (ma_bai_kt,)) or 0
        
        tong_diem_dat = 0
        map_dap_an = {r['MaCauHoi']: (r['MaDapAn'], r['Diem']) for r in dap_an_dung}
        
        for tra_loi in danh_sach_tra_loi:
            ma_cau_hoi = tra_loi.get('ma_cau_hoi')
            ma_dap_an_chon = tra_loi.get('ma_dap_an')
            if ma_cau_hoi in map_dap_an:
                ma_da_dung, diem_cau = map_dap_an[ma_cau_hoi]
                if str(ma_dap_an_chon) == str(ma_da_dung):
                    tong_diem_dat += diem_cau
        
        ty_le = round((tong_diem_dat / tong_diem * 100), 2) if tong_diem > 0 else 0
        
        # Tạo bản ghi NopBai
        nop_bai_sql = """
            INSERT INTO NopBai 
                (MaBaiKT, MaHoSoNH, LanNop, ThoiGianBatDau, ThoiGianNop,
                 TrangThai, TongDiemDat, TyLeDungPhanTram, TraLoiJSON)
            VALUES (?, ?, ?, ?, GETDATE(), 'DaChinhSua', ?, ?, ?)
            SELECT SCOPE_IDENTITY()
        """
        import json
        tra_loi_json = json.dumps(danh_sach_tra_loi, ensure_ascii=False)
        ma_nop_bai = self._execute_insert_get_id(
            nop_bai_sql,
            (ma_bai_kt, ma_ho_so_nh, lan_nop, thoi_gian_bat_dau,
             tong_diem_dat, ty_le, tra_loi_json)
        )
        
        return {
            "ma_nop_bai": ma_nop_bai,
            "lan_nop": lan_nop,
            "tong_diem_dat": float(tong_diem_dat),
            "tong_diem": float(tong_diem),
            "ty_le_dung": float(ty_le),
        }


repo = BaiTapRepository()


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


@bai_tap_bp.route('/', methods=['GET'])
@yeu_cau_dang_nhap
def danh_sach_bai_kiem_tra():
    ma_lop_hp = request.args.get('ma_lop_hp', type=int)
    ma_nh = g.ma_tai_khoan if g.loai_tai_khoan == 'NguoiHoc' else None
    data = repo.lay_ds_bai_kiem_tra(ma_lop_hp, ma_nh)
    return APIResponse.thanh_cong(_normalize(data))


@bai_tap_bp.route('/<int:ma_bai_kt>/de-bai', methods=['GET'])
@yeu_cau_dang_nhap
def lay_de_bai(ma_bai_kt: int):
    """Lấy câu hỏi để làm bài (không có đáp án đúng cho NH)"""
    data = repo.lay_cau_hoi_bai_kiem_tra(ma_bai_kt)
    return APIResponse.thanh_cong(_normalize(data))


@bai_tap_bp.route('/<int:ma_bai_kt>/nop', methods=['POST'])
@yeu_cau_dang_nhap
def nop_bai(ma_bai_kt: int):
    """Nộp bài kiểm tra"""
    if g.loai_tai_khoan != 'NguoiHoc':
        return APIResponse.khong_co_quyen("Chỉ người học mới có thể nộp bài")
    
    from repositories.base_repository import BaseRepository
    base = BaseRepository()
    rows = base._execute_query(
        "SELECT MaHoSoNH FROM HoSoNguoiHoc WHERE MaTKNguoiHoc = ?",
        (g.ma_tai_khoan,))
    if not rows:
        return APIResponse.khong_tim_thay("Không tìm thấy hồ sơ người học")
    ma_ho_so_nh = rows[0]['MaHoSoNH']
    
    data = request.get_json(silent=True)
    if not data:
        return APIResponse.loi("Dữ liệu không hợp lệ")
    
    danh_sach_tra_loi = data.get('tra_loi', [])
    thoi_gian_bat_dau = data.get('thoi_gian_bat_dau', datetime.now().isoformat())
    
    ket_qua = repo.nop_bai(ma_bai_kt, ma_ho_so_nh, danh_sach_tra_loi, thoi_gian_bat_dau)
    return APIResponse.thanh_cong(ket_qua, "Nộp bài thành công")


@bai_tap_bp.route('/ket-qua/<int:ma_bai_kt>', methods=['GET'])
@yeu_cau_dang_nhap
def xem_ket_qua(ma_bai_kt: int):
    """Xem kết quả bài đã nộp"""
    if g.loai_tai_khoan != 'NguoiHoc':
        return APIResponse.khong_co_quyen()
    data = repo.lay_ket_qua_nop_bai(ma_bai_kt, g.ma_tai_khoan)
    if not data:
        return APIResponse.khong_tim_thay("Chưa có kết quả bài nộp")
    return APIResponse.thanh_cong(_normalize(data))
