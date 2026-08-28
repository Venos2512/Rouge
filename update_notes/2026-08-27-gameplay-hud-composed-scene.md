# Gộp Gameplay HUD thành scene

## Thay đổi
- Thêm `res://gungeon_proto/scenes/ui/gameplay_hud.tscn` với slot HP, vàng, weapon và relic có sẵn.
- `game_ui.tscn` instance GameplayHUD cùng DungeonHUD.
- Tắt WeaponIconHUD cũ và HUD relic tạo động.
- Script mới chỉ cập nhật node, không tạo Control runtime.
- Inventory được tách thành scene độc lập ngoài `game_ui.tscn`.
- Đã bỏ `DevTools` weapon-spawn khỏi CoreRuntime.
- Đã xóa `Player/WeaponInventoryUI` cũ, tránh trùng với weapon slots trong GameplayHUD.
- Ẩn HP/hint cũ trong `dungeon_hud.tscn` để tránh chồng với GameplayHUD mới; giữ node trong scene để chỉnh sửa sau.
- Đã xóa hoàn toàn ControllerDebugOverlay và phím debug backtick khỏi runtime.

## Cách chỉnh
- Mở `gameplay_hud.tscn` trong Godot.
- Chỉnh các node `TopLeft`, `TopRight`, `BottomRight`, `Weapon1..9`, `Relic1..6`.
