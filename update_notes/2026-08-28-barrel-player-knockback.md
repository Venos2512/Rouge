# Thùng nổ hất văng người chơi

## Mục tiêu

Cho vụ nổ từ thùng đẩy người chơi ra xa tâm nổ, tạo phản hồi vật lý rõ ràng hơn.

## File thêm/sửa/xóa/di chuyển

- Sửa `res://gungeon_proto/scripts/props/carryable_explosive_barrel.gd`.

## Thay đổi gameplay hoặc kiến trúc

- Khi người chơi nằm trong bán kính nổ, thùng gọi API knockback sẵn có của Player.
- Hướng đẩy đi từ tâm vụ nổ ra vị trí người chơi.
- Lực giảm tuyến tính theo khoảng cách, không khóa cứng điều khiển.

## Thông số trước/sau

- Trước: vụ nổ gây 4 damage nhưng không đẩy người chơi.
- Sau: lực đẩy tối đa `560`, giảm còn `40%` tại mép bán kính nổ; damage giữ nguyên.

## Cách kiểm thử

- Đứng sát, ở giữa và gần mép bán kính của thùng rồi kích nổ.
- Xác nhận người chơi bị đẩy đúng hướng và lực giảm theo khoảng cách.
- Thử khi đang di chuyển, đánh cận chiến và né lăn.
- Thử nhiều thùng nổ dây chuyền để kiểm tra impulse cộng dồn không gây kẹt ngoài biên phòng.

## Lỗi hoặc việc còn lại

- Player đang né lăn miễn nhiễm knockback theo hành vi hiện có của `apply_hit_knockback()`.
