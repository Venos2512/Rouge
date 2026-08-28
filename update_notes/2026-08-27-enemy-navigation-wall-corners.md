# Enemy navigation quanh góc tường

## Mục tiêu

Giảm hiện tượng enemy giật và đổi hướng liên tục khi người chơi nằm phía sau tường hoặc cover.

## File thay đổi

- Sửa `res://gungeon_proto/scripts/dungeon/room_navigation.gd`.
- Thêm `res://update_notes/2026-08-27-enemy-navigation-wall-corners.md`.

## Thay đổi gameplay và kiến trúc

- Khi có đường thẳng thoáng, enemy vẫn đi trực tiếp như trước.
- Khi target nằm sau vật cản, `RoomNavigation` dùng grid path có sẵn để chọn waypoint ổn định thay vì chỉ thử fan hướng cục bộ.
- Path được rút gọn theo line of sight để enemy bo góc mượt hơn, không di chuyển giật theo từng cell.
- Cell bắt đầu path phải thực sự đi thẳng tới được từ vị trí enemy. Việc này ngăn grid chọn nhầm cell ở phía bên kia tường khi enemy đứng sát mép.
- Bỏ cơ chế dịch chuyển enemy sang cell gần nhất sau `0,30 giây` bị kẹt; thay vào đó enemy yêu cầu tính lại navigation và tiếp tục di chuyển bình thường.
- Bổ sung hướng trượt `+/-90°` khi hướng chính và hai hướng `+/-45°` bị chặn, giúp enemy men theo cạnh tường mà không teleport.
- Local steering cũ vẫn là fallback nếu grid không tìm được path.

## Thông số trước/sau

- Trước: chọn hướng trong fan cục bộ với look-ahead `34 px` khi bị che tầm nhìn.
- Sau: tìm path trên grid `20 px`, sau đó chọn waypoint xa nhất còn có đường đi thẳng an toàn; fan `34 px` chỉ còn là fallback.
- Rescue khi kẹt: trước dịch chuyển tối đa `90 px`; sau không dịch chuyển, chỉ xóa cache navigation để tính lại đường.

## Cách kiểm thử

1. Chạy `res://gungeon_proto/main.tscn` và vào phòng có tường/cover ở giữa.
2. Đứng phía sau tường, quan sát enemy đi tới và bo qua mép thay vì rung tại góc.
3. Để enemy tiến sát cạnh dài của tường như tình huống lỗi; xác nhận enemy tiếp tục men sang mép tường, không đứng im.
4. Lặp lại với 1, 5 và nhiều enemy; theo dõi profiler để xác nhận không có spike khung hình rõ rệt.
5. Kiểm tra enemy vẫn đi thẳng bình thường khi không có vật cản.

## Việc còn lại

- Cần xác nhận feel và chi phí pathfinding trong profiler Godot với encounter đông enemy thực tế.
