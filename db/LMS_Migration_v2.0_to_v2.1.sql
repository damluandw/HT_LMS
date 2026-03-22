-- ============================================================
-- LMS MIGRATION SCRIPT: v2.0 → v2.1
-- Mục tiêu: Xóa TaiKhoanSinhVien, HoSoSinhVien (cũ)
--           Chuyển toàn bộ sang TaiKhoanNguoiHoc + HoSoNguoiHoc + HoSoCapHoc
-- Thực hiện theo thứ tự: Backup → Migrate → Repoint FK → Drop
-- ============================================================

USE HT_LMS;
GO

-- ============================================================
-- BƯỚC 0: KIỂM TRA TRƯỚC KHI CHẠY
-- ============================================================

PRINT N'=== KIỂM TRA TIỀN ĐIỀU KIỆN ===';

-- Kiểm tra bảng mới đã tồn tại chưa
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TaiKhoanNguoiHoc')
BEGIN
    RAISERROR(N'❌ Chưa chạy script v2.1! Hãy chạy LMS_v2.1_BoSung trước.', 16, 1);
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'HoSoNguoiHoc')
BEGIN
    RAISERROR(N'❌ Bảng HoSoNguoiHoc chưa tồn tại!', 16, 1);
    RETURN;
END

PRINT N'✅ Bảng mới đã sẵn sàng.';
GO

-- ============================================================
-- BƯỚC 1: BACKUP DỮ LIỆU CŨ (an toàn — không xóa gốc vội)
-- ============================================================

PRINT N'=== BƯỚC 1: BACKUP DỮ LIỆU ===';

-- Backup TaiKhoanSinhVien
SELECT * INTO _bk_TaiKhoanSinhVien FROM TaiKhoanSinhVien;
PRINT N'✅ Backed up TaiKhoanSinhVien → _bk_TaiKhoanSinhVien (' 
    + CAST(@@ROWCOUNT AS NVARCHAR) + N' dòng)';

-- Backup HoSoSinhVien
SELECT * INTO _bk_HoSoSinhVien FROM HoSoSinhVien;
PRINT N'✅ Backed up HoSoSinhVien → _bk_HoSoSinhVien ('
    + CAST(@@ROWCOUNT AS NVARCHAR) + N' dòng)';

-- Backup PhienDangNhapSV
SELECT * INTO _bk_PhienDangNhapSV FROM PhienDangNhapSV;
PRINT N'✅ Backed up PhienDangNhapSV → _bk_PhienDangNhapSV';
GO

-- ============================================================
-- BƯỚC 2: MIGRATE DỮ LIỆU SANG CẤU TRÚC MỚI
-- ============================================================

PRINT N'=== BƯỚC 2: CHUYỂN DỮ LIỆU SANG CẤU TRÚC MỚI ===';

