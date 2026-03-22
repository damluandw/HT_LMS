"""
Models cho Học vụ: HocKy, LopHocPhan, DangKyHocPhan
"""
from dataclasses import dataclass
from datetime import datetime, date
from typing import Optional


@dataclass
class HocKy:
    """Học kỳ"""
    MaHocKy: int = None
    MaNamHoc: int = None
    TenHocKy: str = ""
    ThuTu: int = 1
    NgayBatDau: Optional[date] = None
    NgayKetThuc: Optional[date] = None
    NgayMoDangKy: Optional[date] = None
    NgayDongDangKy: Optional[date] = None
    LaHocKyHienTai: bool = False
    TrangThai: str = "LapKe"
    
    # JOIN
    TenNamHoc: str = ""
    
    def to_dict(self) -> dict:
        return {
            "ma_hoc_ky": self.MaHocKy,
            "ma_nam_hoc": self.MaNamHoc,
            "ten_hoc_ky": self.TenHocKy,
            "thu_tu": self.ThuTu,
            "ngay_bat_dau": self.NgayBatDau.isoformat() if self.NgayBatDau else None,
            "ngay_ket_thuc": self.NgayKetThuc.isoformat() if self.NgayKetThuc else None,
            "la_hoc_ky_hien_tai": self.LaHocKyHienTai,
            "trang_thai": self.TrangThai,
            "ten_nam_hoc": self.TenNamHoc,
        }


@dataclass
class LopHocPhan:
    """Lớp học phần (course section)"""
    MaLopHP: int = None
    MaHocPhan: int = None
    MaHocKy: int = None
    MaDeCuong: Optional[int] = None
    MaCoSo: Optional[int] = None
    MaLopHPCode: str = ""
    TenLop: str = ""
    SiSoToiThieu: int = 5
    SiSoToiDa: int = 50
    LoaiLop: str = "ChinhQuy"
    TrangThai: str = "MoDangKy"
    MoDangKy: bool = True
    DaDuaRaDiem: bool = False
    NgayTao: Optional[datetime] = None
    NgayCapNhat: Optional[datetime] = None
    
    # JOIN
    TenHocPhan: str = ""
    MaHocPhanCode: str = ""
    SoTinChi: int = 0
    TenHocKy: str = ""
    SiSoHienTai: int = 0
    
    def to_dict(self) -> dict:
        return {
            "ma_lop_hp": self.MaLopHP,
            "ma_hoc_phan": self.MaHocPhan,
            "ma_hoc_ky": self.MaHocKy,
            "ma_lop_hp_code": self.MaLopHPCode,
            "ten_lop": self.TenLop,
            "si_so_toi_da": self.SiSoToiDa,
            "si_so_hien_tai": self.SiSoHienTai,
            "loai_lop": self.LoaiLop,
            "trang_thai": self.TrangThai,
            "mo_dang_ky": self.MoDangKy,
            "da_dua_ra_diem": self.DaDuaRaDiem,
            "ten_hoc_phan": self.TenHocPhan,
            "ma_hoc_phan_code": self.MaHocPhanCode,
            "so_tin_chi": self.SoTinChi,
            "ten_hoc_ky": self.TenHocKy,
        }


@dataclass
class DangKyHocPhan:
    """Đăng ký học phần của sinh viên"""
    MaDangKy: int = None
    MaHoSoSV: int = None
    MaLopHP: int = None
    LoaiDangKy: str = "BinhThuong"
    TrangThai: str = "DaDangKy"
    NgayDangKy: Optional[datetime] = None
    NgayRut: Optional[datetime] = None
    LyDoRut: str = ""
    
    # JOIN
    HoTenSV: str = ""
    MaSinhVien: str = ""
    TenLopHP: str = ""
    TenHocPhan: str = ""
    
    def to_dict(self) -> dict:
        return {
            "ma_dang_ky": self.MaDangKy,
            "ma_ho_so_sv": self.MaHoSoSV,
            "ma_lop_hp": self.MaLopHP,
            "loai_dang_ky": self.LoaiDangKy,
            "trang_thai": self.TrangThai,
            "ngay_dang_ky": self.NgayDangKy.isoformat() if self.NgayDangKy else None,
            "ho_ten_sv": self.HoTenSV,
            "ma_sinh_vien": self.MaSinhVien,
            "ten_hoc_phan": self.TenHocPhan,
        }
