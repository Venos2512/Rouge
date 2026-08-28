# Inventory grid UI

## Mục tiêu

Cải thiện inventory theo tham chiếu pixel-art: túi đồ dạng lưới ở giữa, hiệu ứng bên trái và mô tả item bên phải.

## File thêm/sửa/xóa/di chuyển

- Sửa `res://gungeon_proto/scripts/ui/inventory_overlay.gd`.
- Sửa `res://gungeon_proto/scenes/ui/inventory_overlay.tscn`.

## Thay đổi gameplay hoặc kiến trúc

- Giữ nguyên dữ liệu weapon, relic và upgrade hiện có.
- Thêm ô item có thể chọn để xem mô tả.
- Inventory tiếp tục mở bằng Tab, đóng bằng Tab hoặc Esc và tạm dừng gameplay.
- Dùng đúng một `PanelRoot`; khi inventory đóng, toàn bộ vùng bắt chuột cũng được ẩn để không chặn reward UI.

## Cách kiểm thử

- Chạy game, nhấn Tab.
- Xác nhận bố cục ba panel, các item đã nhặt xuất hiện trong grid và click item cập nhật mô tả.

## Lỗi hoặc việc còn lại

- Icon pixel-art riêng cho từng item có thể bổ sung ở bước tiếp theo; hiện ô dùng ký hiệu và tên viết tắt để tránh phụ thuộc asset mới.
