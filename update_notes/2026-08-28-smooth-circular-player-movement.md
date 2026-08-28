# Di chuyển Player mượt và bo hướng

## Mục tiêu

Giảm cảm giác đổi hướng cứng theo 8 hướng và giữ chuyển động analog 360° tự nhiên.

## File thêm/sửa/xóa/di chuyển

- Sửa `res://gungeon_proto/scripts/player/player.gd`.
- Sửa `res://gungeon_proto/scripts/core/game_input_runtime.gd`.

## Thay đổi gameplay hoặc kiến trúc

- Player tăng/giảm velocity dần về vector mục tiêu thay vì đổi ngay trong một physics frame.
- Chuyển hướng tạo cung ngắn, giúp quỹ đạo bo tròn hơn khi đổi phím liên tục.
- Left Stick giữ biên độ analog sau deadzone; nghiêng nhẹ đi chậm, nghiêng hết đạt tốc độ tối đa.
- Roll dùng cùng vector Left Stick 360° thay vì rơi về hướng ngắm khi chơi controller.
- Knockback, melee lunge và roll tiếp tục cộng/tách khỏi movement cơ bản như trước.

## Thông số trước/sau

- Trước: velocity cơ bản đổi tức thì; controller luôn bị normalize thành 100% tốc độ.
- Sau lần tinh chỉnh feel: acceleration `2200 px/s²`, deceleration `2800 px/s²`, turn acceleration `3600 px/s²`; analog được remap từ deadzone `0.22` tới `1.0`.
- Bản smoothing đầu tiên dùng acceleration `1050` và deceleration `1350`, gây cảm giác nặng nên đã được thay thế.
- Tốc độ tối đa giữ nguyên `155 px/s` trước upgrade.

## Cách kiểm thử

- Giữ W rồi lần lượt chuyển sang D, S, A; quan sát đường đi bo nhẹ thay vì gãy góc tức thì.
- Nhấn/thả phím nhanh để kiểm tra acceleration và stopping distance.
- Xoay Left Stick theo vòng tròn, thử cả nghiêng nhẹ và nghiêng hết.
- Thử di chuyển khi đánh cận chiến, nhận knockback và ngay trước/sau né lăn.

## Lỗi hoặc việc còn lại

- Bàn phím vật lý chỉ cung cấp 8 tổ hợp hướng; độ tròn đến từ smoothing velocity. Di chuyển 360° đầu vào thực sự cần analog stick.
