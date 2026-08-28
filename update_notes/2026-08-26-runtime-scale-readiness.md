# Runtime scale readiness — 26/08/2026

## Mục tiêu

Sửa cấu hình runtime bị hỏng và giảm số vị trí phải sửa khi thêm loại enemy mới.

## File thêm

- `res://update_notes/2026-08-26-runtime-scale-readiness.md`

## File sửa

- `res://gungeon_proto/scenes/gameplay/core_runtime.tscn`
- `res://gungeon_proto/scripts/core/runtime_validator.gd`
- `res://gungeon_proto/scripts/enemies/enemy_data.gd`
- `res://gungeon_proto/scripts/gameplay/gameplay_spawner.gd`
- Các resource enemy trong `res://gungeon_proto/resources/enemies/`

## File di chuyển hoặc xóa

- Di chuyển baseline từ `res://2026-08-26-project-baseline.md` sang `res://update_notes/2026-08-26-project-baseline.md`.
- Xóa file tạm `res://gungeon_proto/main.tscn5444608997.tmp`; file này còn tham chiếu script migration cũ và không thuộc runtime.

## Thay đổi kiến trúc và gameplay

- `EnemyData` nhận thêm trường `scene: PackedScene` và trở thành nguồn ánh xạ ưu tiên từ dữ liệu enemy sang scene runtime.
- `GameplaySpawner` đọc scene từ `EnemyData`; bảng `match` cũ chỉ còn là fallback tương thích cho resource chưa migrate.
- Các enemy đang nằm trong `EnemyDatabase` đã được gắn scene trực tiếp trong resource.
- `RuntimeValidator` kiểm tra các scene bắt buộc của `GameplaySpawner` thay vì chỉ kiểm tra node service.
- Sửa boss scene từ đường dẫn `scenes/actors/boss_m5.tscn` không tồn tại sang `scenes/enemies/bosses/boss.tscn`.
- Không thay đổi chỉ số, sát thương, tốc độ hoặc spawn weight.

## Cách kiểm thử

1. Mở `res://gungeon_proto/scenes/gameplay/core_runtime.tscn`; xác nhận không còn lỗi load boss scene.
2. Chạy `res://gungeon_proto/main.tscn`; Output phải có `CoreRuntime OK` và `spawn configuration OK`.
3. Vào nhiều phòng combat và xác nhận Gunner, Chaser, Spread, Suicide Bot và Elite vẫn spawn đúng.
4. Kiểm thử với 1, 5 và nhiều enemy; xác nhận room clear và reward vẫn hoạt động.
5. Tạo thử một `EnemyData` mới có scene, thêm vào `EnemyDatabase`, rồi xác nhận không cần thêm nhánh vào `_get_enemy_scene()`.

## Lỗi hoặc việc còn lại

- Chưa tách các script lớn như `dungeon_main.gd` và `weapon_special_controller.gd`; nên thực hiện theo từng patch nhỏ có regression test.
- Các shim `v2`, `v3` và `runtime` vẫn được giữ để bảo toàn tương thích với scene/debug tool cũ.
- Môi trường chỉnh sửa hiện không có Godot CLI nên cần chạy kiểm thử parse/runtime trong Godot Editor.

## Bổ sung — tách combat feedback

### File thêm

- `res://gungeon_proto/scripts/core/combat_feedback_director.gd`

### Trách nhiệm được chuyển

- `CombatFeedbackDirector` nhận trách nhiệm tạo damage number, chuyển camera shake tới Player, điều phối hit stop chồng lấn và khôi phục `Engine.time_scale` khi thoát runtime.
- `dungeon_main.gd` giữ ba API công khai cũ làm lớp chuyển tiếp để enemy, projectile, prop và weapon hiện tại không cần thay đổi đồng loạt.
- `CoreRuntime` chứa director mới và `RuntimeValidator` kiểm tra cả node lẫn `damage_number_scene` bắt buộc.

### Gameplay trước/sau

