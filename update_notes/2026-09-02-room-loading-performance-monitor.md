# Ổn định tải phòng và bảng theo dõi hiệu năng

## Mục tiêu

- Loại bỏ nguồn cấp phát lặp lại khi đổi trạng thái/phòng.
- Ngăn frame spike quay lại khi layout được bổ sung thêm wall, prop hoặc trap.
- Hiển thị số liệu runtime để phát hiện hồi quy mà không cần mở profiler.

## File thêm/sửa/xóa/di chuyển

- Thêm `res://gungeon_proto/scripts/debug/runtime_performance_overlay.gd`.
- Sửa `res://gungeon_proto/scenes/gameplay/core_runtime.tscn`.
- Sửa `res://gungeon_proto/scripts/dungeon/room_director.gd`.
- Sửa `res://gungeon_proto/scripts/dungeon/room_visual_scene_controller.gd`.
- Sửa `res://gungeon_proto/scripts/core/dungeon_main.gd`.

## Thay đổi gameplay hoặc kiến trúc

- Thêm `RuntimePerformanceOverlay` độc lập trong `CoreRuntime`; nhấn F3 để ẩn/hiện.
- Overlay theo dõi FPS, frame time, frame tệ nhất trong mẫu, spike từ 25 ms, node, object, RAM, enemy, bullet và FX.
- Đo riêng thời gian dọn phòng, dựng layout và tạo encounter gần nhất.
- Cache signature hình học và terrain để không xóa/tạo lại lưới cùng chi tiết sàn khi chỉ trạng thái cửa thay đổi.
- Dựng layout theo ngân sách thích ứng: tối đa 4 scene hoặc 0,75 ms mỗi frame, tùy giới hạn nào đến trước. Nội dung và thứ tự gameplay giữ nguyên; phòng chỉ mở combat sau khi layout hoàn tất.
- Theo dõi thêm dip từ 6 ms để bắt được đoạn tụt khoảng 240 xuống dưới 167 FPS, thay vì chỉ ghi spike lớn từ 25 ms.
- Bomber đi thẳng khi có line of sight thay vì chạy navigation BFS định kỳ trong phòng mở; khi bị chắn, navigation vẫn hoạt động nhưng giảm tần suất từ 0,14-0,20 giây xuống 0,28-0,42 giây.
- Bomb giới hạn redraw cả lúc bay ở 30 Hz và dùng kiểm tra khoảng cách bình phương khi tìm destructible trong vùng nổ.
- Overlay hiển thị riêng số bomb đang hoạt động.

## Thông số trước/sau

- Trước: toàn bộ wall/prop/barrel/trap được tạo trong một frame; chi phí tăng tuyến tính và không có trần khi nội dung update thêm.
- Sau: tối đa 4 scene hoặc 0,75 ms công việc layout trong một frame rồi nhường cho SceneTree xử lý; ngân sách thời gian ngăn scene phức tạp phá vỡ giới hạn chỉ dựa trên số lượng.
- Trước: grid và 12 terrain detail bị xóa/tạo lại khi room visual refresh dù kích thước/terrain không đổi.
- Sau: các phần này chỉ rebuild khi signature hình học hoặc terrain thực sự đổi.
- Ngưỡng cảnh báo spike: 25 ms (xấp xỉ dưới 40 FPS cho frame đó).
- Ngưỡng ghi nhận dip nhỏ: 6 ms (xấp xỉ dưới 167 FPS cho frame đó).
- Tần suất cập nhật hình Bomber bomb lúc bay: trước theo FPS hiển thị; sau tối đa 30 Hz.

## Cách kiểm thử

- Chạy `res://gungeon_proto/main.tscn`, quan sát overlay góc trái; F3 phải ẩn/hiện được.
- Đi liên tục qua phòng thường, elite, treasure, shop và boss; kiểm tra chỉ số `ROOM clear/layout/encounter`.
- Thử phòng có 1, 5 và nhiều enemy, đồng thời bắn nhiều projectile/effect.
- Xác nhận player chỉ điều khiển lại sau khi layout hoàn tất, cửa/collision/prop/trap và reward xuất hiện đủ.
- Quay lại phòng đã clear và kiểm tra node không tăng liên tục qua mỗi lần chuyển phòng.

## Lỗi hoặc việc còn lại

- Overlay đo thời gian tường của pha layout (bao gồm các frame chủ động nhường), còn `worst` và spike phản ánh độ khựng thực tế của từng frame.
- Nếu spike còn vượt 25 ms, ảnh chụp overlay sẽ chỉ rõ đó là layout hay encounter để khoanh scene cụ thể.