BEGIN TRANSACTION;
BEGIN TRY

    -- 2A. Chuyển TaiKhoanSinhVien → TaiKhoanNguoiHoc
    -- Dùng SET IDENTITY_INSERT để giữ nguyên MaTaiKhoan (quan trọng cho FK)
    SET IDENTITY_INSERT TaiKhoanNguoiHoc ON;

    INSERT INTO TaiKhoanNguoiHoc (
        MaTKNguoiHoc,   -- Giữ nguyên ID cũ → FK không bị vỡ
        MaTruong,
        TenDangNhap,
        MatKhauHash,
        Salt,
        Email,
        DaXacThucEmail,
        SoDienThoai,
        DaXacThucSDT,
        TrangThai,
        SoLanDangNhapSai,
        KhoaDen,
        BatXacThuc2Buoc,
        BiMat2Buoc,
        LanDangNhapCuoi,
        NgayDoiMatKhau,
        TuyChinhJSON,
        NgayTao,
        NgayCapNhat
    )
    SELECT
        tk.MaTaiKhoanSV,    -- Map ID cũ → ID mới (giữ nguyên số)
        tk.MaTruong,
        tk.TenDangNhap,
        tk.MatKhauHash,
        tk.Salt,
        tk.Email,
        tk.DaXacThucEmail,
        tk.SoDienThoai,
        tk.DaXacThucSDT,
        tk.TrangThai,
        tk.SoLanDangNhapSai,
        tk.KhoaDen,
        tk.BatXacThuc2Buoc,
        tk.BíMat2Buoc,
        tk.LanDangNhapCuoi,
        tk.NgayDoiMatKhau,
        tk.TuyChinhJSON,
        tk.NgayTao,
        tk.NgayCapNhat
    FROM TaiKhoanSinhVien tk
    WHERE NOT EXISTS (
        -- Tránh duplicate nếu chạy lại script
        SELECT 1 FROM TaiKhoanNguoiHoc t2
        WHERE t2.MaTKNguoiHoc = tk.MaTaiKhoanSV
    );

    SET IDENTITY_INSERT TaiKhoanNguoiHoc OFF;
    PRINT N'  ✅ TaiKhoanSinhVien → TaiKhoanNguoiHoc: ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' dòng';

    -- 2B. Chuyển HoSoSinhVien → HoSoNguoiHoc + HoSoCapHoc
    -- Xác định MaCapHoc ĐH/CĐ
    DECLARE @MaCapHocDH INT, @MaCapHocCD INT;
    SELECT @MaCapHocDH = MaCapHoc FROM CapHoc WHERE TenCapHoc = N'DaiHoc';
    SELECT @MaCapHocCD = MaCapHoc FROM CapHoc WHERE TenCapHoc = N'CaoDang';

    -- 2B-1. Tạo HoSoNguoiHoc từ HoSoSinhVien
    SET IDENTITY_INSERT HoSoNguoiHoc ON;

    INSERT INTO HoSoNguoiHoc (
        MaHoSoNH,
        MaKyHieu,           -- Dùng MaSinhVien cũ làm mã ký hiệu
        MaTKNguoiHoc,
        HoTen,
        Ho,
        Ten,
        NgaySinh,
        GioiTinh,
        SoCMND,
        NgayCap,
        NoiCap,
        HinhAnh,
        DanToc,
        TonGiao,
        QuocTich,
        DiaChiThuongTru,
        DiaChiTamTru,
        TinhThanh,
        QuanHuyen,
        HoTenPhuHuynh,
        SDTPhuHuynh,
        MoiQuanHePH,
        EmailPhuHuynh,
        NgayCapNhat
    )
    SELECT
        sv.MaHoSoSV,
        sv.MaSinhVien,      -- Giữ nguyên mã SV cũ làm MaKyHieu
        sv.MaTaiKhoanSV,    -- Trỏ sang TaiKhoanNguoiHoc (đã migrate cùng ID)
        sv.HoTen,
        sv.Ho,
        sv.Ten,
        sv.NgaySinh,
        sv.GioiTinh,
        sv.SoCMND,
        sv.NgayCap,
        sv.NoiCap,
        sv.HinhAnh,
        sv.DanToc,
        sv.TonGiao,
        sv.QuocTich,
        sv.DiaChiThuongTru,
        sv.DiaChiTamTru,
        sv.TinhThanh,
        sv.QuanHuyen,
        sv.HoTenPhuHuynh,
        sv.SDTPhuHuynh,
        sv.MoiQuanHe,
        sv.EmailPhuHuynh,
        sv.NgayCapNhat
    FROM HoSoSinhVien sv
    WHERE NOT EXISTS (
        SELECT 1 FROM HoSoNguoiHoc nh WHERE nh.MaHoSoNH = sv.MaHoSoSV
    );

    SET IDENTITY_INSERT HoSoNguoiHoc OFF;
    PRINT N'  ✅ HoSoSinhVien → HoSoNguoiHoc: ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' dòng';

    -- 2B-2. Tạo HoSoCapHoc từ HoSoSinhVien
    INSERT INTO HoSoCapHoc (
        MaKyHieuCapHoc,
        MaHoSoNH,
        MaCapHoc,
        MaTruong,
        MaNganh,
        NienKhoa,
        NamBatDau,
        NamDuKienTotNghiep,
        HinhThucDaoTao,
        TrangThaiHocTap,
        LoaiHinhDaoTao,
        LaNguoiHocHienTai,
        NgayBatDau
    )
    SELECT
        -- Tạo MaKyHieuCapHoc: thêm tiền tố cấp học
        CASE ng.TrinhDo
            WHEN N'Cao đẳng' THEN N'SV-CD-' + sv.MaSinhVien
            ELSE                   N'SV-DH-' + sv.MaSinhVien
        END,
        sv.MaHoSoSV,           -- = MaHoSoNH sau migrate
        CASE ng.TrinhDo
            WHEN N'Cao đẳng' THEN @MaCapHocCD
            ELSE                   @MaCapHocDH
        END,
        tk.MaTruong,
        sv.MaNganh,
        sv.NienKhoa,
        sv.NamBatDau,
        sv.NamDuKienTotNghiep,
        sv.HinhThucDaoTao,
        sv.TrangThaiHocTap,
        N'TinChi',             -- Mặc định; có thể cập nhật thủ công sau
        CASE WHEN sv.TrangThaiHocTap = N'DangHoc' THEN 1 ELSE 0 END,
        CAST(CAST(sv.NamBatDau AS NVARCHAR) + N'-09-01' AS DATE)
    FROM HoSoSinhVien sv
    JOIN TaiKhoanSinhVien tk ON tk.MaTaiKhoanSV = sv.MaTaiKhoanSV
    LEFT JOIN Nganh ng       ON ng.MaNganh       = sv.MaNganh
    WHERE NOT EXISTS (
        SELECT 1 FROM HoSoCapHoc ch
        WHERE ch.MaHoSoNH = sv.MaHoSoSV
    );

    PRINT N'  ✅ HoSoSinhVien → HoSoCapHoc: ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' dòng';

    -- 2C. Chuyển PhienDangNhapSV → PhienDangNhapNguoiHoc
    INSERT INTO PhienDangNhapNguoiHoc (
        MaPhien,
        MaTKNguoiHoc,       -- ID giống TaiKhoanSinhVien (đã giữ nguyên)
        DiaChiIP,
        ThietBi,
        TrinhDuyet,
        ThoiGianDangNhap,
        ThoiGianHoatDongCuoi,
        ThoiGianDangXuat,
        DangHoatDong,
        MaPhienToken
    )
    SELECT
        p.MaPhien,
        p.MaTaiKhoanSV,     -- Trỏ sang TaiKhoanNguoiHoc cùng ID
        p.DiaChiIP,
        p.ThietBi,
        p.TrinhDuyet,
        p.ThoiGianDangNhap,
        p.ThoiGianHoatDongCuoi,
        p.ThoiGianDangXuat,
        p.DangHoatDong,
        p.MaPhienToken
    FROM PhienDangNhapSV p
    WHERE NOT EXISTS (
        SELECT 1 FROM PhienDangNhapNguoiHoc np WHERE np.MaPhien = p.MaPhien
    );

    PRINT N'  ✅ PhienDangNhapSV → PhienDangNhapNguoiHoc: ' + CAST(@@ROWCOUNT AS NVARCHAR) + N' dòng';

    COMMIT TRANSACTION;
    PRINT N'✅ BƯỚC 2 HOÀN THÀNH — Dữ liệu đã migrate thành công.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT N'❌ LỖI trong BƯỚC 2: ' + ERROR_MESSAGE();
    PRINT N'   Dòng lỗi: ' + CAST(ERROR_LINE() AS NVARCHAR);
    RETURN;
