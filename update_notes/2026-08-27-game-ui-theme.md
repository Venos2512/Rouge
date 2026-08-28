# Đồng bộ UI toàn game

## Mục tiêu
- Thiết lập một ngôn ngữ thị giác chung cho HUD, inventory, reward, shop, upgrade, pause và menu.

## File thêm/sửa
- Đã thử nghiệm theme runtime tập trung, sau đó loại bỏ theo yêu cầu để giữ style trực tiếp trong từng scene.
- Cập nhật `res://gungeon_proto/scenes/gameplay/core_runtime.tscn`.

## Thay đổi giao diện
- Panel xanh đậm, viền sáng, bo góc.
- Button có trạng thái normal/hover/pressed/focus rõ ràng.
- Progress bar dùng accent vàng.
- Text chính/phụ dùng màu sáng/xám xanh nhất quán.
- Theme tự áp dụng cho Control tạo động trong runtime.

## Cách kiểm thử
- Chạy main scene và kiểm tra gameplay HUD, inventory, pause, reward, shop và upgrade.
- Hover/focus/click các button để xác nhận trạng thái hiển thị.

## Lỗi hoặc việc còn lại
- Chưa có font/art direction riêng; bộ theme hiện dùng theme mặc định của Godot cùng màu và stylebox thống nhất.
