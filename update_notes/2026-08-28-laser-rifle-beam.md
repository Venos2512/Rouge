# Súng laser beam giữ chuột

## Mục tiêu

Thêm Laser Rifle bắn tia năng lượng liên tục khi người chơi giữ nút tấn công.

## File thêm/sửa

- Thêm resource, HUD icon và attack provider riêng cho Laser Rifle.
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

## Giảm lag khi tải tầng mới

- `WeaponPickup` không còn gọi `get_first_node_in_group("player")` ở mỗi frame cho
  từng pickup trong phòng bắt đầu.
- Tham chiếu player được cache một lần; nếu player chưa sẵn sàng hoặc đã bị giải
  phóng, pickup chỉ thử tìm lại mỗi 0,5 giây.
- Trước: 5 pickup khởi đầu tạo 5 lần tìm toàn SceneTree mỗi frame.
- Sau: tối đa một lần tìm cho mỗi pickup khi spawn, không có tree scan mỗi frame
  trong trạng thái bình thường.

## Loại bỏ công việc tải tầng không cần thiết

- Laser Rifle không còn tạo thêm pickup thứ năm trong mọi phòng bắt đầu; súng thay
  vị trí Grenade Launcher trong loadout và cả hai vẫn nằm trong pool treasure.
- Xóa SVG được tham chiếu trực tiếp từ weapon database nhưng không được HUD sử
  dụng. HUD tiếp tục dùng icon vẽ bằng code, vì hệ thống hiện chỉ tìm texture PNG.
- Số pickup loadout khi bắt đầu tầng trở về mức trước khi thêm Laser Rifle: 5 → 4.
- Việc tải weapon database không còn đồng bộ load/rasterize SVG của Laser Rifle.

## Khôi phục damage của beam

- Raycast vật lý tiếp tục giới hạn beam ở tường và prop.
- Enemy được phát hiện bằng `EnemyCrowdService` và hit-radius, giống projectile hiện
  tại, vì phần lớn scene enemy không có `CollisionShape2D` để physics raycast trả về.
- Beam chọn enemy gần nhất trên đoạn tia và không gây damage xuyên qua tường.

## Làm mượt hướng hiển thị beam

- Trước: điểm đầu và điểm cuối của tia chỉ đổi theo tick bắn 0,1 giây, khiến tia
  nhảy thành từng nấc khi lia chuột hoặc vừa di chuyển vừa ngắm.
- Sau: hình ảnh beam lấy hướng ngắm mới nhất ở mỗi lần redraw; khoảng cách va
  chạm, damage 2, tiêu hao đạn và fire interval 0,1 giây vẫn giữ nguyên.
- Kiểm thử bằng cách giữ chuột trái, lia nhanh quanh người chơi, vừa chạy vừa đổi
  hướng và thử lần lượt với 1, 5 rồi nhiều enemy; tia phải xoay liên tục mà không
  tăng số lần raycast hay damage query.
