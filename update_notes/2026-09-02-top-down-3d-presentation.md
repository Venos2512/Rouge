# Chuyển lớp trình bày sang 3D top-down

## Mục tiêu

Chuyển runtime chính sang không gian 3D top-down nhưng giữ nguyên mô phỏng, AI, combat, dungeon, reward và dữ liệu cân bằng hiện có.

## File thêm/sửa

- Sửa `res://gungeon_proto/main.tscn`: root chuyển từ `Node2D` sang `Node3D`, thêm `Planar3DPresenter`.
- Sửa `res://gungeon_proto/scripts/core/dungeon_main.gd`: lớp tích hợp chính chuyển sang `Node3D` nhưng giữ nguyên API điều phối.
- Thêm `res://gungeon_proto/scripts/presentation/planar_3d_presenter.gd`: camera, ánh sáng, phòng và proxy 3D đồng bộ với mô phỏng gameplay.
- Thêm `res://gungeon_proto/scripts/presentation/authored_visual_3d.gd` và sửa toàn bộ enemy/Boss scene để visual 3D có thể chỉnh trực tiếp trong Godot Editor.
- Thêm `res://tests/top_down_3d_smoke_test.gd`: kiểm tra root, camera, proxy và việc ẩn canvas gameplay cũ.
- Thêm `res://gungeon_proto/resources/materials/colormap_material.tres`: `StandardMaterial3D` dùng chung, gán `albedo_texture = colormap.png`.
- Sửa toàn bộ 24 file `res://gungeon_proto/assets/models/pet/*.fbx.import` (player + mọi quái/boss dùng animal model): thêm `_subresources` remap material `"colormap"` sang `use_external` trỏ tới `colormap_material.tres` ở trên.

## Thay đổi gameplay và kiến trúc

- Gameplay tiếp tục được tính trên mặt phẳng 2D để không làm thay đổi tốc độ, khoảng cách, hit detection, AI và room flow.
- Vị trí gameplay `Vector2(x, y)` được trình bày tại `Vector3(x * 0.02, height, y * 0.02)`.
- Camera 3D orthographic bám theo tâm camera gameplay cũ, giữ phép ngắm chuột tương ứng với màn hình.
- Camera được nghiêng theo offset `(height: 13.5, depth: 4.2)` và phép ngắm chuột được chiếu bằng ray từ camera xuống mặt phẳng XZ.
- Camera follow dùng exponential smoothing độc lập FPS, có look-ahead 18 pixel theo hướng ngắm và nhận camera shake từ mô phỏng.
- Player proxy có chỉ báo hướng ngắm; roll có squash/stretch; actor có hit flash phát sáng.
- Melee FX và room FX quan trọng được mirror sang mesh phát sáng 3D thay vì biến mất cùng canvas gameplay cũ.
- Vũ khí đang trang bị có mesh 3D riêng cho pistol, shotgun, machine gun, laser rifle, grenade launcher, crossbow, sword, spear và hammer; ranged weapon có muzzle flash.
- Terrain wall nội bộ được mirror theo đúng `wall_size`, loại bỏ trường hợp collision tồn tại nhưng tường không hiển thị.
- Knockback velocity buộc proxy bám ngay vị trí mô phỏng để cú bật không bị camera/proxy smoothing lọc mất.
- Bomb và grenade dùng `explosion_visual_timer` cùng bán kính gameplay để bung vòng nổ 3D; bomb warning có nhịp pulse.
- Screen shake được cộng trực tiếp sau camera smoothing; damage number được hiển thị bằng `Label3D` billboard.
- Damage number dùng transform top-level và đồng bộ basis theo camera mỗi frame, nên không còn bị nghiêng theo rotation của actor/proxy.
- Mỗi enemy và boss có health bar 3D luôn hướng camera, tự cập nhật tỷ lệ và đổi màu xanh sang đỏ theo máu hiện tại.
- Lớp fill của health bar nằm về phía camera trong billboard basis, tránh bị nền tối che khi thanh đang đầy.
- Chaser, Gunner, Spread, Elite/Tactical, Shield, Charger, Suicide Bot và Bomber có silhouette, màu cùng phụ kiện vai trò riêng để đọc loại quái ngay trong combat.
- Shield có tấm khiên 3D bám đúng `facing_direction`; khiên ẩn trong thời gian guard-break và hiện lại khi hồi phục.
- Indicator 3D đọc trực tiếp melee wind-up, shield bash, charger wind-up, suicide fuse, bomber wind-up và tactical aim; indicator hướng theo cùng vector dùng bởi hit logic.
- Player proxy dùng `animal-cat.fbx`; enemy dùng animal model riêng theo vai trò: Dog/Chaser, Fox/Gunner, Bee/Spread, Lion/Elite, Monkey/Tactical, Polar/Shield, Cow/Charger, Crab/Suicide, Penguin/Bomber và Elephant/Boss.
- Vũ khí player dùng FBX mới cho Pistol, Shotgun, Machine Gun, Laser Rifle, Grenade Launcher, Sword, Spear và Hammer; Crossbow giữ mesh procedural vì pack hiện không có model crossbow.
- Gunner/Spread/Elite có blaster FBX riêng, Shield dùng `shield-round-a.fbx`, Bomber mang `grenade-a.fbx`; primitive tương ứng chỉ còn là fallback khi asset thiếu/import lỗi.
- Model FBX được đo bounds và scale tự động khi instantiate, tránh sai tỷ lệ giữa animal, blaster và bộ medieval.
- Lookdev chuyển sang palette dungeon tối: key light ấm, fill xanh, rim tím, ambient dịu, fog chiều sâu và Filmic tonemapping; glow/SSAO được bật khi renderer hỗ trợ.
- Sàn dùng một mặt phẳng màu tối, nhám hoàn toàn; đã bỏ grid và mesh đèn nằm sát mặt sàn để loại bỏ aliasing/z-fighting khi camera di chuyển. Mỗi phòng vẫn có bốn accent light không đổ bóng để định hình không gian.
- Player/enemy có contact shadow, spawn ring và hit glow. Projectile dùng emissive material; muzzle flash và explosion có omni light ngắn, không shadow và chỉ sáng khi effect hoạt động.
- Material StandardMaterial3D từ FBX được duplicate theo instance rồi cân lại roughness/specular, tránh sửa chung resource import hoặc làm mọi model đổi vật liệu đồng loạt.
- Player, enemy, boss, projectile, pickup, hazard và prop được tự động phát hiện theo group và có proxy 3D.
- Cửa 3D phản ánh kết nối phòng và trạng thái đã dọn phòng; tường vật lý 2D không bị tạo proxy trùng.
- Sàn, tường và cửa được dựng lại theo `current_room_rect` và `door_offsets` của từng phòng; lối đi nhìn thấy nay trùng với trigger chuyển phòng thật.
- Canvas gameplay cũ được ẩn; HUD, menu và minimap vẫn là UI màn hình.