- Damage number, camera shake và hit stop giữ nguyên tham số, thời lượng và quy tắc ưu tiên hit stop mới nhất.
- Không thay đổi cân bằng combat.

### Kiểm thử bổ sung

1. Gây sát thương lên enemy và Player; xác nhận damage number vẫn xuất hiện đúng vị trí và màu.
2. Dùng melee, projectile, bomb và prop để xác nhận camera shake vẫn chạy.
3. Tạo nhiều hit stop liên tiếp; xác nhận game trở lại `Engine.time_scale = 1.0` sau hiệu ứng cuối.
4. Pause, chết, trở về menu và chạy lượt mới; xác nhận time scale không bị giữ ở trạng thái chậm.

## Bổ sung — Godot CLI

### File thêm

- `res://tools/godot.cmd`

### Thay đổi công cụ

- Thêm launcher project trỏ tới Godot `4.7.2.stable.official` hiện có trên máy.
- Có thể gọi `tools\godot.cmd --version` để kiểm tra phiên bản.
- Có thể gọi `tools\godot.cmd --headless --editor --path . --quit` từ project root để kiểm tra parser, scene và resource.

### Kết quả kiểm thử

- Godot headless editor đã quét toàn bộ project và thoát mà không báo lỗi parser, scene hoặc resource.
- Những lỗi AppData ở lần chạy sandbox đầu tiên là giới hạn quyền ghi của môi trường; lần chạy đầy đủ ngoài sandbox không có lỗi.

## Bổ sung — tách trình bày Dungeon HUD

### File thêm

- `res://gungeon_proto/scripts/ui/dungeon_presentation_director.gd`

### File sửa

- `res://gungeon_proto/scripts/core/dungeon_main.gd`
- `res://gungeon_proto/scripts/core/runtime_validator.gd`
- `res://gungeon_proto/scripts/ui/dungeon_hud_controller.gd`
- `res://gungeon_proto/scenes/gameplay/core_runtime.tscn`

### Thay đổi kiến trúc

- `DungeonPresentationDirector` nhận trách nhiệm theo dõi vàng, boss, HP boss và floor để điều phối HUD.
- `dungeon_main.gd` không còn gọi cập nhật gold/boss trong `_process()` và không còn chứa hai hàm trình bày tương ứng.
- `DungeonHUD` có API theo giá trị (`update_gold_value`, `update_boss_actor`); API cũ vẫn được giữ để tương thích.
- `RuntimeValidator` yêu cầu `DungeonPresentationDirector` trong composition của `CoreRuntime`.

### Thông số trước/sau

- Trước: gold và boss HUD được cập nhật mỗi frame; tìm boss bằng group query mỗi frame.
- Sau: kiểm tra trạng thái HUD mỗi `0.1` giây và chỉ ghi Control khi giá trị thay đổi.
- Gameplay và chỉ số combat không thay đổi; độ trễ trình bày tối đa là `0.1` giây.

### Cách kiểm thử

1. Nhặt và tiêu vàng, xác nhận GoldLabel đổi đúng trong tối đa `0.1` giây.
2. Vào boss room, gây sát thương liên tục và xác nhận boss bar theo đúng HP.
3. Hạ boss, chuyển floor và xác nhận boss bar ẩn, nhãn floor cập nhật đúng.
4. Chạy Godot headless editor để kiểm tra parser/resource và smoke-test runtime ít nhất 180 frame.

### Kết quả

- Godot `4.7.2` headless editor parse project sạch.
- Runtime headless chạy 180 frame và thoát không có lỗi.

## Bổ sung — consolidation kiến trúc và regression checks

### File thêm

- `res://gungeon_proto/resources/enemies/bomber.tres`
- `res://gungeon_proto/resources/enemies/gunner_elite.tres`
- `res://gungeon_proto/scenes/enemies/tactical_gunner.tscn`
- `res://gungeon_proto/scripts/weapons/specials/sword_special_handler.gd`
- `res://gungeon_proto/scripts/weapons/specials/spear_special_handler.gd`
- `res://gungeon_proto/scripts/weapons/specials/hammer_special_handler.gd`
- `res://gungeon_proto/scripts/weapons/specials/weapon_special_router.gd`
- `res://tests/architecture_smoke_test.gd`
- `res://tools/check_project.cmd`

