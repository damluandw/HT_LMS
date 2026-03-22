"""
AuthRepository - Truy vấn dữ liệu xác thực người dùng
Hỗ trợ 3 loại: SinhVien / GiangVien / NhanVien
"""
import logging
from datetime import datetime
from repositories.base_repository import BaseRepository
from models.nguoi_dung import (
    TaiKhoanNguoiHoc, HoSoNguoiHoc,
    TaiKhoanGiangVien, HoSoGiangVien,
    TaiKhoanNhanVien, HoSoNhanVien,
    VaiTro
)

logger = logging.getLogger(__name__)


class AuthRepository(BaseRepository):
    """Repository xử lý xác thực cho toàn bộ hệ thống"""
    
    # ── NGƯỜI HỌC ─────────────────────────────────────────────────────────────
    
    def lay_tai_khoan_nh_theo_ten_dang_nhap(self, ten_dang_nhap: str) -> TaiKhoanNguoiHoc | None:
        """Lấy tài khoản người học theo tên đăng nhập hoặc email"""
        sql = """
            SELECT MaTKNguoiHoc, MaTruong, TenDangNhap, MatKhauHash, Salt,
                   Email, DaXacThucEmail, SoDienThoai, TrangThai,
                   SoLanDangNhapSai, KhoaDen, LanDangNhapCuoi, NgayTao, NgayCapNhat
            FROM TaiKhoanNguoiHoc
            WHERE (TenDangNhap = ? OR Email = ?)
        """
        rows = self._execute_query(sql, (ten_dang_nhap, ten_dang_nhap))
        if not rows:
            return None
        r = rows[0]
        return TaiKhoanNguoiHoc(
            MaTKNguoiHoc=r['MaTKNguoiHoc'],
            MaTruong=r['MaTruong'],
            TenDangNhap=r['TenDangNhap'],
            MatKhauHash=r['MatKhauHash'],
            Salt=r['Salt'],
            Email=r['Email'],
            DaXacThucEmail=bool(r['DaXacThucEmail']),
            SoDienThoai=r['SoDienThoai'] or '',
            TrangThai=r['TrangThai'],
            SoLanDangNhapSai=r['SoLanDangNhapSai'],
            KhoaDen=r['KhoaDen'],
            LanDangNhapCuoi=r['LanDangNhapCuoi'],
            NgayTao=r['NgayTao'],
        )

    def lay_tai_khoan_nh_theo_id(self, ma_tai_khoan: int) -> TaiKhoanNguoiHoc | None:
        """Lấy tài khoản người học theo ID"""
        sql = """
            SELECT MaTKNguoiHoc, MaTruong, TenDangNhap, MatKhauHash, Salt,
                   Email, DaXacThucEmail, SoDienThoai, TrangThai,
                   SoLanDangNhapSai, KhoaDen, LanDangNhapCuoi, NgayTao
            FROM TaiKhoanNguoiHoc
            WHERE MaTKNguoiHoc = ?
        """
        rows = self._execute_query(sql, (ma_tai_khoan,))
        if not rows:
            return None
        r = rows[0]
        return TaiKhoanNguoiHoc(
            MaTKNguoiHoc=r['MaTKNguoiHoc'],
            MaTruong=r['MaTruong'],
            TenDangNhap=r['TenDangNhap'],
            MatKhauHash=r['MatKhauHash'],
            Salt=r['Salt'],
            Email=r['Email'],
            DaXacThucEmail=bool(r['DaXacThucEmail']),
            SoDienThoai=r['SoDienThoai'] or '',
            TrangThai=r['TrangThai'],
            SoLanDangNhapSai=r['SoLanDangNhapSai'],
            KhoaDen=r['KhoaDen'],
            LanDangNhapCuoi=r['LanDangNhapCuoi'],
            NgayTao=r['NgayTao'],
        )
    
    def lay_ho_so_nh_theo_tai_khoan(self, ma_tai_khoan: int) -> HoSoNguoiHoc | None:
        """Lấy hồ sơ người học kèm thông tin khoa/ngành"""
        sql = """
            SELECT hs.MaHoSoNH, hs.MaTKNguoiHoc, hs.MaKyHieu, hs.HoTen,
                   hs.Ho, hs.Ten, hs.NgaySinh, hs.GioiTinh, hs.HinhAnh,
                   ch.MaNganh, ch.NienKhoa, ch.TrangThaiHocTap,
                   n.TenNganh, lhc.TenLop, t.TenTruong
            FROM HoSoNguoiHoc hs
            LEFT JOIN HoSoCapHoc ch ON ch.MaHoSoNH = hs.MaHoSoNH AND ch.LaNguoiHocHienTai = 1
            LEFT JOIN Nganh n ON n.MaNganh = ch.MaNganh
            LEFT JOIN LopHanhChinh lhc ON lhc.MaLopHC = (SELECT TOP 1 MaLopHC FROM LopHanhChinh WHERE MaNganh = ch.MaNganh) -- Simplified for now
            LEFT JOIN Truong t ON t.MaTruong = ch.MaTruong
            WHERE hs.MaTKNguoiHoc = ?
        """
        rows = self._execute_query(sql, (ma_tai_khoan,))
        if not rows:
            return None
        r = rows[0]
        return HoSoNguoiHoc(
            MaHoSoNH=r['MaHoSoNH'],
            MaTKNguoiHoc=r['MaTKNguoiHoc'],
            MaKyHieu=r['MaKyHieu'],
            HoTen=r['HoTen'],
            Ho=r['Ho'] or '',
            Ten=r['Ten'] or '',
            NgaySinh=str(r['NgaySinh']) if r['NgaySinh'] else None,
            GioiTinh=r['GioiTinh'] or '',
            HinhAnh=r['HinhAnh'] or '',
            MaNganh=r['MaNganh'],
            MaLopHanhChinh=None, # Update if needed
            NienKhoa=r['NienKhoa'] or '',
            TrangThaiHocTap=r['TrangThaiHocTap'],
            TenNganh=r['TenNganh'] or '',
            TenLop=r['TenLop'] or '',
            TenTruong=r['TenTruong'] or '',
        )
    
    # ── GIẢNG VIÊN ────────────────────────────────────────────────────────────
    
    def lay_tai_khoan_gv_theo_ten_dang_nhap(self, ten_dang_nhap: str) -> TaiKhoanGiangVien | None:
        """Lấy tài khoản giảng viên theo tên đăng nhập hoặc email"""
        sql = """
            SELECT MaTaiKhoanGV, MaTruong, TenDangNhap, MatKhauHash, Salt,
                   Email, DaXacThucEmail, SoDienThoai, TrangThai,
                   SoLanDangNhapSai, KhoaDen, LanDangNhapCuoi, NgayTao
            FROM TaiKhoanGiangVien
            WHERE (TenDangNhap = ? OR Email = ?)
        """
        rows = self._execute_query(sql, (ten_dang_nhap, ten_dang_nhap))
        if not rows:
            return None
        r = rows[0]
        return TaiKhoanGiangVien(
            MaTaiKhoanGV=r['MaTaiKhoanGV'],
            MaTruong=r['MaTruong'],
            TenDangNhap=r['TenDangNhap'],
            MatKhauHash=r['MatKhauHash'],
            Salt=r['Salt'],
            Email=r['Email'],
            DaXacThucEmail=bool(r['DaXacThucEmail']),
            SoDienThoai=r['SoDienThoai'] or '',
            TrangThai=r['TrangThai'],
            SoLanDangNhapSai=r['SoLanDangNhapSai'],
            KhoaDen=r['KhoaDen'],
            LanDangNhapCuoi=r['LanDangNhapCuoi'],
            NgayTao=r['NgayTao'],
        )

    def lay_tai_khoan_gv_theo_id(self, ma_tai_khoan: int) -> TaiKhoanGiangVien | None:
        """Lấy tài khoản giảng viên theo ID"""
        sql = """
            SELECT MaTaiKhoanGV, MaTruong, TenDangNhap, MatKhauHash, Salt,
                   Email, DaXacThucEmail, SoDienThoai, TrangThai,
                   SoLanDangNhapSai, KhoaDen, LanDangNhapCuoi, NgayTao
            FROM TaiKhoanGiangVien
            WHERE MaTaiKhoanGV = ?
        """
        rows = self._execute_query(sql, (ma_tai_khoan,))
        if not rows:
            return None
        r = rows[0]
        return TaiKhoanGiangVien(
            MaTaiKhoanGV=r['MaTaiKhoanGV'],
            MaTruong=r['MaTruong'],
            TenDangNhap=r['TenDangNhap'],
            MatKhauHash=r['MatKhauHash'],
            Salt=r['Salt'],
            Email=r['Email'],
            DaXacThucEmail=bool(r['DaXacThucEmail']),
            SoDienThoai=r['SoDienThoai'] or '',
            TrangThai=r['TrangThai'],
            SoLanDangNhapSai=r['SoLanDangNhapSai'],
            KhoaDen=r['KhoaDen'],
            LanDangNhapCuoi=r['LanDangNhapCuoi'],
            NgayTao=r['NgayTao'],
        )
    
    def lay_ho_so_gv_theo_tai_khoan(self, ma_tai_khoan: int) -> HoSoGiangVien | None:
        """Lấy hồ sơ giảng viên kèm thông tin bộ môn/khoa"""
        sql = """
            SELECT hs.MaHoSoGV, hs.MaTaiKhoanGV, hs.MaGiangVien, hs.HoTen,
                   hs.Ho, hs.Ten, hs.NgaySinh, hs.GioiTinh, hs.HinhAnh,
                   hs.MaBoMon, hs.HocHam, hs.HocVi, hs.ChuyenNganh,
                   hs.ChucVu, hs.LoaiHopDong, hs.TrangThai,
                   bm.TenBoMon, k.TenKhoa
            FROM HoSoGiangVien hs
            LEFT JOIN BoMon bm ON bm.MaBoMon = hs.MaBoMon
            LEFT JOIN Khoa k ON k.MaKhoa = bm.MaKhoa
            WHERE hs.MaTaiKhoanGV = ?
        """
        rows = self._execute_query(sql, (ma_tai_khoan,))
        if not rows:
            return None
        r = rows[0]
        return HoSoGiangVien(
            MaHoSoGV=r['MaHoSoGV'],
            MaTaiKhoanGV=r['MaTaiKhoanGV'],
            MaGiangVien=r['MaGiangVien'],
            HoTen=r['HoTen'],
            Ho=r['Ho'] or '',
            Ten=r['Ten'] or '',
            NgaySinh=str(r['NgaySinh']) if r['NgaySinh'] else None,
            GioiTinh=r['GioiTinh'] or '',
            HinhAnh=r['HinhAnh'] or '',
            MaBoMon=r['MaBoMon'],
            HocHam=r['HocHam'] or '',
            HocVi=r['HocVi'] or '',
            ChuyenNganh=r['ChuyenNganh'] or '',
            ChucVu=r['ChucVu'] or '',
            LoaiHopDong=r['LoaiHopDong'] or '',
            TrangThai=r['TrangThai'],
            TenBoMon=r['TenBoMon'] or '',
            TenKhoa=r['TenKhoa'] or '',
        )
    
    # ── NHÂN VIÊN ─────────────────────────────────────────────────────────────
    
    def lay_tai_khoan_nv_theo_ten_dang_nhap(self, ten_dang_nhap: str) -> TaiKhoanNhanVien | None:
        """Lấy tài khoản nhân viên theo tên đăng nhập hoặc email"""
        sql = """
            SELECT MaTaiKhoanNV, MaTruong, TenDangNhap, MatKhauHash, Salt,
                   Email, DaXacThucEmail, SoDienThoai, TrangThai,
                   SoLanDangNhapSai, KhoaDen, LanDangNhapCuoi, NgayTao
            FROM TaiKhoanNhanVien
            WHERE (TenDangNhap = ? OR Email = ?)
        """
        rows = self._execute_query(sql, (ten_dang_nhap, ten_dang_nhap))
        if not rows:
            return None
        r = rows[0]
        return TaiKhoanNhanVien(
            MaTaiKhoanNV=r['MaTaiKhoanNV'],
            MaTruong=r['MaTruong'],
            TenDangNhap=r['TenDangNhap'],
            MatKhauHash=r['MatKhauHash'],
            Salt=r['Salt'],
            Email=r['Email'],
            DaXacThucEmail=bool(r['DaXacThucEmail']),
            SoDienThoai=r['SoDienThoai'] or '',
            TrangThai=r['TrangThai'],
            SoLanDangNhapSai=r['SoLanDangNhapSai'],
            KhoaDen=r['KhoaDen'],
            LanDangNhapCuoi=r['LanDangNhapCuoi'],
            NgayTao=r['NgayTao'],
        )

    def lay_tai_khoan_nv_theo_id(self, ma_tai_khoan: int) -> TaiKhoanNhanVien | None:
        """Lấy tài khoản nhân viên theo ID"""
        sql = """
            SELECT MaTaiKhoanNV, MaTruong, TenDangNhap, MatKhauHash, Salt,
                   Email, DaXacThucEmail, SoDienThoai, TrangThai,
                   SoLanDangNhapSai, KhoaDen, LanDangNhapCuoi, NgayTao
            FROM TaiKhoanNhanVien
            WHERE MaTaiKhoanNV = ?
        """
        rows = self._execute_query(sql, (ma_tai_khoan,))
        if not rows:
            return None
        r = rows[0]
        return TaiKhoanNhanVien(
            MaTaiKhoanNV=r['MaTaiKhoanNV'],
            MaTruong=r['MaTruong'],
            TenDangNhap=r['TenDangNhap'],
            MatKhauHash=r['MatKhauHash'],
            Salt=r['Salt'],
            Email=r['Email'],
            DaXacThucEmail=bool(r['DaXacThucEmail']),
            SoDienThoai=r['SoDienThoai'] or '',
            TrangThai=r['TrangThai'],
            SoLanDangNhapSai=r['SoLanDangNhapSai'],
            KhoaDen=r['KhoaDen'],
            LanDangNhapCuoi=r['LanDangNhapCuoi'],
            NgayTao=r['NgayTao'],
        )
    
    def lay_ho_so_nv_theo_tai_khoan(self, ma_tai_khoan: int) -> HoSoNhanVien | None:
        """Lấy hồ sơ nhân viên kèm vai trò"""
        sql = """
            SELECT hs.MaHoSoNV, hs.MaTaiKhoanNV, hs.MaNhanVien, hs.HoTen,
                   hs.Ho, hs.Ten, hs.DonViCongTac, hs.ChucVu,
                   hs.LoaiNhanVien, hs.TrangThai, hs.HinhAnh
            FROM HoSoNhanVien hs
            WHERE hs.MaTaiKhoanNV = ?
        """
        rows = self._execute_query(sql, (ma_tai_khoan,))
        if not rows:
            return None
        r = rows[0]
        return HoSoNhanVien(
            MaHoSoNV=r['MaHoSoNV'],
            MaTaiKhoanNV=r['MaTaiKhoanNV'],
            MaNhanVien=r['MaNhanVien'],
            HoTen=r['HoTen'],
            Ho=r['Ho'] or '',
            Ten=r['Ten'] or '',
            DonViCongTac=r['DonViCongTac'] or '',
            ChucVu=r['ChucVu'] or '',
            LoaiNhanVien=r['LoaiNhanVien'],
            TrangThai=r['TrangThai'],
            HinhAnh=r['HinhAnh'] or '',
        )
    
    def lay_vai_tro_nhan_vien(self, ma_tai_khoan: int) -> list[VaiTro]:
        """Lấy danh sách vai trò của nhân viên"""
        sql = """
            SELECT vt.MaVaiTro, vt.TenVaiTro, vt.MaVaiTroCode, vt.MoTa
            FROM VaiTro vt
            INNER JOIN VaiTroNhanVien vtnv ON vtnv.MaVaiTro = vt.MaVaiTro
            WHERE vtnv.MaTaiKhoanNV = ? AND vtnv.ConHieuLuc = 1
            ORDER BY vt.ThuTuHienThi
        """
        rows = self._execute_query(sql, (ma_tai_khoan,))
        return [VaiTro(
            MaVaiTro=r['MaVaiTro'],
            TenVaiTro=r['TenVaiTro'],
            MaVaiTroCode=r['MaVaiTroCode'],
            MoTa=r['MoTa'] or '',
        ) for r in rows]
    
    # ── GHI LOG ĐĂNG NHẬP ─────────────────────────────────────────────────────
    
    def cap_nhat_lan_dang_nhap_cuoi(self, loai: str, ma_tai_khoan: int):
        """Cập nhật thời điểm đăng nhập mới nhất"""
        table_map = {
            'NguoiHoc': ('TaiKhoanNguoiHoc', 'MaTKNguoiHoc'),
            'GiangVien': ('TaiKhoanGiangVien', 'MaTaiKhoanGV'),
            'NhanVien': ('TaiKhoanNhanVien', 'MaTaiKhoanNV'),
        }
        if loai not in table_map:
            return
        table, pk = table_map[loai]
        sql = f"""
            UPDATE {table}
            SET LanDangNhapCuoi = GETDATE(), SoLanDangNhapSai = 0, NgayCapNhat = GETDATE()
            WHERE {pk} = ?
        """
        self._execute_non_query(sql, (ma_tai_khoan,))
    
    def ghi_nhat_ky_he_thong(self, loai_tai_khoan: str, ma_tai_khoan: int,
                               hanh_dong: str, thanh_cong: bool = True,
                               ip: str = None, mo_ta: str = None):
        """Ghi nhật ký hệ thống (Audit Log)"""
        sql = """
            INSERT INTO NhatKyHeThong 
                (LoaiTaiKhoan, MaTaiKhoan, HanhDong, ThanhCong, DiaChiIP, MoTa, ThoiGian)
            VALUES (?, ?, ?, ?, ?, ?, GETDATE())
        """
        try:
            self._execute_non_query(sql, (loai_tai_khoan, ma_tai_khoan, 
                                          hanh_dong, 1 if thanh_cong else 0, ip, mo_ta))
        except Exception as e:
            logger.error(f"Ghi nhật ký thất bại: {e}")
