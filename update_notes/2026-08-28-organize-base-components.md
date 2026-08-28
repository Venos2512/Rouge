# Tách riêng các base scene và base script

## Mục tiêu

Gom các scene/script nền dùng chung vào thư mục `base`, tách khỏi implementation gameplay cụ thể.

## File thêm/sửa/xóa/di chuyển

- Chuyển enemy base class, fallback và data binding vào `res://gungeon_proto/scripts/enemies/base/`.
- Giữ enemy actor scene tại `res://gungeon_proto/scenes/enemies/base/`.
- Chuyển melee special provider base vào `res://gungeon_proto/scripts/weapons/specials/base/`.
- Chuyển interface `weapon_special_provider.gd` vào cùng thư mục `specials/base/`.
- Cập nhật reference của 7 enemy và Sword/Spear/Hammer special provider.
- Di chuyển toàn bộ sidecar `.gd.uid` cùng script tương ứng.

## Thay đổi gameplay hoặc kiến trúc

- Không thay đổi gameplay.
- Base component không còn nằm lẫn với enemy hoặc weapon implementation cụ thể.
- Các file database/service/data không bị chuyển vì không phải base class hoặc base scene.
- Bỏ global `class_name MeleeSpecialProviderBase` vì các provider cụ thể kế thừa bằng đường dẫn; tránh xung đột global script class sau khi di chuyển.

## Thông số trước/sau

- Không thay đổi thông số cân bằng.

## Cách kiểm thử

- Mở và chạy các scene gunner, chaser, spread, elite, suicide bot, charger và shield.
- Kích hoạt special của Sword, Spear và Hammer.
- Kiểm tra Output không có lỗi `extends`, preload hoặc đường dẫn file cũ.

## Lỗi hoặc việc còn lại

- Chưa chạy Godot headless vì executable Godot không có trong môi trường hiện tại.