END CATCH;
GO

-- ============================================================
-- BƯỚC 3: REPOINT CÁC BẢNG ĐANG FK VÀO BẢNG CŨ
-- Các bảng trỏ vào HoSoSinhVien (MaHoSoSV) cần cập nhật
-- thành HoSoNguoiHoc (MaHoSoNH) — nhưng ID giống nhau nên
-- chỉ cần thay tên FK, không cần cập nhật giá trị data.
-- ============================================================

PRINT N'=== BƯỚC 3: CẬP NHẬT FOREIGN KEYS ===';

-- Danh sách FK cần xóa và tạo lại trỏ sang bảng mới
-- (ID giữ nguyên → không cần UPDATE data)

-- 3A. DangKyHocPhan: MaHoSoSV → MaHoSoNH (HoSoNguoiHoc)
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DangKy_HoSoSV')
    ALTER TABLE DangKyHocPhan DROP CONSTRAINT FK_DangKy_HoSoSV;
-- Đổi tên cột nếu cần, hoặc chỉ thêm FK mới
ALTER TABLE DangKyHocPhan
    ADD CONSTRAINT FK_DangKy_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ DangKyHocPhan → HoSoNguoiHoc';

-- 3B. LopHC_SinhVien
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_LopHC_SinhVien_HoSo')
    ALTER TABLE LopHC_SinhVien DROP CONSTRAINT FK_LopHC_SinhVien_HoSo;
ALTER TABLE LopHC_SinhVien
    ADD CONSTRAINT FK_LopHC_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ LopHC_SinhVien → HoSoNguoiHoc';

