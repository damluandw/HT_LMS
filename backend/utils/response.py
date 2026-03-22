"""
Chuẩn hóa JSON response cho tất cả API endpoints
Format thống nhất: { success, data, message, errors }
"""
from flask import jsonify


class APIResponse:
    """Lớp chuẩn hóa API response"""
    
    @staticmethod
    def thanh_cong(data=None, message: str = "Thành công", status_code: int = 200):
        """Response thành công"""
        response = {
            "success": True,
            "message": message,
            "data": data
        }
        return jsonify(response), status_code
    
    @staticmethod
    def tao_moi_thanh_cong(data=None, message: str = "Tạo mới thành công"):
        """Response tạo mới thành công (201)"""
        return APIResponse.thanh_cong(data, message, 201)
    
    @staticmethod 
    def loi(message: str = "Có lỗi xảy ra", errors=None, status_code: int = 400):
        """Response lỗi"""
        response = {
            "success": False,
            "message": message,
            "errors": errors
        }
        return jsonify(response), status_code
    
    @staticmethod
    def khong_co_quyen(message: str = "Bạn không có quyền thực hiện thao tác này"):
        """Response 403 - Không có quyền"""
        return APIResponse.loi(message, status_code=403)
    
    @staticmethod
    def chua_xac_thuc(message: str = "Vui lòng đăng nhập để tiếp tục"):
        """Response 401 - Chưa xác thực"""
        return APIResponse.loi(message, status_code=401)
    
    @staticmethod 
    def khong_tim_thay(message: str = "Không tìm thấy dữ liệu"):
        """Response 404 - Không tìm thấy"""
        return APIResponse.loi(message, status_code=404)
    
    @staticmethod
    def loi_server(message: str = "Lỗi máy chủ nội bộ"):
        """Response 500 - Lỗi server"""
        return APIResponse.loi(message, status_code=500)
    
    @staticmethod
    def phan_trang(data: list, tong_ban_ghi: int, trang: int, 
                    so_ban_ghi_tren_trang: int, message: str = "Thành công"):
        """Response có phân trang"""
        tong_trang = (tong_ban_ghi + so_ban_ghi_tren_trang - 1) // so_ban_ghi_tren_trang
        response = {
            "success": True,
            "message": message,
            "data": data,
            "pagination": {
                "trang_hien_tai": trang,
                "so_ban_ghi_tren_trang": so_ban_ghi_tren_trang,
                "tong_ban_ghi": tong_ban_ghi,
                "tong_trang": tong_trang,
                "co_trang_truoc": trang > 1,
                "co_trang_sau": trang < tong_trang
            }
        }
        return jsonify(response), 200
