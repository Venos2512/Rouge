# Inventory Tab và phím debug

## Mục tiêu
- Đổi phím controller debug từ Tab sang backtick (`).
- Thêm inventory mở bằng Tab, hiển thị relic, vũ khí, upgrade, vàng và trạng thái nhân vật.

## File thêm/sửa
- Thêm `res://gungeon_proto/scripts/ui/inventory_overlay.gd`.
- Sửa controller debug và `core_runtime.tscn`.

## Thay đổi gameplay/kiến trúc
- Tab mở/đóng inventory và tạm dừng gameplay; Esc đóng.
- Backtick mở/đóng controller debug overlay.

## Cách kiểm thử
- Chạy `res://gungeon_proto/main.tscn`, nhấn Tab/backtick trong gameplay.
- Nhặt weapon/relic/upgrade rồi mở inventory để kiểm tra cập nhật.

## Lỗi hoặc việc còn lại
- Inventory hiện dùng danh sách chữ, chưa có icon riêng cho từng ô.
