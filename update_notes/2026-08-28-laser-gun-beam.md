# Súng Laser bắn beam liên tục

## Mục tiêu

Thêm **Súng Laser** tạo beam tức thời và tiếp tục bắn trong thời gian người chơi giữ nút tấn công.

## File thêm/sửa/xóa

- Thêm `laser_gun.tres` và `laser_beam_attack_provider.gd`.
- Sửa `weapon_data.gd` và `weapon_database.tres` để cấu hình, đăng ký beam weapon.
- Sửa rule phòng khởi đầu/phòng kho báu, Training Room, Dev Tools, player audio và HUD icon để vũ khí có thể xuất hiện và được kiểm thử.
- Sửa architecture smoke test để phân biệt beam với projectile dạng node.
- Không xóa hoặc di chuyển file.

## Gameplay và kiến trúc

- Súng Laser có `automatic = true`, vì vậy runtime hiện có gọi provider liên tục khi giữ chuột trái hoặc trigger tấn công.
- Mỗi nhịp beam tìm kẻ địch gần nhất nằm trên tia, dừng tại kẻ địch hoặc blocker đầu tiên và gây một tick shock damage; beam không tạo projectile node.
- Provider vẽ ba lớp beam gồm glow, lõi cyan và lõi trắng. Beam tự tắt ngay sau khi người chơi thả nút bắn.
- Truy vấn kẻ địch ưu tiên `EnemyCrowdService`; danh sách blocker được cache và chỉ refresh tối đa mỗi 0,5 giây.
- Ray march kiểm tra blocker được giới hạn ở 96 mẫu mỗi nhịp để tránh truy vấn không giới hạn.

## Thông số

- Trước: chưa có Súng Laser hoặc beam weapon.
- Sau: 1 shock damage mỗi 0,08 giây; tầm 620 px; rộng 7 px; băng 45; dự trữ 180; nạp 1,2 giây; recoil 0,35 mỗi tick.

## Cách kiểm thử

1. Chạy `res://gungeon_proto/main.tscn`, nhặt Súng Laser trong phòng khởi đầu.
2. Giữ chuột trái và xác nhận beam duy trì liên tục; thả chuột và xác nhận beam tắt ngay, không còn node projectile.
3. Lia tia qua nhiều kẻ địch và xác nhận chỉ mục tiêu gần nhất nhận damage; đặt tường ở trước mục tiêu và xác nhận tia dừng tại tường.
4. Thử với 1, 5 và nhiều kẻ địch, giữ beam qua nhiều băng đạn; theo dõi ổn định frame time và việc nạp đạn.
5. Đổi vũ khí, chuyển phòng, tạm dừng, chết và bắt đầu lượt mới; xác nhận beam cũ không còn hiển thị hoặc gây damage.
6. Chạy headless editor và `res://tests/architecture_smoke_test.gd` để kiểm tra parse, resource và provider contract.

## Lỗi hoặc việc còn lại

- Súng Laser tạm tái sử dụng SFX machine gun; cần SFX loop riêng để tránh tiếng bắn lặp khi audio asset hoàn thiện.