### Enemy catalog

- Bomber và Tactical Gunner/Gunner Elite đã có `EnemyData` và scene riêng trong database.
- `GameplaySpawner` không còn preload từng enemy scene hoặc dùng bảng `match` để ánh xạ `enemy_type`.
- Spawn theo ID chưa đăng ký giờ báo lỗi database rõ ràng thay vì âm thầm tạo fallback.
- Spawn weight trước/sau giữ nguyên về hành vi: Bomber vẫn có nhánh xuất hiện `22%` trong normal wave; các weight khác không đổi.

### Weapon special

- Input policy và dispatch của Sword, Spear, Hammer được tách thành handler riêng.
- `WeaponSpecialController` vẫn giữ state và execution API hiện tại để bảo toàn timing, charge, parry và Hammer physics.
- Đây là ranh giới module để tiếp tục chuyển từng implementation ra ngoài mà không làm phình `_process()`.

### Room lifecycle và combat query

- Đếm enemy sống chuyển về `RoomDirector`; Main chỉ giữ wrapper tương thích.
- Xóa `_clear_group()` không còn sử dụng khỏi Main.
- `EnemyCrowdService` cung cấp spatial query `get_enemies_near()`.
- Player bullet và melee dùng spatial snapshot, có fallback về scene group nếu service không tồn tại.
- Các explosion/query hiếm vẫn giữ group query trực tiếp để không đổi thứ tự physics hoặc hit semantics.

### Dọn migration

- Scene và script đã chuyển sang canonical `game_input_runtime`, `weapon_stack_hud`, `carryable_prop`, `carryable_explosive_barrel`, training dummy/controller runtime.
- Xóa các shim root, `v2`, `v3` và UID tương ứng sau khi thay toàn bộ reference runtime/scene.
- Xóa breakpoint trỏ tới shim cũ.
- `ReferencePathMigrator` không còn chạy lúc game boot; tool vẫn được giữ trong `scripts/debug` để dùng thủ công.

### Regression checks

- `architecture_smoke_test.gd` kiểm tra EnemyDatabase, ID trùng, scene thiếu, CoreRuntime service, shim quay lại và khả năng instantiate 1, 5, 40 enemy.
- `tools/check_project.cmd` chạy headless editor parse trước, sau đó chạy architecture smoke test.
- Runtime headless đã chạy 600 frame không lỗi sau consolidation.

### Việc còn lại

- Cần kiểm thử tương tác bằng controller/mouse trong Godot Editor cho parry, spear charge/release và Hammer launch chain.
- Spatial snapshot cập nhật theo nhịp của `EnemyCrowdService`; cần profiler thực tế nếu số enemy vượt xa stress scenario hiện tại.

## Bổ sung — hoàn thiện ranh giới runtime

### File thêm

- `res://gungeon_proto/scripts/core/core_runtime.gd`

### Thay đổi kiến trúc

- Root `CoreRuntime` trở thành service registry và cache service theo tên.
- `dungeon_main.gd` lấy DungeonGenerator, RoomDirector, RoomFlowDirector, GameplaySpawner, CombatFeedbackDirector, ShopDirector và RewardDirector qua một API registry duy nhất.
- Main tiếp tục giữ façade API công khai để actor cũ không phụ thuộc trực tiếp vào composition nội bộ.
- Script lớn không được tách cơ học nếu phần code còn chung state/physics; weapon special đã có router/handler boundary và contract test trước khi tiếp tục extraction implementation.

### Regression bổ sung

- Architecture smoke test yêu cầu CoreRuntime có `get_service()`.
- Thêm fake-controller contract test cho Sword parry, Spear charge/release và Hammer charge/release.
- Contract test xác nhận thứ tự start, update và release không đổi sau khi tách router.

