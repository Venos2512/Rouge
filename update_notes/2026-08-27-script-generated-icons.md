# Script-generated icon assets

## Mục tiêu
- Bổ sung PNG hình khối đơn giản cho relic, vũ khí và suicide bot, được tạo bằng Godot script.

## File thêm/sửa
- Thêm `tools/generate_icon_art.gd`.
- Thêm PNG vào `gungeon_proto/assets/icons/relics`, `weapons` và `enemies`.
- Thêm `icon_texture` vào `WeaponData` và `EnemyData`.
- Nối texture vào resource weapon và `suicide_bot.tres`.
- `GameHudIcon` ưu tiên texture PNG và giữ fallback vẽ bằng script.
- Upgrade choice có icon riêng; weapon HUD hiển thị icon kèm tên; relic HUD chỉ hiển thị icon.
- Đổi tên weapon icon theo tiền tố `weapon_`; HUD đọc texture từ `WeaponData.icon_texture`, còn pickup mặt đất giữ lại kiểu vẽ script cũ.

## Cách kiểm thử
- Chạy `godot --headless --path . --script res://tools/generate_icon_art.gd` và kiểm tra log `ICON_ART_OK`.
- Mở project bằng Godot, chạy scene khởi động, kiểm tra HUD weapon/relic và resource enemy.

## Lỗi hoặc việc còn lại
- Đây là placeholder art hình khối, chưa phải art production.
