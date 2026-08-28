# Charger charge feel

## Mục tiêu

Cải thiện cảm giác xuyên vật thể và sửa hướng sau khi Charger trượt dọc tường.

## File thêm/sửa/xóa/di chuyển

- Sửa `res://gungeon_proto/scripts/enemies/charger.gd`.
- Thêm `res://update_notes/2026-08-28-charger-charge-feel.md`.
- Không xóa hoặc di chuyển file.

## Thay đổi gameplay và kiến trúc

- Charge phá dứt điểm mọi `room_prop` chạm phải nếu prop không thuộc `terrain_walls`, kể cả prop còn nhiều HP hoặc được đánh dấu không phá hủy trong combat thường.
- Explosive barrel phát nổ ngay khi bị Charger xuyên qua.
- Phá xuyên prop cộng 34 px/s vào tốc độ hiện tại, không vượt tốc độ charge tối đa 390 px/s, giúp cú lao không hụt lực sau va chạm.
- Hướng trượt là hướng tạm thời. Vector charge đã khóa không còn bị ghi đè; khi hết mép vật cản, Charger tiếp tục theo đúng góc khóa ban đầu.
- Thêm trail tỷ lệ theo tốc độ trong lúc charge và trôi giảm tốc.

## Thông số trước/sau

- Trước: prop nhiều hơn 2 HP có thể còn tồn tại và biến cú xuyên vật thành wall impact; hướng trượt thay thế vĩnh viễn hướng charge.
- Sau: mọi room prop không phải tường cứng bị phá trong một lần tiếp xúc; bonus xuyên vật 34 px/s; hướng charge gốc được khôi phục ngay khi không còn tiếp xúc vật cản.

## Cách kiểm thử

1. Dụ Charger lao qua crate, pot, table, pillar và explosive barrel; xác nhận nó xuyên qua, prop bị phá/nổ và Charger không choáng.
2. Đặt nhiều prop liên tiếp; xác nhận mỗi prop chỉ nhận một lần xử lý và Charger giữ được lực lao.
3. Dụ Charger lao chéo vào cạnh tường; xác nhận nó trượt dọc cạnh trong lúc bị chặn.
4. Khi Charger vượt qua mép tường, xác nhận nó quay lại đúng vector đã khóa trước va chạm thay vì tiếp tục bay theo hướng trượt.
5. Đâm gần vuông góc vào `terrain_walls`; xác nhận vẫn tạo impact, bật lùi và choáng.
6. Kiểm thử với 1, 5 và nhiều Charger để theo dõi số effect và độ ổn định khung hình.

## Lỗi hoặc việc còn lại

- Cần playtest để tinh chỉnh bonus tốc độ xuyên vật và độ dài trail theo mật độ prop thực tế.
