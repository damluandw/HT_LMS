-- ============================================================
-- LMS TIẾNG VIỆT - BỔ SUNG & CẬP NHẬT
-- Phiên bản: 2.1 (Patch on top of v2.0)
-- Thay đổi:
--   1. Thêm mã ký hiệu (MaKyHieu) cho tất cả đối tượng chính
--   2. Gộp HocSinh + SinhVien thành NguoiHoc (hỗ trợ đa cấp)
--   3. Thêm cấu trúc cấp học: DaiHoc/CaoDang/THPT
--   4. Hỗ trợ 4 loại lớp: TinChi / NienChe / KhoiBan / ChuyenDe
--   5. Học sinh THPT có thể đồng thời là sinh viên CĐ
-- ============================================================

USE HT_LMS;
GO

-- ============================================================
-- PHẦN 1: BẢNG CẤP HỌC & LOẠI HÌNH ĐÀO TẠO
-- (Thêm mới — bổ sung cho cấu trúc Truong/Nganh hiện có)
-- ============================================================

-- 1.1 Cấp học (phân loại toàn trường)
CREATE TABLE CapHoc (
    MaCapHoc        INT IDENTITY(1,1) PRIMARY KEY,
    MaCapHocKH      AS (N'CH' + RIGHT('000' + CAST(MaCapHoc AS NVARCHAR), 3)) PERSISTED,
    -- Mã ký hiệu tự sinh: CH001, CH002...
    TenCapHoc       NVARCHAR(100) NOT NULL,
    -- DaiHoc / CaoDang / THPT / ThacSi / TienSi / SoCapNgheNghiep
    MoTa            NVARCHAR(500),
    ThuTu           INT           NOT NULL DEFAULT 0,
    ConHieuLuc      BIT           NOT NULL DEFAULT 1
);
GO

INSERT INTO CapHoc (TenCapHoc, MoTa, ThuTu) VALUES
(N'THPT',       N'Trung học phổ thông (lớp 10-12)', 1),
(N'CaoDang',    N'Cao đẳng (2-3 năm)', 2),
(N'DaiHoc',     N'Đại học (4-5 năm)', 3),
(N'ThacSi',     N'Sau đại học — Thạc sĩ', 4),
(N'TienSi',     N'Sau đại học — Tiến sĩ', 5);
GO

-- 1.2 Loại hình lớp học (dùng chung cho mọi cấp)
CREATE TABLE LoaiHinhLop (
    MaLoaiHinhLop   INT IDENTITY(1,1) PRIMARY KEY,
    MaLoaiHinhKH    AS (N'LHL' + RIGHT('00' + CAST(MaLoaiHinhLop AS NVARCHAR), 2)) PERSISTED,
    TenLoai         NVARCHAR(100) NOT NULL,
    -- TinChi / NienChe / KhoiBan / ChuyenDe
    ApDungCapHoc    NVARCHAR(100) NOT NULL,
    -- DaiHoc,CaoDang / THPT / TatCa
    MoTa            NVARCHAR(500),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1
);
GO

INSERT INTO LoaiHinhLop (TenLoai, ApDungCapHoc, MoTa) VALUES
(N'TinChi',   N'DaiHoc,CaoDang', N'Sinh viên chọn môn từng học kỳ, lớp học phần mở theo môn'),
(N'NienChe',  N'DaiHoc,CaoDang', N'Học theo lớp cố định, tiến độ chung theo năm học'),
(N'KhoiBan',  N'THPT',           N'Lớp học cố định theo khối A/B/C/D hoặc ban KHTN/KHXH'),
(N'ChuyenDe', N'THPT',           N'Lớp chuyên đề tự chọn theo Chương trình GDPT 2018');
GO

-- ============================================================
-- PHẦN 2: MÃ KÝ HIỆU — QUY TẮC SINH TỰ ĐỘNG
-- Áp dụng cho tất cả đối tượng chính
-- Quy tắc: [TienTo][MaTruongVietTat][NamHoc][SoThuTu]
-- Ví dụ: SV-DLU-2024-001234 / GV-DLU-GV0089 / HP-DLU-CS101
-- ============================================================

CREATE TABLE QuyTacMaKyHieu (
    MaQuyTac        INT IDENTITY(1,1) PRIMARY KEY,
    LoaiDoiTuong    NVARCHAR(50)  NOT NULL UNIQUE,
    -- NguoiHoc / GiangVien / NhanVien / HocPhan / MonHoc
    -- LopHocPhan / LopHanhChinh / LopNienChe / LopKhoiBan / LopChuyenDe
    TienTo          NVARCHAR(10)  NOT NULL,   -- SV, HS, GV, GK, HP, MH, LHP...
    CauTruc         NVARCHAR(200) NOT NULL,
    -- Mô tả cấu trúc: [TienTo]-[MaTruong]-[NamVao]-[SoTT6So]
    ViDu            NVARCHAR(100),
    SoDemHienTai    INT           NOT NULL DEFAULT 0,
    MoTa            NVARCHAR(500)
);
GO

INSERT INTO QuyTacMaKyHieu
    (LoaiDoiTuong, TienTo, CauTruc, ViDu, MoTa)
