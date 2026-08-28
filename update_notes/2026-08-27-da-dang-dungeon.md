# Đa dạng dungeon

## Mục tiêu

Tạo nhiều dungeon có số phòng, hình dáng bản đồ và nhận diện địa hình khác nhau mà không làm phình lớp tích hợp runtime.

## File thêm/sửa

- Thêm `dungeon_archetype_data.gd` và bốn resource archetype trong `resources/dungeon/`.
- Sửa `dungeon_generation_data.gd`, `dungeon_generator.gd` và `dungeon_pattern_mapper.gd`.
- Sửa `room_visual_theme.gd`, `room_visual_theme.tres` và `room_visual_scene_controller.gd`.
- Thêm `tests/dungeon_variety_test.gd`.

## Gameplay và kiến trúc

- Floor xoay vòng qua Moss Garden, Frozen Passage, Lava Forge và Void Labyrinth.
- Mỗi archetype cấu hình độc lập số phòng, giới hạn bản đồ, hướng phát triển, độ phân nhánh, terrain và nhóm layout combat.
- Dungeon mới giữ topology do generator tạo thay vì bị ép về mẫu tối đa 11 phòng cũ.
- Metadata terrain được lưu trong từng room để renderer đổi màu nền.
- Mỗi phòng chọn ngẫu nhiên một trong bốn kích thước từ 1056×600 đến 1536×864; boss luôn tối thiểu 1344×756.
- Mỗi biome có bốn biến thể bề mặt riêng, kèm chi tiết nền sinh ổn định theo tọa độ phòng.
- Đã gỡ phần preview hình chữ nhật của phòng liền kề khỏi world view theo phản hồi về độ rõ hình ảnh. Enemy vẫn chỉ được spawn sau khi chuyển phòng.
- Hai đầu cùng một kết nối dùng chung offset chuẩn hóa; renderer, vùng chuyển phòng và vị trí xuất hiện đều bám theo cửa thực tế.
- Sau vòng chỉnh feel, cửa dùng ba lane rõ ràng với trọng số 25% lệch âm, 50% ở giữa và 25% lệch dương.
- Minimap dùng một kiểu ô thống nhất cho mọi phòng. Phòng special đã ghé dùng icon giữa ô: kim cương treasure, tam giác elite, mặt boss và vòng tròn shop; phòng chưa ghé không lộ icon.
- Minimap luôn dịch bản đồ để phòng hiện tại nằm giữa khung và bật clipping, vì vậy nhánh dungeon dài không còn vẽ tràn sang Gold HUD hoặc ra ngoài viền.
- Phòng combat thường có 70% xác suất dùng cỡ nhỏ, 25% cỡ vừa và 5% cỡ lớn. Shop/treasure luôn nhỏ, elite luôn vừa và boss luôn lớn.
- Phòng vừa nhận thêm tối đa 1 enemy, phòng lớn thêm tối đa 2 enemy; trần tương ứng là 8 và 9. Spawn point được phân bố theo diện tích an toàn của phòng thay vì tọa độ cố định quanh tâm.
- Layout runtime giữ hành lang tiếp cận dài 210 px trước mỗi cửa; wall, prop, barrel, spike và saw giao với lane này sẽ không được spawn.
- Thêm `BiomeRoomGeometry`: layout cơ sở được giãn theo kích thước phòng rồi bổ sung topology cho combat/elite theo biome. Moss tạo cụm pillar/pot, Ice tạo hai lane dọc và saw ngang, Lava tạo choke point với spike, Void tạo cover bất đối xứng. Start/shop/treasure/boss giữ layout chuyên dụng và không nhận hazard biome ngoài ý muốn.

## Thông số trước/sau

- Trước: 8-11 phòng, bị remap về tối đa 11 phòng, một terrain stone.
- Sau: 7-9, 10-13, 12-15 hoặc 15-18 phòng tùy archetype; bốn terrain moss, ice, lava và void.
- Kích thước phòng ban đầu: ngẫu nhiên 704×400 đến 1024×576. Sau điều chỉnh cuối: chiều rộng và chiều cao đều tăng 1,5 lần, thành 1056×600, 1152×648, 1344×756 hoặc 1536×864; diện tích tăng 2,25 lần.

## Cách kiểm thử

1. Chạy game và đi qua ít nhất bốn floor; kiểm tra minimap có quy mô/hình dáng khác nhau.
2. Kiểm tra màu nền lần lượt xanh rêu, xanh băng, đỏ dung nham và tím hư không.
3. Chạy `tests/dungeon_variety_test.gd`; kết quả mong đợi là `DUNGEON_VARIETY_TEST_OK`.
4. Đi sát một cửa đã mở; kiểm tra không còn hình chữ nhật preview phòng kế. Bước qua cửa và kiểm tra biên di chuyển/camera theo đúng kích thước phòng mới.
5. Kiểm tra cửa ở nhiều phòng không luôn nằm giữa tường; thử đi sát cạnh tường ngoài vùng cửa để bảo đảm không chuyển phòng.
6. Kiểm tra ít nhất một phòng nhỏ, vừa, elite và boss; xác nhận mật độ quái không bị dồn giữa phòng.
7. Qua đủ bốn biome và xác nhận hình học phòng thay đổi rõ ràng, telegraph của saw/spike vẫn có đủ không gian phản ứng, đồng thời lane trước cửa không bị chặn.
8. Đi đến các phòng xa điểm bắt đầu theo cả bốn hướng; xác nhận ô hiện tại luôn nằm giữa minimap và không có room/connection nào vẽ ngoài khung.

## Việc còn lại

- Terrain hiện khác về màu sắc và nhóm bố cục/chướng ngại; texture, hiệu ứng môi trường và hazard chuyên biệt có thể bổ sung sau.
