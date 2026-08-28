# Nền móng loại sát thương

## Mục tiêu

Chuẩn hóa dữ liệu của một lần gây sát thương để weapon, projectile, melee,
explosion, enemy, player và vật thể môi trường có thể trao đổi loại sát thương,
cách truyền sát thương và kết quả hit mà không tiếp tục mở rộng
`take_damage(amount)` thành nhiều chữ ký khác nhau.

## File thêm

- `res://gungeon_proto/scripts/combat/damage_types.gd`
- `res://gungeon_proto/scripts/combat/damage_info.gd`
- `res://gungeon_proto/scripts/combat/damage_result.gd`
- `res://gungeon_proto/scripts/combat/damage_resolver.gd`
- `res://tests/damage_system_test.gd`

## File sửa

- `res://gungeon_proto/scripts/weapons/weapon_data.gd`
- `res://gungeon_proto/scripts/weapons/attacks/projectile_attack_provider.gd`
- `res://gungeon_proto/scripts/weapons/attacks/grenade_launcher_attack_provider.gd`
- `res://gungeon_proto/scripts/weapons/projectiles/bullet.gd`
- `res://gungeon_proto/scripts/weapons/projectiles/player_grenade.gd`
- `res://gungeon_proto/scripts/weapons/melee/melee_attack_system.gd`
- `res://gungeon_proto/scripts/enemies/base/enemy_base.gd`
- `res://gungeon_proto/scripts/player/player.gd`
- `res://gungeon_proto/scripts/props/room_prop.gd`
- `res://gungeon_proto/scripts/weapons/weapon_database.gd`
- `res://gungeon_proto/scripts/weapons/projectiles/enemy_bullet.gd`
- `res://gungeon_proto/scripts/weapons/projectiles/parry_counter_projectile.gd`
- `res://gungeon_proto/scripts/weapons/projectiles/spear_special_projectile.gd`
- `res://gungeon_proto/scripts/weapons/melee/milestone14_combat.gd`
- `res://gungeon_proto/scripts/weapons/melee/hammer_airborne_actor.gd`
- `res://gungeon_proto/scripts/weapons/specials/hammer_special_provider.gd`
- `res://gungeon_proto/scripts/enemies/base/enemy_fallback.gd`
- `res://gungeon_proto/scripts/enemies/chaser.gd`
- `res://gungeon_proto/scripts/enemies/charger.gd`
- `res://gungeon_proto/scripts/enemies/shield.gd`
- `res://gungeon_proto/scripts/enemies/bomber.gd`
- `res://gungeon_proto/scripts/enemies/bomber_bomb.gd`
- `res://gungeon_proto/scripts/enemies/suicide_bot.gd`
- `res://gungeon_proto/scripts/enemies/tactical_gunner.gd`
- `res://gungeon_proto/scripts/enemies/tactical_gunner_projectile.gd`
- `res://gungeon_proto/scripts/enemies/boss.gd`
- `res://gungeon_proto/scripts/gameplay/spike_trap.gd`
- `res://gungeon_proto/scripts/gameplay/saw_trap.gd`
- `res://gungeon_proto/scripts/props/carryable_prop.gd`
- `res://gungeon_proto/scripts/props/carryable_explosive_barrel.gd`
- `res://gungeon_proto/scripts/debug/dev_tools.gd`
- `res://gungeon_proto/scripts/debug/training/training_test_bullet.gd`
- `res://gungeon_proto/scripts/debug/training/training_dummy.gd`
- `res://gungeon_proto/scripts/debug/training/training_dummy_runtime.gd`

## Thay đổi gameplay và kiến trúc

- Thêm năm loại sát thương ban đầu: physical, fire, shock, poison và void.
- Tách loại sát thương khỏi cách truyền: melee, projectile, explosion, contact,
  trap và thrown prop.
- Weapon resource có trường `damage_type`; runtime dictionary giữ lại trường này.
- Weapon database báo lỗi nếu resource dùng damage type ngoài danh sách chuẩn;
  `DamageInfo` cũng lọc delivery tag và fallback loại không hợp lệ về physical.
- Player bullet, đòn melee chuẩn và grenade tạo `DamageInfo` rồi đi qua
  `DamageResolver`.
- Shield giữ phản ứng riêng với explosion: nhận 50% damage và không chặn lực hất,
  nhưng phản ứng này nay đọc delivery tag thay vì phụ thuộc API grenade riêng.
- Enemy kế thừa `enemy_base`, player và room prop hỗ trợ armor cùng bảng hệ số
  loại sát thương.
- Tactical gunner, bomber, boss, carryable prop, explosive barrel và training
  dummy đã dùng cùng receiver contract; mọi đối tượng có `take_damage` hiện đều
  có đường nhận `DamageInfo` trực tiếp hoặc kế thừa từ enemy base.
- Enemy melee/contact/projectile, bomb, suicide explosion, barrel explosion,
  trap, thrown prop, parry projectile, spear special, hammer collision,
  shockwave, wall slam và công cụ debug đã migrate khỏi call site damage cũ.
- Receiver cũ vẫn hoạt động thông qua fallback `take_damage(amount)`. Việc này
  cho phép migrate từng nhóm mà không làm hỏng combat đang chạy.
- Các consumer preload trực tiếp script combat và dùng kiểu nền `RefCounted`,
  không phụ thuộc thứ tự Godot cập nhật global class cache khi mở project.

## Thông số trước và sau

- Trước: mọi hit chỉ có `amount`; không có loại, tag truyền, nguồn hoặc kết quả.
- Sau: mặc định mọi weapon là physical, hệ số mặc định của mọi loại là `1.0`.
- Armor mặc định: `0`; mỗi điểm armor trừ một điểm sát thương sau multiplier,
  kết quả lẻ được làm tròn lên và tối thiểu bằng `0`.
- Room prop, carryable prop và explosive barrel nhận fire multiplier `1.5`;
  các loại khác giữ `1.0`.
- Các weapon resource hiện tại không khai báo trường mới vẫn tự dùng physical,
  vì vậy damage cơ bản không đổi.

## Cách kiểm thử

1. Chạy `res://gungeon_proto/main.tscn` và bắn enemy bằng pistol, shotgun và
   machine gun; damage phải giữ nguyên như trước.
2. Đánh enemy và room prop bằng sword, spear và hammer; không được gây hit hai lần.
3. Bắn grenade vào nhiều enemy và prop cùng lúc; mỗi mục tiêu chỉ nhận một hit.
4. Tạm đặt `damage_type = "fire"` trên một weapon resource, bắn room prop và xác
   nhận damage được nhân 1.5 sau khi làm tròn.
5. Tạm đặt armor trên player/enemy base thành `1`, kiểm tra sát thương giảm đúng
   một điểm và hit bằng 0 không tạo phản hồi nhận sát thương.
6. Lặp lại với 1, 5 và nhiều enemy để xác nhận resolver không tạo node hoặc tween
   bổ sung theo frame.
7. Chạy `res://tests/damage_system_test.gd`; kết quả phải là
   `DAMAGE_SYSTEM_TEST_OK`.

## Lỗi hoặc việc còn lại

- `take_damage(amount)` vẫn được giữ làm API tương thích cho addon hoặc nội dung
  ngoài danh sách hiện tại; code runtime trong project không còn gọi trực tiếp.
- Status effect như burn, shock chain và poison tick chưa được triển khai; bản này
  chỉ cung cấp metadata và điểm mở rộng an toàn.