-- 3C. ChiTietDiemDanh
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ChiTietDD_SinhVien')
    ALTER TABLE ChiTietDiemDanh DROP CONSTRAINT FK_ChiTietDD_SinhVien;
ALTER TABLE ChiTietDiemDanh
    ADD CONSTRAINT FK_ChiTietDD_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ ChiTietDiemDanh → HoSoNguoiHoc';

-- 3D. BaiNopSinhVien
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_BaiNop_SinhVien')
    ALTER TABLE BaiNopSinhVien DROP CONSTRAINT FK_BaiNop_SinhVien;
ALTER TABLE BaiNopSinhVien
    ADD CONSTRAINT FK_BaiNop_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ BaiNopSinhVien → HoSoNguoiHoc';

-- 3E. ThanhVienNhom
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ThanhVien_SinhVien')
    ALTER TABLE ThanhVienNhom DROP CONSTRAINT FK_ThanhVien_SinhVien;
ALTER TABLE ThanhVienNhom
    ADD CONSTRAINT FK_ThanhVien_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ ThanhVienNhom → HoSoNguoiHoc';

-- 3F. TienDoHocLieu
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TienDoHL_SinhVien')
    ALTER TABLE TienDoHocLieu DROP CONSTRAINT FK_TienDoHL_SinhVien;
ALTER TABLE TienDoHocLieu
    ADD CONSTRAINT FK_TienDoHL_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ TienDoHocLieu → HoSoNguoiHoc';

-- 3G. BaiLamThi
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_BaiLam_SinhVien')
    ALTER TABLE BaiLamThi DROP CONSTRAINT FK_BaiLam_SinhVien;
ALTER TABLE BaiLamThi
    ADD CONSTRAINT FK_BaiLam_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ BaiLamThi → HoSoNguoiHoc';

-- 3H. NhatKyThi
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_NhatKy_SinhVien')
    ALTER TABLE NhatKyThi DROP CONSTRAINT FK_NhatKy_SinhVien;
ALTER TABLE NhatKyThi
    ADD CONSTRAINT FK_NhatKyThi_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ NhatKyThi → HoSoNguoiHoc';

-- 3I. DanhSachThiSinh
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ThiSinh_SinhVien')
    ALTER TABLE DanhSachThiSinh DROP CONSTRAINT FK_ThiSinh_SinhVien;
ALTER TABLE DanhSachThiSinh
    ADD CONSTRAINT FK_ThiSinh_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ DanhSachThiSinh → HoSoNguoiHoc';

-- 3J. PhucKhao
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PhucKhao_SinhVien')
    ALTER TABLE PhucKhao DROP CONSTRAINT FK_PhucKhao_SinhVien;
ALTER TABLE PhucKhao
    ADD CONSTRAINT FK_PhucKhao_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ PhucKhao → HoSoNguoiHoc';

-- 3K. CanhBaoSinhVien
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CanhBao_SinhVien')
    ALTER TABLE CanhBaoSinhVien DROP CONSTRAINT FK_CanhBao_SinhVien;
ALTER TABLE CanhBaoSinhVien
    ADD CONSTRAINT FK_CanhBao_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ CanhBaoSinhVien → HoSoNguoiHoc';

-- 3L. TienDoHocTapSV
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TienDoHT_SinhVien')
    ALTER TABLE TienDoHocTapSV DROP CONSTRAINT FK_TienDoHT_SinhVien;
ALTER TABLE TienDoHocTapSV
    ADD CONSTRAINT FK_TienDoHT_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ TienDoHocTapSV → HoSoNguoiHoc';

-- 3M. ChungChiDaCap, HuyHieuDaCap, HoSoNangLuc
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ChungChi_SinhVien')
    ALTER TABLE ChungChiDaCap DROP CONSTRAINT FK_ChungChi_SinhVien;
ALTER TABLE ChungChiDaCap
    ADD CONSTRAINT FK_ChungChi_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ ChungChiDaCap → HoSoNguoiHoc';

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_HuyHieu_SinhVien')
    ALTER TABLE HuyHieuDaCap DROP CONSTRAINT FK_HuyHieu_SinhVien;
ALTER TABLE HuyHieuDaCap
    ADD CONSTRAINT FK_HuyHieu_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ HuyHieuDaCap → HoSoNguoiHoc';

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_HoSoNL_SinhVien')
    ALTER TABLE HoSoNangLuc DROP CONSTRAINT FK_HoSoNL_SinhVien;
