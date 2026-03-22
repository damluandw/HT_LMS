-- ============================================================
-- HỆ THỐNG LMS - CƠ SỞ DỮ LIỆU TIẾNG VIỆT
-- Phiên bản: 2.0
-- Đặc điểm: Tách hoàn toàn TaiKhoan SinhVien / GiangVien / NhanVien
--            Toàn bộ tên bảng và cột bằng tiếng Việt (không dấu)
-- ============================================================

USE master;
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'HT_LMS')
    DROP DATABASE HT_LMS;
GO
CREATE DATABASE HT_LMS 
ON PRIMARY 
( NAME = N'HT_LMS', FILENAME = N'D:\00.DATABASE\HT_LMS.mdf', SIZE = 8192KB, FILEGROWTH = 65536KB )
LOG ON 
( NAME = N'HT_LMS_log', FILENAME = N'D:\00.DATABASE\HT_LMS_log.ldf', SIZE = 8192KB, FILEGROWTH = 65536KB )
COLLATE Vietnamese_CI_AS

GO
USE HT_LMS;
GO

-- ============================================================
-- PHÂN HỆ 1: QUẢN TRỊ & TỔ CHỨC
-- ============================================================

-- 1.1 Cơ cấu tổ chức trường
CREATE TABLE Truong (
    MaTruong        INT IDENTITY(1,1) PRIMARY KEY,
    TenTruong       NVARCHAR(200) NOT NULL,
    TenVietTat      NVARCHAR(50),
    MaTruongCode    NVARCHAR(20)  NOT NULL UNIQUE,
    Logo            NVARCHAR(500),
    CauHinhGiaoDien NVARCHAR(MAX),           -- JSON: màu sắc, font thương hiệu
    DiaChi          NVARCHAR(500),
    Website         NVARCHAR(200),
    DienThoai       NVARCHAR(50),
    Email           NVARCHAR(200),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE CoSo (
    MaCoSo          INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenCoSo         NVARCHAR(200) NOT NULL,
    MaCoSoCode      NVARCHAR(20)  NOT NULL,
    DiaChi          NVARCHAR(500),
    DienThoai       NVARCHAR(50),
    LaCoSoChinh     BIT           NOT NULL DEFAULT 0,
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_CoSo UNIQUE (MaTruong, MaCoSoCode)
);
GO

CREATE TABLE Khoa (
    MaKhoa          INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    MaCoSo          INT           REFERENCES CoSo(MaCoSo),
    TenKhoa         NVARCHAR(200) NOT NULL,
    MaKhoaCode      NVARCHAR(20)  NOT NULL,
    MoTa            NVARCHAR(MAX),
    MaTruongKhoa    INT,                     -- FK → GiangVien (thêm sau)
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_Khoa UNIQUE (MaTruong, MaKhoaCode)
);
GO

CREATE TABLE BoMon (
    MaBoMon         INT IDENTITY(1,1) PRIMARY KEY,
    MaKhoa          INT           NOT NULL REFERENCES Khoa(MaKhoa),
    TenBoMon        NVARCHAR(200) NOT NULL,
    MaBoMonCode     NVARCHAR(20)  NOT NULL,
    MoTa            NVARCHAR(MAX),
    MaTruongBoMon   INT,                     -- FK → GiangVien (thêm sau)
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_BoMon UNIQUE (MaKhoa, MaBoMonCode)
);
GO

CREATE TABLE Nganh (
    MaNganh         INT IDENTITY(1,1) PRIMARY KEY,
    MaBoMon         INT           NOT NULL REFERENCES BoMon(MaBoMon),
    TenNganh        NVARCHAR(200) NOT NULL,
    MaNganhCode     NVARCHAR(20)  NOT NULL,
    TongTinChi      INT           NOT NULL DEFAULT 0,
    ThoiGianDaoTaoNam INT         NOT NULL DEFAULT 4,
    TrinhDo         NVARCHAR(50)  NOT NULL DEFAULT N'Đại học',
    -- Đại học / Cao đẳng / THPT / Thạc sĩ / Tiến sĩ
    MoTa            NVARCHAR(MAX),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_Nganh UNIQUE (MaBoMon, MaNganhCode)
);
GO

-- ============================================================
-- PHÂN HỆ 2: TÀI KHOẢN & PHÂN QUYỀN
-- Tách hoàn toàn 3 loại: SinhVien / GiangVien / NhanVien
-- ============================================================

-- 2.1 Vai trò & Quyền hạn (dùng chung)
CREATE TABLE VaiTro (
    MaVaiTro        INT IDENTITY(1,1) PRIMARY KEY,
    TenVaiTro       NVARCHAR(100) NOT NULL UNIQUE,
    MaVaiTroCode    NVARCHAR(50)  NOT NULL UNIQUE,
    -- SuperAdmin / QuanTriHeTong / PhongDaoTao / TruongKhoa
    -- TruongBoMon / GiangVien / TroGiang / CoVanHocTap
    -- SinhVien / Khach / DoanhNghiep
    MoTa            NVARCHAR(500),
    LaVaiTroHeThong BIT           NOT NULL DEFAULT 0,
    ThuTuHienThi    INT           NOT NULL DEFAULT 0
);
GO

CREATE TABLE QuyenHan (
    MaQuyen         INT IDENTITY(1,1) PRIMARY KEY,
    MaQuyenCode     NVARCHAR(100) NOT NULL UNIQUE,
    TenQuyen        NVARCHAR(200) NOT NULL,
    PhanHe          NVARCHAR(100) NOT NULL,
    -- QuanTri / KhoaHoc / BaiTap / Thi / Diem / BaoCao / ThuVien
    HanhDong        NVARCHAR(50)  NOT NULL,
    -- Xem / Tao / Sua / Xoa / XuatFile / DuyetDuyet
    MoTa            NVARCHAR(500)
);
GO

CREATE TABLE VaiTro_QuyenHan (
    MaVaiTroQuyen   INT IDENTITY(1,1) PRIMARY KEY,
    MaVaiTro        INT           NOT NULL REFERENCES VaiTro(MaVaiTro),
    MaQuyen         INT           NOT NULL REFERENCES QuyenHan(MaQuyen),
    CONSTRAINT UQ_VaiTroQuyen UNIQUE (MaVaiTro, MaQuyen)
);
GO

-- ============================================================
-- 2.2 TÀI KHOẢN SINH VIÊN
-- ============================================================

CREATE TABLE TaiKhoanSinhVien (
    MaTaiKhoanSV    INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenDangNhap     NVARCHAR(100) NOT NULL UNIQUE,
    MatKhauHash     NVARCHAR(256) NOT NULL,
    Salt            NVARCHAR(100) NOT NULL,
    Email           NVARCHAR(200) NOT NULL UNIQUE,
    DaXacThucEmail  BIT           NOT NULL DEFAULT 0,
    SoDienThoai     NVARCHAR(20),
    DaXacThucSDT    BIT           NOT NULL DEFAULT 0,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    -- HoatDong / KhoaTam / KhoaViPham / ChoXacThuc
    SoLanDangNhapSai  INT         NOT NULL DEFAULT 0,
    KhoaDen         DATETIME2,
    BatXacThuc2Buoc BIT           NOT NULL DEFAULT 0,
    BíMat2Buoc      NVARCHAR(200),
    LanDangNhapCuoi DATETIME2,
    NgayDoiMatKhau  DATETIME2,
    TuyChinhJSON    NVARCHAR(MAX),            -- JSON: ngôn ngữ, giao diện, thông báo
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_TKSinhVien_MaTruong  ON TaiKhoanSinhVien(MaTruong);
CREATE INDEX IX_TKSinhVien_TrangThai ON TaiKhoanSinhVien(TrangThai);
GO

CREATE TABLE HoSoSinhVien (
    MaHoSoSV        INT IDENTITY(1,1) PRIMARY KEY,
    MaTaiKhoanSV    INT           NOT NULL REFERENCES TaiKhoanSinhVien(MaTaiKhoanSV) UNIQUE,
    MaSinhVien      NVARCHAR(50)  NOT NULL UNIQUE,   -- Mã số sinh viên
    HoTen           NVARCHAR(200) NOT NULL,
    Ho              NVARCHAR(100),
    Ten             NVARCHAR(100),
    NgaySinh        DATE,
    GioiTinh        NVARCHAR(20),             -- Nam / Nữ / Khác
    SoCMND          NVARCHAR(50),             -- CMND / CCCD
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
    -- Học lực
    MaNganh         INT           NOT NULL REFERENCES Nganh(MaNganh),
    MaLopHanhChinh  INT,                      -- FK → LopHanhChinh (thêm sau)
    NienKhoa        NVARCHAR(20),             -- K2020, K2021...
    NamBatDau       INT,
    NamDuKienTotNghiep INT,
    HinhThucDaoTao  NVARCHAR(100),            -- Chính quy / Vừa học vừa làm / Từ xa
    LoaiHinhSinhVien NVARCHAR(100),           -- Thường / Liên thông / Chuyển trường
    TrangThaiHocTap NVARCHAR(50)  NOT NULL DEFAULT N'DangHoc',
    -- DangHoc / BaoLuu / ThoiHoc / TotNghiep / DiChuyen / DinhChi
    -- Phụ huynh / Người liên hệ khẩn cấp
    HoTenPhuHuynh   NVARCHAR(200),
    SDTPhuHuynh     NVARCHAR(50),
    MoiQuanHe       NVARCHAR(100),
    EmailPhuHuynh   NVARCHAR(200),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_HoSoSV_MaSinhVien   ON HoSoSinhVien(MaSinhVien);
CREATE INDEX IX_HoSoSV_MaNganh      ON HoSoSinhVien(MaNganh);
CREATE INDEX IX_HoSoSV_TrangThai    ON HoSoSinhVien(TrangThaiHocTap);
GO

-- Lịch sử trạng thái học vụ sinh viên
CREATE TABLE LichSuTrangThaiSV (
    MaLichSu        INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaHocKy        INT,                       -- FK → HocKy (thêm sau)
    TrangThai       NVARCHAR(50)  NOT NULL,
    NgayHieuLuc     DATE          NOT NULL,
    NgayKetThuc     DATE,
    LyDo            NVARCHAR(1000),
    SoQuyetDinh     NVARCHAR(100),
    NguoiDuyet      INT,                      -- FK → HoSoNhanVien
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Phiên đăng nhập sinh viên
CREATE TABLE PhienDangNhapSV (
    MaPhien         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MaTaiKhoanSV    INT           NOT NULL REFERENCES TaiKhoanSinhVien(MaTaiKhoanSV),
    DiaChiIP        NVARCHAR(50),
    ThietBi         NVARCHAR(500),
    TrinhDuyet      NVARCHAR(500),
    ThoiGianDangNhap DATETIME2   NOT NULL DEFAULT GETDATE(),
    ThoiGianHoatDongCuoi DATETIME2 NOT NULL DEFAULT GETDATE(),
    ThoiGianDangXuat DATETIME2,
    DangHoatDong    BIT           NOT NULL DEFAULT 1,
    MaPhienToken    NVARCHAR(500) NOT NULL
);
GO

CREATE INDEX IX_PhienSV_TaiKhoan ON PhienDangNhapSV(MaTaiKhoanSV);
GO

-- ============================================================
-- 2.3 TÀI KHOẢN GIẢNG VIÊN
-- ============================================================

CREATE TABLE TaiKhoanGiangVien (
    MaTaiKhoanGV    INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenDangNhap     NVARCHAR(100) NOT NULL UNIQUE,
    MatKhauHash     NVARCHAR(256) NOT NULL,
    Salt            NVARCHAR(100) NOT NULL,
    Email           NVARCHAR(200) NOT NULL UNIQUE,
    EmailNoiBo      NVARCHAR(200),            -- Email công vụ trường cấp
    DaXacThucEmail  BIT           NOT NULL DEFAULT 0,
    SoDienThoai     NVARCHAR(20),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    SoLanDangNhapSai  INT         NOT NULL DEFAULT 0,
    KhoaDen         DATETIME2,
    BatXacThuc2Buoc BIT           NOT NULL DEFAULT 0,
    BíMat2Buoc      NVARCHAR(200),
    LanDangNhapCuoi DATETIME2,
    NgayDoiMatKhau  DATETIME2,
    TuyChinhJSON    NVARCHAR(MAX),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_TKGiangVien_MaTruong ON TaiKhoanGiangVien(MaTruong);
GO

CREATE TABLE HoSoGiangVien (
    MaHoSoGV        INT IDENTITY(1,1) PRIMARY KEY,
    MaTaiKhoanGV    INT           NOT NULL REFERENCES TaiKhoanGiangVien(MaTaiKhoanGV) UNIQUE,
    MaGiangVien     NVARCHAR(50)  NOT NULL UNIQUE,   -- Mã giảng viên
    HoTen           NVARCHAR(200) NOT NULL,
    Ho              NVARCHAR(100),
    Ten             NVARCHAR(100),
    NgaySinh        DATE,
    GioiTinh        NVARCHAR(20),
    SoCMND          NVARCHAR(50),
    HinhAnh         NVARCHAR(500),
    -- Thông tin chuyên môn
    MaBoMon         INT           NOT NULL REFERENCES BoMon(MaBoMon),
    HocHam          NVARCHAR(100),            -- Giáo sư / Phó Giáo sư
    HocVi           NVARCHAR(100),            -- Tiến sĩ / Thạc sĩ / Cử nhân
    ChuyenNganh     NVARCHAR(300),
    ChuyenMonSauDH  NVARCHAR(300),
    NamVaoTruong    INT,
    NamNhanChucDanhHienTai INT,
    LoaiHopDong     NVARCHAR(100),            -- Cơ hữu / Thỉnh giảng / Hợp đồng
    ChucVu          NVARCHAR(200),            -- Giảng viên / Giảng viên chính / Trưởng BM
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DangLamViec',
    -- DangLamViec / NghiPhep / NghiHuuTriHuu / ThoiViec
    -- Liên hệ
    DiaChiCoQuan    NVARCHAR(500),
    DiaChiNhaRieng  NVARCHAR(500),
    -- Thông tin học thuật
    HuongNghienCuu  NVARCHAR(MAX),
    GioiThieuNgan   NVARCHAR(MAX),
    LinkGoogleScholar NVARCHAR(300),
    LinkResearchGate  NVARCHAR(300),
    SoHDSDGiangDay  INT           NOT NULL DEFAULT 0,  -- Số giờ/tuần
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_HoSoGV_MaGiangVien ON HoSoGiangVien(MaGiangVien);
CREATE INDEX IX_HoSoGV_MaBoMon     ON HoSoGiangVien(MaBoMon);
GO

-- Phiên đăng nhập giảng viên
CREATE TABLE PhienDangNhapGV (
    MaPhien         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MaTaiKhoanGV    INT           NOT NULL REFERENCES TaiKhoanGiangVien(MaTaiKhoanGV),
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

-- ============================================================
-- 2.4 TÀI KHOẢN NHÂN VIÊN (Quản lý, Phòng ban, Admin)
-- ============================================================

CREATE TABLE TaiKhoanNhanVien (
    MaTaiKhoanNV    INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenDangNhap     NVARCHAR(100) NOT NULL UNIQUE,
    MatKhauHash     NVARCHAR(256) NOT NULL,
    Salt            NVARCHAR(100) NOT NULL,
    Email           NVARCHAR(200) NOT NULL UNIQUE,
    EmailNoiBo      NVARCHAR(200),
    DaXacThucEmail  BIT           NOT NULL DEFAULT 0,
    SoDienThoai     NVARCHAR(20),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    SoLanDangNhapSai  INT         NOT NULL DEFAULT 0,
    KhoaDen         DATETIME2,
    BatXacThuc2Buoc BIT           NOT NULL DEFAULT 0,
    BíMat2Buoc      NVARCHAR(200),
    LanDangNhapCuoi DATETIME2,
    NgayDoiMatKhau  DATETIME2,
    TuyChinhJSON    NVARCHAR(MAX),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_TKNhanVien_MaTruong ON TaiKhoanNhanVien(MaTruong);
GO

CREATE TABLE HoSoNhanVien (
    MaHoSoNV        INT IDENTITY(1,1) PRIMARY KEY,
    MaTaiKhoanNV    INT           NOT NULL REFERENCES TaiKhoanNhanVien(MaTaiKhoanNV) UNIQUE,
    MaNhanVien      NVARCHAR(50)  NOT NULL UNIQUE,
    HoTen           NVARCHAR(200) NOT NULL,
    Ho              NVARCHAR(100),
    Ten             NVARCHAR(100),
    NgaySinh        DATE,
    GioiTinh        NVARCHAR(20),
    SoCMND          NVARCHAR(50),
    HinhAnh         NVARCHAR(500),
    -- Chức vụ & Phòng ban
    DonViCongTac    NVARCHAR(200),            -- Phòng Đào tạo / IT / Hành chính...
    ChucVu          NVARCHAR(200),
    LoaiNhanVien    NVARCHAR(100) NOT NULL,
    -- QuanTriHeThong / PhongDaoTao / PhongHanhChinh / QuanLyKhoa / CoVanHocTap / KiemSatThi
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DangLamViec',
    DiaChiCoQuan    NVARCHAR(500),
    NamVaoTruong    INT,
    GhiChu          NVARCHAR(MAX),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_HoSoNV_MaNhanVien ON HoSoNhanVien(MaNhanVien);
GO

-- Phiên đăng nhập nhân viên
CREATE TABLE PhienDangNhapNV (
    MaPhien         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MaTaiKhoanNV    INT           NOT NULL REFERENCES TaiKhoanNhanVien(MaTaiKhoanNV),
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

-- Cập nhật FK trưởng khoa / trưởng bộ môn
ALTER TABLE Khoa   ADD CONSTRAINT FK_Khoa_TruongKhoa   FOREIGN KEY (MaTruongKhoa)   REFERENCES HoSoGiangVien(MaHoSoGV);
ALTER TABLE BoMon  ADD CONSTRAINT FK_BoMon_TruongBoMon  FOREIGN KEY (MaTruongBoMon)  REFERENCES HoSoGiangVien(MaHoSoGV);
GO

-- 2.5 Phân quyền theo từng loại tài khoản
CREATE TABLE VaiTroNhanVien (
    MaVaiTroNV      INT IDENTITY(1,1) PRIMARY KEY,
    MaTaiKhoanNV    INT           NOT NULL REFERENCES TaiKhoanNhanVien(MaTaiKhoanNV),
    MaVaiTro        INT           NOT NULL REFERENCES VaiTro(MaVaiTro),
    MaTruong        INT           REFERENCES Truong(MaTruong),
    MaCoSo          INT           REFERENCES CoSo(MaCoSo),
    MaKhoa          INT           REFERENCES Khoa(MaKhoa),
    MaBoMon         INT           REFERENCES BoMon(MaBoMon),
    NgayGan         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NguoiGan        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayHetHan      DATETIME2,
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    CONSTRAINT UQ_VaiTroNV UNIQUE (MaTaiKhoanNV, MaVaiTro, MaTruong, MaKhoa)
);
GO

CREATE TABLE VaiTroGiangVien (
    MaVaiTroGV      INT IDENTITY(1,1) PRIMARY KEY,
    MaTaiKhoanGV    INT           NOT NULL REFERENCES TaiKhoanGiangVien(MaTaiKhoanGV),
    MaVaiTro        INT           NOT NULL REFERENCES VaiTro(MaVaiTro),
    MaKhoa          INT           REFERENCES Khoa(MaKhoa),
    MaBoMon         INT           REFERENCES BoMon(MaBoMon),
    NgayGan         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayHetHan      DATETIME2,
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    CONSTRAINT UQ_VaiTroGV UNIQUE (MaTaiKhoanGV, MaVaiTro, MaKhoa)
);
GO

-- Quyền ghi đè cá nhân (cấp thêm / thu hồi)
CREATE TABLE QuyenGhiDeNhanVien (
    MaGhiDe         INT IDENTITY(1,1) PRIMARY KEY,
    MaTaiKhoanNV    INT           NOT NULL REFERENCES TaiKhoanNhanVien(MaTaiKhoanNV),
    MaQuyen         INT           NOT NULL REFERENCES QuyenHan(MaQuyen),
    DuocCap         BIT           NOT NULL DEFAULT 1,
    LyDo            NVARCHAR(500),
    NguoiCap        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayCap         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayHetHan      DATETIME2
);
GO

-- Trợ giảng phân công nhiệm vụ
CREATE TABLE PhanCongTroGiang (
    MaPhanCong      INT IDENTITY(1,1) PRIMARY KEY,
    MaTaiKhoanGV_TroGiang INT     NOT NULL REFERENCES TaiKhoanGiangVien(MaTaiKhoanGV),
    MaLopHocPhan    INT           NOT NULL,  -- FK → LopHocPhan (thêm sau)
    MaTaiKhoanGV_ChinH INT        NOT NULL REFERENCES TaiKhoanGiangVien(MaTaiKhoanGV),
    NhiemVuJSON     NVARCHAR(MAX) NOT NULL,
    -- JSON: ["ChamBaiNhomA","QuanLyForumChuDeB","DiemDanhLopC"]
    NgayBatDau      DATE,
    NgayKetThuc     DATE,
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Nhật ký kiểm tra (Audit Log) — theo loại tài khoản
CREATE TABLE NhatKyHeThong (
    MaNhatKy        BIGINT IDENTITY(1,1) PRIMARY KEY,
    LoaiTaiKhoan    NVARCHAR(20)  NOT NULL,  -- SinhVien / GiangVien / NhanVien
    MaTaiKhoan      INT           NOT NULL,  -- ID tương ứng với loại
    MaPhienLamViec  NVARCHAR(100),
    HanhDong        NVARCHAR(100) NOT NULL,
    -- DangNhap / TaoMoi / CapNhat / Xoa / XuatFile / DuyetDiem
    TenBang         NVARCHAR(100),
    MaBanGhi        NVARCHAR(100),
    GiaTriCuJSON    NVARCHAR(MAX),
    GiaTriMoiJSON   NVARCHAR(MAX),
    DiaChiIP        NVARCHAR(50),
    TrinhDuyet      NVARCHAR(500),
    MoTa            NVARCHAR(1000),
    ThanhCong       BIT           NOT NULL DEFAULT 1,
    ThongBaoLoi     NVARCHAR(1000),
    ThoiGian        DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_NhatKy_TaiKhoan  ON NhatKyHeThong(LoaiTaiKhoan, MaTaiKhoan);
CREATE INDEX IX_NhatKy_HanhDong  ON NhatKyHeThong(HanhDong);
CREATE INDEX IX_NhatKy_ThoiGian ON NhatKyHeThong(ThoiGian);
GO

-- ============================================================
-- PHÂN HỆ 3: QUẢN LÝ HỌC VỤ
-- ============================================================

CREATE TABLE NamHoc (
    MaNamHoc        INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenNamHoc       NVARCHAR(100) NOT NULL,   -- 2024-2025
    NgayBatDau      DATE          NOT NULL,
    NgayKetThuc     DATE          NOT NULL,
    LaNamHienTai    BIT           NOT NULL DEFAULT 0,
    CONSTRAINT UQ_NamHoc UNIQUE (MaTruong, TenNamHoc)
);
GO

CREATE TABLE HocKy (
    MaHocKy         INT IDENTITY(1,1) PRIMARY KEY,
    MaNamHoc        INT           NOT NULL REFERENCES NamHoc(MaNamHoc),
    TenHocKy        NVARCHAR(100) NOT NULL,
    ThuTu           INT           NOT NULL DEFAULT 1,  -- HK1 / HK2 / HK3 / Hè
    NgayBatDau      DATE          NOT NULL,
    NgayKetThuc     DATE          NOT NULL,
    NgayMoDangKy    DATE,
    NgayDongDangKy  DATE,
    LaHocKyHienTai  BIT           NOT NULL DEFAULT 0,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'LapKe',
    -- LapKe / DangKy / DangHoc / ChamDiem / DaDong
    CONSTRAINT UQ_HocKy UNIQUE (MaNamHoc, TenHocKy)
);
GO

-- Cập nhật FK LichSuTrangThaiSV
ALTER TABLE LichSuTrangThaiSV ADD CONSTRAINT FK_LichSu_HocKy FOREIGN KEY (MaHocKy) REFERENCES HocKy(MaHocKy);
GO

CREATE TABLE TuanHoc (
    MaTuanHoc       INT IDENTITY(1,1) PRIMARY KEY,
    MaHocKy         INT           NOT NULL REFERENCES HocKy(MaHocKy),
    SoTuan          INT           NOT NULL,
    NgayBatDau      DATE          NOT NULL,
    NgayKetThuc     DATE          NOT NULL,
    LoaiTuan        NVARCHAR(50)  DEFAULT N'HocLyThuyet',
    -- HocLyThuyet / Thi / NghiLe / OntapKiemTra
    GhiChu          NVARCHAR(500),
    CONSTRAINT UQ_TuanHoc UNIQUE (MaHocKy, SoTuan)
);
GO

-- 3.1 Chương trình đào tạo
CREATE TABLE ChuongTrinhDaoTao (
    MaCTDT          INT IDENTITY(1,1) PRIMARY KEY,
    MaNganh         INT           NOT NULL REFERENCES Nganh(MaNganh),
    MaCTDTCode      NVARCHAR(50)  NOT NULL,
    TenCTDT         NVARCHAR(300) NOT NULL,
    NamApDung       INT           NOT NULL,
    TongTinChi      INT           NOT NULL,
    MoTa            NVARCHAR(MAX),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'BanNhap',
    -- BanNhap / DangApDung / HetHieuLuc
    NguoiPheDuyet   INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayPheDuyet    DATETIME2,
    NguoiTao        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_CTDT UNIQUE (MaNganh, MaCTDTCode)
);
GO

-- Chuẩn đầu ra chương trình (PLO)
CREATE TABLE ChuanDauRaChuongTrinh (
    MaCDRCT         INT IDENTITY(1,1) PRIMARY KEY,
    MaCTDT          INT           NOT NULL REFERENCES ChuongTrinhDaoTao(MaCTDT),
    MaCDRCode       NVARCHAR(20)  NOT NULL,   -- PLO1, PLO2...
    MoTa            NVARCHAR(1000) NOT NULL,
    NhomNangLuc     NVARCHAR(100),            -- KienThuc / KyNang / ThaiBo
    ThuTu           INT           NOT NULL DEFAULT 0,
    CONSTRAINT UQ_CDR_CT UNIQUE (MaCTDT, MaCDRCode)
);
GO

-- 3.2 Học phần (Môn học)
CREATE TABLE HocPhan (
    MaHocPhan       INT IDENTITY(1,1) PRIMARY KEY,
    MaBoMon         INT           NOT NULL REFERENCES BoMon(MaBoMon),
    MaHocPhanCode   NVARCHAR(20)  NOT NULL UNIQUE,
    TenHocPhan      NVARCHAR(300) NOT NULL,
    TenTiengAnh     NVARCHAR(300),
    SoTinChi        INT           NOT NULL DEFAULT 3,
    SoTietLyThuyet  INT           NOT NULL DEFAULT 0,
    SoTietThucHanh  INT           NOT NULL DEFAULT 0,
    SoTietTuHoc     INT           NOT NULL DEFAULT 0,
    LoaiHocPhan     NVARCHAR(50)  NOT NULL DEFAULT N'BatBuoc',
    -- BatBuoc / TuChon / TuChonDinhHuong
    LaMonTuChon     BIT           NOT NULL DEFAULT 0,
    MoTa            NVARCHAR(MAX),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_HocPhan_BoMon ON HocPhan(MaBoMon);
GO

-- Điều kiện tiên quyết
CREATE TABLE DieuKienTienQuyet (
    MaDKTQ          INT IDENTITY(1,1) PRIMARY KEY,
    MaHocPhan       INT           NOT NULL REFERENCES HocPhan(MaHocPhan),
    MaHocPhanTienQuyet INT        NOT NULL REFERENCES HocPhan(MaHocPhan),
    LoaiDieuKien    NVARCHAR(50)  NOT NULL DEFAULT N'BatBuoc',
    -- BatBuoc / KhuyenCao / SongHanh
    CONSTRAINT UQ_DKTQ UNIQUE (MaHocPhan, MaHocPhanTienQuyet)
);
GO

-- Đề cương môn học
CREATE TABLE DeCuong (
    MaDeCuong       INT IDENTITY(1,1) PRIMARY KEY,
    MaHocPhan       INT           NOT NULL REFERENCES HocPhan(MaHocPhan),
    PhienBan        NVARCHAR(20)  NOT NULL DEFAULT '1.0',
    MucTieu         NVARCHAR(MAX),
    TongQuan        NVARCHAR(MAX),
    PhuongPhapGiangDay NVARCHAR(MAX),
    KeHoachDanhGia  NVARCHAR(MAX),           -- JSON: cơ cấu điểm số
    TaiLieuThamKhao NVARCHAR(MAX),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'BanNhap',
    NguoiPheDuyet   INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayPheDuyet    DATETIME2,
    NguoiTao        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_DeCuong UNIQUE (MaHocPhan, PhienBan)
);
GO

-- Chuẩn đầu ra học phần (CLO)
CREATE TABLE ChuanDauRaHocPhan (
    MaCDRHP         INT IDENTITY(1,1) PRIMARY KEY,
    MaDeCuong       INT           NOT NULL REFERENCES DeCuong(MaDeCuong),
    MaCLOCode       NVARCHAR(20)  NOT NULL,   -- CLO1, CLO2...
    MoTa            NVARCHAR(1000) NOT NULL,
    MucDoBloom      NVARCHAR(50),
    -- NhoLai / HieuBiet / VanDung / PhanTich / DanhGia / SangTao
    ThuTu           INT           NOT NULL DEFAULT 0,
    CONSTRAINT UQ_CLO UNIQUE (MaDeCuong, MaCLOCode)
);
GO

-- Ánh xạ CLO → PLO
CREATE TABLE AnhXaCLO_PLO (
    MaAnhXa         INT IDENTITY(1,1) PRIMARY KEY,
    MaCDRHP         INT           NOT NULL REFERENCES ChuanDauRaHocPhan(MaCDRHP),
    MaCDRCT         INT           NOT NULL REFERENCES ChuanDauRaChuongTrinh(MaCDRCT),
    MucDoTuongQuan  NVARCHAR(10)  DEFAULT N'Cao',  -- Cao / TrungBinh / Thap
    CONSTRAINT UQ_AnhXa UNIQUE (MaCDRHP, MaCDRCT)
);
GO

-- Học phần trong CTĐT
CREATE TABLE HocPhanTrongCTDT (
    MaHPCTDT        INT IDENTITY(1,1) PRIMARY KEY,
    MaCTDT          INT           NOT NULL REFERENCES ChuongTrinhDaoTao(MaCTDT),
    MaHocPhan       INT           NOT NULL REFERENCES HocPhan(MaHocPhan),
    NhomHocPhan     NVARCHAR(100),
    -- DaiCuong / CoSoNganh / ChuyenNganh / TotNghiep / GiaoDucTheChatQuocPhong
    LaBatBuoc       BIT           NOT NULL DEFAULT 1,
    HocKyDeNghi     INT,
    MaHocPhanThayThe INT          REFERENCES HocPhan(MaHocPhan),
    ThuTu           INT           NOT NULL DEFAULT 0,
    CONSTRAINT UQ_HP_CTDT UNIQUE (MaCTDT, MaHocPhan)
);
GO

-- 3.3 Lớp hành chính
CREATE TABLE LopHanhChinh (
    MaLopHC         INT IDENTITY(1,1) PRIMARY KEY,
    MaNganh         INT           NOT NULL REFERENCES Nganh(MaNganh),
    MaCoSo          INT           REFERENCES CoSo(MaCoSo),
    TenLop          NVARCHAR(100) NOT NULL,
    MaLopCode       NVARCHAR(50)  NOT NULL UNIQUE,
    NienKhoa        NVARCHAR(20)  NOT NULL,
    MaCoVanHocTap   INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    SiSoToiDa       INT           NOT NULL DEFAULT 50,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    NamBatDau       INT,
    NamDuKienTotNghiep INT,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Cập nhật FK HoSoSinhVien
ALTER TABLE HoSoSinhVien ADD CONSTRAINT FK_SinhVien_LopHC FOREIGN KEY (MaLopHanhChinh) REFERENCES LopHanhChinh(MaLopHC);
GO

CREATE TABLE LopHC_SinhVien (
    MaLopHC_SV      INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaLopHC         INT           NOT NULL REFERENCES LopHanhChinh(MaLopHC),
    NgayVaoLop      DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    NgayRoiLop      DATE,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    CONSTRAINT UQ_LopHC_SV UNIQUE (MaHoSoSV, MaLopHC)
);
GO

-- 3.4 Lớp học phần
CREATE TABLE LopHocPhan (
    MaLopHP         INT IDENTITY(1,1) PRIMARY KEY,
    MaHocPhan       INT           NOT NULL REFERENCES HocPhan(MaHocPhan),
    MaHocKy         INT           NOT NULL REFERENCES HocKy(MaHocKy),
    MaDeCuong       INT           REFERENCES DeCuong(MaDeCuong),
    MaCoSo          INT           REFERENCES CoSo(MaCoSo),
    MaLopHPCode     NVARCHAR(50)  NOT NULL,
    TenLop          NVARCHAR(200),
    SiSoToiThieu    INT           NOT NULL DEFAULT 5,
    SiSoToiDa       INT           NOT NULL DEFAULT 50,
    PhongHoc        NVARCHAR(100),
    LoaiLop         NVARCHAR(50)  NOT NULL DEFAULT N'ChinhQuy',
    -- ChinhQuy / ThucHanh / TrucTuyen / HybRid / HocLai / CaiThien
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'MoDangKy',
    -- MoDangKy / DayDu / DaDong / DaHuy / DangHoc / DaHoanThanh
    MoDangKy        BIT           NOT NULL DEFAULT 1,
    DanhSachChoEnabled BIT        NOT NULL DEFAULT 1,
    SoChoToiDaDanhSachCho INT     NOT NULL DEFAULT 10,
    DaDuaRaDiem     BIT           NOT NULL DEFAULT 0,
    NgayDuaRaDiem   DATETIME2,
    NguoiTao        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_LopHocPhan UNIQUE (MaHocPhan, MaHocKy, MaLopHPCode)
);
GO

CREATE INDEX IX_LopHP_HocKy   ON LopHocPhan(MaHocKy);
CREATE INDEX IX_LopHP_HocPhan ON LopHocPhan(MaHocPhan);
GO

-- Cập nhật FK PhanCongTroGiang
ALTER TABLE PhanCongTroGiang ADD CONSTRAINT FK_TroGiang_LopHP FOREIGN KEY (MaLopHocPhan) REFERENCES LopHocPhan(MaLopHP);
GO

-- Giảng viên phụ trách lớp học phần
CREATE TABLE GiangVien_LopHocPhan (
    MaGV_LopHP      INT IDENTITY(1,1) PRIMARY KEY,
    MaLopHP         INT           NOT NULL REFERENCES LopHocPhan(MaLopHP),
    MaHoSoGV        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    VaiTroDayHoc    NVARCHAR(50)  NOT NULL DEFAULT N'GiangVienChinh',
    -- GiangVienChinh / GiangVienPhu / TroGiang
    NgayPhanCong    DATETIME2     NOT NULL DEFAULT GETDATE(),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    CONSTRAINT UQ_GV_LopHP UNIQUE (MaLopHP, MaHoSoGV)
);
GO

-- Lịch học
CREATE TABLE LichHoc (
    MaLichHoc       INT IDENTITY(1,1) PRIMARY KEY,
    MaLopHP         INT           NOT NULL REFERENCES LopHocPhan(MaLopHP),
    MaTuanHoc       INT           REFERENCES TuanHoc(MaTuanHoc),
    ThuTrongTuan    TINYINT       NOT NULL,   -- 2=Thứ 2 ... 8=CN
    GioBatDau       TIME          NOT NULL,
    GioKetThuc      TIME          NOT NULL,
    PhongHoc        NVARCHAR(100),
    CoSo            NVARCHAR(200),
    LoaiBuoiHoc     NVARCHAR(50)  NOT NULL DEFAULT N'LyThuyet',
    -- LyThuyet / ThucHanh / TrucTuyen / BuHoc
    NgayHocCuThe    DATE,                     -- Cho buổi học đặc biệt/bù
    LinkHopTrucTuyen NVARCHAR(500),
    GhiChu          NVARCHAR(500),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_LichHoc_LopHP ON LichHoc(MaLopHP);
GO

-- Đăng ký học phần
CREATE TABLE DangKyHocPhan (
    MaDangKy        INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaLopHP         INT           NOT NULL REFERENCES LopHocPhan(MaLopHP),
    LoaiDangKy      NVARCHAR(50)  NOT NULL DEFAULT N'BinhThuong',
    -- BinhThuong / HocLai / CaiThien / DuThinh
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DaDangKy',
    -- DaDangKy / DanhSachCho / DaRut / HoanThanh / TruotMon
    NgayDangKy      DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayRut         DATETIME2,
    LyDoRut         NVARCHAR(500),
    ViTriDanhSachCho INT,
    NguoiDangKy     INT           REFERENCES HoSoNhanVien(MaHoSoNV),  -- NULL nếu SV tự đăng
    CONSTRAINT UQ_DangKy UNIQUE (MaHoSoSV, MaLopHP)
);
GO

CREATE INDEX IX_DangKy_SinhVien ON DangKyHocPhan(MaHoSoSV);
CREATE INDEX IX_DangKy_LopHP    ON DangKyHocPhan(MaLopHP);
GO

-- 3.5 Điểm danh
CREATE TABLE BuoiDiemDanh (
    MaBuoiDD        INT IDENTITY(1,1) PRIMARY KEY,
    MaLopHP         INT           NOT NULL REFERENCES LopHocPhan(MaLopHP),
    MaLichHoc       INT           REFERENCES LichHoc(MaLichHoc),
    NgayDiemDanh    DATE          NOT NULL,
    GioBatDau       TIME          NOT NULL,
    GioKetThuc      TIME,
    SoBuoi          INT           NOT NULL,
    HinhThucDiemDanh NVARCHAR(50) NOT NULL DEFAULT N'ThuCong',
    -- ThuCong / MaQR / NhanDienKhuonMat / LopAo
    MaBuoiHopAo     NVARCHAR(200),
    NguoiDiemDanh   INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    DaHoanThanh     BIT           NOT NULL DEFAULT 0,
    NgayHoanThanh   DATETIME2,
    GhiChu          NVARCHAR(500),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_BuoiDD_LopHP   ON BuoiDiemDanh(MaLopHP);
CREATE INDEX IX_BuoiDD_Ngay    ON BuoiDiemDanh(NgayDiemDanh);
GO

CREATE TABLE ChiTietDiemDanh (
    MaChiTietDD     INT IDENTITY(1,1) PRIMARY KEY,
    MaBuoiDD        INT           NOT NULL REFERENCES BuoiDiemDanh(MaBuoiDD),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    TrangThaiDiemDanh NVARCHAR(50) NOT NULL DEFAULT N'CóMat',
    -- CoMat / VangKhongPhep / VangCoPhep / DiMuon / VeSom
    GioCheckIn      DATETIME2,
    HinhThucCheckIn NVARCHAR(50),
    CoPhep          BIT           NOT NULL DEFAULT 0,
    LyDoVang        NVARCHAR(500),
    GiayToMinhChung NVARCHAR(500),
    NguoiCapNhat    INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayCapNhat     DATETIME2,
    CONSTRAINT UQ_ChiTietDD UNIQUE (MaBuoiDD, MaHoSoSV)
);
GO

CREATE INDEX IX_ChiTietDD_Buoi    ON ChiTietDiemDanh(MaBuoiDD);
CREATE INDEX IX_ChiTietDD_SinhVien ON ChiTietDiemDanh(MaHoSoSV);
GO

-- ============================================================
-- PHÂN HỆ 4: QUẢN LÝ KHOÁ HỌC & HỌC LIỆU
-- ============================================================

CREATE TABLE KhoaHocLMS (
    MaKhoaHocLMS    INT IDENTITY(1,1) PRIMARY KEY,
    MaLopHP         INT           NOT NULL REFERENCES LopHocPhan(MaLopHP) UNIQUE,
    TenKhoaHoc      NVARCHAR(300) NOT NULL,
    MoTaKhoaHoc     NVARCHAR(MAX),
    AnhBia          NVARCHAR(500),
    MaMauKhoaHoc    INT,                      -- FK → MauKhoaHoc
    PhamViHienThi   NVARCHAR(50)  NOT NULL DEFAULT N'ChiNguoiHoc',
    -- ChiNguoiHoc / NoiBoKhoa / NoiBoTruong / CongKhai
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    -- BanNhap / HoatDong / LuuTru
    QuyTacHoanThanhJSON NVARCHAR(MAX),
    NguoiTao        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE MauKhoaHoc (
    MaMau           INT IDENTITY(1,1) PRIMARY KEY,
    MaBoMon         INT           REFERENCES BoMon(MaBoMon),
    TenMau          NVARCHAR(200) NOT NULL,
    MoTa            NVARCHAR(MAX),
    CauTrucJSON     NVARCHAR(MAX) NOT NULL,
    NguoiTao        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    LaCongKhai      BIT           NOT NULL DEFAULT 0,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

ALTER TABLE KhoaHocLMS ADD CONSTRAINT FK_KhoaHoc_Mau FOREIGN KEY (MaMauKhoaHoc) REFERENCES MauKhoaHoc(MaMau);
GO

-- Chương / Module
CREATE TABLE ChuongHoc (
    MaChuong        INT IDENTITY(1,1) PRIMARY KEY,
    MaKhoaHocLMS    INT           NOT NULL REFERENCES KhoaHocLMS(MaKhoaHocLMS),
    MaChuongCha     INT           REFERENCES ChuongHoc(MaChuong),
    TenChuong       NVARCHAR(300) NOT NULL,
    MoTa            NVARCHAR(MAX),
    ThuTu           INT           NOT NULL DEFAULT 0,
    SoTuan          INT,
    HienThi         BIT           NOT NULL DEFAULT 1,
    -- Điều kiện mở khoá
    LoaiDieuKienMo  NVARCHAR(50),
    -- LucNao / SauNgay / SauChuong / SauDiem
    MoSauChuongID   INT           REFERENCES ChuongHoc(MaChuong),
    MoSauNgay       DATE,
    MoSauDiem       DECIMAL(5,2),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_ChuongHoc_KhoaHoc ON ChuongHoc(MaKhoaHocLMS);
GO

-- Học liệu
CREATE TABLE HocLieu (
    MaHocLieu       INT IDENTITY(1,1) PRIMARY KEY,
    MaChuong        INT           NOT NULL REFERENCES ChuongHoc(MaChuong),
    MaKhoaHocLMS    INT           NOT NULL REFERENCES KhoaHocLMS(MaKhoaHocLMS),
    TieuDe          NVARCHAR(300) NOT NULL,
    LoaiHocLieu     NVARCHAR(50)  NOT NULL,
    -- Video / PDF / BaiGiang / Audio / TaiLieu / LienKet / H5P / SCORM / NhungVao
    DuongDanFile    NVARCHAR(1000),
    KichThuocFile   BIGINT,
    KieuMIME        NVARCHAR(100),
    ThoiLuongGiay   INT,                      -- Cho video/audio
    CoPhuDe         BIT           NOT NULL DEFAULT 0,
    DuongDanPhuDe   NVARCHAR(500),
    DuongDanBanPhai NVARCHAR(500),
    AnhThumbnail    NVARCHAR(500),
    DanhSachChuongJSON NVARCHAR(MAX),          -- JSON: chapter video
    ChoPhepTai      BIT           NOT NULL DEFAULT 0,
    ThuTu           INT           NOT NULL DEFAULT 0,
    HienThi         BIT           NOT NULL DEFAULT 1,
    -- Điều kiện mở khoá
    LoaiDieuKienMo  NVARCHAR(50),
    MoSauHocLieuID  INT           REFERENCES HocLieu(MaHocLieu),
    MoSauNgay       DATE,
    LuotXem         INT           NOT NULL DEFAULT 0,
    MaHocLieuThuVien INT,                     -- Liên kết kho chung
    MaCDRHP         INT           REFERENCES ChuanDauRaHocPhan(MaCDRHP),
    NguoiTao        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_HocLieu_Chuong   ON HocLieu(MaChuong);
CREATE INDEX IX_HocLieu_KhoaHoc  ON HocLieu(MaKhoaHocLMS);
GO

-- Kho học liệu dùng chung
CREATE TABLE ThuVienHocLieu (
    MaThuVien       INT IDENTITY(1,1) PRIMARY KEY,
    MaBoMon         INT           REFERENCES BoMon(MaBoMon),
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TieuDe          NVARCHAR(300) NOT NULL,
    MoTa            NVARCHAR(MAX),
    LoaiHocLieu     NVARCHAR(50)  NOT NULL,
    DuongDanFile    NVARCHAR(1000) NOT NULL,
    KichThuocFile   BIGINT,
    KieuMIME        NVARCHAR(100),
    TuKhoa          NVARCHAR(500),
    PhamViXem       NVARCHAR(50)  NOT NULL DEFAULT N'BoMon',
    -- BoMon / Khoa / Truong
    LuotTai         INT           NOT NULL DEFAULT 0,
    NguoiDang       INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Cập nhật FK HocLieu
ALTER TABLE HocLieu ADD CONSTRAINT FK_HocLieu_ThuVien FOREIGN KEY (MaHocLieuThuVien) REFERENCES ThuVienHocLieu(MaThuVien);
GO

-- Tiến độ xem học liệu
CREATE TABLE TienDoHocLieu (
    MaTienDo        INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaHocLieu       INT           NOT NULL REFERENCES HocLieu(MaHocLieu),
    GiayDaXem       INT           NOT NULL DEFAULT 0,
    DaHoanThanh     BIT           NOT NULL DEFAULT 0,
    PhanTramHoanThanh DECIMAL(5,2) NOT NULL DEFAULT 0,
    ViTriCuoiGiay   INT           NOT NULL DEFAULT 0,
    LanXemDauTien   DATETIME2,
    LanXemCuoiCung  DATETIME2,
    SoLanXem        INT           NOT NULL DEFAULT 0,
    CONSTRAINT UQ_TienDoHL UNIQUE (MaHoSoSV, MaHocLieu)
);
GO

CREATE INDEX IX_TienDoHL_SinhVien ON TienDoHocLieu(MaHoSoSV);
CREATE INDEX IX_TienDoHL_HocLieu  ON TienDoHocLieu(MaHocLieu);
GO

-- ============================================================
-- PHÂN HỆ 5: BÀI TẬP – KIỂM TRA – THI CỬ
-- ============================================================

-- 5.1 Ngân hàng câu hỏi
CREATE TABLE NganHangCauHoi (
    MaNganHang      INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoGV        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    MaBoMon         INT           REFERENCES BoMon(MaBoMon),
    TenNganHang     NVARCHAR(200) NOT NULL,
    MoTa            NVARCHAR(MAX),
    ChiaSeSe        BIT           NOT NULL DEFAULT 0,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE DanhMucCauHoi (
    MaDanhMuc       INT IDENTITY(1,1) PRIMARY KEY,
    MaNganHang      INT           NOT NULL REFERENCES NganHangCauHoi(MaNganHang),
    MaDanhMucCha    INT           REFERENCES DanhMucCauHoi(MaDanhMuc),
    TenDanhMuc      NVARCHAR(200) NOT NULL,
    MaCDRHP         INT           REFERENCES ChuanDauRaHocPhan(MaCDRHP),
    ThuTu           INT           NOT NULL DEFAULT 0
);
GO

CREATE TABLE CauHoi (
    MaCauHoi        INT IDENTITY(1,1) PRIMARY KEY,
    MaNganHang      INT           NOT NULL REFERENCES NganHangCauHoi(MaNganHang),
    MaDanhMuc       INT           REFERENCES DanhMucCauHoi(MaDanhMuc),
    MaCDRHP         INT           REFERENCES ChuanDauRaHocPhan(MaCDRHP),
    LoaiCauHoi      NVARCHAR(50)  NOT NULL,
    -- TracNghiem / DungSai / DienKhuyet / GhepCap / TuLuan
    -- KeoTha / DiemNong / ThamSoHoa / LapTrinh / TranKetSQL / MoPhong
    MucDo           NVARCHAR(20)  NOT NULL DEFAULT N'TrungBinh',
    -- DeDang / TrungBinh / KhoHon / RatKho
    NoiDungCauHoi   NVARCHAR(MAX) NOT NULL,
    NoiDungHTML     NVARCHAR(MAX),
    DuongDanHinh    NVARCHAR(500),
    DuongDanAm      NVARCHAR(500),
    DuongDanVideo   NVARCHAR(500),
    DiemMacDinh     DECIMAL(5,2)  NOT NULL DEFAULT 1,
    GiaiThich       NVARCHAR(MAX),
    ThamSoJSON      NVARCHAR(MAX),            -- Cho câu hỏi tham số hóa
    TestCaseJSON    NVARCHAR(MAX),            -- Cho câu hỏi lập trình
    GioiHanGiay     INT,
    TuKhoa          NVARCHAR(500),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    SoLanDuocDung   INT           NOT NULL DEFAULT 0,
    NguoiTao        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_CauHoi_NganHang ON CauHoi(MaNganHang);
CREATE INDEX IX_CauHoi_Loai     ON CauHoi(LoaiCauHoi);
CREATE INDEX IX_CauHoi_MucDo    ON CauHoi(MucDo);
GO

CREATE TABLE DapAnCauHoi (
    MaDapAn         INT IDENTITY(1,1) PRIMARY KEY,
    MaCauHoi        INT           NOT NULL REFERENCES CauHoi(MaCauHoi),
    NoiDungDapAn    NVARCHAR(MAX) NOT NULL,
    NoiDungHTML     NVARCHAR(MAX),
    LaDapAnDung     BIT           NOT NULL DEFAULT 0,
    DiemTungPhan    DECIMAL(5,2),
    KhoaGhepCap     NVARCHAR(200),
    ThuTu           INT           NOT NULL DEFAULT 0,
    PhanHoiRieng    NVARCHAR(1000)
);
GO

CREATE INDEX IX_DapAn_CauHoi ON DapAnCauHoi(MaCauHoi);
GO

-- 5.2 Thang điểm rubric
CREATE TABLE ThangDiemRubric (
    MaRubric        INT IDENTITY(1,1) PRIMARY KEY,
    NguoiTao        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    TenRubric       NVARCHAR(200) NOT NULL,
    MoTa            NVARCHAR(MAX),
    LaMau           BIT           NOT NULL DEFAULT 0,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE TieuChiRubric (
    MaTieuChi       INT IDENTITY(1,1) PRIMARY KEY,
    MaRubric        INT           NOT NULL REFERENCES ThangDiemRubric(MaRubric),
    TenTieuChi      NVARCHAR(200) NOT NULL,
    MoTa            NVARCHAR(1000),
    DiemToiDa       DECIMAL(7,2)  NOT NULL,
    ThuTu           INT           NOT NULL DEFAULT 0
);
GO

CREATE TABLE MucDatRubric (
    MaMucDat        INT IDENTITY(1,1) PRIMARY KEY,
    MaTieuChi       INT           NOT NULL REFERENCES TieuChiRubric(MaTieuChi),
    TenMuc          NVARCHAR(100) NOT NULL,
    MoTa            NVARCHAR(1000),
    DiemMuc         DECIMAL(7,2)  NOT NULL,
    ThuTu           INT           NOT NULL DEFAULT 0
);
GO

-- 5.3 Bài tập
CREATE TABLE BaiTap (
    MaBaiTap        INT IDENTITY(1,1) PRIMARY KEY,
    MaKhoaHocLMS    INT           NOT NULL REFERENCES KhoaHocLMS(MaKhoaHocLMS),
    MaChuong        INT           REFERENCES ChuongHoc(MaChuong),
    MaCDRHP         INT           REFERENCES ChuanDauRaHocPhan(MaCDRHP),
    TieuDe          NVARCHAR(300) NOT NULL,
    HuongDan        NVARCHAR(MAX),
    LoaiBaiTap      NVARCHAR(50)  NOT NULL DEFAULT N'NopFile',
    -- NopFile / NopVanBan / NopLink / NopVideo / NopCode / NhomBaiTap / Bai TapQuiz
    KieuNopBai      NVARCHAR(MAX) NOT NULL DEFAULT N'["NopFile"]',
    -- JSON: NopFile/VanBan/Link/Video/CodeRepo
    DiemToiDa       DECIMAL(7,2)  NOT NULL DEFAULT 100,
    DiemDatMon      DECIMAL(7,2),
    ChoPhepNopNhieuLan BIT        NOT NULL DEFAULT 0,
    SoLanNopToiDa   INT           NOT NULL DEFAULT 1,
    NgayMo          DATETIME2,
    HanNop          DATETIME2,
    ChoPhepNopTre   BIT           NOT NULL DEFAULT 0,
    LoaiPhatNopTre  NVARCHAR(50),            -- PhanTram / SoDiem / Zero
    MucPhatNopTre   DECIMAL(5,2),
    HanNopTre       DATETIME2,
    LaBaiNhom       BIT           NOT NULL DEFAULT 0,
    SoThanhVienNhomToiDa INT,
    CachChiaThanhVien NVARCHAR(50),          -- ThuCong / NgauNhien / SinhVienChon
    BatDanhGiaDongDang BIT        NOT NULL DEFAULT 0,
    HanDanhGiaDongDang DATETIME2,
    MaRubric        INT           REFERENCES ThangDiemRubric(MaRubric),
    HienThi         BIT           NOT NULL DEFAULT 1,
    ThuTu           INT           NOT NULL DEFAULT 0,
    NguoiTao        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_BaiTap_KhoaHoc ON BaiTap(MaKhoaHocLMS);
GO

-- Nhóm bài tập
CREATE TABLE NhomBaiTap (
    MaNhom          INT IDENTITY(1,1) PRIMARY KEY,
    MaBaiTap        INT           NOT NULL REFERENCES BaiTap(MaBaiTap),
    TenNhom         NVARCHAR(200),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE ThanhVienNhom (
    MaThanhVien     INT IDENTITY(1,1) PRIMARY KEY,
    MaNhom          INT           NOT NULL REFERENCES NhomBaiTap(MaNhom),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    VaiTro          NVARCHAR(50)  NOT NULL DEFAULT N'ThanhVien',
    -- NhomTruong / ThanhVien
    PhanTramDongGop DECIMAL(5,2),
    CONSTRAINT UQ_ThanhVienNhom UNIQUE (MaNhom, MaHoSoSV)
);
GO

-- Nộp bài
CREATE TABLE BaiNopSinhVien (
    MaBaiNop        INT IDENTITY(1,1) PRIMARY KEY,
    MaBaiTap        INT           NOT NULL REFERENCES BaiTap(MaBaiTap),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaNhom          INT           REFERENCES NhomBaiTap(MaNhom),
    LanNopThuBao    INT           NOT NULL DEFAULT 1,
    KieuNopBai      NVARCHAR(50)  NOT NULL,
    NoiDungVanBan   NVARCHAR(MAX),
    DuongDanLink    NVARCHAR(1000),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'BanNhap',
    -- BanNhap / DaNop / NopTre / DaCham / DaTraLai / CanNopLai
    NopTre          BIT           NOT NULL DEFAULT 0,
    NgayNop         DATETIME2,
    Diem            DECIMAL(7,2),
    DiemToiDa       DECIMAL(7,2),
    NguoiCham       INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayCham        DATETIME2,
    NhanXet         NVARCHAR(MAX),
    DiemRubricJSON  NVARCHAR(MAX),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_BaiNop_BaiTap   ON BaiNopSinhVien(MaBaiTap);
CREATE INDEX IX_BaiNop_SinhVien ON BaiNopSinhVien(MaHoSoSV);
GO

CREATE TABLE FileBaiNop (
    MaFile          INT IDENTITY(1,1) PRIMARY KEY,
    MaBaiNop        INT           NOT NULL REFERENCES BaiNopSinhVien(MaBaiNop),
    TenFile         NVARCHAR(300) NOT NULL,
    DuongDanFile    NVARCHAR(1000) NOT NULL,
    KichThuocFile   BIGINT,
    KieuMIME        NVARCHAR(100),
    NgayTai         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Đánh giá đồng đẳng (Peer Review)
CREATE TABLE DanhGiaDongDang (
    MaDanhGia       INT IDENTITY(1,1) PRIMARY KEY,
    MaBaiTap        INT           NOT NULL REFERENCES BaiTap(MaBaiTap),
    NguoiDanhGia    INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    NguoiDuocDG     INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaBaiNop        INT           NOT NULL REFERENCES BaiNopSinhVien(MaBaiNop),
    Diem            DECIMAL(7,2),
    DiemRubricJSON  NVARCHAR(MAX),
    NhanXet         NVARCHAR(MAX),
    AnDanh          BIT           NOT NULL DEFAULT 1,
    NgayNop         DATETIME2,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'ChoDanhGia',
    CONSTRAINT UQ_DG_DongDang UNIQUE (MaBaiTap, NguoiDanhGia, NguoiDuocDG)
);
GO

-- 5.4 Đề thi
CREATE TABLE DeThi (
    MaDeThi         INT IDENTITY(1,1) PRIMARY KEY,
    MaKhoaHocLMS    INT           REFERENCES KhoaHocLMS(MaKhoaHocLMS),
    MaBaiTap        INT           REFERENCES BaiTap(MaBaiTap),
    TieuDeDe        NVARCHAR(300) NOT NULL,
    LoaiDe          NVARCHAR(50)  NOT NULL DEFAULT N'GiuaKy',
    -- GiuaKy / CuoiKy / KiemTraNhanh / LuyenTap / ThiLai
    HuongDan        NVARCHAR(MAX),
    TongDiem        DECIMAL(7,2)  NOT NULL DEFAULT 100,
    GioiHanPhut     INT           NOT NULL DEFAULT 60,
    SoLanToiDa      INT           NOT NULL DEFAULT 1,
    XaoTronCauHoi   BIT           NOT NULL DEFAULT 1,
    XaoTronDapAn    BIT           NOT NULL DEFAULT 1,
    HienThiKetQua   BIT           NOT NULL DEFAULT 0,
    HienThiDapAn    BIT           NOT NULL DEFAULT 0,
    -- Bảo mật thi
    KhoaTrinhDuyet  BIT           NOT NULL DEFAULT 0,
    GioiHanTab      BIT           NOT NULL DEFAULT 0,
    GiamSatThi      BIT           NOT NULL DEFAULT 0,
    LoaiGiamSat     NVARCHAR(50),            -- Webcam / AI / ManHinh
    GhiManHinh      BIT           NOT NULL DEFAULT 0,
    DanhSachIPChophep NVARCHAR(1000),
    YeuCauMatKhau   BIT           NOT NULL DEFAULT 0,
    MatKhauThi      NVARCHAR(100),
    DiemDat         DECIMAL(7,2),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'BanNhap',
    -- BanNhap / DaDang / DangThi / DaDong
    NguoiTao        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Phòng thi & Ca thi
CREATE TABLE PhongThi (
    MaPhongThi      INT IDENTITY(1,1) PRIMARY KEY,
    MaDeThi         INT           NOT NULL REFERENCES DeThi(MaDeThi),
    TenPhong        NVARCHAR(200) NOT NULL,
    ThoiGianBatDau  DATETIME2     NOT NULL,
    ThoiGianKetThuc DATETIME2     NOT NULL,
    SoThiSinhToiDa  INT           NOT NULL DEFAULT 50,
    GiamThiChinh    INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DaLenLich',
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE DanhSachThiSinh (
    MaThiSinh       INT IDENTITY(1,1) PRIMARY KEY,
    MaPhongThi      INT           NOT NULL REFERENCES PhongThi(MaPhongThi),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    SoGheNgoi       NVARCHAR(20),
    CONSTRAINT UQ_ThiSinh UNIQUE (MaPhongThi, MaHoSoSV)
);
GO

-- Phần thi & Câu hỏi trong đề
CREATE TABLE PhanDeThi (
    MaPhan          INT IDENTITY(1,1) PRIMARY KEY,
    MaDeThi         INT           NOT NULL REFERENCES DeThi(MaDeThi),
    TenPhan         NVARCHAR(200),
    HuongDan        NVARCHAR(MAX),
    TongDiem        DECIMAL(7,2)  NOT NULL DEFAULT 0,
    ThuTu           INT           NOT NULL DEFAULT 0
);
GO

CREATE TABLE CauHoiTrongDe (
    MaCHDE          INT IDENTITY(1,1) PRIMARY KEY,
    MaPhan          INT           NOT NULL REFERENCES PhanDeThi(MaPhan),
    MaDeThi         INT           NOT NULL REFERENCES DeThi(MaDeThi),
    MaCauHoi        INT           REFERENCES CauHoi(MaCauHoi),
    -- NULL nếu lấy ngẫu nhiên từ pool
    LayNgauNhienTuDanhMuc INT     REFERENCES DanhMucCauHoi(MaDanhMuc),
    MucDoNgauNhien  NVARCHAR(20),
    Diem            DECIMAL(5,2)  NOT NULL DEFAULT 1,
    ThuTu           INT           NOT NULL DEFAULT 0,
    BatBuocLamBai   BIT           NOT NULL DEFAULT 1
);
GO

-- Bài làm thi của sinh viên
CREATE TABLE BaiLamThi (
    MaBaiLam        INT IDENTITY(1,1) PRIMARY KEY,
    MaDeThi         INT           NOT NULL REFERENCES DeThi(MaDeThi),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaPhongThi      INT           REFERENCES PhongThi(MaPhongThi),
    LanThiBaoNhieu  INT           NOT NULL DEFAULT 1,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DangLam',
    -- DangLam / DaNop / DaCham / BiHuy
    BatDauLuc       DATETIME2     NOT NULL DEFAULT GETDATE(),
    NopLuc          DATETIME2,
    ThoiGianLamBaiGiay INT,
    DiaChiIP        NVARCHAR(50),
    ThietBi         NVARCHAR(500),
    TongDiem        DECIMAL(7,2),
    DiemToiDa       DECIMAL(7,2),
    DaChamTuDong    BIT           NOT NULL DEFAULT 0,
    NguoiKiemTraLai INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    DauHieuBatThuongJSON NVARCHAR(MAX),
    SoLanMatKetNoi  INT           NOT NULL DEFAULT 0,
    ThoiGianBuThem  INT           NOT NULL DEFAULT 0,
    CONSTRAINT UQ_BaiLamThi UNIQUE (MaDeThi, MaHoSoSV, LanThiBaoNhieu)
);
GO

CREATE INDEX IX_BaiLamThi_DeThi  ON BaiLamThi(MaDeThi);
CREATE INDEX IX_BaiLamThi_SV     ON BaiLamThi(MaHoSoSV);
GO

-- Câu trả lời từng câu
CREATE TABLE TraLoiCauHoi (
    MaTraLoi        INT IDENTITY(1,1) PRIMARY KEY,
    MaBaiLam        INT           NOT NULL REFERENCES BaiLamThi(MaBaiLam),
    MaCHDE          INT           NOT NULL REFERENCES CauHoiTrongDe(MaCHDE),
    MaCauHoi        INT           NOT NULL REFERENCES CauHoi(MaCauHoi),
    DapAnChonJSON   NVARCHAR(MAX),           -- JSON: [1,3] cho trắc nghiệm
    BaiTuLuan       NVARCHAR(MAX),
    BaiCode         NVARCHAR(MAX),
    BaiLamJSON      NVARCHAR(MAX),           -- Cho dạng phức tạp
    TraLoiDung      BIT,
    Diem            DECIMAL(5,2),
    DiemToiDa       DECIMAL(5,2),
    NhanXetGiamKhao NVARCHAR(MAX),
    NguoiCham       INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayCham        DATETIME2,
    ThoiDiemTraLoi  DATETIME2,
    ThoiGianLamGiay INT,
    CONSTRAINT UQ_TraLoi UNIQUE (MaBaiLam, MaCHDE)
);
GO

-- Nhật ký thi
CREATE TABLE NhatKyThi (
    MaNhatKyThi     BIGINT IDENTITY(1,1) PRIMARY KEY,
    MaBaiLam        INT           NOT NULL REFERENCES BaiLamThi(MaBaiLam),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    LoaiSuKien      NVARCHAR(100) NOT NULL,
    -- BatDau / DaNop / ChuyenTab / DanPaste / MatFocus
    -- MatKetNoi / KetNoiLai / Camera / ManHinh
    DuLieuSuKien    NVARCHAR(MAX),
    DiaChiIP        NVARCHAR(50),
    ThoiDiem        DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_NhatKyThi_BaiLam ON NhatKyThi(MaBaiLam);
GO

-- ============================================================
-- PHÂN HỆ 6: SỔ ĐIỂM & PHÚC KHẢO
-- ============================================================

CREATE TABLE CauHinhDiem (
    MaCauHinhDiem   INT IDENTITY(1,1) PRIMARY KEY,
    MaLopHP         INT           NOT NULL REFERENCES LopHocPhan(MaLopHP) UNIQUE,
    ThangDiem       NVARCHAR(50)  NOT NULL DEFAULT N'10',
    -- 10 / 100 / 4.0 / ChuCai
    SoDoXepLoaiJSON NVARCHAR(MAX) NOT NULL,
    -- JSON: [{"tuDiem":8.5,"denDiem":10,"ChuCai":"A","DiemGPA":4.0},...]
    CauPhanDiemJSON NVARCHAR(MAX) NOT NULL,
    -- JSON: [{"Ten":"ChuyenCan","TrongSo":0.1},{"Ten":"QuaTr ình","TrongSo":0.3},{"Ten":"ThiCuoiKy","TrongSo":0.6}]
    DiemDatMon      DECIMAL(5,2)  NOT NULL DEFAULT 5.0,
    NguoiThietLap   INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Sổ điểm sinh viên theo lớp học phần
CREATE TABLE SoDiemSinhVien (
    MaSoDiem        INT IDENTITY(1,1) PRIMARY KEY,
    MaDangKy        INT           NOT NULL REFERENCES DangKyHocPhan(MaDangKy) UNIQUE,
    MaCauHinhDiem   INT           NOT NULL REFERENCES CauHinhDiem(MaCauHinhDiem),
    DiemChuyenCan   DECIMAL(5,2),
    DiemQuaTrinh    DECIMAL(5,2),
    DiemGiuaKy      DECIMAL(5,2),
    DiemCuoiKy      DECIMAL(5,2),
    DiemCong        DECIMAL(5,2)  DEFAULT 0,
    DiemTongKet     DECIMAL(5,2),
    XepLoai         NVARCHAR(5),             -- A+ / A / B+ / B / C+ / C / D+ / D / F
    DiemGPA         DECIMAL(3,2),
    DatMon          BIT,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'TamThoi',
    -- TamThoi / ChinhThuc / DangXetPhucKhao / DaSuaDoi
    ChiTietDiemJSON NVARCHAR(MAX),           -- JSON: chi tiết từng thành phần
    KetQuaCLOJSON   NVARCHAR(MAX),           -- JSON: mức đạt từng CLO
    NguoiNhapDiem   INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayNhap        DATETIME2,
    NguoiDuyetDiem  INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayDuyet       DATETIME2,
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_SoDiem_DangKy ON SoDiemSinhVien(MaDangKy);
GO

-- Lịch sử thay đổi điểm
CREATE TABLE LichSuThayDoisDiem (
    MaLichSuDiem    INT IDENTITY(1,1) PRIMARY KEY,
    MaSoDiem        INT           NOT NULL REFERENCES SoDiemSinhVien(MaSoDiem),
    NguoiThayDoi    INT           NOT NULL,   -- MaHoSoGV hoặc MaHoSoNV
    LoaiNguoiThayDoi NVARCHAR(20) NOT NULL,   -- GiangVien / NhanVien
    TruongThayDoi   NVARCHAR(100) NOT NULL,
    GiaTriCu        NVARCHAR(100),
    GiaTriMoi       NVARCHAR(100),
    LyDoThayDoi     NVARCHAR(500) NOT NULL,
    MaPhucKhaoLQ    INT,                      -- FK → PhucKhao
    ThoiGianThayDoi DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Phúc khảo điểm
CREATE TABLE PhucKhao (
    MaPhucKhao      INT IDENTITY(1,1) PRIMARY KEY,
    MaSoDiem        INT           NOT NULL REFERENCES SoDiemSinhVien(MaSoDiem),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    LyDoPhucKhao    NVARCHAR(MAX) NOT NULL,
    TaiLieuDinhKem  NVARCHAR(500),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'ChoXuLy',
    -- ChoXuLy / DangXuLy / ChapNhan / TuChoi
    NguoiXuLy       INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    KetQuaXuLy      NVARCHAR(MAX),
    DiemMoi         DECIMAL(5,2),
    NgayGuiYeuCau   DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayXuLy        DATETIME2,
    NgayDong        DATETIME2
);
GO

ALTER TABLE LichSuThayDoisDiem ADD CONSTRAINT FK_LSD_PhucKhao FOREIGN KEY (MaPhucKhaoLQ) REFERENCES PhucKhao(MaPhucKhao);
GO

-- ============================================================
-- PHÂN HỆ 7: GIAO TIẾP & CỘNG TÁC
-- ============================================================

CREATE TABLE ThongBao (
    MaThongBao      INT IDENTITY(1,1) PRIMARY KEY,
    LoaiNguoiGui    NVARCHAR(20)  NOT NULL,   -- GiangVien / NhanVien
    NguoiGuiGV      INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NguoiGuiNV      INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    TieuDe          NVARCHAR(500) NOT NULL,
    NoiDung         NVARCHAR(MAX) NOT NULL,
    PhamVi          NVARCHAR(50)  NOT NULL DEFAULT N'KhoaHoc',
    -- KhoaHoc / Khoa / Truong / HeThong
    MaPhamViTuong   INT,
    DoUuTien        NVARCHAR(20)  NOT NULL DEFAULT N'BinhThuong',
    NgayDang        DATETIME2,
    NgayHetHan      DATETIME2,
    DatLichDang     BIT           NOT NULL DEFAULT 0,
    ThoiGianDatLich DATETIME2,
    GuiPushNotif    BIT           NOT NULL DEFAULT 1,
    GuiEmail        BIT           NOT NULL DEFAULT 0,
    GuiSMS          BIT           NOT NULL DEFAULT 0,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE ThongBaoDaDoc (
    MaDoc           INT IDENTITY(1,1) PRIMARY KEY,
    MaThongBao      INT           NOT NULL REFERENCES ThongBao(MaThongBao),
    MaHoSoSV        INT           REFERENCES HoSoSinhVien(MaHoSoSV),
    MaHoSoGV        INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayDoc         DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_ThongBaoDoc_SV UNIQUE (MaThongBao, MaHoSoSV),
    CONSTRAINT UQ_ThongBaoDoc_GV UNIQUE (MaThongBao, MaHoSoGV)
);
GO

-- Thông báo đẩy cá nhân
CREATE TABLE ThongBaoCaNhan (
    MaTBCaNhan      BIGINT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           REFERENCES HoSoSinhVien(MaHoSoSV),
    MaHoSoGV        INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    MaHoSoNV        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    TieuDe          NVARCHAR(300) NOT NULL,
    NoiDung         NVARCHAR(1000) NOT NULL,
    LoaiThongBao    NVARCHAR(100) NOT NULL,
    -- HanNop / ThongBao / Diem / Forum / CuocHop / HeThong
    LoaiBanGhiLQ    NVARCHAR(50),
    MaBanGhiLQ      INT,
    DuongDanDen     NVARCHAR(500),
    DaDoc           BIT           NOT NULL DEFAULT 0,
    NgayDoc         DATETIME2,
    KenhGui         NVARCHAR(50)  NOT NULL DEFAULT N'TrongUng',
    -- TrongUng / DayNhanh / Email / SMS
    NgayGui         DATETIME2,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_TBCN_SV     ON ThongBaoCaNhan(MaHoSoSV);
CREATE INDEX IX_TBCN_GV     ON ThongBaoCaNhan(MaHoSoGV);
CREATE INDEX IX_TBCN_DaDoc  ON ThongBaoCaNhan(MaHoSoSV, DaDoc);
GO

-- Diễn đàn
CREATE TABLE DienDan (
    MaDienDan       INT IDENTITY(1,1) PRIMARY KEY,
    MaKhoaHocLMS    INT           NOT NULL REFERENCES KhoaHocLMS(MaKhoaHocLMS),
    TenDienDan      NVARCHAR(300) NOT NULL,
    MoTa            NVARCHAR(MAX),
    LoaiDienDan     NVARCHAR(50)  NOT NULL DEFAULT N'ChungChung',
    -- ChungChung / HoiDap / ThongBaoGV / ThaoLuanNhom
    CoChoDiem       BIT           NOT NULL DEFAULT 0,
    DiemToiDa       DECIMAL(5,2),
    HanDienDan      DATETIME2,
    YeuCauDangBai   BIT           NOT NULL DEFAULT 0,
    BiKhoa          BIT           NOT NULL DEFAULT 0,
    ThuTu           INT           NOT NULL DEFAULT 0,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE ChuDeDienDan (
    MaChuDe         INT IDENTITY(1,1) PRIMARY KEY,
    MaDienDan       INT           NOT NULL REFERENCES DienDan(MaDienDan),
    MaHoSoSV        INT           REFERENCES HoSoSinhVien(MaHoSoSV),
    MaHoSoGV        INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    TieuDe          NVARCHAR(500) NOT NULL,
    NoiDung         NVARCHAR(MAX) NOT NULL,
    GhimLen         BIT           NOT NULL DEFAULT 0,
    BiKhoa          BIT           NOT NULL DEFAULT 0,
    DaGiaiQuyet     BIT           NOT NULL DEFAULT 0,
    LuotXem         INT           NOT NULL DEFAULT 0,
    SoPhanHoi       INT           NOT NULL DEFAULT 0,
    ThoiGianPhanHoiCuoi DATETIME2,
    NguoiPhanHoiCuoiSV  INT       REFERENCES HoSoSinhVien(MaHoSoSV),
    NguoiPhanHoiCuoiGV  INT       REFERENCES HoSoGiangVien(MaHoSoGV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE PhanHoiDienDan (
    MaPhanHoi       INT IDENTITY(1,1) PRIMARY KEY,
    MaChuDe         INT           NOT NULL REFERENCES ChuDeDienDan(MaChuDe),
    MaPhanHoiCha    INT           REFERENCES PhanHoiDienDan(MaPhanHoi),
    MaHoSoSV        INT           REFERENCES HoSoSinhVien(MaHoSoSV),
    MaHoSoGV        INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NoiDung         NVARCHAR(MAX) NOT NULL,
    FileDinhKemJSON NVARCHAR(MAX),
    LaCauTraLoiDung BIT           NOT NULL DEFAULT 0,
    SoLuotThich     INT           NOT NULL DEFAULT 0,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Lịch gặp giảng viên
CREATE TABLE LichGapGiangVien (
    MaLichGap       INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoGV        INT           NOT NULL REFERENCES HoSoGiangVien(MaHoSoGV),
    MaLopHP         INT           REFERENCES LopHocPhan(MaLopHP),
    NgayGap         DATE          NOT NULL,
    GioBatDau       TIME          NOT NULL,
    GioKetThuc      TIME          NOT NULL,
    DiaDiem         NVARCHAR(200),
    LinkHopTrucTuyen NVARCHAR(500),
    ConTroNgoi      BIT           NOT NULL DEFAULT 1,
    SoChoToiDa      INT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE DatLichGapGiangVien (
    MaDatLich       INT IDENTITY(1,1) PRIMARY KEY,
    MaLichGap       INT           NOT NULL REFERENCES LichGapGiangVien(MaLichGap),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MucDichGap      NVARCHAR(500),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DaDat',
    -- DaDat / XacNhan / Huy / DaGap
    LinkHopRieng    NVARCHAR(500),
    GhiChu          NVARCHAR(500),
    NgayDat         DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_DatLich UNIQUE (MaLichGap, MaHoSoSV)
);
GO

-- Lớp học ảo (trực tuyến)
CREATE TABLE LopHocAo (
    MaLopAo         INT IDENTITY(1,1) PRIMARY KEY,
    MaLopHP         INT           NOT NULL REFERENCES LopHocPhan(MaLopHP),
    MaLichHoc       INT           REFERENCES LichHoc(MaLichHoc),
    NenTang         NVARCHAR(50)  NOT NULL DEFAULT N'Zoom',
    MaCuocHop       NVARCHAR(200),
    DuongDanThamGia NVARCHAR(500) NOT NULL,
    DuongDanChuTri  NVARCHAR(500),
    MatKhauPhong    NVARCHAR(100),
    ThoiGianBatDau  DATETIME2     NOT NULL,
    ThoiGianKetThuc DATETIME2,
    DuongDanGhiAm   NVARCHAR(500),
    ThongTinThamDuJSON NVARCHAR(MAX),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DaLenLich',
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- PHÂN HỆ 8: THEO DÕI TIẾN ĐỘ & CẢNH BÁO SỚM
-- ============================================================

CREATE TABLE TienDoHocTapSV (
    MaTienDoHT      INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaKhoaHocLMS    INT           NOT NULL REFERENCES KhoaHocLMS(MaKhoaHocLMS),
    MaDangKy        INT           NOT NULL REFERENCES DangKyHocPhan(MaDangKy),
    TongHocLieu     INT           NOT NULL DEFAULT 0,
    HocLieuHoanThanh INT          NOT NULL DEFAULT 0,
    TongBaiTap      INT           NOT NULL DEFAULT 0,
    BaiTapDaNop     INT           NOT NULL DEFAULT 0,
    TyLeChuyenCan   DECIMAL(5,2)  NOT NULL DEFAULT 0,
    DiemTrungBinh   DECIMAL(5,2),
    HoatDongCuoiLuc DATETIME2,
    SoNgayDangNhap  INT           NOT NULL DEFAULT 0,
    DaHoanThanh     BIT           NOT NULL DEFAULT 0,
    NgayHoanThanh   DATETIME2,
    DiemNguyCo      DECIMAL(5,2),            -- 0-100: nguy cơ bỏ học
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_TienDoHT UNIQUE (MaHoSoSV, MaKhoaHocLMS)
);
GO

CREATE INDEX IX_TienDoHT_SV     ON TienDoHocTapSV(MaHoSoSV);
CREATE INDEX IX_TienDoHT_KhoaHoc ON TienDoHocTapSV(MaKhoaHocLMS);
GO

-- Quy tắc cảnh báo sớm
CREATE TABLE QuyTacCanhBao (
    MaQuyTac        INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenQuyTac       NVARCHAR(200) NOT NULL,
    LoaiQuyTac      NVARCHAR(100) NOT NULL,
    -- VangQuaNguong / KhongDangNhapNgay / NopTreNhieuLan
    -- DiemThapQua / TienDoDuoi / NguyCoCaoBo
    DieuKienJSON    NVARCHAR(MAX) NOT NULL,
    -- JSON: {"nguong":3,"khoangThoiGian":"HocKy","donVi":"Buoi"}
    CapDo           NVARCHAR(20)  NOT NULL DEFAULT N'CanhBao',
    -- ThongTin / CanhBao / NguyHiem / KhanCap
    TuDongGuiSV     BIT           NOT NULL DEFAULT 1,
    TuDongGuiCoVan  BIT           NOT NULL DEFAULT 1,
    TuDongGuiGV     BIT           NOT NULL DEFAULT 0,
    MauThongBao     NVARCHAR(MAX),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE CanhBaoSinhVien (
    MaCanhBao       INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaQuyTac        INT           NOT NULL REFERENCES QuyTacCanhBao(MaQuyTac),
    MaLopHP         INT           REFERENCES LopHocPhan(MaLopHP),
    MaHocKy         INT           REFERENCES HocKy(MaHocKy),
    DuLieuKichHoat  NVARCHAR(MAX),
    CapDo           NVARCHAR(20)  NOT NULL,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DangHieuLuc',
    -- DangHieuLuc / DaXacNhan / DaXuLy / DaDongLai
    MaCoVanHocTap   INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    GhiChuCoVan     NVARCHAR(1000),
    NgayXuLy        DATETIME2,
    ThoiGianKichHoat DATETIME2    NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_CanhBao_SV      ON CanhBaoSinhVien(MaHoSoSV);
CREATE INDEX IX_CanhBao_HocKy   ON CanhBaoSinhVien(MaHocKy);
GO

-- ============================================================
-- PHÂN HỆ 9: CHỨNG CHỈ, HUY HIỆU, E-PORTFOLIO
-- ============================================================

CREATE TABLE MauChungChi (
    MaMauCC         INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenMau          NVARCHAR(200) NOT NULL,
    LoaiMau         NVARCHAR(50)  NOT NULL DEFAULT N'KhoaHoc',
    -- KhoaHoc / ChuongTrinh / ViBang / HuyHieu
    BoCucJSON       NVARCHAR(MAX),
    MauHTMLLayout   NVARCHAR(MAX),
    AnhNen          NVARCHAR(500),
    NguoiKy         INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE ChungChiDaCap (
    MaChungChi      INT IDENTITY(1,1) PRIMARY KEY,
    MaMauCC         INT           NOT NULL REFERENCES MauChungChi(MaMauCC),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaKhoaHocLMS    INT           REFERENCES KhoaHocLMS(MaKhoaHocLMS),
    MaCTDT          INT           REFERENCES ChuongTrinhDaoTao(MaCTDT),
    SoChungChi      NVARCHAR(100) NOT NULL UNIQUE,
    TenChungChi     NVARCHAR(300) NOT NULL,
    NgayCap         DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    NgayHetHan      DATE,
    DuongDanXacMinh NVARCHAR(500),
    MaXacMinh       NVARCHAR(100) NOT NULL UNIQUE,
    SieuDuLieuJSON  NVARCHAR(MAX),           -- JSON: kỹ năng, thời lượng, đơn vị cấp
    DuongDanFile    NVARCHAR(500),
    BiThuHoi        BIT           NOT NULL DEFAULT 0,
    NgayThuHoi      DATETIME2,
    LyDoThuHoi      NVARCHAR(500),
    NguoiCap        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_ChungChi_SV ON ChungChiDaCap(MaHoSoSV);
GO

-- Huy hiệu số (Open Badges)
CREATE TABLE MauHuyHieu (
    MaMauHH         INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenHuyHieu      NVARCHAR(200) NOT NULL,
    MoTa            NVARCHAR(MAX),
    DuongDanAnh     NVARCHAR(500) NOT NULL,
    DanhSachKyNangJSON NVARCHAR(MAX),
    TieuChiDat      NVARCHAR(MAX),
    CachDatDuoc     NVARCHAR(MAX),
    PhanLoai        NVARCHAR(100),
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE HuyHieuDaCap (
    MaHuyHieu       INT IDENTITY(1,1) PRIMARY KEY,
    MaMauHH         INT           NOT NULL REFERENCES MauHuyHieu(MaMauHH),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    NgayCap         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayHetHan      DATE,
    DuongDanKhangDinh NVARCHAR(500),
    NguoiCap        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    CONSTRAINT UQ_HuyHieuCap UNIQUE (MaMauHH, MaHoSoSV)
);
GO

-- E-Portfolio
CREATE TABLE HoSoNangLuc (
    MaHSNL          INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV) UNIQUE,
    TieuDe          NVARCHAR(300),
    GioiThieu       NVARCHAR(MAX),
    DuongDanRieng   NVARCHAR(300) UNIQUE,
    CongKhai        BIT           NOT NULL DEFAULT 0,
    CauHinhGiaoDienJSON NVARCHAR(MAX),
    KyNangJSON      NVARCHAR(MAX),
    MangXaHoiJSON   NVARCHAR(MAX),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE MucHoSoNangLuc (
    MaMucHSNL       INT IDENTITY(1,1) PRIMARY KEY,
    MaHSNL          INT           NOT NULL REFERENCES HoSoNangLuc(MaHSNL),
    LoaiMuc         NVARCHAR(50)  NOT NULL,
    -- DuAn / BaiLam / ChungChi / HuyHieu / ThucTap / BaiBao
    TieuDe          NVARCHAR(300) NOT NULL,
    MoTa            NVARCHAR(MAX),
    DuongDanMedia   NVARCHAR(500),
    DuongDanNgoai   NVARCHAR(500),
    MaKhoaHocLMS    INT           REFERENCES KhoaHocLMS(MaKhoaHocLMS),
    MaChungChi      INT           REFERENCES ChungChiDaCap(MaChungChi),
    MaHuyHieu       INT           REFERENCES HuyHieuDaCap(MaHuyHieu),
    TuKhoa          NVARCHAR(500),
    CongKhai        BIT           NOT NULL DEFAULT 1,
    ThuTu           INT           NOT NULL DEFAULT 0,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- PHÂN HỆ 10: AI & SMART LMS
-- ============================================================

CREATE TABLE PhienChatAI (
    MaPhienAI       INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           REFERENCES HoSoSinhVien(MaHoSoSV),
    MaHoSoGV        INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    MaHoSoNV        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    MaKhoaHocLMS    INT           REFERENCES KhoaHocLMS(MaKhoaHocLMS),
    TieuDePhien     NVARCHAR(300),
    VaiTroNguoiDung NVARCHAR(50)  NOT NULL DEFAULT N'SinhVien',
    -- SinhVien / GiangVien / NhanVien / QuanTri
    BatDauLuc       DATETIME2     NOT NULL DEFAULT GETDATE(),
    KetThucLuc      DATETIME2,
    SoTinNhan       INT           NOT NULL DEFAULT 0,
    TongTokenDung   INT           NOT NULL DEFAULT 0,
    DiemDanhGia     TINYINT,
    NhanXetDanhGia  NVARCHAR(500)
);
GO

CREATE TABLE TinNhanAI (
    MaTinNhan       BIGINT IDENTITY(1,1) PRIMARY KEY,
    MaPhienAI       INT           NOT NULL REFERENCES PhienChatAI(MaPhienAI),
    VaiTro          NVARCHAR(20)  NOT NULL,   -- NguoiDung / TroLy / HeThong
    NoiDung         NVARCHAR(MAX) NOT NULL,
    TrichDanJSON    NVARCHAR(MAX),            -- JSON: đoạn tài liệu trích dẫn
    SoToken         INT           NOT NULL DEFAULT 0,
    ThoiGianPhanHoiMs INT,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_TinNhanAI_Phien ON TinNhanAI(MaPhienAI);
GO

-- AI sinh nội dung (câu hỏi, flashcard, đề cương...)
CREATE TABLE NoiDungAISinh (
    MaNoiDungAI     INT IDENTITY(1,1) PRIMARY KEY,
    NguoiYeuCauGV   INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NguoiYeuCauSV   INT           REFERENCES HoSoSinhVien(MaHoSoSV),
    LoaiNoiDung     NVARCHAR(50)  NOT NULL,
    -- CauHoi / TheFlashcard / DeCuong / TomTat / KeHoachDayHoc / GoiYHoatDong
    MaHocLieuNguon  INT           REFERENCES HocLieu(MaHocLieu),
    MaKhoaHocLMS    INT           REFERENCES KhoaHocLMS(MaKhoaHocLMS),
    MaCDRHP         INT           REFERENCES ChuanDauRaHocPhan(MaCDRHP),
    MucDoKho        NVARCHAR(20),
    PromptSuDung    NVARCHAR(MAX),
    KetQuaSinh      NVARCHAR(MAX) NOT NULL,
    DuocChapNhan    BIT,
    NgayChapNhan    DATETIME2,
    LuuVaoCauHoiID  INT           REFERENCES CauHoi(MaCauHoi),
    PhienBanModel   NVARCHAR(100),
    SoTokenDung     INT,
    NgaySinh        DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- Hồ sơ học tập cá nhân hóa cho AI
CREATE TABLE HoSoHocTapCaNhan (
    MaHoSoHT        INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV) UNIQUE,
    PhongCachHocJSON NVARCHAR(MAX),           -- visual/auditory/reading/kinesthetic
    DiemYeuTheoCLOJSON NVARCHAR(MAX),
    DiemManhTheoCLOJSON NVARCHAR(MAX),
    GioHocUaThich   NVARCHAR(50),
    PhutHocTrungBinh INT,
    LoTrinhDeNghiJSON NVARCHAR(MAX),         -- JSON lộ trình gợi ý
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- PHÂN HỆ 11: ĐA CÔNG NĂNG (Khoá ngắn hạn, Thực tập, MOOC)
-- ============================================================

CREATE TABLE LoaiChuongTrinh (
    MaLoai          INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenLoai         NVARCHAR(200) NOT NULL,
    MaLoaiCode      NVARCHAR(50)  NOT NULL,
    -- DaoTaoChinhQuy / KhoaNganHan / CPD / DaoTaoNoiBo / ThucTap / MOOC
    CoThuPhi        BIT           NOT NULL DEFAULT 0,
    CapChungChi     BIT           NOT NULL DEFAULT 1,
    MoTa            NVARCHAR(MAX),
    CONSTRAINT UQ_LoaiCT UNIQUE (MaTruong, MaLoaiCode)
);
GO

CREATE TABLE KhoaHocNganHan (
    MaKhoaNH        INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    MaLoai          INT           NOT NULL REFERENCES LoaiChuongTrinh(MaLoai),
    MaKhoaCode      NVARCHAR(50)  NOT NULL,
    TenKhoa         NVARCHAR(300) NOT NULL,
    MoTa            NVARCHAR(MAX),
    HocPhi          DECIMAL(15,2) NOT NULL DEFAULT 0,
    DonViTienTe     NVARCHAR(10)  NOT NULL DEFAULT N'VND',
    SoNgay          INT,
    SoHocVienToiDa  INT,
    HanDangKy       DATETIME2,
    NgayKhaiGiang   DATE,
    NgayBeGiang     DATE,
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'BanNhap',
    NguoiTao        INT           NOT NULL REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_KhoaNH UNIQUE (MaTruong, MaKhoaCode)
);
GO

CREATE TABLE DangKyKhoaNganHan (
    MaDangKyNH      INT IDENTITY(1,1) PRIMARY KEY,
    MaKhoaNH        INT           NOT NULL REFERENCES KhoaHocNganHan(MaKhoaNH),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    TrangThaiThanhToan NVARCHAR(50) NOT NULL DEFAULT N'ChoDongTien',
    SoTienDaDong    DECIMAL(15,2) NOT NULL DEFAULT 0,
    NgayThanhToan   DATETIME2,
    MaGiaoDich      NVARCHAR(200),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DaDangKy',
    NgayDangKy      DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_DangKyNH UNIQUE (MaKhoaNH, MaHoSoSV)
);
GO

-- Doanh nghiệp đối tác
CREATE TABLE DoanhNghiep (
    MaDN            INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenDN           NVARCHAR(300) NOT NULL,
    MaSoThue        NVARCHAR(50),
    LinhVuc         NVARCHAR(200),
    DiaChi          NVARCHAR(500),
    Website         NVARCHAR(300),
    NguoiLienHe     NVARCHAR(200),
    EmailLienHe     NVARCHAR(200),
    SDTLienHe       NVARCHAR(50),
    DuongDanHopDong NVARCHAR(500),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'HoatDong',
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE ChuongTrinhThucTap (
    MaCTTT          INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    MaDN            INT           NOT NULL REFERENCES DoanhNghiep(MaDN),
    MaLopHP         INT           REFERENCES LopHocPhan(MaLopHP),
    TenChuongTrinh  NVARCHAR(300) NOT NULL,
    NgayBatDau      DATE          NOT NULL,
    NgayKetThuc     DATE          NOT NULL,
    SoSinhVienToiDa INT,
    MoTa            NVARCHAR(MAX),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DangMo',
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE DangKyThucTap (
    MaDKTT          INT IDENTITY(1,1) PRIMARY KEY,
    MaCTTT          INT           NOT NULL REFERENCES ChuongTrinhThucTap(MaCTTT),
    MaHoSoSV        INT           NOT NULL REFERENCES HoSoSinhVien(MaHoSoSV),
    MaGVHuongDan    INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    MaNguoiDNHuongDan INT         REFERENCES HoSoNhanVien(MaHoSoNV),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DangThucTap',
    -- DangThucTap / HoanThanh / ChuyenNganh / Quit
    DiemTongKet     DECIMAL(5,2),
    DiemDoanhNghiep DECIMAL(5,2),
    DiemGiangVien   DECIMAL(5,2),
    NgayBatDau      DATE,
    NgayHoanThanh   DATE,
    CONSTRAINT UQ_DKTT UNIQUE (MaCTTT, MaHoSoSV)
);
GO

CREATE TABLE NhatKyThucTap (
    MaNKTT          INT IDENTITY(1,1) PRIMARY KEY,
    MaDKTT          INT           NOT NULL REFERENCES DangKyThucTap(MaDKTT),
    NgayGhi         DATE          NOT NULL,
    HoatDongThucHien NVARCHAR(MAX) NOT NULL,
    SuyNghi         NVARCHAR(MAX),
    FileDinhKemJSON NVARCHAR(MAX),
    NguoiNhanXet    INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    TrangThaiNhanXet NVARCHAR(50) NOT NULL DEFAULT N'ChoDuyet',
    GhiChuNhanXet   NVARCHAR(500),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- PHÂN HỆ 12: HỆ THỐNG BÁO CÁO
-- ============================================================

CREATE TABLE MauBaoCao (
    MaMauBC         INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenMau          NVARCHAR(300) NOT NULL,
    MaMauCode       NVARCHAR(100) NOT NULL,
    DanhMuc         NVARCHAR(100) NOT NULL,
    -- HocVu / DiemDanh / KetQuaHoc / TienDo / ChuanDauRa / DangKy / TaiChinh
    MoTa            NVARCHAR(MAX),
    DinhNghiaTratVan NVARCHAR(MAX) NOT NULL,
    ThamSoJSON      NVARCHAR(MAX),
    DinhDangXuat    NVARCHAR(50)  NOT NULL DEFAULT N'Excel',
    -- Excel / PDF / CSV / JSON / Dashboard
    LaMauHeThong    BIT           NOT NULL DEFAULT 0,
    NguoiTao        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_MauBC UNIQUE (MaTruong, MaMauCode)
);
GO

CREATE TABLE LichBaoCao (
    MaLich          INT IDENTITY(1,1) PRIMARY KEY,
    MaMauBC         INT           NOT NULL REFERENCES MauBaoCao(MaMauBC),
    TenLich         NVARCHAR(200) NOT NULL,
    BieuThucCron    NVARCHAR(100) NOT NULL,
    ThamSoJSON      NVARCHAR(MAX),
    DanhSachNguoiNhanJSON NVARCHAR(MAX),
    DinhDangXuat    NVARCHAR(50)  NOT NULL DEFAULT N'Excel',
    ConHieuLuc      BIT           NOT NULL DEFAULT 1,
    LanChayGanNhat  DATETIME2,
    LanChayTiepTheo DATETIME2,
    NguoiTao        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE LichSuChayBaoCao (
    MaLichSuBC      INT IDENTITY(1,1) PRIMARY KEY,
    MaMauBC         INT           NOT NULL REFERENCES MauBaoCao(MaMauBC),
    MaLich          INT           REFERENCES LichBaoCao(MaLich),
    NguoiYeuCau     INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    ThamSoJSON      NVARCHAR(MAX),
    TrangThai       NVARCHAR(50)  NOT NULL DEFAULT N'DangChay',
    -- DangChay / HoanThanh / ThatBai
    DuongDanFile    NVARCHAR(500),
    SoDongKetQua    INT,
    ThongBaoLoi     NVARCHAR(MAX),
    BatDauLuc       DATETIME2     NOT NULL DEFAULT GETDATE(),
    HoanThanhLuc    DATETIME2
);
GO

-- ============================================================
-- BẢNG TIỆN ÍCH CHUNG
-- ============================================================

CREATE TABLE CauHinhHeThong (
    MaCauHinh       INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           REFERENCES Truong(MaTruong),
    KhoaCauHinh     NVARCHAR(200) NOT NULL,
    GiaTriCauHinh   NVARCHAR(MAX),
    KieuDuLieu      NVARCHAR(50)  NOT NULL DEFAULT N'ChuoiKyTu',
    MoTa            NVARCHAR(500),
    DuocMaHoa       BIT           NOT NULL DEFAULT 0,
    NguoiCapNhat    INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    NgayCapNhat     DATETIME2     NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_CauHinhHT UNIQUE (MaTruong, KhoaCauHinh)
);
GO

CREATE TABLE KhoLuuTruFile (
    MaFile          INT IDENTITY(1,1) PRIMARY KEY,
    NguoiTaiLen_GV  INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    NguoiTaiLen_SV  INT           REFERENCES HoSoSinhVien(MaHoSoSV),
    NguoiTaiLen_NV  INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenFile         NVARCHAR(500) NOT NULL,
    TenGoc          NVARCHAR(500) NOT NULL,
    DuongDanFile    NVARCHAR(1000) NOT NULL,
    DuongDanLuuTru  NVARCHAR(1000),
    KichThuocByte   BIGINT        NOT NULL,
    KieuMIME        NVARCHAR(100),
    MaHashFile      NVARCHAR(200),
    LoaiLuuTru      NVARCHAR(50)  NOT NULL DEFAULT N'S3',
    LoaiBanGhiLQ    NVARCHAR(100),
    MaBanGhiLQ      INT,
    LaCongKhai      BIT           NOT NULL DEFAULT 0,
    SoLuotTai       INT           NOT NULL DEFAULT 0,
    NgayTao         DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE INDEX IX_KhoFile_BanGhi ON KhoLuuTruFile(LoaiBanGhiLQ, MaBanGhiLQ);
GO

CREATE TABLE ThietBiNguoiDung (
    MaThietBi       INT IDENTITY(1,1) PRIMARY KEY,
    MaHoSoSV        INT           REFERENCES HoSoSinhVien(MaHoSoSV),
    MaHoSoGV        INT           REFERENCES HoSoGiangVien(MaHoSoGV),
    MaHoSoNV        INT           REFERENCES HoSoNhanVien(MaHoSoNV),
    TokenThietBi    NVARCHAR(500) NOT NULL UNIQUE,  -- FCM/APNs
    NenTang         NVARCHAR(50)  NOT NULL,          -- iOS / Android / Web
    TenThietBi      NVARCHAR(200),
    PhienBanUngDung NVARCHAR(50),
    ConHoatDong     BIT           NOT NULL DEFAULT 1,
    LanDungCuoi     DATETIME2     NOT NULL DEFAULT GETDATE(),
    NgayDangKy      DATETIME2     NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE TuKhoaHeThong (
    MaTuKhoa        INT IDENTITY(1,1) PRIMARY KEY,
    MaTruong        INT           NOT NULL REFERENCES Truong(MaTruong),
    TenTuKhoa       NVARCHAR(100) NOT NULL,
    NhomTuKhoa      NVARCHAR(100),
    CONSTRAINT UQ_TuKhoa UNIQUE (MaTruong, TenTuKhoa)
);
GO

CREATE TABLE GanTuKhoa (
    MaGanTK         INT IDENTITY(1,1) PRIMARY KEY,
    MaTuKhoa        INT           NOT NULL REFERENCES TuKhoaHeThong(MaTuKhoa),
    LoaiBanGhi      NVARCHAR(100) NOT NULL,
    MaBanGhi        INT           NOT NULL,
    CONSTRAINT UQ_GanTuKhoa UNIQUE (MaTuKhoa, LoaiBanGhi, MaBanGhi)
);
GO

-- ============================================================
-- VIEWS TỔNG HỢP
-- ============================================================

-- View tổng hợp điểm danh sinh viên
CREATE VIEW v_TongHopDiemDanh AS
SELECT
    dk.MaHoSoSV,
    sv.MaSinhVien,
    sv.HoTen                                        AS TenSinhVien,
    dk.MaLopHP,
    lhp.MaLopHPCode,
    hp.TenHocPhan,
    hk.TenHocKy,
    COUNT(bd.MaBuoiDD)                              AS TongSoBuoi,
    SUM(CASE WHEN ct.TrangThaiDiemDanh IN (N'CoMat', N'DiMuon') THEN 1 ELSE 0 END) AS SoBuoiCoMat,
    SUM(CASE WHEN ct.TrangThaiDiemDanh = N'VangKhongPhep' THEN 1 ELSE 0 END)       AS SoVangKhongPhep,
    SUM(CASE WHEN ct.TrangThaiDiemDanh = N'VangCoPhep' THEN 1 ELSE 0 END)          AS SoVangCoPhep,
    CAST(
        100.0 * SUM(CASE WHEN ct.TrangThaiDiemDanh IN (N'CoMat',N'DiMuon') THEN 1 ELSE 0 END)
        / NULLIF(COUNT(bd.MaBuoiDD), 0)
    AS DECIMAL(5,2))                                AS TyLeChuyenCan
FROM DangKyHocPhan dk
JOIN HoSoSinhVien sv        ON sv.MaHoSoSV    = dk.MaHoSoSV
JOIN LopHocPhan lhp         ON lhp.MaLopHP    = dk.MaLopHP
JOIN HocPhan hp             ON hp.MaHocPhan   = lhp.MaHocPhan
JOIN HocKy hk               ON hk.MaHocKy     = lhp.MaHocKy
LEFT JOIN BuoiDiemDanh bd   ON bd.MaLopHP     = lhp.MaLopHP
LEFT JOIN ChiTietDiemDanh ct ON ct.MaBuoiDD   = bd.MaBuoiDD
                             AND ct.MaHoSoSV   = dk.MaHoSoSV
WHERE dk.TrangThai = N'DaDangKy'
GROUP BY dk.MaHoSoSV, sv.MaSinhVien, sv.HoTen,
         dk.MaLopHP, lhp.MaLopHPCode, hp.TenHocPhan, hk.TenHocKy;
GO

-- View sổ điểm tổng hợp
CREATE VIEW v_SoDiemTongHop AS
SELECT
    sd.MaSoDiem,
    dk.MaHoSoSV,
    sv.MaSinhVien,
    sv.HoTen                AS TenSinhVien,
    lhp.MaLopHP,
    lhp.MaLopHPCode,
    hp.MaHocPhanCode,
    hp.TenHocPhan,
    hp.SoTinChi,
    hk.TenHocKy,
    hk.MaHocKy,
    sd.DiemChuyenCan,
    sd.DiemQuaTrinh,
    sd.DiemGiuaKy,
    sd.DiemCuoiKy,
    sd.DiemTongKet,
    sd.XepLoai,
    sd.DiemGPA,
    sd.DatMon,
    sd.TrangThai            AS TrangThaiDiem
FROM SoDiemSinhVien sd
JOIN DangKyHocPhan dk   ON dk.MaDangKy    = sd.MaDangKy
JOIN HoSoSinhVien sv    ON sv.MaHoSoSV    = dk.MaHoSoSV
JOIN LopHocPhan lhp     ON lhp.MaLopHP    = dk.MaLopHP
JOIN HocPhan hp         ON hp.MaHocPhan   = lhp.MaHocPhan
JOIN HocKy hk           ON hk.MaHocKy     = lhp.MaHocKy;
GO

-- View GPA theo học kỳ
CREATE VIEW v_GPATheoHocKy AS
SELECT
    dk.MaHoSoSV,
    sv.MaSinhVien,
    sv.HoTen            AS TenSinhVien,
    lhp.MaHocKy,
    hk.TenHocKy,
    COUNT(sd.MaSoDiem)                          AS SoMonHoc,
    SUM(hp.SoTinChi)                            AS TongTinChi,
    CAST(
        SUM(hp.SoTinChi * sd.DiemGPA)
        / NULLIF(SUM(hp.SoTinChi), 0)
    AS DECIMAL(4,2))                            AS GPAHocKy,
    SUM(CASE WHEN sd.DatMon = 1 THEN hp.SoTinChi ELSE 0 END) AS TinChiDat
FROM SoDiemSinhVien sd
JOIN DangKyHocPhan dk   ON dk.MaDangKy   = sd.MaDangKy
JOIN HoSoSinhVien sv    ON sv.MaHoSoSV   = dk.MaHoSoSV
JOIN LopHocPhan lhp     ON lhp.MaLopHP   = dk.MaLopHP
JOIN HocPhan hp         ON hp.MaHocPhan  = lhp.MaHocPhan
JOIN HocKy hk           ON hk.MaHocKy    = lhp.MaHocKy
WHERE sd.TrangThai = N'ChinhThuc'
  AND sd.DatMon IS NOT NULL
GROUP BY dk.MaHoSoSV, sv.MaSinhVien, sv.HoTen,
         lhp.MaHocKy, hk.TenHocKy;
GO

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

-- SP: Tính điểm tổng kết
CREATE OR ALTER PROCEDURE sp_TinhDiemTongKet
    @MaDangKy INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @DiemTong DECIMAL(5,2) = 0;
    DECLARE @XepLoai NVARCHAR(5);
    DECLARE @DiemGPA DECIMAL(3,2);

    SELECT @DiemTong =
        ISNULL(sd.DiemChuyenCan, 0) * 0.10 +
        ISNULL(sd.DiemQuaTrinh,  0) * 0.30 +
        ISNULL(sd.DiemGiuaKy,   0) * 0.20 +
        ISNULL(sd.DiemCuoiKy,   0) * 0.40
    FROM SoDiemSinhVien sd
    WHERE sd.MaDangKy = @MaDangKy;

    SET @XepLoai = CASE
        WHEN @DiemTong >= 9.0 THEN N'A+'
        WHEN @DiemTong >= 8.5 THEN N'A'
        WHEN @DiemTong >= 8.0 THEN N'B+'
        WHEN @DiemTong >= 7.0 THEN N'B'
        WHEN @DiemTong >= 6.5 THEN N'C+'
        WHEN @DiemTong >= 5.5 THEN N'C'
        WHEN @DiemTong >= 5.0 THEN N'D+'
        WHEN @DiemTong >= 4.0 THEN N'D'
        ELSE N'F' END;

    SET @DiemGPA = CASE
        WHEN @DiemTong >= 8.5 THEN 4.0
        WHEN @DiemTong >= 8.0 THEN 3.7
        WHEN @DiemTong >= 7.0 THEN 3.3
        WHEN @DiemTong >= 6.5 THEN 3.0
        WHEN @DiemTong >= 5.5 THEN 2.3
        WHEN @DiemTong >= 5.0 THEN 2.0
        WHEN @DiemTong >= 4.0 THEN 1.7
        ELSE 0.0 END;

    UPDATE SoDiemSinhVien
    SET DiemTongKet = @DiemTong,
        XepLoai     = @XepLoai,
        DiemGPA     = @DiemGPA,
        DatMon      = CASE WHEN @DiemTong >= 4.0 THEN 1 ELSE 0 END,
        NgayCapNhat = GETDATE()
    WHERE MaDangKy = @MaDangKy;

    SELECT @DiemTong AS DiemTongKet, @XepLoai AS XepLoai, @DiemGPA AS DiemGPA;
END;
GO

-- SP: Kiểm tra cảnh báo sớm
CREATE OR ALTER PROCEDURE sp_KiemTraCanhBaoSom
    @MaHoSoSV INT,
    @MaHocKy INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Kiểm tra vắng quá 3 buổi không phép trong học kỳ
    INSERT INTO CanhBaoSinhVien
        (MaHoSoSV, MaQuyTac, MaLopHP, MaHocKy, DuLieuKichHoat, CapDo)
    SELECT
        dk.MaHoSoSV,
        qtcb.MaQuyTac,
        dk.MaLopHP,
        @MaHocKy,
        N'{"soVangKhongPhep":' + CAST(COUNT(ct.MaChiTietDD) AS NVARCHAR) + N'}',
        qtcb.CapDo
    FROM DangKyHocPhan dk
    JOIN LopHocPhan lhp         ON lhp.MaLopHP    = dk.MaLopHP
    JOIN BuoiDiemDanh bd        ON bd.MaLopHP      = lhp.MaLopHP
    JOIN ChiTietDiemDanh ct     ON ct.MaBuoiDD     = bd.MaBuoiDD
                                AND ct.MaHoSoSV    = dk.MaHoSoSV
    CROSS JOIN QuyTacCanhBao qtcb
    WHERE dk.MaHoSoSV          = @MaHoSoSV
      AND lhp.MaHocKy          = @MaHocKy
      AND ct.TrangThaiDiemDanh = N'VangKhongPhep'
      AND qtcb.LoaiQuyTac      = N'VangQuaNguong'
      AND qtcb.ConHieuLuc      = 1
      AND NOT EXISTS (
          SELECT 1 FROM CanhBaoSinhVien cb
          WHERE cb.MaHoSoSV    = dk.MaHoSoSV
            AND cb.MaQuyTac    = qtcb.MaQuyTac
            AND cb.MaLopHP     = dk.MaLopHP
            AND cb.TrangThai   = N'DangHieuLuc'
      )
    GROUP BY dk.MaHoSoSV, dk.MaLopHP, qtcb.MaQuyTac, qtcb.CapDo
    HAVING COUNT(ct.MaChiTietDD) >= 3;
END;
GO

-- SP: Thống kê tiến độ sinh viên theo lớp học phần
CREATE OR ALTER PROCEDURE sp_ThongKeTienDoLop
    @MaLopHP INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        sv.MaSinhVien,
        sv.HoTen,
        tht.TyLeChuyenCan,
        tht.SoBuoiCoMat,
        tht.SoVangKhongPhep,
        thht.TienDoHocLieu,
        thht.TienDoBaiTap,
        thht.DiemNguyCo
    FROM DangKyHocPhan dk
    JOIN HoSoSinhVien sv        ON sv.MaHoSoSV     = dk.MaHoSoSV
    JOIN KhoaHocLMS kh          ON kh.MaLopHP      = dk.MaLopHP
    LEFT JOIN v_TongHopDiemDanh tht ON tht.MaHoSoSV = dk.MaHoSoSV
                                   AND tht.MaLopHP  = dk.MaLopHP
    LEFT JOIN (
        SELECT
            MaHoSoSV,
            MaDangKy,
            CAST(100.0 * HocLieuHoanThanh / NULLIF(TongHocLieu,0) AS DECIMAL(5,2)) AS TienDoHocLieu,
            CAST(100.0 * BaiTapDaNop      / NULLIF(TongBaiTap,0)  AS DECIMAL(5,2)) AS TienDoBaiTap,
            DiemNguyCo
        FROM TienDoHocTapSV
    ) thht ON thht.MaHoSoSV = dk.MaHoSoSV
          AND thht.MaDangKy = dk.MaDangKy
    WHERE dk.MaLopHP  = @MaLopHP
      AND dk.TrangThai = N'DaDangKy'
    ORDER BY sv.HoTen;
END;
GO

PRINT N'✅ LMS_TiengViet Database tạo thành công!';
PRINT N'👤 3 loại tài khoản độc lập: TaiKhoanSinhVien / TaiKhoanGiangVien / TaiKhoanNhanVien';
PRINT N'📋 Toàn bộ tên bảng và cột bằng tiếng Việt (không dấu)';
PRINT N'📊 Tổng bảng: ~115 bảng | Views: 3 | Stored Procedures: 3';
GO
