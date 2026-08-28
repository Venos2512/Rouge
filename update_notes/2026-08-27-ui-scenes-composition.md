# Tách UI thành các scene có thể chỉnh sửa

## Mục tiêu
- Cho phép setup và thêm element UI trực tiếp trong Godot Editor.

## Scene mới
- `res://gungeon_proto/scenes/ui/game_ui.tscn`: composition root của UI gameplay.
- `res://gungeon_proto/scenes/ui/dungeon_hud.tscn`: HUD phòng, minimap, boss và vàng.
- `res://gungeon_proto/scenes/ui/inventory_overlay.tscn`: inventory.
- `res://gungeon_proto/scenes/ui/main_menu_overlay.tscn`: main menu.
- `res://gungeon_proto/scenes/ui/pause_runtime_menu.tscn`: pause menu.

## Thay đổi kiến trúc
- CoreRuntime instance `game_ui.tscn` thay vì tự gắn trực tiếp các overlay.
- `DungeonHUD` được chuyển khỏi `main.tscn` vào `game_ui.tscn`, tránh tạo HUD trùng.
- Main menu và pause menu được instantiate từ PackedScene.
- Các script hiện có vẫn chịu trách nhiệm cập nhật dữ liệu và hành vi; scene chịu trách nhiệm composition. Style được đặt trực tiếp trong từng scene.

## Cách kiểm thử
- Mở từng `.tscn` trong Godot Editor và thêm Control/Label/Panel tùy ý.
- Chạy main scene, kiểm tra HUD, inventory, main menu và pause vẫn xuất hiện.

## Lỗi hoặc việc còn lại
- Một số nội dung bên trong menu vẫn được tạo động bởi script cũ; có thể chuyển tiếp từng panel sang node con của scene khi cần custom layout sâu hơn.

## Bổ sung
- Inventory đã được chuyển hoàn toàn sang node con trong `inventory_overlay.tscn`; script chỉ cập nhật nội dung và visibility.
- Main Menu layout chính đã được chuyển thành node con trong `main_menu_overlay.tscn`; script chỉ kết nối button và điều khiển trạng thái.
- Màn chọn relic dùng ba Button node cố định trong scene; script chỉ cập nhật dữ liệu và kết nối lựa chọn.
