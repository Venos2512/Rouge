# Sửa lỗi sau khi tách UI

## Thay đổi
- Xóa `WeaponIconHUD` khỏi danh sách service bắt buộc vì đã thay bằng `GameplayHUD` trong scene.
- Chặn kết nối lặp `RelicChoice/BackButton` khi setup lại màn chọn relic.

## Cách kiểm thử
- Chạy game và kiểm tra không còn lỗi thiếu WeaponIconHUD.
- Nhấn Start Run nhiều lần/đi lại màn chọn relic để xác nhận không còn lỗi signal đã kết nối.
