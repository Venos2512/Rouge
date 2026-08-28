# Chaser melee attack

## Mục tiêu

Cho Chaser chủ động ra đòn cận chiến khi áp sát người chơi, với telegraph và hồi chiêu rõ ràng.

## File sửa

- `res://gungeon_proto/scripts/enemies/chaser.gd`
- `res://update_notes/2026-08-27-chaser-melee-attack.md`

## Thay đổi gameplay và kiến trúc

- Thay contact damage tức thời bằng chu kỳ cận chiến: vào tầm, lấy đà, kiểm tra tầm lần cuối rồi gây sát thương.
- Chaser đứng ở khoảng cách cận chiến 24 px thay vì cố tiến tới 18 px.
- Thêm vòng cảnh báo trong thời gian lấy đà; không tạo thêm node hoặc tween.
- Đòn hụt nếu người chơi rời khỏi tầm trước thời điểm đánh.
- Khi đã bắt đầu lấy đà, Chaser luôn thực hiện hết cú vung và phát hiệu ứng tại hướng đánh đã khóa; việc người chơi rời tầm chỉ khiến cú đánh không gây sát thương.
- Cú đánh được thể hiện thành một nhát chém kiếm theo hướng, gồm lưỡi chém và vệt cung; sát thương chỉ được tính một lần khi bắt đầu vung.
- Chaser được phân vào các vị trí tiếp cận quanh người chơi thay vì cùng đuổi một điểm, giúp cả nhóm bớt xếp hàng.
- Giảm ảnh hưởng của lực tách đội hình riêng khi Chaser truy đuổi và có hướng dự phòng trực tiếp, tránh đứng im ngay ngoài tầm đánh.

## Thông số trước/sau

- Tầm kích hoạt: dưới 19 px -> 30 px.
- Tầm trúng đòn: dưới 19 px -> 36 px tại thời điểm kết thúc lấy đà.
- Thời gian lấy đà: 0 giây -> 0.24 giây.
- Thời gian vung kiếm: 0 giây -> 0.16 giây.
- Hồi chiêu: 0.8 giây -> 0.9 giây.
- Sát thương: giữ nguyên 1.

## Cách kiểm thử

1. Chạy `res://gungeon_proto/main.tscn` và vào phòng có Chaser.
2. Để Chaser áp sát: xác nhận có vòng cảnh báo, sau đó người chơi mất 1 máu.
3. Rời khỏi vòng trong lúc lấy đà: xác nhận Chaser vẫn vung đòn và phát hiệu ứng, nhưng người chơi không mất máu.
4. Đứng trong tầm: xác nhận một nhát chém chỉ gây sát thương một lần, không gây sát thương lặp theo từng khung hình.
5. Thử với 1, 5 và nhiều Chaser: xác nhận nhịp đánh ổn định và không tụt khung hình rõ rệt.
6. Né lăn đúng lúc: xác nhận cơ chế bất tử khi lăn vẫn chặn sát thương.
7. Dẫn 5 hoặc nhiều Chaser đi một đoạn sau khi chúng chém: xác nhận chúng tản quanh người chơi, tiếp tục áp sát và đánh lại sau hồi chiêu.

## Lỗi hoặc việc còn lại

- Cần kiểm tra cảm giác tầm đánh và thời gian lấy đà trực tiếp trong Godot để cân chỉnh thêm nếu cần.