VALUES
(N'SinhVien',    N'SV',  N'[TienTo][MaTruong][NamVao][SoTT6So]',   N'SVDLU20240001',  N'Sinh viên đại học/cao đẳng'),
(N'HocSinhTHPT', N'HS',  N'[TienTo][MaTruong][NamVao][SoTT5So]',   N'HSDLU202400001', N'Học sinh THPT'),
(N'GiangVien',   N'GV',  N'[TienTo][MaTruong][SoTT4So]',           N'GVDLU0089',      N'Giảng viên/Giáo viên'),
(N'NhanVien',    N'NV',  N'[TienTo][MaTruong][SoTT4So]',           N'NVDLU0012',      N'Nhân viên/Quản lý'),
(N'HocPhan',     N'HP',  N'[TienTo][MaBoMon][MaSoMonHoc]',         N'HPCS101',        N'Học phần đại học/cao đẳng'),
(N'MonHoc',      N'MH',  N'[TienTo][MaKhoi][MaSoMon]',             N'MHVAN10A',       N'Môn học THPT'),
(N'LopHocPhan',  N'LHP', N'[TienTo][MaHocPhan][MaHocKy][SoTT2So]', N'LHPCS101HK1-01', N'Lớp học phần (tín chỉ)'),
(N'LopNienChe',  N'LNC', N'[TienTo][MaNganh][NienKhoa][SoTT2So]',  N'LNCKTPM2022-01', N'Lớp niên chế'),
(N'LopHanhChinh',N'LHC', N'[TienTo][MaNganh][NienKhoa][SoTT2So]',  N'LHCKTPM2022A',   N'Lớp hành chính ĐH/CĐ'),
(N'LopKhoiBan',  N'LKB', N'[TienTo][MaTruong][NamHoc][SoLop]',     N'LKBDLU2024-10A1',N'Lớp THPT theo khối/ban'),
(N'LopChuyenDe', N'LCD', N'[TienTo][MaTruong][NamHoc][MaChuyenDe]',N'LCDDLU2024-TH1', N'Lớp chuyên đề THPT');
GO

-- ============================================================
-- PHẦN 3: NGƯỜI HỌC THỐNG NHẤT (Thay thế HoSoSinhVien cũ)
-- Hỗ trợ: Học sinh THPT / SV Cao đẳng / SV Đại học
-- Một người có thể vừa là HS THPT vừa là SV CĐ
-- ============================================================

