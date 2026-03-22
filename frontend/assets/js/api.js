/**
 * HT_LMS - API Client (OOP)
 * Lớp APIClient dùng jQuery AJAX
 * Tự động gắn JWT header, xử lý lỗi, refresh token
 */

class APIClient {
    constructor(baseURL = 'http://localhost:5000') {
        this.baseURL = baseURL;
        this._accessToken = localStorage.getItem('lms_access_token');
        this._refreshToken = localStorage.getItem('lms_refresh_token');
        this._refreshing = false;
    }

    // ── TOKEN MANAGEMENT ────────────────────────────────────────────────────

    setTokens(accessToken, refreshToken) {
        this._accessToken = accessToken;
        this._refreshToken = refreshToken;
        localStorage.setItem('lms_access_token', accessToken);
        if (refreshToken) localStorage.setItem('lms_refresh_token', refreshToken);
    }

    clearTokens() {
        this._accessToken = null;
        this._refreshToken = null;
        localStorage.removeItem('lms_access_token');
        localStorage.removeItem('lms_refresh_token');
        localStorage.removeItem('lms_user_info');
    }

    _getHeaders() {
        const headers = { 'Content-Type': 'application/json' };
        if (this._accessToken) {
            headers['Authorization'] = `Bearer ${this._accessToken}`;
        }
        return headers;
    }

    // ── AJAX REQUEST ─────────────────────────────────────────────────────────

    async _request(method, endpoint, data = null, retry = true) {
        const url = `${this.baseURL}${endpoint}`;

        return new Promise((resolve, reject) => {
            $.ajax({
                url,
                method,
                headers: this._getHeaders(),
                data: data ? JSON.stringify(data) : null,
                contentType: 'application/json',
                success: (res) => resolve(res),
                error: async (xhr) => {
                    const status = xhr.status;
                    const errData = xhr.responseJSON || {};

                    // 401 → thử refresh token
                    if (status === 401 && retry && this._refreshToken) {
                        const refreshed = await this._doRefresh();
                        if (refreshed) {
                            // Retry với token mới
                            const result = await this._request(method, endpoint, data, false);
                            return resolve(result);
                        }
                        // Refresh thất bại → về đăng nhập
                        this.clearTokens();
                        window.location.href = '/pages/auth/login.html';
                        return reject({ message: 'Phiên đăng nhập hết hạn' });
                    }

                    if (status === 403) {
                        Toast.show('Bạn không có quyền thực hiện thao tác này', 'error');
                    }

                    reject({
                        status,
                        message: errData.message || 'Đã xảy ra lỗi',
                        errors: errData.errors
                    });
                }
            });
        });
    }

    async _doRefresh() {
        if (this._refreshing) return false;
        this._refreshing = true;
        try {
            const res = await $.ajax({
                url: `${this.baseURL}/api/auth/lam-moi-token`,
                method: 'POST',
                contentType: 'application/json',
                data: JSON.stringify({ refresh_token: this._refreshToken })
            });
            if (res?.data?.access_token) {
                this._accessToken = res.data.access_token;
                localStorage.setItem('lms_access_token', this._accessToken);
                return true;
            }
        } catch {
            return false;
        } finally {
            this._refreshing = false;
        }
        return false;
    }

    // ── HTTP METHODS ─────────────────────────────────────────────────────────

    get = (endpoint)               => this._request('GET',    endpoint, null);
    post = (endpoint, data)        => this._request('POST',   endpoint, data);
    put = (endpoint, data)         => this._request('PUT',    endpoint, data);
    delete = (endpoint)            => this._request('DELETE', endpoint, null);
    patch = (endpoint, data)       => this._request('PATCH',  endpoint, data);

    // ── AUTH SHORTCUTS ───────────────────────────────────────────────────────

    async dangNhap(tenDangNhap, matKhau, loaiTaiKhoan) {
        const res = await this.post('/api/auth/dang-nhap', {
            ten_dang_nhap: tenDangNhap,
            mat_khau: matKhau,
            loai_tai_khoan: loaiTaiKhoan
        });
        if (res?.data) {
            this.setTokens(res.data.access_token, res.data.refresh_token);
            localStorage.setItem('lms_user_info', JSON.stringify(res.data.user_info));
        }
        return res;
    }

