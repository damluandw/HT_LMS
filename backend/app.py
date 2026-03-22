"""
HT_LMS Backend - Điểm khởi động ứng dụng Flask
Đăng ký tất cả Blueprint và cấu hình middleware
"""
import os
import logging
from flask import Flask, jsonify
from flask_cors import CORS
from config import get_config

# Cấu hình logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)


def create_app() -> Flask:
    """
    Application Factory - Tạo và cấu hình Flask app.
    Pattern này giúp dễ test và quản lý nhiều môi trường.
    """
    app = Flask(__name__)
    
    # Tải cấu hình
    config = get_config()
    app.config.from_object(config)
    
    # Cấu hình CORS (cho phép frontend gọi API)
    CORS(app, 
         origins=config.CORS_ORIGINS,
         supports_credentials=True,
         allow_headers=["Content-Type", "Authorization"])
    
    # Tạo thư mục upload nếu chưa có
    os.makedirs(config.UPLOAD_FOLDER, exist_ok=True)
    
    # ── Đăng ký Blueprints ───────────────────────────────────────────────────
    from api.auth import auth_bp
    from api.nguoi_dung import nguoi_dung_bp
    from api.to_chuc import to_chuc_bp
    from api.hoc_vu import hoc_vu_bp
    from api.khoa_hoc import khoa_hoc_bp
    from api.bai_tap import bai_tap_bp
    from api.diem import diem_bp
    
    app.register_blueprint(auth_bp)
    app.register_blueprint(nguoi_dung_bp)
    app.register_blueprint(to_chuc_bp)
    app.register_blueprint(hoc_vu_bp)
    app.register_blueprint(khoa_hoc_bp)
    app.register_blueprint(bai_tap_bp)
    app.register_blueprint(diem_bp)
    
    # ── Route gốc ────────────────────────────────────────────────────────────
    @app.route('/')
    def index():
        return jsonify({
            "app": "HT_LMS API",
            "version": "1.0.0",
            "status": "running",
            "endpoints": {
                "auth":       "/api/auth/",
                "users":      "/api/users/",
                "org":        "/api/org/",
                "academic":   "/api/hoc-vu/",
                "courses":    "/api/khoa-hoc/",
                "assignments":"/api/bai-tap/",
                "grades":     "/api/diem/",
                "health":     "/api/auth/kiem-tra"
            }
        })
    
    # ── Xử lý lỗi toàn cục ───────────────────────────────────────────────────
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"success": False, "message": "Endpoint không tồn tại"}), 404
    
    @app.errorhandler(405)
    def method_not_allowed(e):
        return jsonify({"success": False, "message": "Phương thức không được phép"}), 405
    
    @app.errorhandler(500)
    def internal_error(e):
        logger.error(f"Lỗi server: {e}")
        return jsonify({"success": False, "message": "Lỗi máy chủ nội bộ"}), 500
    
    logger.info(f"HT_LMS Flask app đã khởi động (Môi trường: {os.getenv('FLASK_ENV', 'development')})")
    return app


if __name__ == '__main__':
    app = create_app()
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('PORT', 5000)),
        debug=get_config().DEBUG
    )