### Tiêu chí hoàn tất kiến trúc

- Scene composition có registry rõ ràng.
- Main là state owner và compatibility façade; director/service sở hữu implementation theo miền.
- Enemy content thêm qua resource/database, không qua hard-code scene map.
- Weapon input dispatch tách theo handler.
- Runtime validation, architecture regression và CLI smoke test đều có thể chạy lại tự động.

## Bổ sung — kiến trúc special weapon dạng provider

### File thêm

- `res://gungeon_proto/scripts/weapons/specials/weapon_special_provider.gd`
- `res://gungeon_proto/scripts/weapons/specials/weapon_special_provider_data.gd`
- `res://gungeon_proto/scripts/weapons/specials/weapon_special_catalog.gd`
- `res://gungeon_proto/scripts/weapons/specials/legacy_melee_special_provider.gd`
- `res://gungeon_proto/resources/weapons/weapon_special_catalog.tres`

### File di chuyển

- Implementation cũ của `weapon_special_controller.gd` chuyển sang `legacy_melee_special_provider.gd`, giữ UID và toàn bộ logic gameplay.
- `weapon_special_controller.gd` mới là orchestrator generic, không chứa implementation Sword, Spear hoặc Hammer.

### Ranh giới mới

- `WeaponSpecialProvider` định nghĩa contract `setup(player)`, `set_special_active(active)` và `get_supported_weapon_ids()`.
- `WeaponSpecialProviderData` ánh xạ một hoặc nhiều weapon ID tới provider script.
- `WeaponSpecialCatalog` là nguồn đăng ký provider và phát hiện weapon ID trùng.
- `WeaponSpecialController` tạo provider từ catalog, theo dõi weapon hiện tại và chỉ kích hoạt provider tương ứng.
- `LegacyMeleeSpecialProvider` đóng gói Sword, Spear và Hammer hiện tại để giữ nguyên feel trong khi không làm controller generic phình thêm.

### Cách thêm special weapon mới

1. Tạo script kế thừa `WeaponSpecialProvider`.
2. Provider tự sở hữu state, input handling, helper node và cleanup của special đó.
3. Tạo `WeaponSpecialProviderData` trong `weapon_special_catalog.tres`, khai báo `weapon_ids` và `provider_script`.
4. Không sửa `WeaponSpecialController`, router hoặc `CoreRuntime`.
5. Chạy `tools\check_project.cmd` để kiểm tra ID trùng, provider contract, parser và resource.

### Validation và regression

- `RuntimeValidator` kiểm tra `provider_catalog` đã được gắn vào controller.
- Architecture smoke test load catalog, chạy validate, dựng controller generic và xác nhận Sword/Spear/Hammer được đăng ký.
- Provider không kế thừa `WeaponSpecialProvider` bị từ chối với lỗi rõ ràng.
- Contract test input cũ tiếp tục bảo vệ thứ tự parry, charge, update và release.

### Gameplay trước/sau

- Không thay đổi timing, damage, charge duration, parry window, Hammer physics hoặc game-feel parameters.
- Khi đổi weapon trong lúc giữ nút special, provider mới đồng bộ trạng thái nút và không tạo một lần `pressed` giả.

## Bổ sung — tách provider Sword, Spear và Hammer

### File thêm

- `res://gungeon_proto/scripts/weapons/specials/sword_special_provider.gd`
- `res://gungeon_proto/scripts/weapons/specials/spear_special_provider.gd`
- `res://gungeon_proto/scripts/weapons/specials/hammer_special_provider.gd`

### File đổi vai trò

- `legacy_melee_special_provider.gd` đổi thành `melee_special_provider_base.gd` và giữ UID.
- Base chứa thuật toán dùng chung/implementation đã ổn định; không còn tự đăng ký weapon ID.
- Sword, Spear và Hammer là ba provider instance riêng, mỗi instance sở hữu state charge/parry/input lifecycle độc lập.

