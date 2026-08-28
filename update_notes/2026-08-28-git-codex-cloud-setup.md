# Thiết lập Git và Codex Cloud

## Mục tiêu

Đưa source dự án lên GitHub để có thể tiếp tục phát triển từ Codex Cloud hoặc máy khác.

## File thêm/sửa/xóa/di chuyển

- Sửa `res://.gitignore` để loại cache Godot, export template cục bộ và bản build khỏi Git.
- Thêm `res://update_notes/2026-08-28-git-codex-cloud-setup.md`.
- Không xóa hoặc di chuyển file source/runtime.

## Thay đổi gameplay hoặc kiến trúc

- Không thay đổi gameplay hay kiến trúc runtime.
- Khởi tạo repository Git, nhánh `main`, và liên kết với `https://github.com/Venos2512/Rouge.git`.

## Thông số trước/sau

- Trước: dự án chỉ tồn tại cục bộ, chưa có lịch sử Git.
- Sau: source được theo dõi trên nhánh `main`; cache, export template và bản build cục bộ không được commit.

## Cách kiểm thử

1. Clone repository trên máy khác.
2. Mở `project.godot` bằng Godot 4.x và chờ import asset hoàn tất.
3. Chạy scene khởi động `res://gungeon_proto/main.tscn`.
4. Xác nhận `git status` sạch sau khi Godot tạo cache cục bộ.

## Lỗi hoặc việc còn lại

- Cần chọn repository `Venos2512/Rouge` trong Codex Cloud và cấu hình Godot headless nếu muốn chạy kiểm tra tự động trên cloud.
- Kiểm tra cảm giác gameplay và VFX vẫn cần Godot có giao diện trên một máy phù hợp.
