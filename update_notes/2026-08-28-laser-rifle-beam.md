# Súng laser beam giữ chuột

## Mục tiêu

Thêm Laser Rifle bắn tia năng lượng liên tục khi người chơi giữ nút tấn công.

## File thêm/sửa

- Thêm resource, icon asset, HUD icon và attack provider riêng cho Laser Rifle.
- Mở rộng `WeaponData` với cấu hình tầm và độ rộng beam.
- Đăng ký súng trong weapon database và các pool phần thưởng start/treasure.

## Thay đổi gameplay và kiến trúc

- Laser Rifle là vũ khí automatic: giữ chuột trái duy trì beam, mỗi tick dùng một viên năng lượng.
- Beam dùng ray query nên dừng ở collider đầu tiên, không xuyên tường, và không tạo projectile node.
- Logic beam nằm trong `LaserBeamAttackProvider`, không mở rộng lớp tích hợp dungeon.

## Thông số trước/sau

- Trước: chưa có vũ khí beam.
- Sau: 2 shock damage mỗi 0,1 giây; tầm 620 px; rộng 5 px; băng 40; dự trữ 160; nạp 1,35 giây.

## Cách kiểm thử

1. Nhặt Laser Rifle trong phòng bắt đầu.
2. Giữ chuột trái và lia tâm: beam phải liên tục bám hướng ngắm, dừng ở enemy/tường và trừ đạn.
3. Kiểm tra với 1, 5 và nhiều enemy; thả chuột phải ngừng gây damage ngay.
4. Bắn hết băng, xác nhận reload và tiếp tục beam sau khi nạp.

## Lỗi hoặc việc còn lại

- Chưa có SFX loop riêng; hiện beam ưu tiên phản hồi hình ảnh để tránh lặp SFX súng đạn mỗi tick.

## Sửa lỗi freed object

- Raycast collider và attack provider hiện được kiểm tra `typeof` cùng
  `is_instance_valid()` trước khi cast sang `Node`.
- Entry provider đã bị giải phóng được xóa khỏi cache để có thể tạo lại an toàn.
- Khắc phục lỗi `Trying to cast a freed object` khi enemy bị hủy hoặc scene chuyển
  phòng đúng lúc beam đang tick.