### Catalog trước/sau

- Trước: một catalog entry ánh xạ chung `sword`, `spear`, `hammer` tới một provider instance.
- Sau: ba catalog entry, ba provider script và ba provider instance độc lập.
- Controller kiểm tra `weapon_ids` khai báo trong catalog phải khớp chính xác `get_supported_weapon_ids()` của provider.

### Tối ưu helper

- Progress helper vẫn được tạo theo lifecycle của từng provider.
- Hammer spin helper chỉ được tạo bởi Hammer provider; Sword và Spear không còn cấp phát helper Hammer.

### Regression bổ sung

- Architecture smoke test yêu cầu controller tạo đúng ba provider.
- Test xác nhận từng provider chỉ sở hữu một tập ID: `[sword]`, `[spear]`, `[hammer]`.
- Parser/resource check tiếp tục xác nhận catalog và provider inheritance hợp lệ.

### Gameplay

- Không đổi parry window, charge duration, projectile, Hammer target/launch/impact hoặc game-feel.
- Chỉ provider tương ứng weapon đang trang bị được process.

## Bổ sung — di chuyển implementation vào provider riêng

### Phân chia cuối

- `melee_special_provider_base.gd`: 537 dòng, chỉ giữ lifecycle, input edge, player/weapon context, progress, attack block, aim, FX và game-feel helper dùng chung.
- `sword_special_provider.gd`: 193 dòng, sở hữu toàn bộ parry window, bullet interception và counter projectile.
- `spear_special_provider.gd`: 117 dòng, sở hữu charge/update/release và spear projectile.
- `hammer_special_provider.gd`: 1.422 dòng, sở hữu charge, target collection, launch, airborne chain, impact, destination và knockback multiplier.
- `weapon_special_controller.gd`: 196 dòng, chỉ làm provider orchestration/catalog selection.

### Kết quả kiến trúc

- Hàm đặc thù Sword, Spear và Hammer không còn nằm trong base chung.
- State được kế thừa nhưng tồn tại trên ba provider instance riêng; provider không active không process.
- Sửa Sword không yêu cầu mở Hammer/Spear provider và ngược lại.
- Special weapon mới không sửa bất kỳ provider hiện tại nào.

### Kiểm thử

- Godot 4.7.2 headless editor parse sạch sau khi di chuyển function blocks.
- Architecture regression suite thành công.
- Runtime headless chạy 600 frame không lỗi.
- Vẫn cần kiểm thử input tương tác trong Editor cho feel/timing thực tế.

## Bổ sung — kiến trúc primary attack scalable

### File thêm

- `res://gungeon_proto/scripts/weapons/attacks/weapon_attack_provider.gd`
- `res://gungeon_proto/scripts/weapons/attacks/weapon_attack_controller.gd`
- `res://gungeon_proto/scripts/weapons/attacks/projectile_attack_provider.gd`
- `res://gungeon_proto/scripts/weapons/attacks/melee_attack_provider.gd`
- `res://gungeon_proto/scripts/weapons/attacks/sword_combo_attack_provider.gd`
- `res://gungeon_proto/scripts/weapons/weapon_database.gd`
- `res://gungeon_proto/resources/weapons/weapon_database.tres`

### Primary attack provider contract

- `WeaponAttackProvider` định nghĩa `tick(delta)` và `perform_attack(player, weapon, aim_direction, weapon_system, god_mode)`.
- `WeaponAttackController` đọc provider từ `WeaponData`, tạo một provider instance riêng cho từng weapon ID và trả kết quả chung gồm performed/cooldown/recoil/muzzle flash.
- Provider không kế thừa `WeaponAttackProvider` bị từ chối với lỗi rõ ràng.
- Hai weapon dùng cùng provider script vẫn có state instance riêng, tránh combo/charge rò khi đổi weapon.

### Archetype hiện tại