    async dangXuat() {
        try { await this.post('/api/auth/dang-xuat', {}); } catch {}
        this.clearTokens();
        window.location.href = '/pages/auth/login.html';
    }

    // ── USER INFO ─────────────────────────────────────────────────────────────

    getUserInfo() {
        try {
            return JSON.parse(localStorage.getItem('lms_user_info')) || null;
        } catch { return null; }
    }

    isLoggedIn() {
        return !!this._accessToken && !!this.getUserInfo();
    }

    getLoaiTaiKhoan() {
        return this.getUserInfo()?.loai_tai_khoan || null;
    }

    getVaiTro() {
        return this.getUserInfo()?.vai_tro_codes?.[0] || this.getLoaiTaiKhoan();
    }

    // ── API METHODS ─────────────────────────────────────────────────────────

    // Users
    // Users
    getNguoiHoc = (params = {})    => this.get('/api/users/nguoi-hoc?' + $.param(params));
    createNguoiHoc = (data)        => this.post('/api/users/nguoi-hoc', data);
    updateNguoiHoc = (id, data)    => this.put(`/api/users/nguoi-hoc/${id}`, data);
    deleteNguoiHoc = (id)          => this.delete(`/api/users/nguoi-hoc/${id}`);
    getNguoiHocById = (id)         => this.get(`/api/users/nguoi-hoc/${id}`);
    
    getGiangVien = (params = {})   => this.get('/api/users/giang-vien?' + $.param(params));
    createGiangVien = (data)       => this.post('/api/users/giang-vien', data);
    updateGiangVien = (id, data)   => this.put(`/api/users/giang-vien/${id}`, data);
    deleteGiangVien = (id)         => this.delete(`/api/users/giang-vien/${id}`);
    getGiangVienById = (id)        => this.get(`/api/users/giang-vien/${id}`);
    
    getNhanVien = (params = {})    => this.get('/api/users/nhan-vien?' + $.param(params));
    createNhanVien = (data)        => this.post('/api/users/nhan-vien', data);
    updateNhanVien = (id, data)    => this.put(`/api/users/nhan-vien/${id}`, data);
    deleteNhanVien = (id)          => this.delete(`/api/users/nhan-vien/${id}`);
    getNhanVienById = (id)         => this.get(`/api/users/nhan-vien/${id}`);

    getProfile = ()                => this.get('/api/users/profile');
    doiMatKhau = (oldPass, newPass) => this.put('/api/users/doi-mat-khau', { mat_khau_cu: oldPass, mat_khau_moi: newPass });

    // Org
    getTruong = ()                         => this.get('/api/org/truong');
    
    getKhoa = (maTruong)                   => this.get('/api/org/khoa?ma_truong=' + (maTruong || ''));
    getKhoaById = (id)                     => this.get(`/api/org/khoa/${id}`);
    createKhoa = (data)                    => this.post('/api/org/khoa', data);
    updateKhoa = (id, data)                => this.put(`/api/org/khoa/${id}`, data);
    deleteKhoa = (id)                      => this.delete(`/api/org/khoa/${id}`);

    getBoMon = (maKhoa)                    => this.get('/api/org/bo-mon' + (maKhoa ? `?ma_khoa=${maKhoa}` : ''));
    getBoMonById = (id)                    => this.get(`/api/org/bo-mon/${id}`);
    createBoMon = (data)                   => this.post('/api/org/bo-mon', data);
    updateBoMon = (id, data)               => this.put(`/api/org/bo-mon/${id}`, data);
    deleteBoMon = (id)                     => this.delete(`/api/org/bo-mon/${id}`);

    getNganh = (maBoMon)                   => this.get('/api/org/nganh' + (maBoMon ? `?ma_bo_mon=${maBoMon}` : ''));
    getNganhById = (id)                    => this.get(`/api/org/nganh/${id}`);
    createNganh = (data)                   => this.post('/api/org/nganh', data);
    updateNganh = (id, data)               => this.put(`/api/org/nganh/${id}`, data);
    deleteNganh = (id)                     => this.delete(`/api/org/nganh/${id}`);