## Thông số trước/sau

- Trước: runtime root `Node2D`, camera `Camera2D`, đồ họa gameplay canvas 2D.
- Sau: runtime root `Node3D`, camera `Camera3D` orthographic, tỷ lệ quy đổi `0.02` đơn vị 3D cho mỗi pixel gameplay.
- Camera trước/sau trong lớp 3D: độ lùi `7.2 -> 4.2`; follow cũ dùng lerp cố định `0.22/frame`, bản mới dùng tốc độ `11.0/s` độc lập FPS.
- Terrain wall trước/sau: không tạo proxy → box mesh dùng đúng footprint collision; explosion ring tối đa dùng bán kính thật của gameplay.
- Enemy trước/sau: capsule/màu chung, không health bar/telegraph → silhouette theo vai trò, health bar billboard và indicator trạng thái.
- Không thay đổi chỉ số combat, tốc độ, cooldown, máu, damage hoặc số lượng spawn.
- Dynamic VFX light trước/sau: không có → tối đa một hit/effect light trên proxy, shadow tắt; bốn accent light/phòng, shadow tắt. Directional key vẫn là nguồn shadow chính.
- Tối đa 8 hit/explosion/warning light được phép sáng đồng thời; proxy ngoài ngân sách vẫn giữ mesh VFX emissive nhưng không tạo thêm chi phí chiếu sáng động.
- Weapon pickup trên sàn đọc `weapon_id` và dựng đúng FBX/mesh fallback tương ứng; model được đặt ngang sát mặt sàn, không bob, có vòng emissive mỏng để nhận biết. Pickup khác vẫn giữ presentation cũ.
- Mỗi enemy `.tscn` và Boss scene có node `Visual3D` authored trực tiếp trong scene, chứa animal cùng trang bị liên quan. Node hiển thị trong editor nhưng tự ẩn bản nguồn lúc runtime; `Planar3DPresenter` duplicate node này sang proxy và chỉ dùng mapping code khi scene chưa có authored visual.

## Cách kiểm thử

1. Mở `res://gungeon_proto/main.tscn` và chạy project.
2. Kiểm tra player di chuyển, lăn, ngắm và bắn đúng hướng.
3. Vào phòng có 1, 5 và nhiều enemy; kiểm tra proxy theo sát vị trí và được giải phóng khi enemy chết.
4. Kiểm tra projectile hai phía, pickup, trap, prop, chuyển phòng, pause, chết và khởi động lượt mới.
5. Quan sát HUD/minimap vẫn hiển thị và camera không lệch khỏi tâm gameplay.