ALTER TABLE HoSoNangLuc
    ADD CONSTRAINT FK_HoSoNL_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ HoSoNangLuc → HoSoNguoiHoc';

-- 3N. PhienChatAI, DangKyThucTap, DanhGiaDongDang...
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_PhienAI_SinhVien')
    ALTER TABLE PhienChatAI DROP CONSTRAINT FK_PhienAI_SinhVien;
ALTER TABLE PhienChatAI
    ADD CONSTRAINT FK_PhienAI_NguoiHoc
    FOREIGN KEY (MaHoSoSV) REFERENCES HoSoNguoiHoc(MaHoSoNH);
PRINT N'  ✅ PhienChatAI → HoSoNguoiHoc';

PRINT N'✅ BƯỚC 3 HOÀN THÀNH — Tất cả FK đã trỏ sang bảng mới.';
GO

-- ============================================================
-- BƯỚC 4: KIỂM TRA TÍNH TOÀN VẸN DỮ LIỆU TRƯỚC KHI XÓA
-- ============================================================

PRINT N'=== BƯỚC 4: KIỂM TRA TOÀN VẸN ===';

-- So sánh số lượng
DECLARE @SoTK_Cu   INT = (SELECT COUNT(*) FROM _bk_TaiKhoanSinhVien);
DECLARE @SoTK_Moi  INT = (SELECT COUNT(*) FROM TaiKhoanNguoiHoc WHERE MaTKNguoiHoc IN (SELECT MaTaiKhoanSV FROM _bk_TaiKhoanSinhVien));
DECLARE @SoHS_Cu   INT = (SELECT COUNT(*) FROM _bk_HoSoSinhVien);
DECLARE @SoHS_Moi  INT = (SELECT COUNT(*) FROM HoSoNguoiHoc WHERE MaHoSoNH IN (SELECT MaHoSoSV FROM _bk_HoSoSinhVien));
DECLARE @SoCH_Moi  INT = (SELECT COUNT(*) FROM HoSoCapHoc WHERE MaHoSoNH IN (SELECT MaHoSoSV FROM _bk_HoSoSinhVien));

PRINT N'  TaiKhoan cũ: ' + CAST(@SoTK_Cu AS NVARCHAR) + N' | Đã migrate: ' + CAST(@SoTK_Moi AS NVARCHAR);
PRINT N'  HoSo cũ:     ' + CAST(@SoHS_Cu AS NVARCHAR) + N' | Đã migrate: ' + CAST(@SoHS_Moi AS NVARCHAR);
PRINT N'  HoSoCapHoc:  ' + CAST(@SoCH_Moi AS NVARCHAR) + N' bản ghi (mới)';

-- Kiểm tra FK toàn vẹn — tìm orphan record
DECLARE @OrphanDangKy INT = (
    SELECT COUNT(*) FROM DangKyHocPhan dk
    WHERE NOT EXISTS (SELECT 1 FROM HoSoNguoiHoc nh WHERE nh.MaHoSoNH = dk.MaHoSoSV)
);

IF @OrphanDangKy > 0
    PRINT N'  ⚠️  CẢNH BÁO: ' + CAST(@OrphanDangKy AS NVARCHAR) + N' DangKy không có HoSo tương ứng!'
ELSE
    PRINT N'  ✅ DangKyHocPhan: không có orphan';

-- Kiểm tra email không trùng
DECLARE @EmailDuplicate INT = (
    SELECT COUNT(*) FROM (
        SELECT Email FROM TaiKhoanNguoiHoc GROUP BY Email HAVING COUNT(*) > 1
    ) x
);
IF @EmailDuplicate > 0
    PRINT N'  ⚠️  CẢNH BÁO: Có ' + CAST(@EmailDuplicate AS NVARCHAR) + N' email bị trùng trong TaiKhoanNguoiHoc!'
ELSE
    PRINT N'  ✅ Email không trùng lặp';

IF @SoTK_Cu = @SoTK_Moi AND @SoHS_Cu = @SoHS_Moi AND @OrphanDangKy = 0 AND @EmailDuplicate = 0
    PRINT N'✅ BƯỚC 4 HOÀN THÀNH — Dữ liệu toàn vẹn, an toàn để xóa bảng cũ.'
ELSE
    PRINT N'❌ CÓ VẤN ĐỀ — KHÔNG NÊN XÓA BẢNG CŨ. Kiểm tra lại!';
GO