- Pistol, Shotgun, Machine Gun dùng `ProjectileAttackProvider`; pellets và spread vẫn lấy từ data.
- Spear và Hammer primary dùng `MeleeAttackProvider`.
- Sword combo được chuyển hoàn toàn khỏi Player sang `SwordComboAttackProvider`; combo state và reset timer thuộc provider.
- Player `_shoot()` không còn phân nhánh theo melee/ranged, style hoặc tên weapon.

### Weapon data

- `attack_provider`: script thực thi primary attack.
- `uses_ammo`: quyết định ammo/reload, không còn suy luận từ melee/ranged.
- `hud_icon_id`: chọn icon archetype cho HUD.
- `pickup_color`: màu presentation của pickup.
- Các trường combat cũ giữ nguyên để bảo toàn gameplay và upgrade compatibility.

### Weapon database

- `Player.tscn` chỉ tham chiếu `weapon_database.tres` thay vì sáu resource riêng.
- Thêm weapon mới bằng cách tạo `WeaponData` rồi thêm vào database; không sửa Player scene composition.
- Database kiểm tra resource null, ID rỗng/trùng và attack provider thiếu.
- WeaponSystem giữ `weapon_resources` làm fallback cho scene/debug cũ.

### HUD và pickup

- Ammo HUD đọc `uses_ammo`; weapon không dùng ammo hiển thị vô hạn mà không cần danh sách ID hard-code.
- HUD đọc `hud_icon_id` từ runtime data.
- Weapon pickup đọc display name, type và color từ WeaponDatabase; xóa nhánh theo Sword/Shotgun/Machine Gun.

### Cách thêm weapon mới

1. Chọn provider hiện có hoặc tạo script mới kế thừa `WeaponAttackProvider`.
2. Tạo `WeaponData`, khai báo stats, `attack_provider`, `uses_ammo`, `hud_icon_id` và `pickup_color`.
3. Thêm resource vào `weapon_database.tres`.
4. Nếu có special, tạo `WeaponSpecialProvider` và thêm entry vào `weapon_special_catalog.tres`.
5. Không sửa Player, WeaponSystem, WeaponAttackController hoặc WeaponSpecialController.

### Regression

- Kiểm tra tất cả weapon resource có ID duy nhất và provider đúng contract.
- Kiểm tra Player scene có WeaponAttackController.
- Kiểm tra hai weapon ID dùng cùng provider script vẫn nhận hai instance khác nhau.
- Execution regression equip và đánh thử cả sáu weapon; ranged phải tạo projectile, melee không tạo projectile.

### Tách presentation khỏi Player

- `WeaponAttackProvider` sở hữu thêm hook `draw_held_weapon()`.
- Gun, melee cơ bản và sword combo tự vẽ presentation qua provider tương ứng.
- Xóa nhánh `melee/ranged` và toàn bộ trạng thái sword swing khỏi `Player`; thêm archetype mới không cần sửa `_draw()`.
- Bổ sung fallback lifecycle parry trong base special provider để mọi provider con parse độc lập.

### Sửa stale enemy reference trong spatial query

- `EnemyCrowdService.get_enemies_near()` kiểm tra `is_instance_valid()` trên Variant trước khi cast sang `Node2D`.
- Tránh lỗi `Trying to cast a freed object` trong khoảng ngắn giữa lúc enemy bị giải phóng và lần refresh spatial cache tiếp theo.
- Không thay đổi bán kính query, nhịp cache hoặc hành vi va chạm projectile.

### Sample PNG cho player và map

- Thêm `player_sample.png`, `room_floor_sample.png` và `world_background_sample.png` kích thước 32x32.
- Player dùng `Sprite2D` và texture PNG thay cho khối hình vẽ trực tiếp; hit flash và roll vẫn đổi tint runtime.
- `RoomVisualTheme` nhận texture background/floor, cho phép thay skin map chỉ bằng resource.
- Floor và background dùng texture trung tính để màu room type tiếp tục được áp qua theme.
- Thêm `tools/generate_sample_art.gd` để tái tạo placeholder PNG deterministic.