Smoke test tự động còn tạo và giải phóng 64 enemy giả để kiểm tra lifecycle proxy trong tình huống đông đối tượng.
Smoke test cũng tạo Shield thật và damage number thật để kiểm tra health bar, mesh khiên, guard-break, indicator wind-up và hướng billboard so với camera.
`model_asset_inspection.gd` xác nhận toàn bộ FBX đang dùng tải được và có visible mesh bounds hợp lệ.

## Lỗi hoặc việc còn lại

- Proxy đang dùng primitive 3D theo vai trò; model/animation 3D chuyên biệt có thể thay dần mà không đổi logic gameplay.
- Đã chạy bằng Godot 4.7.2: architecture, damage, dungeon variety và top-down 3D smoke test đều đạt; main scene chạy 180 frame không có lỗi project.
- Smoke test 3D kiểm tra thêm góc camera, chiếu chuột, vị trí cửa theo offset và chuyển thành công sang một phòng kề.
- Smoke test hiện đi vào encounter thật, xác nhận enemy mesh, held weapon, terrain wall, screen shake và displacement knockback.
- Chế độ headless trong sandbox báo không ghi được `user://logs` và không đọc được certificate store của Windows; đây là giới hạn môi trường kiểm thử, không phải lỗi scene hoặc gameplay.

## Fix bổ sung (2026-09-02): thiếu material trên model nhân vật/quái