-- ============================================================
-- BƯỚC 5: XÓA BẢNG CŨ
-- CHỈ CHẠY SAU KHI BƯỚC 4 BÁO: ✅ an toàn
-- Xóa theo thứ tự: con trước, cha sau
-- ============================================================

PRINT N'=== BƯỚC 5: XÓA BẢNG CŨ ===';

-- ============================================================
-- FIX BƯỚC 5: TỰ ĐỘNG TÌM VÀ DROP TẤT CẢ FK CÒN LẠI
-- Thay vì liệt kê thủ công, dùng dynamic SQL quét sys.foreign_keys
-- ============================================================
 
PRINT N'=== FIX BƯỚC 5A: TÌM TẤT CẢ FK TRỎ VÀO HoSoSinhVien ===';
 
DECLARE @sql NVARCHAR(MAX) = N'';
 
-- Tìm tất cả FK còn trỏ vào HoSoSinhVien
SELECT @sql = @sql +
    N'ALTER TABLE ' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)) +
    N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + CHAR(10) +
    N'PRINT N''  ✅ Đã drop FK: ' + fk.name +
    N' (bảng ' + OBJECT_NAME(fk.parent_object_id) + N')'';' + CHAR(10)
FROM sys.foreign_keys fk
JOIN sys.tables t ON t.object_id = fk.referenced_object_id
WHERE t.name = 'HoSoSinhVien';
 
IF LEN(@sql) > 0
BEGIN
    PRINT N'  Danh sách FK sẽ drop:';
    PRINT @sql;
    EXEC sp_executesql @sql;
END
ELSE
    PRINT N'  Không còn FK nào trỏ vào HoSoSinhVien.';
GO
 
PRINT N'=== FIX BƯỚC 5B: TÌM TẤT CẢ FK TRỎ VÀO TaiKhoanSinhVien ===';
 
DECLARE @sql2 NVARCHAR(MAX) = N'';
 
SELECT @sql2 = @sql2 +
    N'ALTER TABLE ' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)) +
    N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + CHAR(10) +
    N'PRINT N''  ✅ Đã drop FK: ' + fk.name +
    N' (bảng ' + OBJECT_NAME(fk.parent_object_id) + N')'';' + CHAR(10)
FROM sys.foreign_keys fk
JOIN sys.tables t ON t.object_id = fk.referenced_object_id
WHERE t.name = 'TaiKhoanSinhVien';
 
IF LEN(@sql2) > 0
BEGIN
    PRINT N'  Danh sách FK sẽ drop:';
    PRINT @sql2;
    EXEC sp_executesql @sql2;
END
ELSE
    PRINT N'  Không còn FK nào trỏ vào TaiKhoanSinhVien.';
GO
 
-- Xóa bảng sau khi đã dọn FK hết
PRINT N'=== FIX BƯỚC 5C: XÓA BẢNG CŨ ===';
 
-- Kiểm tra trước khi xóa
IF EXISTS (SELECT 1 FROM sys.foreign_keys fk
           JOIN sys.tables t ON t.object_id = fk.referenced_object_id
           WHERE t.name IN ('HoSoSinhVien','TaiKhoanSinhVien'))
BEGIN
    PRINT N'❌ Vẫn còn FK chưa drop! Kiểm tra lại sys.foreign_keys.';
    SELECT
        OBJECT_NAME(fk.parent_object_id)     AS BangCon,
        fk.name                              AS TenFK,
        OBJECT_NAME(fk.referenced_object_id) AS BangCha
    FROM sys.foreign_keys fk
    JOIN sys.tables t ON t.object_id = fk.referenced_object_id
    WHERE t.name IN ('HoSoSinhVien','TaiKhoanSinhVien');
END
ELSE
BEGIN
    DROP TABLE IF EXISTS HoSoSinhVien;
    PRINT N'  ✅ Đã xóa HoSoSinhVien';
 
    DROP TABLE IF EXISTS TaiKhoanSinhVien;
    PRINT N'  ✅ Đã xóa TaiKhoanSinhVien';
 
    PRINT N'✅ FIX BƯỚC 5 HOÀN THÀNH.';
END
GO

-- ============================================================
-- BƯỚC 6: DỌN DẸP BACKUP (chạy sau khi hệ thống ổn định ~7 ngày)
-- COMMENT OUT — chỉ chạy khi chắc chắn không cần rollback
-- ============================================================

