"""
Models cho Người dùng: NguoiHoc, GiangVien, NhanVien
Ánh xạ với các bảng: TaiKhoanNguoiHoc, HoSoNguoiHoc,
                      TaiKhoanGiangVien, HoSoGiangVien,
                      TaiKhoanNhanVien, HoSoNhanVien
"""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


# ─── SINH VIÊN ────────────────────────────────────────────────────────────────

@dataclass
class TaiKhoanNguoiHoc:
    """Tài khoản đăng nhập của Người học (Sinh viên, Học sinh)"""
    MaTKNguoiHoc: int = None
    MaTruong: int = None
    TenDangNhap: str = ""
    MatKhauHash: str = ""
    Salt: str = ""
    Email: str = ""
    DaXacThucEmail: bool = False
    SoDienThoai: str = ""
    TrangThai: str = "HoatDong"
    SoLanDangNhapSai: int = 0
    KhoaDen: Optional[datetime] = None
    LanDangNhapCuoi: Optional[datetime] = None
    NgayTao: Optional[datetime] = None
    NgayCapNhat: Optional[datetime] = None
    
    def la_bi_khoa(self) -> bool:
        """Kiểm tra tài khoản có bị khóa không"""
        if self.TrangThai in ('KhoaTam', 'KhoaViPham'):
            return True
        if self.KhoaDen and datetime.now() < self.KhoaDen:
            return True
        return False
    
    def to_dict(self) -> dict:
        return {
            "ma_tai_khoan": self.MaTKNguoiHoc,
            "ma_truong": self.MaTruong,
            "ten_dang_nhap": self.TenDangNhap,
            "email": self.Email,
            "so_dien_thoai": self.SoDienThoai,
            "trang_thai": self.TrangThai,
            "lan_dang_nhap_cuoi": self.LanDangNhapCuoi.isoformat() if self.LanDangNhapCuoi else None,
        }


@dataclass
class HoSoNguoiHoc:
    """Thông tin chi tiết hồ sơ Người học"""
    MaHoSoNH: int = None
    MaTKNguoiHoc: int = None
    MaKyHieu: str = ""
    HoTen: str = ""
    Ho: str = ""
    Ten: str = ""
    NgaySinh: Optional[str] = None
    GioiTinh: str = ""
    HinhAnh: str = ""
    MaNganh: int = None
    MaLopHanhChinh: int = None
    NienKhoa: str = ""
    TrangThaiHocTap: str = "DangHoc"
    NgayCapNhat: Optional[datetime] = None
    
    # Thông tin bổ sung (JOIN từ bảng khác)
    TenNganh: str = ""
    TenLop: str = ""
    TenTruong: str = ""
    
    def to_dict(self) -> dict:
        return {
            "ma_ho_so": self.MaHoSoNH,
            "ma_tai_khoan": self.MaTKNguoiHoc,
            "ma_nguoi_hoc": self.MaKyHieu,
            "ho_ten": self.HoTen,
            "ho": self.Ho,
            "ten": self.Ten,
            "ngay_sinh": self.NgaySinh,
            "gioi_tinh": self.GioiTinh,
            "hinh_anh": self.HinhAnh,
            "ma_nganh": self.MaNganh,
            "nien_khoa": self.NienKhoa,
            "trang_thai_hoc_tap": self.TrangThaiHocTap,
            "ten_nganh": self.TenNganh,
            "ten_lop": self.TenLop,
            "ten_truong": self.TenTruong,
        }


# ─── GIẢNG VIÊN ──────────────────────────────────────────────────────────────

@dataclass
class TaiKhoanGiangVien:
    """Tài khoản đăng nhập của Giảng viên"""
    MaTaiKhoanGV: int = None
    MaTruong: int = None
    TenDangNhap: str = ""
    MatKhauHash: str = ""
    Salt: str = ""
    Email: str = ""
    DaXacThucEmail: bool = False
    SoDienThoai: str = ""
    TrangThai: str = "HoatDong"
    SoLanDangNhapSai: int = 0
    KhoaDen: Optional[datetime] = None
    LanDangNhapCuoi: Optional[datetime] = None
    NgayTao: Optional[datetime] = None
    
    def la_bi_khoa(self) -> bool:
        if self.TrangThai in ('KhoaTam', 'KhoaViPham'):
            return True
        if self.KhoaDen and datetime.now() < self.KhoaDen:
            return True
        return False
    
    def to_dict(self) -> dict:
        return {
            "ma_tai_khoan": self.MaTaiKhoanGV,
            "ma_truong": self.MaTruong,
            "ten_dang_nhap": self.TenDangNhap,
            "email": self.Email,
            "so_dien_thoai": self.SoDienThoai,
            "trang_thai": self.TrangThai,
        }


