# Shield bot

## Mục tiêu

Thêm vai trò Shield: luôn hướng khiên về người chơi, chặn đòn từ phía trước và đứng che cho Gunner hoặc Support.

## File thay đổi

- Thêm `gungeon_proto/scripts/enemies/shield.gd`.
- Thêm `gungeon_proto/scenes/enemies/shield.tscn`.
- Thêm `gungeon_proto/resources/enemies/shield.tres`.
- Sửa `gungeon_proto/resources/enemies/enemy_database.tres` để Shield xuất hiện trong normal pool.
- Sửa `gungeon_proto/scripts/gameplay/gameplay_spawner.gd` để wave từ hai enemy luôn có cặp Shield + Gunner.

## Gameplay và kiến trúc

- Shield quay mặt theo vị trí người chơi ở mỗi nhịp AI.
- Shield tìm đồng minh gần nhất có loại `gunner` hoặc `support`, sau đó giữ vị trí giữa đồng minh và người chơi.
- Đòn từ cung trước bị chặn cả damage lẫn knockback khi guard đang hoạt động.
- Đòn sau lưng vẫn gây damage và đẩy lệch Shield.
- Lực đánh từ 250 trở lên phá guard trong 1,15 giây; đòn phá guard vẫn gây damage và knockback.
- Khi chưa có Gunner hoặc Support phù hợp, Shield tự giữ tuyến trước gần người chơi.
- Truy vấn đồng minh được cache và chỉ làm mới mỗi 0,25 giây để tránh quét đội hình mỗi frame.
- Thêm mũi tên vàng trên thân Shield, luôn trùng với hướng guard đang nhìn; khi guard vỡ, chỉ báo chuyển sang cam đỏ.
- Wave thường có từ hai enemy trở lên luôn dành hai vị trí đầu cho Shield và Gunner, thay vì phụ thuộc hoàn toàn vào lựa chọn ngẫu nhiên.
- Tăng bán kính hiển thị thân từ 9 lên 13 px; tâm khiên từ 11 lên 16 px, chiều dài khiên từ 18 lên 26 px và độ dày từ 5 lên 7 px.
- Hướng guard có tám hướng cố định, gồm trái/phải/lên/xuống và bốn góc chéo. Shield đổi từng nấc 45 độ sau mỗi 0,30 giây; quay ngược 180 độ mất khoảng 1,20 giây để người chơi có đủ cửa sổ roll vòng ra sau.
- Tăng tốc Shield từ 34 lên 54, cao hơn Gunner (42). Khi cách vị trí bảo kê trên 72 px, Shield tăng tốc thêm 25% lên 67,5 để bắt lại đội hình.
- Thêm shield bash khi người chơi vào gần Shield hoặc áp sát Gunner/Support được bảo kê: telegraph 1 giây, gây 1 damage, hất lực 245 và hồi chiêu 1,75 giây. Roll né được cả damage lẫn lực hất.
- Khi không có đồng minh để bảo vệ, Shield chủ động áp sát người chơi tới khoảng 36 px. Khi đang bảo kê, nó cũng chuyển sang tấn công nếu người chơi vào trong 105 px.
- Trong 1 giây telegraph, hướng khiên bị khóa. Shield bash chỉ trúng cung phía trước; người chơi dodge qua lưng sẽ làm đòn đánh hụt và có cửa sổ phản công.
- Sau telegraph, Shield lao cả thân theo hướng đã khóa với tốc độ 150 trong 0,12 giây (khoảng 18 px) rồi mới kết thúc hit check. Dodge qua lưng khiến Shield lao hụt và lộ lưng xa hơn.
- Player có API knockback dùng chung; lực hất giảm dần 920 đơn vị/giây và không áp dụng khi đang roll.
- Mỗi Gunner/Support chỉ nhận một Shield bảo kê qua reservation runtime. Shield thứ hai sẽ tìm đồng minh khác hoặc giữ tuyến riêng; reservation được nhả khi Shield đổi mục tiêu hoặc bị xóa.
- Shield dùng bán kính separation 42 px. Crowd service cũng tạo hướng tách ổn định khi hai bot trùng chính xác cùng tâm, thay vì bỏ qua trường hợp này.

## Thông số trước/sau

- Trước: chưa có Shield bot.
- Sau: 7 HP, tốc độ 54 (bắt đội hình 67,5), thân 13 px, khiên dài 26 px/dày 7 px, tám hướng guard với nhịp quay 45 độ mỗi 0,30 giây, góc chặn phía trước khoảng 139 độ, ngưỡng phá guard 250 lực, thời gian vỡ guard 1,15 giây, trọng số spawn ngẫu nhiên 0,7; wave từ hai enemy bảo đảm có một Shield.

## Cách kiểm thử

1. Spawn một Shield và một Gunner; xác nhận Shield di chuyển vào giữa Gunner và người chơi.
2. Chạy vòng quanh Shield; xác nhận mặt khiên luôn xoay về người chơi.
   Mũi tên vàng phải xoay cùng mặt khiên và chỉ chính xác hướng có thể chặn đòn.
3. Bắn hoặc chém nhẹ vào mặt khiên; xác nhận Shield không mất máu và không bị đẩy.
4. Đánh từ sau lưng; xác nhận Shield mất máu và bị kéo lệch khỏi tuyến bảo vệ.
   Roll nhanh qua cạnh khiên; xác nhận hướng guard cần thời gian quay theo và đòn đánh vào lưng trong khoảng đó gây damage.
5. Dùng hammer (310 knockback) đánh trực diện; xác nhận guard đổi màu/vỡ trong 1,15 giây và Shield nhận damage.
6. Kiểm thử với 1, 5 và nhiều enemy để theo dõi di chuyển đội hình và chi phí tìm đồng minh.
7. Áp sát Shield hoặc Gunner được bảo kê; xác nhận khiên chuyển vàng và hiện cung telegraph 1 giây trước khi hất. Roll qua lưng trong nhịp telegraph phải làm đòn đánh hụt và hướng khiên không được quay theo; còn đứng phía trước phải nhận 1 damage và bị đẩy ra.
9. Hạ Gunner đang được bảo kê; xác nhận Shield không đứng chờ mà chủ động áp sát người chơi để dùng shield bash.
10. Đứng trước Shield tới hết telegraph; xác nhận cả thân Shield lao lên khoảng 18 px. Roll qua lưng trước cú lao; xác nhận Shield vẫn lao theo hướng cũ và đòn đánh hụt.
8. Spawn hai Shield và một Gunner; xác nhận chỉ một Shield đứng che Gunner, Shield còn lại giữ tuyến riêng và các bot tự tách nếu bị đặt trùng vị trí.

## Còn lại

- Loại Support chưa tồn tại trong database hiện tại; Shield đã nhận diện sẵn `enemy_type = "support"` khi loại này được bổ sung.
- Đã sửa lỗi parser ở bảng tám hướng và khôi phục giá trị trả về của hàm chọn hướng sau khi thêm shield bash.
