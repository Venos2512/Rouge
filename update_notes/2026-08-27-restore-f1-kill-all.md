# Khôi phục F1 kill all bot

## Mục tiêu

Khôi phục phím F1 để tiêu diệt toàn bộ enemy trong runtime gameplay.

## File thêm/sửa/xóa/di chuyển

- Sửa `res://gungeon_proto/scenes/gameplay/core_runtime.tscn`.
- Thêm note này.

## Thay đổi gameplay hoặc kiến trúc

- Thêm lại node `CoreRuntime/DevTools`, dùng script DevTools hiện có.
- F1 tiếp tục gọi kill-all enemy và cập nhật trạng thái debug.

## Thông số trước/sau

- Trước: DevTools không được instantiate nên F1 không có handler.
- Sau: DevTools chạy cùng CoreRuntime và bắt được F1.

## Cách kiểm thử

- Chạy game, vào encounter có bot, nhấn F1.
- Xác nhận toàn bộ bot hiện tại bị hạ và status debug báo số enemy đã kill.

## Lỗi hoặc việc còn lại

- Chưa chạy kiểm thử Godot headless vì executable Godot không có trong môi trường hiện tại.
