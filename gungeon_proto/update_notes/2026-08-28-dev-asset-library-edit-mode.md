# Dev asset library và edit mode

## Mục tiêu

Mở rộng DevTools trên phím F2 thành asset library có thể spawn, chọn, kéo và xóa
đối tượng trực tiếp trong phòng mà không cần rời runtime.

## File sửa

- `res://gungeon_proto/scripts/debug/dev_tools.gd`

## Thay đổi gameplay và kiến trúc

- F2 mở panel library bên trái và tạm dừng gameplay.
- Library giữ danh sách weapon hiện có, đồng thời thêm crate, pot, table, pillar,
  explosive barrel, spike trap, saw trap, upgrade chest và các enemy thường.
- Asset vừa spawn được đăng ký vào group `dev_editable_assets` và tự được chọn.
- Edit mode có thể chọn cả room prop, pickup, hazard và enemy hiện có.
- Giữ chuột trái trên vùng game để kéo asset; Delete xóa asset đang chọn.
- Khung cyan theo dõi asset đang chọn trong screen space.
- Panel chỉ chặn chuột trong vùng library; vùng game bên phải vẫn nhận thao tác edit.

## Thông số trước và sau

- Trước: F2 chỉ mở menu spawn weapon toàn màn hình; asset đã spawn không thể chỉnh vị trí.
- Sau: panel rộng 450 px; bán kính chọn asset trong world là 30 px.
- Không thay đổi thông số combat hoặc dữ liệu dungeon.

## Cách kiểm thử

1. Chạy `res://gungeon_proto/main.tscn`, nhấn F2 và xác nhận gameplay tạm dừng.
2. Spawn từng prop/trap/chest và weapon, xác nhận asset xuất hiện trước mặt player.
3. Nhấn giữ chuột trái trên asset ở vùng game bên phải rồi kéo sang vị trí mới.
4. Chọn prop, pickup, hazard và enemy có sẵn; xác nhận khung cyan bám đúng mục tiêu.
5. Nhấn Delete và xác nhận chỉ asset đang chọn bị xóa.
6. Nhấn F2 hoặc Escape để đóng tool; xác nhận gameplay tiếp tục.
7. Mở/đóng tool nhiều lần và chuyển phòng để kiểm tra không giữ node đã bị giải phóng.

## Lỗi hoặc việc còn lại

- Vị trí chỉnh trong runtime chỉ tồn tại trong lượt chạy hiện tại; chưa có lưu room layout
  thành resource.
- Edit mode hiện chỉ hỗ trợ di chuyển và xóa; chưa có xoay, duplicate, grid snap hoặc undo.
