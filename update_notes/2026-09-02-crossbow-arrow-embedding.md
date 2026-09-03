# Nỏ và mũi tên găm

## Mục tiêu

Thêm vũ khí Nỏ dùng projectile mũi tên. Mũi tên gây sát thương một lần rồi găm vào kẻ địch hoặc vật cản/tường để tăng độ rõ và cảm giác lực của phát bắn.

## File thêm/sửa/xóa

- Thêm `crossbow_attack_provider.gd`, `arrow_projectile.gd` và `crossbow.tres`.
- Sửa `weapon_database.tres`, room rule phòng bắt đầu/kho báu, âm thanh bắn trong `player.gd`, icon dự phòng trong `game_hud_icon.gd` và danh sách resource của architecture smoke test.
- Không xóa hoặc di chuyển file.

## Gameplay và kiến trúc

- Nỏ có attack provider riêng; logic mũi tên không được thêm vào projectile đạn súng chung.
- Mũi tên chia quãng đường bay thành bước tối đa 6 px để giảm nguy cơ xuyên mục tiêu khi tốc độ cao.
- Khi trúng enemy, mũi tên gây physical projectile damage một lần, tạo knockback/hit feedback rồi được reparent vào mục tiêu để di chuyển theo nó.
- Khi trúng bullet blocker, mũi tên gây damage tương thích với vật thể phá được rồi đứng yên hoặc bám vật thể nếu vật thể còn tồn tại.
- Mũi tên găm tự biến mất sau 6 giây; toàn scene chỉ giữ tối đa 32 mũi tên găm để tránh tích lũy node.
- Nỏ được thêm vào database, phòng bắt đầu để kiểm thử và pool ưu tiên của phòng kho báu.

## Thông số trước/sau

- Trước: chưa có Nỏ.
- Sau: damage 4; tốc độ 720 px/s; nhịp bắn 0,72 giây; băng 1 mũi; dự trữ 24 mũi; nạp 1,05 giây; thời gian bay tối đa 1,6 giây; thời gian găm 6 giây; recoil 3,5.

## Cách kiểm thử

1. Chạy `res://gungeon_proto/main.tscn`, nhặt Nỏ trong phòng đầu và xác nhận HUD/đạn/nạp đạn đúng.
2. Bắn enemy đứng yên và đang di chuyển; xác nhận mỗi mũi tên chỉ gây một lần damage và tiếp tục bám theo enemy.
3. Bắn tường, crate, pot và thùng nổ; xác nhận mũi tên dừng tại điểm va chạm, đồng thời vật thể phá được vẫn nhận damage.
4. Thử với 1, 5 và nhiều enemy; bắn liên tục và xác nhận số mũi tên găm không vượt 32, mũi tên được dọn sau 6 giây.
5. Kiểm tra bắn sát mép tường, chuyển phòng, tạm dừng, chết và bắt đầu lượt mới để bảo đảm không giữ projectile cũ.

## Lỗi hoặc việc còn lại

- Nỏ tạm tái sử dụng SFX súng lục; nên thay bằng SFX dây nỏ riêng khi có asset âm thanh.
- Icon dùng bản vẽ vector dự phòng của HUD; chưa có texture PNG riêng.
