# Sword combo ba đòn

## Mục tiêu

Đảm bảo ba lần click kiếm liên tiếp tạo thành chuỗi attack 1 → 2 → finisher thay vì mất input trong cooldown.

## File thêm/sửa

- Sửa `res://gungeon_proto/scripts/player/player.gd`.
- Dùng combo profile hiện có trong `res://gungeon_proto/scripts/weapons/attacks/sword_combo_attack_provider.gd`.

## Gameplay

- Thêm input buffer riêng cho Sword: `0.32s`.
- Đòn 1: slash nhanh, knockback nhẹ.
- Đòn 2: slash đảo chiều, range và knockback cao hơn.
- Đòn 3: finisher rộng, thêm damage, knockback và hit stop mạnh.
- Combo reset nếu không đánh tiếp trong `0.86s`.
- Model kiếm 3D đọc swing angle của provider: hit 1 quét trái→phải, hit 2 quét ngược, hit 3 quét cung rộng; không còn khóa thẳng theo aim như động tác chọc.
- Thêm `SwordTrail3D` bằng arc ribbon emissive trong mặt phẳng XZ; trail mở rộng theo tiến trình swing, đổi chiều cùng model kiếm, hit 3 cho cung rộng hơn và không cast shadow.
- Không mirror generic `melee_fx` khi `attack_style == "slash"`, loại BoxMesh trắng dài từng chồng lên arc mới; thrust của Spear và smash của Hammer vẫn giữ proxy riêng.
- Đồng bộ hit thật vào 34% thời lượng swing thay vì gây damage ngay khi bấm; anticipation giờ xảy ra trước va chạm nên hit-stop, camera shake và phản ứng mục tiêu khớp với lưỡi kiếm.
- Kéo thời lượng ba đòn từ `0.22 / 0.24 / 0.34s` lên `0.34 / 0.37 / 0.52s`, cooldown tương ứng từ `0.28 / 0.30 / 0.46s` lên `0.36 / 0.39 / 0.56s`.
- Chia pose thành wind-up, active sweep, follow-through và recovery; trail chỉ xuất hiện lúc quét, giữ lại ngắn sau điểm va chạm rồi fade thay vì reset tức thì.
- Timing trước/sau: hit 1 `0.12 → 0.22s`, hit 2 `0.13 → 0.24s`, finisher `0.18 → 0.34s`; mỗi swing có wind-up 18%, active sweep đến 78%, rồi follow-through trở về aim. Cooldown lần lượt `0.28/0.30/0.46s`.

## Cách kiểm thử

1. Trang bị Sword và click ba lần liên tiếp, kể cả click hơi sớm trong recovery.
2. Xác nhận đủ ba hit và đòn thứ ba có camera shake/knockback mạnh hơn.
3. Chờ quá `0.62s`, click lại và xác nhận combo bắt đầu từ đòn 1.

## Việc còn lại

- Cần kiểm thử cảm giác input trực tiếp trong Godot Editor.