@dataclass
class HoSoGiangVien:
    """Thông tin chi tiết hồ sơ Giảng viên"""
    MaHoSoGV: int = None
    MaTaiKhoanGV: int = None
    MaGiangVien: str = ""
    HoTen: str = ""
    Ho: str = ""
    Ten: str = ""
    NgaySinh: Optional[str] = None
    GioiTinh: str = ""
    HinhAnh: str = ""
    MaBoMon: int = None
    HocHam: str = ""
    HocVi: str = ""
    ChuyenNganh: str = ""
    ChucVu: str = ""
    LoaiHopDong: str = ""
    TrangThai: str = "DangLamViec"
    NgayCapNhat: Optional[datetime] = None
    
    # Thông tin JOIN
    TenBoMon: str = ""
    TenKhoa: str = ""
    
    def to_dict(self) -> dict:
        return {
            "ma_ho_so": self.MaHoSoGV,
            "ma_tai_khoan": self.MaTaiKhoanGV,
            "ma_giang_vien": self.MaGiangVien,
            "ho_ten": self.HoTen,
            "ho": self.Ho,
            "ten": self.Ten,
            "ngay_sinh": self.NgaySinh,
            "gioi_tinh": self.GioiTinh,
            "hinh_anh": self.HinhAnh,
            "ma_bo_mon": self.MaBoMon,
            "hoc_ham": self.HocHam,
            "hoc_vi": self.HocVi,
            "chuyen_nganh": self.ChuyenNganh,
            "chuc_vu": self.ChucVu,
            "loai_hop_dong": self.LoaiHopDong,
            "trang_thai": self.TrangThai,
            "ten_bo_mon": self.TenBoMon,
            "ten_khoa": self.TenKhoa,
        }


# ─── NHÂN VIÊN ───────────────────────────────────────────────────────────────

@dataclass
class TaiKhoanNhanVien:
    """Tài khoản đăng nhập của Nhân viên (Admin, Phòng đào tạo...)"""
    MaTaiKhoanNV: int = None
    MaTruong: int = None
    TenDangNhap: str = ""
    MatKhauHash: str = ""
    Salt: str = ""
    Email: str = ""
    DaXacThucEmail: bool = False
    SoDienThoai: str = ""
    TrangThai: str = "HoatDong"
    SoLanDangNhapSai: int = 0
    KhoaDen: Optional[datetime] = None
    LanDangNhapCuoi: Optional[datetime] = None
    NgayTao: Optional[datetime] = None
    
    def la_bi_khoa(self) -> bool:
        if self.TrangThai in ('KhoaTam', 'KhoaViPham'):
            return True
        if self.KhoaDen and datetime.now() < self.KhoaDen:
            return True
        return False
    
    def to_dict(self) -> dict:
        return {
            "ma_tai_khoan": self.MaTaiKhoanNV,
            "ma_truong": self.MaTruong,
            "ten_dang_nhap": self.TenDangNhap,
            "email": self.Email,
            "so_dien_thoai": self.SoDienThoai,
            "trang_thai": self.TrangThai,
        }


@dataclass
class HoSoNhanVien:
    """Thông tin chi tiết hồ sơ Nhân viên"""
    MaHoSoNV: int = None
    MaTaiKhoanNV: int = None
    MaNhanVien: str = ""
    HoTen: str = ""
    Ho: str = ""
    Ten: str = ""
    DonViCongTac: str = ""
    ChucVu: str = ""
    LoaiNhanVien: str = ""
    TrangThai: str = "DangLamViec"
    HinhAnh: str = ""
    NgayCapNhat: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            "ma_ho_so": self.MaHoSoNV,
            "ma_tai_khoan": self.MaTaiKhoanNV,
            "ma_nhan_vien": self.MaNhanVien,
            "ho_ten": self.HoTen,
            "don_vi_cong_tac": self.DonViCongTac,
            "chuc_vu": self.ChucVu,
            "loai_nhan_vien": self.LoaiNhanVien,
            "trang_thai": self.TrangThai,
            "hinh_anh": self.HinhAnh,
        }


# ─── VAI TRÒ ─────────────────────────────────────────────────────────────────

@dataclass
class VaiTro:
    """Vai trò (Role) trong hệ thống"""
    MaVaiTro: int = None
    TenVaiTro: str = ""
    MaVaiTroCode: str = ""
    MoTa: str = ""
    LaVaiTroHeThong: bool = False
    ThuTuHienThi: int = 0
    
    def to_dict(self) -> dict:
        return {
            "ma_vai_tro": self.MaVaiTro,
            "ten_vai_tro": self.TenVaiTro,
            "ma_vai_tro_code": self.MaVaiTroCode,
            "mo_ta": self.MoTa,
        }
