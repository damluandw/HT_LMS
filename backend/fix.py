import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from repositories.base_repository import BaseRepository

try:
    repo = BaseRepository()
    
    # Kiem tra Truong
    r = repo._execute_query("SELECT MaTruong FROM Truong WHERE MaTruongCode = 'UOT'")
    if not r:
        repo._execute_non_query("INSERT INTO Truong (TenTruong, MaTruongCode, ConHieuLuc) VALUES ('UoT', 'UOT', 1)")
        r = repo._execute_query("SELECT MaTruong FROM Truong")

    print("- Truong:", r[0]['MaTruong'] if r else "None")

    # Kiem tra NV
    nv = repo._execute_query("SELECT MaTaiKhoanNV, TenDangNhap FROM TaiKhoanNhanVien")
    print("- NV:", nv)

    # Them VaiTro nếu chưa có
    vt = repo._execute_query("SELECT MaVaiTro FROM VaiTro WHERE MaVaiTroCode='SuperAdmin'")
    if not vt:
        repo._execute_non_query("INSERT INTO VaiTro (MaVaiTroCode, TenVaiTro, MoTa, LaVaiTroHeThong) VALUES ('SuperAdmin', N'Quản trị', 'Full', 1)")
        vt = repo._execute_query("SELECT MaVaiTro FROM VaiTro WHERE MaVaiTroCode='SuperAdmin'")
    
    print("- Role SuperAdmin ID:", vt[0]['MaVaiTro'] if vt else "None")

    # Gắn Role
    if nv:
        ma_nv = nv[0]['MaTaiKhoanNV']
        ma_vt = vt[0]['MaVaiTro']
        has_role = repo._execute_query("SELECT 1 FROM VaiTroNhanVien WHERE MaTaiKhoanNV=? AND MaVaiTro=?", (ma_nv, ma_vt))
        if not has_role:
            repo._execute_non_query("INSERT INTO VaiTroNhanVien (MaTaiKhoanNV, MaVaiTro, ConHieuLuc, NgayGan) VALUES (?, ?, 1, GETDATE())", (ma_nv, ma_vt))
            print("- Da gan role SuperAdmin cho admin!")
        else:
            print("- Admin da co role roi.")

    gv = repo._execute_query("SELECT TenDangNhap FROM TaiKhoanGiangVien")
    sv = repo._execute_query("SELECT TenDangNhap FROM TaiKhoanSinhVien")
    print("- GV:", gv)
    print("- SV:", sv)

except Exception as e:
    print("LOI:", e)
