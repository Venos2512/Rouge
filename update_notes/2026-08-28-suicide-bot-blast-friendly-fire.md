# Vụ nổ bot cảm tử gây damage và knockback diện rộng

## Mục tiêu

Cho bot cảm tử gây damage và hất văng cả người chơi lẫn các enemy khác trong vùng nổ.

## File thêm/sửa/xóa/di chuyển

- Sửa `res://gungeon_proto/scripts/enemies/suicide_bot.gd`.

## Thay đổi gameplay hoặc kiến trúc

- Vụ nổ duyệt các enemy trong group `enemies`, bỏ qua chính bot đang nổ.
- Knockback được áp dụng trước damage để mục tiêu chết bởi hit vẫn nhận phản hồi vật lý hợp lệ.
- Lực hất giảm tuyến tính theo khoảng cách tới tâm nổ.
- SuicideBot khác cũng xử lý impulse từ EnemyBase; chase movement không triệt tiêu knockback.

## Thông số trước/sau

- Trước: Player nhận `1` damage; không có knockback; enemy khác không bị ảnh hưởng.
- Sau: Player nhận `1` damage và lực hất tối đa `520`.
- Enemy khác nhận `3` damage và lực hất tối đa `380`.
- Tại mép bán kính, lực hất còn `35%`; bán kính nổ giữ nguyên `76`.

## Cách kiểm thử

- Để bot nổ sát Player và xác nhận vừa mất máu vừa bị đẩy khỏi tâm nổ.
- Gom 1, 5 và nhiều enemy quanh bot rồi kích nổ; xác nhận enemy khác mất máu và văng đúng hướng.
- Thử mục tiêu ở sát tâm, giữa và mép bán kính để kiểm tra falloff.
- Xác nhận bot đang nổ không tự nhận hit lần hai và không gây lỗi node đã bị giải phóng.

## Lỗi hoặc việc còn lại

- Player đang né lăn vẫn miễn nhiễm knockback theo API Player hiện tại.
