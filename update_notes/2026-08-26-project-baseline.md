# Mốc nền dự án — 26/08/2026

## Mục tiêu

Thiết lập tài liệu gốc cho dự án Gungeon và bắt đầu hệ thống update note dùng cho mọi thay đổi đáng kể từ thời điểm này.

## File được thêm

- `res://AGENTS.md`
- `res://update_notes/2026-08-26-project-baseline.md`

## Hiện trạng được ghi nhận

- Engine: Godot 4.x.
- Thể loại: game hành động roguelite 2D góc nhìn từ trên xuống, đi theo từng phòng.
- Scene chính: `res://gungeon_proto/main.tscn`.
- Runtime đã tách các khối dungeon generation, room flow, encounter, reward, shop, relic, spawn và HUD.
- Player có các hệ thống vũ khí, nâng cấp và tiền tệ riêng.
- Dungeon có các loại phòng chiến đấu, kho báu, cửa hàng, elite và boss.
- Trọng tâm refine hiện tại là cảm giác di chuyển/cận chiến, vai trò kẻ địch rõ ràng và hiệu năng khi phòng đông quái.

## Thay đổi quy trình

- Dùng `AGENTS.md` làm nguồn quy ước chung khi phân tích hoặc chỉnh sửa dự án.
- Mọi thay đổi đáng kể sau mốc này phải có note trong `res://update_notes/`.
- Patch qua ChatGPT Bridge phải dùng `CHATGPT_BRIDGE_PATCH_V1`, với `SEARCH` khớp chính xác một vị trí.
- Thay đổi cân bằng phải ghi thông số trước/sau khi có thể.
- Thay đổi kiến trúc phải ghi rõ module nào nhận hoặc mất trách nhiệm.

## Cách kiểm thử

1. Xác nhận hai file xuất hiện trong FileSystem của Godot.
2. Mở hai file và kiểm tra tiếng Việt hiển thị đúng UTF-8.
3. Chạy project để xác nhận việc thêm tài liệu không ảnh hưởng runtime.

## Việc còn lại

- Dùng note riêng cho patch gameplay/code tiếp theo.
- Khi có context toàn bộ repository mới hơn, cập nhật mục kiến trúc trong `AGENTS.md` nếu cấu trúc thực tế thay đổi.
