# Giảm khựng khi vào phòng

## Mục tiêu

Giảm frame spike khi chuyển sang phòng mới, đặc biệt ở phòng có nhiều collision, prop, trap và enemy.

## File thêm/sửa/xóa/di chuyển

- Sửa `res://gungeon_proto/scripts/core/dungeon_main.gd`.
- Sửa `res://gungeon_proto/scripts/dungeon/room_director.gd`.

## Thay đổi gameplay hoặc kiến trúc

- Thêm trạng thái `room_transition_in_progress` để không kiểm tra room clear/chuyển cửa khi phòng đang được dựng.
- Chia chuyển phòng thành ba nhịp: dọn phòng cũ, dựng layout/collision, rồi spawn encounter/reward.
- Cho SceneTree một frame để giải phóng node cũ trước khi tạo node phòng mới.
- Sau khi refresh room visual, lưu ngay signature mới để frame kế tiếp không dựng lại grid và terrain lần thứ hai.

## Thông số trước/sau

- Trước: xóa entity cũ, tạo layout và spawn encounter trong cùng một frame.
- Sau: ba nhóm công việc được phân bổ qua ba frame liên tiếp; gameplay và nội dung phòng giữ nguyên.
- Room visual giảm từ hai lượt rebuild liên tiếp xuống một lượt cho mỗi refresh.

## Cách kiểm thử

- Chạy qua nhiều cửa liên tục, gồm phòng thường, elite, treasure và boss.
- Kiểm tra player được đặt đúng cửa, enemy/reward xuất hiện đầy đủ và không chuyển phòng hai lần.
- Quan sát Monitor/Profiler để so sánh đỉnh frame time tại thời điểm qua cửa.
- Thử phòng có 1, 5 và nhiều enemy.

## Lỗi hoặc việc còn lại

- Nếu vẫn còn spike lớn, cần lấy capture Profiler để xác định scene enemy hoặc prop cụ thể có `_ready()` nặng.