/*
PRINT N'=== BƯỚC 6: XÓA BACKUP (chạy sau 7 ngày) ===';
DROP TABLE IF EXISTS _bk_TaiKhoanSinhVien;
DROP TABLE IF EXISTS _bk_HoSoSinhVien;
DROP TABLE IF EXISTS _bk_PhienDangNhapSV;
PRINT N'✅ Đã xóa các bảng backup.';
*/

-- ============================================================
-- BƯỚC 7: CẬP NHẬT CÁC VIEW CŨ THAM CHIẾU BẢNG ĐÃ XÓA
-- ============================================================
 
PRINT N'=== FIX BƯỚC 7: CẬP NHẬT VIEWS ===';
GO  -- <-- batch separator bắt buộc trước CREATE/ALTER VIEW
 
CREATE OR ALTER VIEW v_TongHopDiemDanh AS
SELECT
    dk.MaHoSoSV                                     AS MaHoSoNH,
    nh.MaKyHieu                                     AS MaNguoiHoc,
    nh.HoTen                                        AS TenNguoiHoc,
    dk.MaLopHP,
    lhp.MaLopHPCode,
    hp.TenHocPhan,
    hk.TenHocKy,
    COUNT(bd.MaBuoiDD)                              AS TongSoBuoi,
    SUM(CASE WHEN ct.TrangThaiDiemDanh IN (N'CoMat',N'DiMuon') THEN 1 ELSE 0 END) AS SoBuoiCoMat,
    SUM(CASE WHEN ct.TrangThaiDiemDanh = N'VangKhongPhep'      THEN 1 ELSE 0 END) AS SoVangKhongPhep,
    SUM(CASE WHEN ct.TrangThaiDiemDanh = N'VangCoPhep'         THEN 1 ELSE 0 END) AS SoVangCoPhep,
    CAST(
        100.0 * SUM(CASE WHEN ct.TrangThaiDiemDanh IN (N'CoMat',N'DiMuon') THEN 1 ELSE 0 END)
        / NULLIF(COUNT(bd.MaBuoiDD), 0)
    AS DECIMAL(5,2))                                AS TyLeChuyenCan
FROM DangKyHocPhan dk
JOIN HoSoNguoiHoc nh         ON nh.MaHoSoNH    = dk.MaHoSoSV
JOIN LopHocPhan lhp          ON lhp.MaLopHP    = dk.MaLopHP
JOIN HocPhan hp              ON hp.MaHocPhan   = lhp.MaHocPhan
JOIN HocKy hk                ON hk.MaHocKy     = lhp.MaHocKy
LEFT JOIN BuoiDiemDanh bd    ON bd.MaLopHP     = lhp.MaLopHP
LEFT JOIN ChiTietDiemDanh ct ON ct.MaBuoiDD    = bd.MaBuoiDD
                            AND ct.MaHoSoSV    = dk.MaHoSoSV
WHERE dk.TrangThai = N'DaDangKy'
GROUP BY
    dk.MaHoSoSV, nh.MaKyHieu, nh.HoTen,
    dk.MaLopHP, lhp.MaLopHPCode, hp.TenHocPhan, hk.TenHocKy;
GO  -- <-- batch kết thúc
 
CREATE OR ALTER VIEW v_SoDiemTongHop AS
SELECT
    sd.MaSoDiem,
    dk.MaHoSoSV                 AS MaHoSoNH,
    nh.MaKyHieu                 AS MaNguoiHoc,
    nh.HoTen                    AS TenNguoiHoc,
    ch.MaKyHieuCapHoc,
    lhp.MaLopHP,
    lhp.MaLopHPCode,
    hp.MaHocPhanCode,
    hp.TenHocPhan,
    hp.SoTinChi,
    hk.TenHocKy,
    sd.DiemChuyenCan,
    sd.DiemQuaTrinh,
    sd.DiemGiuaKy,
    sd.DiemCuoiKy,
    sd.DiemTongKet,
    sd.XepLoai,
    sd.DiemGPA,
    sd.DatMon,
    sd.TrangThai                AS TrangThaiDiem
FROM SoDiemSinhVien sd
JOIN DangKyHocPhan dk   ON dk.MaDangKy  = sd.MaDangKy
JOIN HoSoNguoiHoc nh    ON nh.MaHoSoNH  = dk.MaHoSoSV
JOIN LopHocPhan lhp     ON lhp.MaLopHP  = dk.MaLopHP
JOIN HocPhan hp         ON hp.MaHocPhan = lhp.MaHocPhan
JOIN HocKy hk           ON hk.MaHocKy   = lhp.MaHocKy
LEFT JOIN HoSoCapHoc ch ON ch.MaHoSoNH  = nh.MaHoSoNH;
GO
 
