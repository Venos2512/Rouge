# Đồng bộ màu UI Editor và runtime

## Mục tiêu
- Đảm bảo Main Menu hiển thị cùng màu trong Godot Editor và khi Play.

## Thay đổi
- Main Menu có StyleBoxFlat cố định cho panel và button ngay trong scene.
- Theme runtime dùng palette tối giống scene thay vì palette xanh mặc định.

## Cách kiểm thử
- Mở `main_menu_overlay.tscn` và so sánh panel/button.
- Chạy game bằng F5, xác nhận màu runtime không chuyển sang xanh.
