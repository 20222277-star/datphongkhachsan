# HỆ THỐNG QUẢN LÝ ĐẶT PHÒNG KHÁCH SẠN - VN-BOOKING PRO

Ứng dụng Web đặt phòng khách sạn chuyên nghiệp được phát triển bằng Flutter và Supabase Cloud.

## 🚀 Tính năng chính

### 1. Phía Người dùng (User)
* **Tìm kiếm thông minh**: Lọc theo địa điểm, xếp hạng sao, khoảng giá.
* **Kiểm tra phòng trống**: Hệ thống tự động kiểm tra lịch đặt để hiển thị phòng thực sự còn trống trong khoảng thời gian khách chọn.
* **Đặt phòng đa kênh**: Hỗ trợ thanh toán qua mã QR hoặc thanh toán tại khách sạn.
* **Quản lý đơn hàng**: Theo dõi trạng thái đơn, upload minh chứng thanh toán và hủy đơn.
* **Đánh giá & Bình luận**: Chia sẻ trải nghiệm sau mỗi kỳ nghỉ.

### 2. Phía Quản trị viên (Admin)
* **Dashboard chuyên nghiệp**: Biểu đồ doanh thu tuần và các chỉ số thống kê quan trọng.
* **Quản lý Kho phòng (Inventory)**: Cập nhật thông tin, giá cả và trạng thái phòng (Trống/Sửa chữa).
* **Quy trình duyệt đơn tự động**: Xác nhận Bill -> Check-in -> Check-out (Tự động cập nhật trạng thái phòng).
* **Cài đặt hệ thống**: Tùy chỉnh mã QR thanh toán toàn hệ thống.

## 🛠 Công nghệ sử dụng
* **Frontend**: Flutter Web (Responsive Design).
* **Backend**: Supabase (PostgreSQL Cloud).
* **Kết nối**: REST API thuần (siêu nhẹ, bảo mật RLS).

## 📖 Hướng dẫn cài đặt
1. Clone dự án: `git clone https://github.com/20222277-star/datphongkhachsan.git`
2. Chạy lệnh: `flutter pub get`
3. Chạy ứng dụng trên Chrome: `flutter run -d chrome`

## 🔑 Tài khoản mẫu
* **Admin**: `admin` / mật khẩu: `123`
* **User**: `user1` / mật khẩu: `123`