- Phát hiện: toàn bộ 24 model `animal-*.fbx` (dùng cho Player và mọi Enemy/Boss qua `PLAYER_MODEL_PATH`/`ENEMY_MODEL_PATHS` và các node `Visual3D` authored) có material `colormap` nhưng `albedo_texture` bị `null` — model hiển thị trắng/không texture trong game lẫn khi mở scene trong editor. Model vũ khí (`Blaster`, `Medieval`) không bị ảnh hưởng, texture đã đúng sẵn.
- Nguyên nhân: file FBX gốc của bộ pet không tự resolve được ảnh `colormap.png` khi Godot import (khác với bộ blaster/medieval đã resolve đúng), xác nhận bằng script kiểm tra headless (`load()` từng fbx rồi soi `surface_get_material(...).albedo_texture`).
- Cách sửa: thêm material dùng chung `colormap_material.tres` và remap qua `_subresources` trong từng `*.fbx.import` của thư mục `assets/models/pet/` (Godot's material "use external" override), thay vì vá texture trong code trình bày — giữ đúng nguyên tắc "resource là nguồn cấu hình", không rải logic sửa material trong `planar_3d_presenter.gd`.
- Đã kiểm thử: script headless xác nhận cả 24 model đều có `albedo_texture` sau khi reimport; `res://tests/top_down_3d_smoke_test.gd` chạy lại vẫn `TOP_DOWN_3D_SMOKE_TEST_OK`; chạy `main.tscn` headless 120 frame không phát sinh lỗi mới.
- Việc còn lại: nên mở project trong Godot Editor để xác nhận trực quan Player, từng loại Enemy và Boss đều lên da/màu đúng khi test tay; nếu muốn player có silhouette riêng thay vì dùng chung mesh mèo, có thể thêm node `Visual3D` authored trực tiếp trong `player.tscn` tương tự các Enemy.

## Fix bổ sung (2026-09-02): đảm bảo cast shadow real-time cho actor dùng authored Visual3D

- Phát hiện: `_add_actor_model()` trong `res://gungeon_proto/scripts/presentation/planar_3d_presenter.gd` chỉ gọi `_tune_imported_meshes()` (hàm ép `cast_shadow = SHADOW_CASTING_SETTING_ON` và cân roughness/specular) ở nhánh fallback (khi scene chưa có node `Visual3D` authored). Nhánh dùng `Visual3D` authored — hiện toàn bộ Enemy/Boss đều dùng nhánh này — bỏ qua bước này, khiến việc đổ bóng real-time chỉ phụ thuộc giá trị mặc định lúc import FBX thay vì được đảm bảo tường minh trong code.
- Cách sửa: gọi thêm `_tune_imported_meshes(authored_copy)` ngay sau khi duplicate authored visual trong `_add_actor_model()`, để mọi actor (Player lẫn toàn bộ Enemy/Boss, dù dùng nhánh nào) đều chắc chắn `cast_shadow = ON` và material được cân sáng đồng nhất dưới `KeyLight` (DirectionalLight3D, `shadow_enabled = true`, nguồn đổ bóng real-time chính của scene).
- Không thêm shadow cho các light phụ (accent light, player fill light, muzzle light...) để giữ hiệu năng khi phòng có nhiều quái — đúng định hướng hiệu năng của dự án; toàn bộ shadow real-time vẫn tập trung vào một `DirectionalLight3D` duy nhất.
- Đã kiểm thử: chạy `res://tests/top_down_3d_smoke_test.gd` nhiều lần (headless, Godot 4.7.2) vẫn `TOP_DOWN_3D_SMOKE_TEST_OK`; cảnh báo "N ObjectDB leaked at exit" đã đối chiếu bằng `--verbose` — toàn bộ là `AudioStreamWAV/AudioStreamPlaybackWAV` và một `MeshInstance3D` mồ côi không liên quan tới material/mesh actor, số lượng dao động 7-8 giữa các lần chạy dù code không đổi (artifact non-deterministic của audio streaming trong headless, không phải leak do thay đổi này). Chạy lại `main.tscn` headless 150 frame không phát sinh lỗi mới.
- Việc còn lại: nên tự kiểm tra trực quan trong Godot Editor (chạy `main.tscn`) để xác nhận bóng đổ dưới chân Player/Enemy/Boss rõ nét theo `KeyLight`; có thể chỉnh `key_light.shadow_blur`/`directional_shadow_max_distance` nếu muốn bóng mềm/rõ hơn tuỳ thẩm mỹ.

## Fix bổ sung (2026-09-02): shadow_blur quá lớn khiến cast shadow real-time vô hình

- Phát hiện: sau khi đảm bảo `cast_shadow = ON` (fix phía trên), bóng đổ vẫn **không hiển thị** cho bất kỳ object nào (Player, Enemy, prop, weapon pickup) khi chơi thật — người dùng xác nhận bằng ảnh chụp gameplay thật.
- Cách điều tra: viết script headless/non-headless tự động (không dùng chuột/bàn phím OS — tự boot thẳng `main.tscn` qua `change_scene_to_packed`, tự ẩn `MainMenuOverlay`, tự chụp `get_viewport().get_texture().get_image()` rồi lưu PNG) để tái hiện chính xác màn hình người dùng gửi mà không phải thao tác trên desktop thật (tránh rủi ro đụng ứng dụng khác của người dùng). Đối chiếu màu pixel sàn dưới chân actor với sàn trống bằng script — xác nhận trước khi sửa, chênh lệch gần như bằng 0 (không có bóng thật).
- Đã cô lập bằng cách dựng lại chính xác environment/camera/floor của game trong scene tối giản và tắt/bật từng thuộc tính (`ambient_light_energy`, `fog_enabled`, `ssao_enabled`, `glow_enabled`, `tonemap_mode`, `fill_light`/`rim_light`, màu sàn, `directional_shadow_max_distance`) — nguyên nhân duy nhất là `key_light.shadow_blur = 1.8` trong `_create_environment()` (`res://gungeon_proto/scripts/presentation/planar_3d_presenter.gd`). Giá trị blur này được tuned cho world scale thông thường (1 unit ~ 1 mét), nhưng dự án dùng `WORLD_SCALE = 0.02` khiến toàn bộ actor/prop chỉ cao 0.4-1.5 đơn vị — blur 1.8 lớn hơn nhiều lần kích thước vật thể nên làm mờ bóng tới mức biến mất hoàn toàn khỏi khung hình, kể cả khi tăng cường độ sáng lên gấp nhiều lần.
- Cách sửa: giảm `key_light.shadow_blur` từ `1.8` xuống `0.3` — vẫn giữ bóng mềm nhẹ nhưng không còn bị làm mờ tới mức vô hình ở scale nhỏ của dự án.
- Đã kiểm thử: script tự động boot `main.tscn`, ẩn menu, chụp lại đúng phòng bắt đầu (giống ảnh người dùng gửi) — so màu pixel sàn dưới chân Player/prop trước và sau: trước fix ~(104-105) so với sàn trống (104), lệch ~0 (không bóng); sau fix ~(21-40) so với sàn trống (48-49), lệch rõ rệt (bóng hiển thị, xác nhận cả bằng crop phóng to). `top_down_3d_smoke_test.gd` chạy lại vẫn `TOP_DOWN_3D_SMOKE_TEST_OK`; `main.tscn` headless 150 frame không lỗi mới.
- Việc còn lại: `shadow_blur = 0.3` là giá trị hợp lý cho world scale hiện tại nhưng mang tính thẩm mỹ — có thể tinh chỉnh thêm (0.15–0.5) nếu muốn bóng sắc nét hơn hoặc mềm hơn khi xem trực tiếp trong Editor.
