# Tích hợp SFX gameplay

## Mục tiêu

Đưa bộ SFX hiện có vào runtime và bảo đảm combat đông đối tượng không tạo số lượng audio player mất kiểm soát.

## File thêm

- `res://gungeon_proto/scripts/audio/audio_director.gd`
- `res://gungeon_proto/scripts/audio/game_audio.gd`

## File sửa

- `res://gungeon_proto/main.tscn`
- Các script player, weapon, projectile, melee special, enemy, dungeon, pickup và UI có sự kiện phát âm thanh.

## Thay đổi gameplay và kiến trúc

- Thêm `AudioDirector` vào scene chính, tự quét SFX theo tên file và gom các file có hậu tố số thành biến thể ngẫu nhiên.
- Thêm bus `SFX` khi runtime chưa có bus này.
- Nối SFX cho né, bước chân, nhận sát thương, chết, hồi máu, súng, reload, đổi vũ khí, cận chiến, parry, weapon special, projectile impact, enemy, bomb, boss, room flow, reward, pickup, upgrade và pause UI.
- Âm thanh thế giới dùng `AudioStreamPlayer2D`; UI và các node không có vị trí dùng `AudioStreamPlayer`.
- Giới hạn tối đa 32 SFX đang hoạt động và cooldown 0,025 giây cho cùng một event.

## Thông số trước/sau

- Trước: chưa có hệ thống phát SFX.
- Sau: tối đa 32 audio player đồng thời; cùng event không phát lại sớm hơn 0,025 giây; pitch variation theo từng lời gọi, thường từ 0% đến 9%.

## Cách kiểm thử

1. Chạy `res://gungeon_proto/main.tscn`.
2. Thử pistol, machine gun, shotgun, reload, đổi vũ khí và dry fire.
3. Thử sword combo/parry, spear charge/release và hammer charge/launch.
4. Kiểm tra phòng thường, elite, bomber, suicide bot và boss.
5. Nhặt coin/weapon/relic, mở chest, chọn upgrade và dùng floor exit.
6. Spawn nhiều quái và bắn liên tục để xác nhận âm thanh không làm giật khung hình.

## Kiểm tra và việc còn lại

- Godot 4.7.2 đã parse, import 93 WAV và chạy scene headless thành công; `RuntimeValidator` báo 17 services và spawn configuration hợp lệ.
- Chưa cân bằng loudness thực tế giữa các file; cần nghe trực tiếp trong editor để chỉnh volume từng nhóm nếu nguồn âm có độ lớn không đồng đều.
