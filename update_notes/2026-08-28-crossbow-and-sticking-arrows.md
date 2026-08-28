# Nỏ và mũi tên găm mục tiêu

## Mục tiêu

Thêm vũ khí **Nỏ** với projectile mũi tên riêng. Mũi tên gây sát thương một lần rồi giữ lại trực quan khi găm vào kẻ địch hoặc tường.

## File thêm/sửa/xóa

- Thêm `crossbow.tres`, `crossbow_attack_provider.gd` và `arrow.gd`.
- Sửa `weapon_data.gd` và `weapon_database.tres` để cấu hình thời gian găm và đăng ký Nỏ.
- Sửa rule phòng khởi đầu/phòng kho báu, Training Room và Dev Tools để Nỏ có thể xuất hiện và được kiểm thử.
- Sửa player audio, HUD icon và architecture smoke test cho vũ khí mới.
- Không xóa hoặc di chuyển file.

## Gameplay và kiến trúc

- Nỏ dùng attack provider riêng; projectile thường và runtime dungeon không có thêm nhánh đặc biệt.
- Mũi tên dùng swept collision theo đoạn bay với kẻ địch và lấy mẫu có giới hạn với blocker, giúp giảm khả năng xuyên mục tiêu ở tốc độ cao.
- Khi trúng kẻ địch, mũi tên gây sát thương đúng một lần, găm thành node con để đi theo mục tiêu và tự giải phóng sau thời gian cấu hình.
- Khi trúng tường/vật cản, mũi tên gây damage projectile nếu vật cản hỗ trợ damage, găm tại điểm chạm và tự giải phóng.
- Projectile đang găm được rời group projectile hoạt động nên không tiếp tục tham gia va chạm hoặc bị tính là đạn đang bay.
- Danh sách blocker được cache một lần khi spawn và số mẫu va chạm mỗi physics tick được giới hạn ở 12.

## Thông số

- Trước: chưa có Nỏ hoặc mũi tên có khả năng găm.
- Sau: sát thương 5; tốc độ mũi tên 720 px/s; tầm tồn tại khi bay 1,25 giây; tồn tại khi găm 4 giây; băng 1 mũi; dự trữ 30 mũi; nhịp bắn 0,72 giây; nạp 1,05 giây; recoil 4; knockback khi trúng địch 125.

## Cách kiểm thử

1. Chạy `res://gungeon_proto/main.tscn`, nhặt Nỏ trong phòng khởi đầu và bắn vào tường; xác nhận mũi tên dừng đúng điểm chạm rồi biến mất sau 4 giây.
2. Bắn vào kẻ địch đang di chuyển; xác nhận mũi tên gây đúng 5 damage một lần và tiếp tục đi theo kẻ địch.
3. Thử lần lượt với 1, 5 và một nhóm đông kẻ địch; xác nhận không xuyên mục tiêu ở nhịp khung hình bình thường và mũi tên găm đều được giải phóng.
4. Bắn vào crate/pot và vật cản có thể bị phá; xác nhận không còn projectile mồ côi nếu vật cản bị giải phóng.
5. Nạp đạn, đổi vũ khí, chuyển phòng, tạm dừng và khởi động lượt mới; xác nhận ammo và mũi tên cũ không rò sang lượt mới.
6. Chạy headless editor và `res://tests/architecture_smoke_test.gd` để kiểm tra parse/resource/provider.

## Lỗi hoặc việc còn lại

- Nỏ tạm dùng SFX pistol và icon HUD vẽ bằng code; có thể thay bằng asset riêng khi art/audio hoàn thiện.
