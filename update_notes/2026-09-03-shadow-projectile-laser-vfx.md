# Cải thiện shadow, projectile glow và laser beam 3D

## Mục tiêu

Làm bóng realtime rõ hơn ở world scale nhỏ, tăng khả năng đọc của đạn và bổ sung beam 3D cho Laser Rifle.

## File thêm/sửa

- Sửa `res://gungeon_proto/scripts/presentation/planar_3d_presenter.gd`.
- Thêm note này.

## Thay đổi

- Tắt `shadow_blur`/PCSS của KeyLight, giảm vùng shadow camera từ `28.0` xuống `18.0`, và bổ sung bias để hạn chế bóng vỡ/khấp khểnh.
- Projectile 3D tiếp tục dùng emissive glow material.
- Laser Rifle có beam 3D gồm halo, core sáng và impact orb; beam chỉ hiện trong thời gian bắn.
- Beam dùng material lit per-pixel với emission nhẹ; BeamLight chỉ bổ sung ánh sáng cục bộ quanh muzzle, không thay thế geometry.
- Sửa shadow acne dạng sọc chéo: floor chỉ nhận shadow, không cast shadow; tăng bias nhẹ cho world scale nhỏ.
- Wall segment tiếp tục cast shadow. Directional shadow chuyển sang 4 cascade, shadow map 8192 (mobile 4096), tắt PCSS/constant blur và dùng bộ lọc sắc hơn để cải thiện bóng của toàn bộ geometry mà không thay đổi world scale.
- Theo yêu cầu kiểm thử trực quan, đổi `WORLD_SCALE` từ `0.02` lên `1.0`; cập nhật smoke test căn cửa theo cùng scale. Thay đổi này phóng không gian presentation 3D lên 50 lần so với gameplay pixel-unit trước đó.
- Scale đồng bộ model/proxy, room thickness/height, camera, light range, fog, SSAO, billboard và VFX bằng `VISUAL_UNIT_SCALE = 50.0`, giữ tỷ lệ hình ảnh cũ trong world mới.
- Loại sọc dithering chéo trên bề mặt lit: tắt SSAO screen-space và chuyển directional shadow filter sang Hard (`0`).
- Sửa Laser Rifle dùng model FBX không tạo beam do `_rebuild_weapon_mesh()` return sớm; thêm smoke check cho `LaserBeam3D` ở nhánh model thật.
- Sửa VFX sau normalize scale: melee offset chia `VISUAL_UNIT_SCALE` trước khi proxy scale, tránh bị đẩy xa 50 lần; giảm chu kỳ phát hiện proxy từ `0.12s` xuống `0.025s` để không bỏ lỡ VFX sống ngắn 0.12–0.18 giây.
- Tăng readability cho ranged combat: muzzle flash dùng lõi emissive + halo và light energy `2.6 → 4.5`; projectile dùng material unshaded emissive `3.4 → 5.5` kèm halo trong suốt, không thêm light riêng cho từng viên để giữ hiệu năng.
- Thay presentation Player/Enemy/Boss từ authored/imported model sang capsule procedural có box nhô về local +X để biểu thị hướng mặt; bỏ enemy identity equipment khỏi runtime presentation và cập nhật smoke test.
- Sửa self-shadow acne trên primitive sau khi world tăng 50 lần: `shadow_bias 0.08 → 1.0`, `shadow_normal_bias 0.35 → 4.0`, bật reverse-face shadow culling; vẫn giữ cast shadow cho primitive.
- Projectile và laser giữ material emission thật, đồng thời bổ sung illumination realtime: projectile có `ProjectileEmissionLight3D` theo ngân sách tối đa 8 combat lights; laser tăng BeamLight range và đặt giữa beam để chiếu sáng sàn/vật thể, shadow của VFX light vẫn tắt.
- Chuyển `TopDownCamera3D` từ orthographic sang perspective, giữ trục nhìn top-down nghiêng hiện tại. FOV được tính lại theo chiều cao viewport và khoảng cách tới focus plane (giới hạn `35–75°`) để gần với framing một world-unit/pixel cũ; near/far đặt `2 / 5000` world units.

## Cách kiểm thử

- Chạy `res://tests/top_down_3d_smoke_test.gd` trong Godot.
- Kiểm tra gameplay với Player/Enemy ở gần và xa camera, đạn thường và Laser Rifle.

## Việc còn lại

- Cần xác nhận trực quan trong Godot Editor vì môi trường hiện không có executable Godot để chạy headless test.
