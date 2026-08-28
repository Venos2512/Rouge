# Fix chest reward UI

## Mục tiêu

Đảm bảo mở rương hiển thị lựa chọn reward và không làm mất rương nếu reward UI chưa sẵn sàng.

## File thêm/sửa/xóa/di chuyển

- Sửa `res://gungeon_proto/scripts/dungeon/reward_director.gd`.
- Sửa `res://gungeon_proto/scripts/core/dungeon_main.gd`.
- Sửa `res://gungeon_proto/scripts/gameplay/upgrade_chest.gd`.

## Thay đổi gameplay hoặc kiến trúc

- RewardDirector lấy `UpgradeChoiceUI` đúng từ `CoreRuntime/GameUI/DungeonHUD/UpgradeChoiceUI`.
- Rương chỉ được đánh dấu đã mở và giải phóng sau khi màn chọn upgrade thực sự mở.
- Đưa reward UI lên lớp hiển thị ưu tiên và bổ sung bắt phím 1/2/3 độc lập với event UI.
- Card reward nhận focus và click trực tiếp; card đầu tiên được focus khi mở.

## Thông số trước/sau

- Trước: rương bị xóa dù UI không tìm thấy, người chơi không nhận reward.
- Sau: UI reward mở đúng; nếu UI lỗi, rương vẫn còn để thử lại.

## Cách kiểm thử

- Chạy scene chính, vào phòng treasure/elite/boss, đứng gần rương và nhấn E.
- Xác nhận màn `CHOOSE 1 UPGRADE` hiện 1–3 lựa chọn và chọn được bằng chuột hoặc phím 1/2/3.
- Thử cả click chuột, phím số hàng trên và Enter trên card đang focus.

## Lỗi hoặc việc còn lại

- Rương hiện cho upgrade; relic riêng trong chest chưa được thêm vào reward pool.