    getLopHanhChinh = (params = {})        => this.get('/api/org/lop-hanh-chinh?' + $.param(params));
    getLopHanhChinhById = (id)             => this.get(`/api/org/lop-hanh-chinh/${id}`);
    createLopHanhChinh = (data)            => this.post('/api/org/lop-hanh-chinh', data);
    updateLopHanhChinh = (id, data)        => this.put(`/api/org/lop-hanh-chinh/${id}`, data);
    deleteLopHanhChinh = (id)              => this.delete(`/api/org/lop-hanh-chinh/${id}`);

    // Academic
    getHocKy = ()                          => this.get('/api/hoc-vu/hoc-ky');
    getHocKyById = (id)                    => this.get(`/api/hoc-vu/hoc-ky/${id}`);
    createHocKy = (data)                   => this.post('/api/hoc-vu/hoc-ky', data);
    updateHocKy = (id, data)               => this.put(`/api/hoc-vu/hoc-ky/${id}`, data);
    deleteHocKy = (id)                     => this.delete(`/api/hoc-vu/hoc-ky/${id}`);

    getLopHocPhan = (params = {})          => this.get('/api/hoc-vu/lop-hoc-phan?' + $.param(params));
    getLopHocPhanById = (id)               => this.get(`/api/hoc-vu/lop-hoc-phan/${id}`);
    createLopHocPhan = (data)              => this.post('/api/hoc-vu/lop-hoc-phan', data);
    updateLopHocPhan = (id, data)          => this.put(`/api/hoc-vu/lop-hoc-phan/${id}`, data);
    deleteLopHocPhan = (id)                => this.delete(`/api/hoc-vu/lop-hoc-phan/${id}`);

    getHocPhan = (tuKhoa = '')             => this.get('/api/hoc-vu/hoc-phan?tu_khoa=' + tuKhoa);
    getHocPhanById = (id)                  => this.get(`/api/hoc-vu/hoc-phan/${id}`);
    createHocPhan = (data)                 => this.post('/api/hoc-vu/hoc-phan', data);
    updateHocPhan = (id, data)             => this.put(`/api/hoc-vu/hoc-phan/${id}`, data);
    deleteHocPhan = (id)                   => this.delete(`/api/hoc-vu/hoc-phan/${id}`);
    
    getlopCuaToi = (params = {})           => this.get('/api/hoc-vu/cua-toi?' + $.param(params));

    // Courses
    getKhoaHoc = ()                        => this.get('/api/khoa-hoc/');
    getChiTietKhoaHoc = (id)               => this.get(`/api/khoa-hoc/${id}`);
    getChuong = (maKhoaHoc)                => this.get(`/api/khoa-hoc/${maKhoaHoc}/chuong`);
    getHocLieu = (maKhoaHoc, maChuong)     => {
        let url = `/api/khoa-hoc/${maKhoaHoc}/hoc-lieu`;
        if (maChuong) url += `?ma_chuong=${maChuong}`;
        return this.get(url);
    }

    // Assignments
    getBaiKiemTra = (params = {})          => this.get('/api/bai-tap/?' + $.param(params));
    getDeBai = (maBaiKT)                   => this.get(`/api/bai-tap/${maBaiKT}/de-bai`);
    nopBai = (maBaiKT, data)               => this.post(`/api/bai-tap/${maBaiKT}/nop`, data);
    getKetQua = (maBaiKT)                  => this.get(`/api/bai-tap/ket-qua/${maBaiKT}`);

    // Grades
    getDiemCuaToi = (params = {})          => this.get('/api/diem/cua-toi?' + $.param(params));
    getBangDiemLop = (maLopHP)             => this.get(`/api/diem/lop/${maLopHP}`);
    getDiemTongHop = ()                    => this.get('/api/diem/tong-hop');
}


/**
 * Toast notification system
 */
