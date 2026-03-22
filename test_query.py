import sys, os
sys.path.insert(0, os.path.join(os.getcwd(), 'backend'))
from repositories.base_repository import BaseRepository
repo = BaseRepository()

sql = "SELECT COUNT(*) FROM TaiKhoanSinhVien tk INNER JOIN HoSoSinhVien hs ON hs.MaTaiKhoanSV = tk.MaTaiKhoanSV WHERE tk.MaTruong = ?"
print("Count:", repo._execute_scalar(sql, (1,)))

sql2 = """           
SELECT tk.MaTaiKhoanSV, tk.Email, tk.TrangThai, tk.NgayTao,
       hs.MaHoSoSV, hs.MaSinhVien, hs.HoTen, hs.GioiTinh, 
       hs.HinhAnh, hs.NienKhoa, hs.TrangThaiHocTap,
       n.TenNganh, lhc.TenLop, k.TenKhoa
FROM TaiKhoanSinhVien tk
INNER JOIN HoSoSinhVien hs ON hs.MaTaiKhoanSV = tk.MaTaiKhoanSV
LEFT JOIN Nganh n ON n.MaNganh = hs.MaNganh
LEFT JOIN LopHanhChinh lhc ON lhc.MaLopHC = hs.MaLopHanhChinh
LEFT JOIN BoMon bm ON bm.MaBoMon = n.MaBoMon
LEFT JOIN Khoa k ON k.MaKhoa = bm.MaKhoa
WHERE 1=1 AND tk.MaTruong = ?
ORDER BY hs.MaSinhVien
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
"""
print("Rows:", repo._execute_query(sql2, (1,)))
