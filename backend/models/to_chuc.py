"""
Models cho Tổ chức: Truong, CoSo, Khoa, BoMon, Nganh
"""
from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class Truong:
    """Trường đại học"""
    MaTruong: int = None
    TenTruong: str = ""
    TenVietTat: str = ""
    MaTruongCode: str = ""
    Logo: str = ""
    DiaChi: str = ""
    Website: str = ""
    DienThoai: str = ""
    Email: str = ""
    ConHieuLuc: bool = True
    NgayTao: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            "ma_truong": self.MaTruong,
            "ten_truong": self.TenTruong,
            "ten_viet_tat": self.TenVietTat,
            "ma_truong_code": self.MaTruongCode,
            "logo": self.Logo,
            "dia_chi": self.DiaChi,
            "website": self.Website,
            "dien_thoai": self.DienThoai,
            "email": self.Email,
            "con_hieu_luc": self.ConHieuLuc,
        }


@dataclass
class Khoa:
    """Khoa trong trường"""
    MaKhoa: int = None
    MaTruong: int = None
    MaCoSo: Optional[int] = None
    TenKhoa: str = ""
    MaKhoaCode: str = ""
    MoTa: str = ""
    ConHieuLuc: bool = True
    NgayTao: Optional[datetime] = None
    NgayCapNhat: Optional[datetime] = None
    
    # Thông tin JOIN
    TenTruong: str = ""
    
    def to_dict(self) -> dict:
        return {
            "ma_khoa": self.MaKhoa,
            "ma_truong": self.MaTruong,
            "ten_khoa": self.TenKhoa,
            "ma_khoa_code": self.MaKhoaCode,
            "mo_ta": self.MoTa,
            "con_hieu_luc": self.ConHieuLuc,
            "ten_truong": self.TenTruong,
        }


@dataclass
class BoMon:
    """Bộ môn trong Khoa"""
    MaBoMon: int = None
    MaKhoa: int = None
    TenBoMon: str = ""
    MaBoMonCode: str = ""
    MoTa: str = ""
    ConHieuLuc: bool = True
    NgayTao: Optional[datetime] = None
    NgayCapNhat: Optional[datetime] = None
    
    # Thông tin JOIN
    TenKhoa: str = ""
    TenTruong: str = ""
    
    def to_dict(self) -> dict:
        return {
            "ma_bo_mon": self.MaBoMon,
            "ma_khoa": self.MaKhoa,
            "ten_bo_mon": self.TenBoMon,
            "ma_bo_mon_code": self.MaBoMonCode,
            "mo_ta": self.MoTa,
            "con_hieu_luc": self.ConHieuLuc,
            "ten_khoa": self.TenKhoa,
            "ten_truong": self.TenTruong,
        }


@dataclass
class Nganh:
    """Ngành đào tạo"""
    MaNganh: int = None
    MaBoMon: int = None
    TenNganh: str = ""
    MaNganhCode: str = ""
    TongTinChi: int = 0
    ThoiGianDaoTaoNam: int = 4
    TrinhDo: str = "Đại học"
    MoTa: str = ""
    ConHieuLuc: bool = True
    
    # Thông tin JOIN
    TenBoMon: str = ""
    TenKhoa: str = ""
    
    def to_dict(self) -> dict:
        return {
            "ma_nganh": self.MaNganh,
            "ma_bo_mon": self.MaBoMon,
            "ten_nganh": self.TenNganh,
            "ma_nganh_code": self.MaNganhCode,
            "tong_tin_chi": self.TongTinChi,
            "thoi_gian_dao_tao_nam": self.ThoiGianDaoTaoNam,
            "trinh_do": self.TrinhDo,
            "con_hieu_luc": self.ConHieuLuc,
            "ten_bo_mon": self.TenBoMon,
            "ten_khoa": self.TenKhoa,
        }


@dataclass
class LopHanhChinh:
    """Lớp hành chính"""
    MaLopHC: int = None
    MaNganh: int = None
    MaCoSo: Optional[int] = None
    TenLop: str = ""
    MaLopCode: str = ""
    NienKhoa: str = ""
    SiSoToiDa: int = 50
    TrangThai: str = "HoatDong"
    NamBatDau: Optional[int] = None
    NamDuKienTotNghiep: Optional[int] = None
    NgayTao: Optional[datetime] = None
    
    # Thông tin JOIN
    TenNganh: str = ""
    TenKhoa: str = ""
    
    def to_dict(self) -> dict:
        return {
            "ma_lop_hc": self.MaLopHC,
            "ma_nganh": self.MaNganh,
            "ten_lop": self.TenLop,
            "ma_lop_code": self.MaLopCode,
            "nien_khoa": self.NienKhoa,
            "si_so_toi_da": self.SiSoToiDa,
            "trang_thai": self.TrangThai,
            "ten_nganh": self.TenNganh,
            "ten_khoa": self.TenKhoa,
        }
