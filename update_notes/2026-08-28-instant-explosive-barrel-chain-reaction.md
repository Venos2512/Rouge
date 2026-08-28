# Vụ nổ kích thùng nổ ngay lập tức

## Mục tiêu

Mọi explosion damage trong vùng của thùng nổ phải kích hoạt thùng ngay, tạo chain reaction không chờ fuse.

## File thêm/sửa/xóa/di chuyển

- Sửa `res://gungeon_proto/scripts/props/carryable_explosive_barrel.gd`.
- Sửa `res://gungeon_proto/scripts/enemies/suicide_bot.gd`.
- Sửa `res://gungeon_proto/scripts/enemies/bomber_bomb.gd`.

## Thay đổi gameplay hoặc kiến trúc

- Thêm API `trigger_from_explosion()` riêng cho thùng.
- Vụ nổ từ thùng khác, bot cảm tử và Bomber Bomb đều kích thùng trong bán kính ngay lập tức.
- Thêm cờ `explosion_started` để một thùng chỉ bắt đầu nổ một lần và ngăn recursion A → B → A.
- Damage thường từ đạn hoặc cận chiến vẫn kích fuse như trước.

## Thông số trước/sau

- Trước: thùng trúng explosion damage bắt đầu fuse `0.32s`.
- Sau: thùng trúng explosion damage nổ ngay trong cùng chain reaction.
- Bán kính và damage của từng nguồn nổ giữ nguyên.

## Cách kiểm thử

- Đặt hai hoặc nhiều thùng gần nhau rồi kích một thùng bằng đạn/cận chiến.
- Cho bot cảm tử nổ cạnh thùng.
- Cho Bomber Bomb nổ cạnh thùng.
- Xác nhận toàn bộ thùng trong chuỗi nổ ngay, mỗi thùng chỉ tạo một explosion và không có lỗi recursion.
- Thử chuỗi nhiều thùng với Player và nhiều enemy trong vùng để kiểm tra hiệu năng và damage.

## Lỗi hoặc việc còn lại

- Chain reaction rất lớn vẫn tạo nhiều FX/damage query trong cùng frame; cần giới hạn nếu room về sau chứa số lượng thùng cao.
