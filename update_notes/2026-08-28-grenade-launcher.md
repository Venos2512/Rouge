# Súng phóng lựu

## Mục tiêu

Thêm **Súng phóng lựu** như một vũ khí riêng. Vũ khí chỉ gây sát thương bằng vụ nổ, không gây thêm sát thương va chạm trực tiếp.

## File thêm/sửa/xóa

- Thêm `grenade_launcher_attack_provider.gd`, `player_grenade.gd` và `grenade_launcher.tres`.
- Sửa `weapon_data.gd`, `weapon_database.tres`, hai room rule cấp vũ khí, HUD/icon túi đồ và âm thanh bắn trong `player.gd`.
- Xóa resource vũ khí đặt tên nhầm ở bản sửa trước; chỉ giữ lại Súng phóng lựu.

## Gameplay và kiến trúc

- Súng phóng lựu dùng attack provider riêng, không thêm nhánh hành vi vào runtime dungeon.
- Đầu đạn nổ khi chạm kẻ địch, vật cản hoặc hết thời gian bay.
- Va chạm chỉ kích hoạt vụ nổ. Toàn bộ `damage` được áp dụng một lần cho mỗi mục tiêu nằm trong bán kính nổ.
- Shield Bot nhận 50% sát thương nổ (làm tròn lên do máu dùng số nguyên) và vẫn bị hất văng, kể cả khi quay mặt khiên về tâm nổ.
- Vụ nổ gây sát thương cho mọi object thuộc group `destructibles`; vì vậy có thể phá crate/pot và kích hoạt dây cháy của thùng nổ.
- Mỗi vụ nổ ưu tiên truy vấn `EnemyCrowdService` để tránh tìm toàn scene khi dịch vụ có sẵn.
- Vũ khí xuất hiện trong phòng khởi đầu để kiểm thử và trong danh sách ưu tiên của phòng kho báu.

## Thông số

- Trước: chưa có Súng phóng lựu.
- Sau: sát thương nổ 5; Shield Bot nhận 3 do 50% được làm tròn lên; sát thương va chạm 0; bán kính nổ 78 px; lực đẩy 220; tốc độ đạn 330 px/s; tồn tại 1,1 giây; băng 3 viên; dự trữ 18 viên; nhịp bắn 0,9 giây; nạp 1,45 giây.

## Cách kiểm thử

1. Chạy `res://gungeon_proto/main.tscn`, nhặt Súng phóng lựu ở phòng đầu.
2. Bắn sát một kẻ địch và xác nhận nó chỉ nhận một lần sát thương nổ, không cộng thêm sát thương va chạm.
3. Thử với một, năm và một nhóm đông kẻ địch; xác nhận mỗi mục tiêu trong vùng chỉ nhận một lần sát thương mỗi phát.
4. Bắn vào tường/vật cản và khoảng trống; xác nhận đầu đạn đều nổ rồi được giải phóng.
5. Cho Shield Bot quay mặt khiên về vụ nổ; xác nhận nhận 3 damage và vẫn bị hất văng.
6. Cho crate, pot và thùng nổ vào vùng nổ; xác nhận object vỡ và thùng được kích hoạt để nổ nối tiếp.
7. Nạp đạn, đổi vũ khí, chuyển phòng, tạm dừng và bắt đầu lượt mới; xác nhận không giữ trạng thái cũ.

## Còn lại

- Súng phóng lựu đang tái sử dụng âm thanh bắn shotgun; có thể thay bằng SFX riêng khi có asset.
