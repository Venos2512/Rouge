# Gameplay HUD thành scene UI

## Mục tiêu
- Đưa trạng thái người chơi vào `dungeon_hud.tscn` để chỉnh trực tiếp trong Godot.

## Thay đổi
- Thêm `PlayerStatus/HealthBar`, `PlayerStatus/HealthLabel` và `WeaponHint` làm node scene.
- Script chỉ cập nhật HP runtime.

## Cách kiểm thử
- Mở `res://gungeon_proto/scenes/ui/dungeon_hud.tscn` để chỉnh node.
- Chạy game và nhận sát thương để kiểm tra health bar.
