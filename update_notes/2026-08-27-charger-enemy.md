# Charger enemy

## Mục tiêu

Thêm Charger với vai trò phá đội hình theo đường thẳng: khóa hướng có telegraph, lao mạnh và bị choáng khi đâm vào tường hoặc vật cản trong phòng.

## File thêm/sửa/xóa/di chuyển

- Thêm `res://gungeon_proto/scripts/enemies/charger.gd`.
- Thêm `res://gungeon_proto/scenes/enemies/charger.tscn`.
- Thêm `res://gungeon_proto/resources/enemies/charger.tres`.
- Sửa `res://gungeon_proto/resources/enemies/enemy_database.tres` để thêm Charger vào normal pool.
- Không xóa hoặc di chuyển file.

## Thay đổi gameplay và kiến trúc

- Charger tiếp cận ở tốc độ vừa, chỉ bắt đầu lao khi người chơi nằm trong khoảng hợp lệ và có đường nhìn.
- Khi bắt đầu telegraph, Charger khóa hướng hiện tại của người chơi; hướng không đổi trong lúc chuẩn bị hoặc lao.
- Va vào biên phòng, crate, pot, table, pillar hoặc blocker khác sẽ dừng cú lao và làm Charger choáng.
- Charger dùng scene/resource riêng và API điều hướng công khai có sẵn; không thêm logic vào `dungeon_main.gd`.
- Sửa Charger luôn xoay mặt theo player trước khi khóa hướng. Khi bị áp sát, nó lùi thẳng có kiểm soát thay vì đứng đơ hoặc dùng navigation tạo chuyển động ngang khó đọc.
- Charger không còn dùng clamp tọa độ cứng `Y = -180..180` của enemy base. Cú lao xuống nửa dưới phòng giữ nguyên vector đã khóa; biên phòng và vật cản được xử lý bởi `RoomNavigation` rồi chuyển sang trạng thái choáng.
- Đổi combat loop: Charger chạy tới cận chiến khi player ở gần và chém một nhát. Charge chỉ bắt đầu từ cự ly xa và có cooldown dài hơn để không spam. Đã bỏ hoàn toàn bước dodge roll sau melee.
- Trong charge, Charger bất tử. Đường charge gây sát thương một lần lên mỗi player, enemy hoặc room prop chạm phải; room prop không phá hủy thông thường cũng bị cú húc phá, riêng `terrain_walls` luôn được miễn.
- Sau melee có khóa charge 1.15 giây, ngăn state kiểm tra khoảng cách kích hoạt charge ngay sau cú chém.
- Va tường gần vuông góc tạo impact, làm Charger bật lùi 10 px rồi nhận impulse lùi và choáng. Va lướt với thành phần hướng vào tường dưới 0.62 sẽ chiếu hướng charge dọc theo mặt tường, tiếp tục trượt mà không tạo impact.
- Charge dùng gia tốc: bắt đầu ở 135 px/s, tăng tối đa đến 390 px/s với gia tốc 620 px/s². Khi hết pha charge, Charger giữ hitbox và quán tính thêm tối đa 0.30 giây rồi giảm tốc 1050 px/s², tạo đoạn overlap/trôi ngắn trước khi trở lại truy đuổi.

## Thông số trước/sau

- Trước: chưa có Charger.
- Sau: 8 HP, tốc độ tiếp cận 56 px/s; cận chiến ở 34 px, windup chém 0.26 giây, tầm trúng 41 px, sát thương chém 1, khóa charge 1.15 giây sau melee; charge từ 145-245 px, windup 0.70 giây, tăng tốc từ 135 lên tối đa 390 px/s với gia tốc 620 px/s² trong tối đa 0.82 giây, sát thương charge 2, cooldown charge 3.25 giây, trôi giảm tốc tối đa 0.30 giây, choáng do va chạm 1.35 giây.
- Trọng số spawn trong normal pool: 0.75; khoảng cách spawn tối thiểu với người chơi: 110 px.

## Cách kiểm thử

1. Chạy dungeon và vào nhiều phòng combat cho tới khi Charger xuất hiện.
2. Đứng trong khoảng 145-245 px, quan sát đường telegraph, né ngang sau khi hướng đã khóa và xác nhận Charger không charge liên tục.
3. Áp sát Charger; xác nhận nó chạy tới, telegraph đòn chém, chém đúng một lần rồi tiếp tục truy đuổi mà không dodge roll.
4. Tiếp tục đứng sát sau cú chém; xác nhận nó không đứng đơ và chỉ chém lại sau cooldown.
5. Đánh Charger trong lúc charge; xác nhận HP không giảm. Đứng/chặn bằng enemy và prop; xác nhận mỗi mục tiêu chỉ nhận sát thương một lần trong mỗi charge.
6. Dụ Charger lao qua crate, table và pillar; xác nhận chúng bị phá. Dụ nó lao vào `terrain_walls`; xác nhận tường không nhận damage và Charger choáng 1.35 giây.
7. Dụ Charger lao chéo sát tường ở góc nhỏ; xác nhận nó trượt dọc tường, không phát impact và không choáng. Thử góc gần vuông; xác nhận nó bật lùi nhẹ rồi choáng.
8. Quan sát một cú charge không va tường; xác nhận tốc độ tăng dần, cuối cú lao trôi thêm một đoạn ngắn và vẫn có thể trúng mục tiêu mới trong đoạn overlap nhưng không đánh lặp mục tiêu cũ.
9. Để Charger chạm người chơi khi lao; xác nhận nhận 2 sát thương và không bị đánh lặp trong cùng một cú lao.
10. Thử phòng có 1, 5 và nhiều enemy để kiểm tra nhịp combat và độ ổn định.

## Lỗi hoặc việc còn lại

- Cần playtest thực tế để tinh chỉnh thời gian windup, tốc độ lao và trọng số spawn theo feel của phòng đông.