-- 3.1 Tài khoản người học (gộp SV + HS)
-- THAY THẾ TaiKhoanSinhVien trong v2.0
CREATE TABLE TaiKhoanNguoiHoc (
    MaTKNguoiHoc    INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenDangNhap     NVARCHAR(100) NOT NULL UNIQUE,
    MatKhauHash     NVARCHAR(256) NOT NULL,
    Salt            NVARCHAR(100) NOT NULL,
    Email           NVARCHAR(200) NOT NULL UNIQUE,
    DaXacThucEmail  BIT           NOT NULL DEFAULT 0,
    SoDienThoai     NVARCHAR(20),
    DaXacThucSDT    BIT           NOT NULL DEFAULT 0,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    SoLanDangNhapSai  INT         NOT NULL DEFAULT 0,
    KhoaDen         DATETIME2,
    BatXacThuc2Buoc BIT           NOT NULL DEFAULT 0,
    BiMat2Buoc      NVARCHAR(200),
    LanDangNhapCuoi DATETIME2,
    NgayDoiMatKhau  DATETIME2,
    TuyChinhJSON    NVARCHAR(MAX),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_TKNguoiHoc_Truong  ON TaiKhoanNguoiHoc(MaTruong);
CREATE INDEX IX_TKNguoiHoc_TrangThai ON TaiKhoanNguoiHoc(TrangThai);
GO

-- 3.2 Hồ sơ người học (thông tin cá nhân dùng chung)
CREATE TABLE HoSoNguoiHoc (
    MaHoSoNH        INT IDENTITY(1,1) PRIMARY KEY,

    -- === MÃ KÝ HIỆU ===
    -- Sinh tự động theo QuyTacMaKyHieu, unique trong toàn hệ thống
    MaKyHieu        NVARCHAR(30)  NOT NULL UNIQUE,
    -- VD: SVDLU20240001 (SV đại học) | HSDLU202400001 (HS THPT)
    -- Người vừa là HS THPT vừa là SV CĐ có 2 mã ký hiệu (xem HoSoCapHoc)

    MaTKNguoiHoc    INT           NOT NULL REFERENCES TaiKhoanNguoiHoc(MaTKNguoiHoc) UNIQUE,

    -- === THÔNG TIN CÁ NHÂN ===
    HoTen           NVARCHAR(200) NOT NULL,
    Ho              NVARCHAR(100),
    Ten             NVARCHAR(100),
    NgaySinh        DATE,
    GioiTinh        NVARCHAR(20),
    SoCMND          NVARCHAR(50),             -- CMND / CCCD / Khai sinh
    NgayCap         DATE,
    NoiCap          NVARCHAR(200),
    HinhAnh         NVARCHAR(500),
    DanToc          NVARCHAR(100),
    TonGiao         NVARCHAR(100),
    QuocTich        NVARCHAR(100) DEFAULT N'Việt Nam',
    DiaChiThuongTru NVARCHAR(500),
    DiaChiTamTru    NVARCHAR(500),
    TinhThanh       NVARCHAR(100),
    QuanHuyen       NVARCHAR(100),

    -- === PHỤ HUYNH / LIÊN HỆ KHẨN CẤP ===
    HoTenPhuHuynh   NVARCHAR(200),
    SDTPhuHuynh     NVARCHAR(50),
    MoiQuanHePH     NVARCHAR(100),
    EmailPhuHuynh   NVARCHAR(200),

    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_HoSoNH_MaKyHieu ON HoSoNguoiHoc(MaKyHieu);
GO

-- 3.3 Hồ sơ theo từng cấp học (1 người có thể có nhiều cấp)
-- Đây là bảng quan trọng: cho phép 1 người vừa là HS THPT vừa là SV CĐ
CREATE TABLE HoSoCapHoc (
    MaHoSoCH        INT IDENTITY(1,1) PRIMARY KEY,

    -- === MÃ KÝ HIỆU THEO CẤP HỌC ===
    -- Mỗi cấp học có mã riêng
    MaKyHieuCapHoc  NVARCHAR(30)  NOT NULL UNIQUE,
    -- VD: SVDLU20240001 (khi học CĐ), HSDLU202400001 (khi học THPT cùng người)

    MaHoSoNH        INT           NOT NULL REFERENCES HoSoNguoiHoc(MaHoSoNH),
    MaCapHoc        INT           NOT NULL REFERENCES CapHoc(MaCapHoc),
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),

    -- === THÔNG TIN THEO CẤP HỌC ===
    -- Đại học / Cao đẳng
    MaNganh         INT           REFERENCES Nganh(MaNganh),
    NienKhoa        NVARCHAR(20),             -- K2020, K2021 (ĐH/CĐ)
    NamBatDau       INT,
    NamDuKienTotNghiep INT,
    HinhThucDaoTao  NVARCHAR(100),
    -- ChinhQuy / VuaHocVuaLam / TuXa / LienThong / ChuyenTruong

    -- THPT
    MaTruongTHPT    INT           REFERENCES Truong(MaTruong),
    -- (có thể học THPT ở trường khác với trường CĐ)
    NamVaoTHPT      INT,
    NamRaTHPT       INT,
    KhoiHoc         NVARCHAR(20),             -- A / A1 / B / C / D / KHTN / KHXH
    BanHoc          NVARCHAR(100),            -- Khoa học tự nhiên / Xã hội / Cơ bản

    -- Chung
    TrangThaiHocTap NVARCHAR(50)  NOT NULL DEFAULT N'DangHoc',
    -- DangHoc / BaoLuu / ThoiHoc / TotNghiep / DiChuyen / DinhChi
    LoaiHinhDaoTao  NVARCHAR(50)  NOT NULL DEFAULT N'TinChi',
    -- TinChi / NienChe / KhoiBan / ChuyenDe
    LaNguoiHocHienTai BIT         NOT NULL DEFAULT 1,  -- Đang theo học cấp này không?
    NgayBatDau      DATE,
    NgayKetThuc     DATE,
    GhiChu          NVARCHAR(500),

    CONSTRAINT UQ_HoSoCapHoc UNIQUE (MaHoSoNH, MaCapHoc, MaTruong)
);
GO

CREATE INDEX IX_HoSoCH_NguoiHoc ON HoSoCapHoc(MaHoSoNH);
CREATE INDEX IX_HoSoCH_CapHoc   ON HoSoCapHoc(MaCapHoc);
CREATE INDEX IX_HoSoCH_Nganh    ON HoSoCapHoc(MaNganh);
GO

-- Lịch sử trạng thái học tập theo từng cấp
CREATE TABLE LichSuTrangThaiHocTap (
    MaLichSuHT      INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoCH        INT           NOT NULL REFERENCES HoSoCapHoc(MaHoSoCH),
    MaHocKy         INT           REFERENCES HocKy(MaHocKy),
    TrangThai       NVARCHAR(50)  NOT NULL,
    NgayHieuLuc     DATE          NOT NULL,
    NgayKetThuc     DATE,
    LyDo            NVARCHAR(1000),
    SoQuyetDinh     NVARCHAR(100),
    NguoiDuyet      INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Phiên đăng nhập người học (gộp)
CREATE TABLE PhienDangNhapNguoiHoc (
    MaPhien         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MaTKNguoiHoc    INT           NOT NULL REFERENCES TaiKhoanNguoiHoc(MaTKNguoiHoc),
    DiaChiIP        NVARCHAR(50),
    ThietBi         NVARCHAR(500),
    TrinhDuyet      NVARCHAR(500),
    ThoiGianDangNhap  DATETIME2   NOT NULL DEFAULT GETDATE(),
    ThoiGianHoatDongCuoi DATETIME2 NOT NULL DEFAULT GETDATE(),
    ThoiGianDangXuat  DATETIME2,
    DangHoatDong    BIT           NOT NULL DEFAULT 1,
    MaPhienToken    NVARCHAR(500) NOT NULL
);
GO

CREATE INDEX IX_PhienNH_TaiKhoan ON PhienDangNhapNguoiHoc(MaTKNguoiHoc);
GO

-- ============================================================
-- PHẦN 4: MÃ KÝ HIỆU BỔ SUNG CHO CÁC ĐỐI TƯỢNG CHÍNH
-- Cập nhật các bảng hiện có thêm cột MaKyHieu
-- ============================================================

-- 4.1 Giảng viên / Giáo viên — thêm MaKyHieu
-- Cột tính toán tự sinh dạng: GV + MaTruongVietTat + SoThuTu 4 chữ số
ALTER TABLE HoSoGiangVien
    ADD MaKyHieuGV AS (
        N'GV' + CAST(MaBoMon AS NVARCHAR) + RIGHT('0000' + CAST(MaHoSoGV AS NVARCHAR), 4)
    ) PERSISTED;
GO
-- Tạo unique index (cho phép tìm kiếm)
CREATE UNIQUE INDEX UX_GV_MaKyHieu ON HoSoGiangVien(MaKyHieuGV);
GO

-- 4.2 Nhân viên — thêm MaKyHieu
ALTER TABLE HoSoNhanVien
    ADD MaKyHieuNV AS (
        N'NV' + RIGHT('0000' + CAST(MaHoSoNV AS NVARCHAR), 4)
    ) PERSISTED;
GO
CREATE UNIQUE INDEX UX_NV_MaKyHieu ON HoSoNhanVien(MaKyHieuNV);
GO

-- 4.3 Học phần ĐH/CĐ — MaHocPhanCode đã là mã ký hiệu (vd: CS101)
-- Bổ sung thêm cột định dạng chuẩn: HP + MaBoMon + Code
ALTER TABLE HocPhan
    ADD MaKyHieuHP AS (
        N'HP' + CAST(MaBoMon AS NVARCHAR) + '-' + MaHocPhanCode
    ) PERSISTED;
GO
CREATE INDEX IX_HocPhan_MaKyHieu ON HocPhan(MaKyHieuHP);
GO

-- ============================================================
-- PHẦN 5: MÔN HỌC THPT
-- (Bảng mới — khác với HocPhan của ĐH/CĐ)
-- ============================================================

CREATE TABLE MonHocTHPT (
    MaMonHoc        INT IDENTITY(1,1) PRIMARY KEY,

    -- === MÃ KÝ HIỆU ===
    MaKyHieuMon     AS (N'MH' + RIGHT('000' + CAST(MaMonHoc AS NVARCHAR), 3)) PERSISTED,

    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenMonHoc       NVARCHAR(200) NOT NULL,
    TenVietTat      NVARCHAR(20),
    Khoi            NVARCHAR(20)  NOT NULL,   -- 10 / 11 / 12
    NhomMon         NVARCHAR(100) NOT NULL,
    -- BatBuoc / TuChonCumA / TuChonCumB / ChuyenDe / GDQuocPhong
    MonThuocBan     NVARCHAR(100),
    -- KHTN / KHXH / CoBan / ChuyenBiet
    SoTietNamHoc    INT           NOT NULL DEFAULT 0,
    SoTietTuan      DECIMAL(4,1)  NOT NULL DEFAULT 0,
    HeSoDiem        DECIMAL(3,1)  NOT NULL DEFAULT 1,
    ApDungTuNam     INT,
    MoTa            NVARCHAR(MAX),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_MonHocTHPT_Truong ON MonHocTHPT(MaTruong);
CREATE INDEX IX_MonHocTHPT_Khoi   ON MonHocTHPT(Khoi);
GO

-- Chuyên đề THPT (theo Chương trình GDPT 2018)
CREATE TABLE ChuyenDeTHPT (
    MaChuyenDe      INT IDENTITY(1,1) PRIMARY KEY,

    MaKyHieuCD      AS (N'CD' + RIGHT('000' + CAST(MaChuyenDe AS NVARCHAR), 3)) PERSISTED,

    MaMonHoc        INT           NOT NULL REFERENCES MonHocTHPT(MaMonHoc),
    TenChuyenDe     NVARCHAR(300) NOT NULL,
    Khoi            NVARCHAR(20)  NOT NULL,
    SoTietThucHien  INT           NOT NULL DEFAULT 0,
    MoTa            NVARCHAR(MAX),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1
);
GO

-- ============================================================
-- PHẦN 6: LỚP HỌC — CẤU TRÚC THỐNG NHẤT CHO 4 LOẠI
-- ============================================================

-- 6.1 Lớp hành chính ĐH/CĐ (Niên chế & Tín chỉ đều có lớp HC)
-- Cập nhật bảng LopHanhChinh hiện có thêm MaKyHieu + LoaiHinhDaoTao
ALTER TABLE LopHanhChinh
    ADD MaKyHieuLHC AS (
        N'LHC' + CAST(MaNganh AS NVARCHAR) + '-' + NienKhoa + '-' + MaLopCode
    ) PERSISTED,
    LoaiHinhDaoTao  NVARCHAR(50) NOT NULL DEFAULT N'TinChi';
    -- TinChi / NienChe
GO

-- 6.2 Lớp học phần (Tín chỉ — ĐH/CĐ)
-- Cập nhật LopHocPhan hiện có thêm MaKyHieu
ALTER TABLE LopHocPhan
    ADD MaKyHieuLHP AS (
        N'LHP-' + MaLopHPCode
    ) PERSISTED;
GO
CREATE INDEX IX_LopHP_MaKyHieu ON LopHocPhan(MaKyHieuLHP);
GO

-- 6.3 Lớp niên chế ĐH/CĐ (Mới — lớp học cố định theo năm)
CREATE TABLE LopNienChe (
    MaLopNC         INT IDENTITY(1,1) PRIMARY KEY,

    -- === MÃ KÝ HIỆU ===
    MaKyHieuLNC     NVARCHAR(50)  NOT NULL UNIQUE,
    -- VD: LNC-KTPM-K2022-01
    -- Sinh theo quy tắc: LNC + MaNganh + NienKhoa + SoThuTu

    MaNganh         INT           NOT NULL REFERENCES Nganh(MaNganh),
    MaCapHoc        INT           NOT NULL REFERENCES CapHoc(MaCapHoc),
    MaCoSo          INT           REFERENCES CoSo(MaCoSo),
    TenLop          NVARCHAR(100) NOT NULL,
    NienKhoa        NVARCHAR(20)  NOT NULL,   -- K2022
    NamHocHienTai   INT           NOT NULL,   -- 2024 (năm học đang học)
    NamHocThuBao    TINYINT       NOT NULL DEFAULT 1,  -- Đang học năm thứ mấy
    NamHocToiDa     TINYINT       NOT NULL DEFAULT 4,  -- Tổng số năm học
    SiSoToiDa       INT           NOT NULL DEFAULT 50,
    MaGiaoVienChuNhiem INT        REFERENCES HoSoGiangVien(MaHoSoGV),
    MaCoVanHocTap   INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    GhiChu          NVARCHAR(500),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_LopNC_Nganh    ON LopNienChe(MaNganh);
CREATE INDEX IX_LopNC_NienKhoa ON LopNienChe(NienKhoa);
GO

-- Sinh viên trong lớp niên chế
CREATE TABLE NguoiHoc_LopNienChe (
    MaNH_LNC        INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoCH        INT           NOT NULL REFERENCES HoSoCapHoc(MaHoSoCH),
    MaLopNC         INT           NOT NULL REFERENCES LopNienChe(MaLopNC),
    NgayVaoLop      DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    NgayRoiLop      DATE,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DangHoc',
    LyDoRoi         NVARCHAR(500),
    CONSTRAINT UQ_NH_LopNC UNIQUE (MaHoSoCH, MaLopNC)
);
GO

-- Lịch học theo môn trong lớp niên chế (cả năm cố định)
CREATE TABLE LichHocNienChe (
    MaLichNC        INT IDENTITY(1,1) PRIMARY KEY,
    MaLopNC         INT           NOT NULL REFERENCES LopNienChe(MaLopNC),
    MaHocPhan       INT           NOT NULL REFERENCES HocPhan(MaHocPhan),
    MaHocKy         INT           NOT NULL REFERENCES HocKy(MaHocKy),
    MaGiangVien     INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    ThuTrongTuan    TINYINT       NOT NULL,
    GioBatDau       TIME          NOT NULL,
    GioKetThuc      TIME          NOT NULL,
    PhongHoc        NVARCHAR(100),
    TuanBatDau      INT           NOT NULL DEFAULT 1,
    TuanKetThuc     INT           NOT NULL DEFAULT 15,
    GhiChu          NVARCHAR(300)
);
GO

-- 6.4 Lớp THPT — Theo Khối/Ban
CREATE TABLE LopKhoiBan (
    MaLopKB         INT IDENTITY(1,1) PRIMARY KEY,

    -- === MÃ KÝ HIỆU ===
    MaKyHieuLKB     NVARCHAR(50)  NOT NULL UNIQUE,
    -- VD: LKB-DLU-2024-10A1 (Lớp 10A1 năm học 2024)

    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    MaCoSo          INT           REFERENCES CoSo(MaCoSo),
    TenLop          NVARCHAR(50)  NOT NULL,   -- 10A1, 11B2, 12C3...
    Khoi            NVARCHAR(10)  NOT NULL,   -- 10 / 11 / 12
    NamHoc          NVARCHAR(20)  NOT NULL,   -- 2024-2025
    KhoiHocBan      NVARCHAR(100),
    -- KHTN / KHXH / CoBan / ToanLy / ToanHoa / VanSu / VanAnh...
    LoaiBan         NVARCHAR(50)  NOT NULL DEFAULT N'CoBan',
    -- CoBan / ChuyenBiet / TangCuong / SongNgu
    SiSoToiDa       INT           NOT NULL DEFAULT 45,
    MaGiaoVienChuNhiem INT        REFERENCES HoSoGiangVien(MaHoSoGV),
    PhongHocChinh   NVARCHAR(100),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_LopKB_Truong  ON LopKhoiBan(MaTruong);
CREATE INDEX IX_LopKB_Khoi    ON LopKhoiBan(Khoi, NamHoc);
GO

-- Học sinh trong lớp khối/ban
CREATE TABLE NguoiHoc_LopKhoiBan (
    MaNH_LKB        INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoCH        INT           NOT NULL REFERENCES HoSoCapHoc(MaHoSoCH),
    MaLopKB         INT           NOT NULL REFERENCES LopKhoiBan(MaLopKB),
    SoThuTu         INT,                      -- Số thứ tự trong lớp
    NgayVaoLop      DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    NgayRoiLop      DATE,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DangHoc',
    CONSTRAINT UQ_NH_LopKB UNIQUE (MaHoSoCH, MaLopKB)
);
GO

-- Thời khóa biểu THPT (mỗi môn-lớp theo tuần)
CREATE TABLE ThoiKhoaBieuTHPT (
    MaTKB           INT IDENTITY(1,1) PRIMARY KEY,
    MaLopKB         INT           NOT NULL REFERENCES LopKhoiBan(MaLopKB),
    MaMonHoc        INT           NOT NULL REFERENCES MonHocTHPT(MaMonHoc),
    MaHoSoGV        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    MaHocKy         INT           NOT NULL REFERENCES HocKy(MaHocKy),
    ThuTrongTuan    TINYINT       NOT NULL,   -- 2..7
    TietBatDau      TINYINT       NOT NULL,   -- Tiết 1..10
    SoTiet          TINYINT       NOT NULL DEFAULT 1,
    PhongHoc        NVARCHAR(100),
    ApDungTuTuan    INT           NOT NULL DEFAULT 1,
    ApDungDenTuan   INT           NOT NULL DEFAULT 18,
    GhiChu          NVARCHAR(300)
);
GO

CREATE INDEX IX_TKB_Lop    ON ThoiKhoaBieuTHPT(MaLopKB);
CREATE INDEX IX_TKB_GiaoVien ON ThoiKhoaBieuTHPT(MaHoSoGV);
GO

-- 6.5 Lớp Chuyên đề THPT
CREATE TABLE LopChuyenDe (
    MaLopCD         INT IDENTITY(1,1) PRIMARY KEY,

    -- === MÃ KÝ HIỆU ===
    MaKyHieuLCD     NVARCHAR(50)  NOT NULL UNIQUE,
    -- VD: LCD-DLU-2024-TH01 (Lớp chuyên đề Toán học 01)

    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    MaChuyenDe      INT           NOT NULL REFERENCES ChuyenDeTHPT(MaChuyenDe),
    MaHocKy         INT           NOT NULL REFERENCES HocKy(MaHocKy),
    TenLop          NVARCHAR(200) NOT NULL,
    SiSoToiDa       INT           NOT NULL DEFAULT 35,
    MaGiaoVien      INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    PhongHoc        NVARCHAR(100),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Học sinh đăng ký chuyên đề
CREATE TABLE DangKyChuyenDe (
    MaDKCD          INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoCH        INT           NOT NULL REFERENCES HoSoCapHoc(MaHoSoCH),
    MaLopCD         INT           NOT NULL REFERENCES LopChuyenDe(MaLopCD),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DaDangKy',
    NgayDangKy      DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_DKCD UNIQUE (MaHoSoCH, MaLopCD)
);
GO

-- ============================================================
-- PHẦN 7: ĐIỂM SỐ THPT — Riêng biệt với SoDiemSinhVien ĐH/CĐ
-- ============================================================

CREATE TABLE SoDiemTHPT (
    MaSoDiemTHPT    INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoCH        INT           NOT NULL REFERENCES HoSoCapHoc(MaHoSoCH),
    MaMonHoc        INT           NOT NULL REFERENCES MonHocTHPT(MaMonHoc),
    MaHocKy         INT           NOT NULL REFERENCES HocKy(MaHocKy),
    MaLopKB         INT           REFERENCES LopKhoiBan(MaLopKB),
    MaLopCD         INT           REFERENCES LopChuyenDe(MaLopCD),

    -- Cơ cấu điểm THPT theo TT 22/2021 & TT 26/2020
    DiemKiemTraThuongXuyen1  DECIMAL(4,1),
    DiemKiemTraThuongXuyen2  DECIMAL(4,1),
    DiemKiemTraThuongXuyen3  DECIMAL(4,1),
    DiemKiemTraThuongXuyen4  DECIMAL(4,1),
    DiemKiemTraGiuaKy        DECIMAL(4,1),
    DiemKiemTraCuoiKy        DECIMAL(4,1),
    DiemTrungBinhMon         DECIMAL(4,2),    -- Tự động tính
    XepLoaiMon               NVARCHAR(20),
    -- Dat / ChuaDat / Gioi / Kha / TrungBinh / Yeu / Kem (THPT)
    NhanXetGiaoVien          NVARCHAR(500),   -- Theo hướng đánh giá phẩm chất

    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'TamThoi',
    NguoiNhap       INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayNhap        DATETIME2,
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE(),

    CONSTRAINT UQ_SoDiemTHPT UNIQUE (MaHoSoCH, MaMonHoc, MaHocKy)
);
GO

-- Tổng kết năm học THPT
CREATE TABLE TongKetNamHocTHPT (
    MaTongKet       INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoCH        INT           NOT NULL REFERENCES HoSoCapHoc(MaHoSoCH),
    MaNamHoc        INT           NOT NULL REFERENCES NamHoc(MaNamHoc),
    DiemTrungBinhNam DECIMAL(4,2),
    XepLoaiHocLuc   NVARCHAR(50),
    -- Gioi / Kha / TrungBinh / YeuKem
    XepLoaiHanhKiem NVARCHAR(50),
    -- Tot / Kha / TrungBinh / Yeu
    DuocLenLop      BIT,
    DuocTotNghiep   BIT,
    DaotDanhHieu    NVARCHAR(100),
    -- HocSinhGioi / HocSinhKha / HocSinhTienTien
    GhiChu          NVARCHAR(500),
    NguoiDuyet      INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayDuyet       DATETIME2,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_TongKet UNIQUE (MaHoSoCH, MaNamHoc)
);
GO

-- ============================================================
-- PHẦN 8: ĐIỂM DANH THỐNG NHẤT (mở rộng cho THPT)
-- ============================================================

-- Bổ sung bảng BuoiDiemDanhTHPT (riêng cho THPT vì theo tiết)
CREATE TABLE BuoiDiemDanhTHPT (
    MaBuoiDDTHPT    INT IDENTITY(1,1) PRIMARY KEY,
    MaLopKB         INT           REFERENCES LopKhoiBan(MaLopKB),
    MaLopCD         INT           REFERENCES LopChuyenDe(MaLopCD),
    MaTKB           INT           REFERENCES ThoiKhoaBieuTHPT(MaTKB),
    MaHocKy         INT           NOT NULL REFERENCES HocKy(MaHocKy),
    NgayDiemDanh    DATE          NOT NULL,
    TietSo          TINYINT       NOT NULL,   -- Tiết 1..10
    MaGiaoVien      INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    DaHoanThanh     BIT           NOT NULL DEFAULT 0,
    GhiChu          NVARCHAR(300),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE ChiTietDiemDanhTHPT (
    MaChiTietDDTHPT INT IDENTITY(1,1) PRIMARY KEY,
    MaBuoiDDTHPT    INT           NOT NULL REFERENCES BuoiDiemDanhTHPT(MaBuoiDDTHPT),
    MaHoSoCH        INT           NOT NULL REFERENCES HoSoCapHoc(MaHoSoCH),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'CoMat',
    -- CoMat / VangKhongPhep / VangCoPhep / DiMuon
    CoPhep          BIT           NOT NULL DEFAULT 0,
    LyDo            NVARCHAR(500),
    GiayToMinhChung NVARCHAR(500),
    NguoiCapNhat    INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    CONSTRAINT UQ_DDTHPT UNIQUE (MaBuoiDDTHPT, MaHoSoCH)
);
GO

-- ============================================================
-- PHẦN 9: MÃ KÝ HIỆU — STORED PROCEDURE SINH TỰ ĐỘNG
-- ============================================================

-- SP sinh mã ký hiệu người học
CREATE OR ALTER PROCEDURE sp_SinhMaKyHieuNguoiHoc
    @MaTruong       INT,
    @MaCapHoc       INT,
    @NamVao         INT,
    @MaKyHieu       NVARCHAR(30) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TienTo NVARCHAR(5);
    DECLARE @TenCapHoc NVARCHAR(50);
    DECLARE @MaTruongVT NVARCHAR(10);
    DECLARE @SoThuTu INT;
    DECLARE @DinhDangSoTT NVARCHAR(10);

    SELECT @TenCapHoc = TenCapHoc FROM CapHoc WHERE MaCapHoc = @MaCapHoc;
    SELECT @MaTruongVT = LEFT(REPLACE(TenVietTat, N' ', N''), 5)
    FROM Truong WHERE MaTruong = @MaTruong;

    SET @TienTo = CASE
        WHEN @TenCapHoc = N'THPT'    THEN N'HS'
        WHEN @TenCapHoc = N'CaoDang' THEN N'SV'
        WHEN @TenCapHoc = N'DaiHoc'  THEN N'SV'
        WHEN @TenCapHoc = N'ThacSi'  THEN N'HV'  -- Học viên
        WHEN @TenCapHoc = N'TienSi'  THEN N'NCS' -- Nghiên cứu sinh
        ELSE N'NH'
    END;

    -- Lấy số thứ tự tiếp theo
    SELECT @SoThuTu = COUNT(*) + 1
    FROM HoSoCapHoc hc
    JOIN TaiKhoanNguoiHoc tk ON tk.MaTKNguoiHoc = (
        SELECT MaTKNguoiHoc FROM HoSoNguoiHoc WHERE MaHoSoNH = hc.MaHoSoNH
    )
    WHERE tk.MaTruong = @MaTruong
      AND hc.MaCapHoc = @MaCapHoc
      AND hc.NamBatDau = @NamVao;

    -- Định dạng số thứ tự
    SET @DinhDangSoTT = CASE
        WHEN @TienTo = N'HS' THEN RIGHT('00000' + CAST(@SoThuTu AS NVARCHAR), 5)
        ELSE RIGHT('0000' + CAST(@SoThuTu AS NVARCHAR), 4)
    END;

    SET @MaKyHieu = @TienTo + @MaTruongVT + CAST(@NamVao AS NVARCHAR) + @DinhDangSoTT;
    -- VD: SVDLU20240001 hoặc HSDLU202400001
END;
GO

-- SP sinh mã ký hiệu lớp học
CREATE OR ALTER PROCEDURE sp_SinhMaKyHieuLop
    @LoaiLop        NVARCHAR(20),  -- LHP / LNC / LHC / LKB / LCD
    @MaLienKet      INT,           -- MaHocPhan / MaNganh / MaTruong
    @ThongTinPhu    NVARCHAR(50),  -- NienKhoa / NamHoc / MaHocKy
    @SoThuTu        INT,
    @MaKyHieu       NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SoTT NVARCHAR(3) = RIGHT('00' + CAST(@SoThuTu AS NVARCHAR), 2);

    SET @MaKyHieu = CASE @LoaiLop
        WHEN N'LHP' THEN N'LHP-' + CAST(@MaLienKet AS NVARCHAR) + N'-' + @ThongTinPhu + N'-' + @SoTT
        WHEN N'LNC' THEN N'LNC-' + CAST(@MaLienKet AS NVARCHAR) + N'-' + @ThongTinPhu + N'-' + @SoTT
        WHEN N'LHC' THEN N'LHC-' + CAST(@MaLienKet AS NVARCHAR) + N'-' + @ThongTinPhu + N'-' + @SoTT
        WHEN N'LKB' THEN N'LKB-' + CAST(@MaLienKet AS NVARCHAR) + N'-' + @ThongTinPhu + N'-' + @SoTT
        WHEN N'LCD' THEN N'LCD-' + CAST(@MaLienKet AS NVARCHAR) + N'-' + @ThongTinPhu + N'-' + @SoTT
        ELSE N'XX-' + @SoTT
    END;
END;
GO

-- ============================================================
-- PHẦN 10: CẬP NHẬT CÁC FK CÒN LẠI SANG NguoiHoc MỚI
-- (Các bảng quan trọng dùng MaHoSoCH thay cho MaHoSoSV cũ)
-- ============================================================

-- View chuyển đổi tương thích ngược: ánh xạ HoSoCH → thông tin quen thuộc
CREATE VIEW v_SinhVienDaiHocCaoDang AS
SELECT
    nh.MaHoSoNH,
    nh.MaKyHieu                         AS MaSinhVien,
    -- Mã ký hiệu dùng để tìm kiếm
    ch.MaKyHieuCapHoc                   AS MaKyHieuCapHoc,
    ch.MaHoSoCH,
    tk.MaTKNguoiHoc,
    tk.TenDangNhap,
    tk.Email,
    nh.HoTen,
    nh.NgaySinh,
    nh.GioiTinh,
    nh.SoCMND,
    nh.HinhAnh,
    cap.TenCapHoc,
    ng.TenNganh,
    ch.NienKhoa,
    ch.NamBatDau,
    ch.HinhThucDaoTao,
    ch.LoaiHinhDaoTao,                  -- TinChi / NienChe
    ch.TrangThaiHocTap,
    ch.LaNguoiHocHienTai,
    tk.TrangThai                        AS TrangThaiTaiKhoan
FROM HoSoNguoiHoc nh
JOIN TaiKhoanNguoiHoc tk    ON tk.MaTKNguoiHoc = nh.MaTKNguoiHoc
JOIN HoSoCapHoc ch          ON ch.MaHoSoNH     = nh.MaHoSoNH
JOIN CapHoc cap             ON cap.MaCapHoc    = ch.MaCapHoc
LEFT JOIN Nganh ng          ON ng.MaNganh      = ch.MaNganh
WHERE cap.TenCapHoc IN (N'DaiHoc', N'CaoDang', N'ThacSi', N'TienSi');
GO

CREATE VIEW v_HocSinhTHPT AS
SELECT
    nh.MaHoSoNH,
    ch.MaKyHieuCapHoc                   AS MaHocSinh,
    -- Mã ký hiệu tìm kiếm học sinh THPT
    ch.MaHoSoCH,
    tk.MaTKNguoiHoc,
    tk.TenDangNhap,
    tk.Email,
    nh.HoTen,
    nh.NgaySinh,
    nh.GioiTinh,
    nh.SoCMND,
    nh.HinhAnh,
    nh.HoTenPhuHuynh,
    nh.SDTPhuHuynh,
    ch.KhoiHoc,
    ch.BanHoc,
    ch.NamVaoTHPT,
    ch.NamRaTHPT,
    ch.TrangThaiHocTap,
    tk.TrangThai                        AS TrangThaiTaiKhoan,
    -- Phát hiện: người học này có đồng thời học CĐ không?
    (SELECT COUNT(*) FROM HoSoCapHoc ch2
     WHERE ch2.MaHoSoNH = nh.MaHoSoNH
       AND ch2.MaCapHoc IN (SELECT MaCapHoc FROM CapHoc WHERE TenCapHoc = N'CaoDang')
       AND ch2.LaNguoiHocHienTai = 1)   AS DongThoriHocCaoDang
FROM HoSoNguoiHoc nh
JOIN TaiKhoanNguoiHoc tk    ON tk.MaTKNguoiHoc = nh.MaTKNguoiHoc
JOIN HoSoCapHoc ch          ON ch.MaHoSoNH     = nh.MaHoSoNH
JOIN CapHoc cap             ON cap.MaCapHoc    = ch.MaCapHoc
WHERE cap.TenCapHoc = N'THPT';
GO

-- View người học đặc biệt: vừa là HS THPT vừa là SV CĐ
CREATE VIEW v_NguoiHocSongTrung AS
SELECT
    nh.MaHoSoNH,
    nh.HoTen,
    tk.Email,
    chHS.MaKyHieuCapHoc     AS MaHocSinhTHPT,
    chSV.MaKyHieuCapHoc     AS MaSinhVienCaoDang,
    chHS.TrangThaiHocTap    AS TrangThaiTHPT,
    chSV.TrangThaiHocTap    AS TrangThaiCaoDang,
    chHS.KhoiHoc,
    ngSV.TenNganh           AS NganhCaoDang
FROM HoSoNguoiHoc nh
JOIN TaiKhoanNguoiHoc tk    ON tk.MaTKNguoiHoc = nh.MaTKNguoiHoc
JOIN HoSoCapHoc chHS        ON chHS.MaHoSoNH   = nh.MaHoSoNH
JOIN CapHoc capHS           ON capHS.MaCapHoc  = chHS.MaCapHoc
    AND capHS.TenCapHoc = N'THPT'
JOIN HoSoCapHoc chSV        ON chSV.MaHoSoNH   = nh.MaHoSoNH
JOIN CapHoc capSV           ON capSV.MaCapHoc  = chSV.MaCapHoc
    AND capSV.TenCapHoc = N'CaoDang'
LEFT JOIN Nganh ngSV        ON ngSV.MaNganh    = chSV.MaNganh
WHERE chHS.LaNguoiHocHienTai = 1
  AND chSV.LaNguoiHocHienTai = 1;
GO

PRINT N'============================================================';
PRINT N'✅ LMS v2.1 Patch áp dụng thành công!';
PRINT N'';
PRINT N'📌 Thay đổi chính:';
PRINT N'   • TaiKhoanNguoiHoc + HoSoNguoiHoc: gộp SV & HS thành 1';
PRINT N'   • HoSoCapHoc: 1 người → nhiều cấp học (THPT + CĐ đồng thời)';
PRINT N'   • MaKyHieu: sinh tự động cho mọi đối tượng';
PRINT N'   • LopNienChe + LopKhoiBan + LopChuyenDe: 3 loại lớp mới';
PRINT N'   • MonHocTHPT + SoDiemTHPT: riêng cho THPT';
PRINT N'   • BuoiDiemDanhTHPT: điểm danh theo tiết THPT';
PRINT N'';
PRINT N'📊 Bảng mới thêm: 22 bảng | Views mới: 3 | SP mới: 2';
PRINT N'============================================================';
GO
