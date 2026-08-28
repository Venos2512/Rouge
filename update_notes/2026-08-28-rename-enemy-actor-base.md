# Đổi tên enemy_m5 thành enemy_actor_base

## Mục tiêu

Loại bỏ tên milestone lịch sử `enemy_m5` và đặt scene/script nền của enemy vào thư mục `base` rõ trách nhiệm.

## File thêm/sửa/xóa/di chuyển

- Di chuyển `res://gungeon_proto/scenes/actors/enemy_m5.tscn` thành `res://gungeon_proto/scenes/enemies/base/enemy_actor_base.tscn`.
- Di chuyển `res://gungeon_proto/scripts/enemies/enemy_m5.gd` và sidecar UID thành `res://gungeon_proto/scripts/enemies/base/enemy_actor_base.gd`.
- Chuyển `enemy_base.gd`, `enemy_fallback.gd`, `enemy_data_binding.gd` và các sidecar UID vào `scripts/enemies/base/`.
- Cập nhật 7 inherited scene: gunner, chaser, spread, elite, suicide bot, charger và shield.
- Sửa reference migrator và dọn cấu hình `GameplaySpawner.enemy_scene` cũ.

## Thay đổi gameplay hoặc kiến trúc

- Không thay đổi hành vi gameplay.
- Scene actor nền vẫn là nguồn composition chung cho 7 enemy.
- Toàn bộ base class, fallback và binding của actor nền nằm riêng trong thư mục `base`.
- GameplaySpawner tiếp tục spawn từ `EnemyData.scene`.

## Thông số trước/sau

- Không có thông số cân bằng thay đổi.

## Cách kiểm thử

- Mở lần lượt 7 scene enemy và xác nhận inherited base tải được.
- Chạy phòng thường có gunner, chaser, spread, suicide bot, charger và shield.
- Chạy phòng elite và xác nhận elite spawn bình thường.
- Kiểm tra Output không có lỗi preload, ext_resource hoặc đường dẫn `enemy_m5` bị thiếu.

## Lỗi hoặc việc còn lại

- `enemy_fallback.gd` vẫn được giữ làm hành vi tối thiểu của actor base khi scene nền chạy trực tiếp.
