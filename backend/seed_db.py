import os
import sys

# Thêm thư mục backend vào sys.path để import
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from utils.password import PasswordHelper
from repositories.base_repository import BaseRepository

repo = BaseRepository()

def seed():
    print("Bắt đầu tạo dữ liệu demo...")
    
    # 1. Khởi tạo Trường
    try:
        repo._execute_non_query("INSERT INTO Truong (TenTruong, MaTruongCode, ConHieuLuc) VALUES (N'Đại học Công Nghệ', 'UOT', 1)")
    except Exception: pass
        
    truong = repo._execute_query("SELECT MaTruong FROM Truong WHERE MaTruongCode = 'UOT'")
    if not truong:
        print("Lỗi: Không tìm thấy Trường UOT")
        return
    ma_truong = truong[0]['MaTruong']

    # 1.2 Khởi tạo Khoa -> Bộ môn -> Ngành (Cần thiết cho schema mới)
    try:
        repo._execute_non_query("INSERT INTO Khoa (MaTruong, TenKhoa, MaKhoaCode) VALUES (?, N'Khoa CNTT', 'CNTT')", (ma_truong,))
    except Exception: pass
    ma_khoa = repo._execute_scalar("SELECT MaKhoa FROM Khoa WHERE MaKhoaCode = 'CNTT' AND MaTruong = ?", (ma_truong,))

    try:
        repo._execute_non_query("INSERT INTO BoMon (MaKhoa, TenBoMon, MaBoMonCode) VALUES (?, N'Công nghệ phần mềm', 'CNPM')", (ma_khoa,))
    except Exception: pass
    ma_bo_mon = repo._execute_scalar("SELECT MaBoMon FROM BoMon WHERE MaBoMonCode = 'CNPM' AND MaKhoa = ?", (ma_khoa,))

    try:
        repo._execute_non_query("INSERT INTO Nganh (MaBoMon, TenNganh, MaNganhCode) VALUES (?, N'Kỹ thuật phần mềm', 'KTPM')", (ma_bo_mon,))
    except Exception: pass
    ma_nganh = repo._execute_scalar("SELECT MaNganh FROM Nganh WHERE MaNganhCode = 'KTPM' AND MaBoMon = ?", (ma_bo_mon,))

    # Lấy MaCapHoc 'DaiHoc'
    ma_cap_hoc = repo._execute_scalar("SELECT MaCapHoc FROM CapHoc WHERE TenCapHoc = 'DaiHoc'") or 1

    # 2. Khởi tạo Tài Khoản
    mat_khau_hash, salt = PasswordHelper.hash_password('123456')
    
    # --- ADMIN / NHÂN VIÊN ---
    exists_nv = repo._execute_query("SELECT MaTaiKhoanNV FROM TaiKhoanNhanVien WHERE TenDangNhap = 'admin'")
    if not exists_nv:
        print("Tạo tài khoản Admin...")
        ma_nv = repo._execute_insert_get_id("""
            SET NOCOUNT ON;
            INSERT INTO TaiKhoanNhanVien (MaTruong, TenDangNhap, MatKhauHash, Salt, Email, TrangThai) 
            VALUES (?, 'admin', ?, ?, 'admin@uot.edu.vn', 'HoatDong');
            SELECT SCOPE_IDENTITY();
        """, (ma_truong, mat_khau_hash, salt))
        
        repo._execute_insert_get_id("""
            SET NOCOUNT ON;
            INSERT INTO HoSoNhanVien (MaTaiKhoanNV, MaNhanVien, HoTen, LoaiNhanVien) 
            VALUES (?, 'NV001', N'Nguyễn Văn Quản Trị', 'PhongDaoTao');
            SELECT SCOPE_IDENTITY();
        """, (ma_nv,))
        
        # Thêm quyền SuperAdmin
        repo._execute_non_query("""
            INSERT INTO VaiTroNhanVien (MaTaiKhoanNV, MaVaiTro, ConHieuLuc, NguoiGan, NgayGan)
            SELECT ?, MaVaiTro, 1, 'System', GETDATE() FROM VaiTro WHERE MaVaiTroCode = 'SuperAdmin'
        """, (ma_nv,))
    else:
        print("Cập nhật mật khẩu Admin...")
        repo._execute_non_query("UPDATE TaiKhoanNhanVien SET MatKhauHash = ?, Salt = ? WHERE TenDangNhap = 'admin'", (mat_khau_hash, salt))

    # --- GIẢNG VIÊN ---
    exists_gv = repo._execute_query("SELECT MaTaiKhoanGV FROM TaiKhoanGiangVien WHERE TenDangNhap = 'giangvien'")
    if not exists_gv:
        print("Tạo tài khoản Giảng viên...")
        ma_gv_tk = repo._execute_insert_get_id("""
            SET NOCOUNT ON;
            INSERT INTO TaiKhoanGiangVien (MaTruong, TenDangNhap, MatKhauHash, Salt, Email, TrangThai) 
            VALUES (?, 'giangvien', ?, ?, 'gv@uot.edu.vn', 'HoatDong');
            SELECT SCOPE_IDENTITY();
        """, (ma_truong, mat_khau_hash, salt))
        
        repo._execute_insert_get_id("""
            SET NOCOUNT ON;
            INSERT INTO HoSoGiangVien (MaTaiKhoanGV, MaGiangVien, HoTen, HocVi, ChucVu, MaBoMon) 
            VALUES (?, 'GV001', N'Trần Thị Giảng Viên', N'Thạc sĩ', N'Giảng viên chính', ?);
            SELECT SCOPE_IDENTITY();
        """, (ma_gv_tk, ma_bo_mon))
    else:
        print("Cập nhật mật khẩu Giảng viên...")
        repo._execute_non_query("UPDATE TaiKhoanGiangVien SET MatKhauHash = ?, Salt = ? WHERE TenDangNhap = 'giangvien'", (mat_khau_hash, salt))

    # --- NGƯỜI HỌC ---
    exists_nh = repo._execute_query("SELECT MaTKNguoiHoc FROM TaiKhoanNguoiHoc WHERE TenDangNhap = 'nguoihoc'")
    if not exists_nh:
        print("Tạo tài khoản Người học...")
        ma_nh_tk = repo._execute_insert_get_id("""
            SET NOCOUNT ON;
            INSERT INTO TaiKhoanNguoiHoc (MaTruong, TenDangNhap, MatKhauHash, Salt, Email, TrangThai) 
            VALUES (?, 'nguoihoc', ?, ?, 'nh@uot.edu.vn', 'HoatDong');
            SELECT SCOPE_IDENTITY();
        """, (ma_truong, mat_khau_hash, salt))
        
        ma_hs_nh = repo._execute_insert_get_id("""
            SET NOCOUNT ON;
            INSERT INTO HoSoNguoiHoc (MaTKNguoiHoc, MaKyHieu, HoTen) 
            VALUES (?, 'NH20240001', N'Lê Văn Người Học');
            SELECT SCOPE_IDENTITY();
        """, (ma_nh_tk,))
        
        # Tạo HoSoCapHoc (SV cần cái này để xác định ngành/năm học)
        repo._execute_non_query("""
            INSERT INTO HoSoCapHoc (MaHoSoNH, MaCapHoc, MaTruong, MaKyHieuCapHoc, MaNganh, NienKhoa, TrangThaiHocTap)
            VALUES (?, ?, ?, 'SV20240001', ?, 'K2023', 'DangHoc')
        """, (ma_hs_nh, ma_cap_hoc, ma_truong, ma_nganh))
    else:
        print("Cập nhật mật khẩu Người học...")
        repo._execute_non_query("UPDATE TaiKhoanNguoiHoc SET MatKhauHash = ?, Salt = ? WHERE TenDangNhap = 'nguoihoc'", (mat_khau_hash, salt))


    print("\n" + "="*50)
    print("HOÀN TẤT TẠO DỮ LIỆU DEMO!")
    print("="*50)
    print("Tất cả mật khẩu đều là: 123456")
    print("1. Admin / Nhân viên đào tạo:")
    print("   User: admin")
    print("2. Giảng viên:")
    print("   User: giangvien")
    print("3. Người học:")
    print("   User: nguoihoc")
    print("="*50)

if __name__ == '__main__':
    seed()