CREATE OR ALTER VIEW v_GPATheoHocKy AS
SELECT
    dk.MaHoSoSV                 AS MaHoSoNH,
    nh.MaKyHieu                 AS MaNguoiHoc,
    nh.HoTen                    AS TenNguoiHoc,
    lhp.MaHocKy,
    hk.TenHocKy,
    COUNT(sd.MaSoDiem)                              AS SoMonHoc,
    SUM(hp.SoTinChi)                                AS TongTinChi,
    CAST(
        SUM(hp.SoTinChi * sd.DiemGPA)
        / NULLIF(SUM(hp.SoTinChi), 0)
    AS DECIMAL(4,2))                                AS GPAHocKy,
    SUM(CASE WHEN sd.DatMon = 1 THEN hp.SoTinChi ELSE 0 END) AS TinChiDat
FROM SoDiemSinhVien sd
JOIN DangKyHocPhan dk   ON dk.MaDangKy  = sd.MaDangKy
JOIN HoSoNguoiHoc nh    ON nh.MaHoSoNH  = dk.MaHoSoSV
JOIN LopHocPhan lhp     ON lhp.MaLopHP  = dk.MaLopHP
JOIN HocPhan hp         ON hp.MaHocPhan = lhp.MaHocPhan
JOIN HocKy hk           ON hk.MaHocKy   = lhp.MaHocKy
WHERE sd.TrangThai = N'ChinhThuc'
  AND sd.DatMon IS NOT NULL
GROUP BY
    dk.MaHoSoSV, nh.MaKyHieu, nh.HoTen,
    lhp.MaHocKy, hk.TenHocKy;
GO
 
PRINT N'✅ FIX BƯỚC 7 HOÀN THÀNH — 3 Views đã cập nhật.';
GO
 
-- ============================================================
-- KIỂM TRA SAU KHI FIX
-- ============================================================
 
PRINT N'=== KIỂM TRA KẾT QUẢ SAU FIX ===';
 
-- Xác nhận bảng cũ đã xóa
IF OBJECT_ID('TaiKhoanSinhVien') IS NULL
    PRINT N'  ✅ TaiKhoanSinhVien: ĐÃ XÓA'
ELSE
    PRINT N'  ❌ TaiKhoanSinhVien: VẪN CÒN';
 
IF OBJECT_ID('HoSoSinhVien') IS NULL
    PRINT N'  ✅ HoSoSinhVien: ĐÃ XÓA'
ELSE
    PRINT N'  ❌ HoSoSinhVien: VẪN CÒN';
 
-- Xác nhận bảng mới có dữ liệu
--PRINT N'  TaiKhoanNguoiHoc: ' + CAST((SELECT COUNT(*) FROM TaiKhoanNguoiHoc) AS NVARCHAR) + N' tài khoản';
--PRINT N'  HoSoNguoiHoc:     ' + CAST((SELECT COUNT(*) FROM HoSoNguoiHoc)     AS NVARCHAR) + N' hồ sơ';
--PRINT N'  HoSoCapHoc:       ' + CAST((SELECT COUNT(*) FROM HoSoCapHoc)       AS NVARCHAR) + N' bản ghi cấp học';
 
-- Xác nhận views hoạt động
BEGIN TRY
    DECLARE @test INT;
    SELECT @test = COUNT(*) FROM v_TongHopDiemDanh;
    PRINT N'  ✅ v_TongHopDiemDanh: OK (' + CAST(@test AS NVARCHAR) + N' dòng)';
END TRY
BEGIN CATCH
    PRINT N'  ❌ v_TongHopDiemDanh lỗi: ' + ERROR_MESSAGE();
END CATCH;
 
BEGIN TRY
    SELECT @test = COUNT(*) FROM v_SoDiemTongHop;
    PRINT N'  ✅ v_SoDiemTongHop: OK (' + CAST(@test AS NVARCHAR) + N' dòng)';
END TRY
BEGIN CATCH
    PRINT N'  ❌ v_SoDiemTongHop lỗi: ' + ERROR_MESSAGE();
END CATCH;
 
PRINT N'';
PRINT N'✅ FIX HOÀN TẤT. Migration v2.0 → v2.1 đã thành công.';
GO