class Toast {
    static show(message, type = 'info', duration = 3500) {
        let container = document.getElementById('toast-container');
        if (!container) {
            container = document.createElement('div');
            container.id = 'toast-container';
            document.body.appendChild(container);
        }

        const icons = {
            success: 'bi-check-circle-fill',
            error:   'bi-x-circle-fill',
            warning: 'bi-exclamation-triangle-fill',
            info:    'bi-info-circle-fill'
        };

        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `<i class="bi ${icons[type] || icons.info}"></i><span>${message}</span>`;
        container.appendChild(toast);

        setTimeout(() => {
            toast.style.animation = 'slideIn .3s ease reverse';
            setTimeout(() => toast.remove(), 300);
        }, duration);
    }
}


/**
 * Auth Guard - Redirect nếu chưa đăng nhập
 */
class AuthGuard {
    static check(requiredRole = null) {
        const api = new APIClient();
        if (!api.isLoggedIn()) {
            window.location.href = '/pages/auth/login.html';
            return false;
        }
        if (requiredRole) {
            const loai = api.getLoaiTaiKhoan();
            if (loai !== requiredRole && api.getVaiTro() !== 'SuperAdmin') {
                Toast.show('Bạn không có quyền truy cập trang này', 'error');
                setTimeout(() => window.history.back(), 2000);
                return false;
            }
        }
        return true;
    }

    static getRedirectByRole() {
        const api = new APIClient();
        const loai = api.getLoaiTaiKhoan();
        const vai = api.getVaiTro();
        if (loai === 'NguoiHoc')  return '/pages/nguoi_hoc/dashboard.html';
        if (loai === 'GiangVien') return '/pages/giang_vien/dashboard.html';
        return '/pages/admin/dashboard.html';
    }
}

/**
 * Utility functions
 */
const LMSUtils = {
    formatDate(dateStr) {
        if (!dateStr) return '—';
        const d = new Date(dateStr);
        return d.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' });
    },
    formatDateTime(dateStr) {
        if (!dateStr) return '—';
        const d = new Date(dateStr);
        return d.toLocaleString('vi-VN');
    },
    getInitials(name) {
        if (!name) return '?';
        return name.split(' ').map(w => w[0]).slice(-2).join('').toUpperCase();
    },
    formatScore(score) {
        if (score === null || score === undefined) return '—';
        return parseFloat(score).toFixed(1);
    },
    formatGPA(gpa) {
        if (gpa === null || gpa === undefined) return '—';
        return parseFloat(gpa).toFixed(2);
    },
    badgeByTrangThai(trangThai) {
        const map = {
            'HoatDong':    '<span class="badge badge-success">Hoạt động</span>',
            'KhoaTam':     '<span class="badge badge-warning">Tạm khóa</span>',
            'DaDangKy':    '<span class="badge badge-primary">Đã đăng ký</span>',
            'DangHoc':     '<span class="badge badge-success">Đang học</span>',
            'TotNghiep':   '<span class="badge badge-muted">Tốt nghiệp</span>',
            'DangLamViec': '<span class="badge badge-success">Đang làm việc</span>',
        };
        return map[trangThai] || `<span class="badge badge-muted">${trangThai}</span>`;
    }
};


// ── Global instance ──────────────────────────────────────────────────────────
const api = new APIClient();

/**
 * Theme Manager for Light/Dark Mode
 */
class ThemeManager {
    static init() {
        const savedTheme = localStorage.getItem('lms_theme') || 'dark';
        this.setTheme(savedTheme);

        // Bind toggle event delegation
        $(document).on('click', '#themeToggle', () => {
            const current = document.documentElement.getAttribute('data-theme') || 'dark';
            this.setTheme(current === 'dark' ? 'light' : 'dark');
        });
    }

    static setTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('lms_theme', theme);

        const btn = document.getElementById('themeToggle');
        if (btn) {
            btn.innerHTML = theme === 'dark' 
                ? '<i class="bi bi-sun"></i>' 
                : '<i class="bi bi-moon-stars"></i>';
        }
    }
}

// Initial theme check
ThemeManager.init();
