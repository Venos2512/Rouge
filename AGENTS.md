# Gungeon — Hướng dẫn làm việc trong dự án

## 1. Mô tả dự án

Gungeon là game hành động roguelite 2D góc nhìn từ trên xuống, phát triển bằng Godot 4.x. Trọng tâm trải nghiệm là chiến đấu cận chiến có lực, kết hợp vũ khí tầm xa, né tránh, tương tác với môi trường và lựa chọn nâng cấp theo từng lượt chơi.

Vòng lặp chính:

1. Bắt đầu một lượt chơi và tạo tầng dungeon.
2. Di chuyển qua các phòng nối với nhau trên lưới.
3. Dọn encounter, né bẫy, phá vật thể và nhận phần thưởng.
4. Chọn đường qua phòng chiến đấu, kho báu, cửa hàng, elite và boss.
5. Nhận vũ khí, tiền, relic hoặc nâng cấp để phát triển build.
6. Đánh boss, sang tầng tiếp theo và tăng độ khó.

Định hướng thiết kế hiện tại:

- Ưu tiên cảm giác di chuyển và cận chiến trước khi mở rộng nội dung.
- Đòn đánh phải rõ nhịp chuẩn bị, va chạm, phản hồi và hồi chiêu.
- Kẻ địch có vai trò dễ đọc, phối hợp để tạo áp lực thay vì mọi loại đều quá thông minh hoặc di chuyển liên tục.
- Màn chơi đông đối tượng vẫn phải ổn định; hiệu ứng không được đổi lấy giật khung hình.
- Kiến trúc dữ liệu và scene phải dễ mở rộng thêm vũ khí, quái, phòng và nâng cấp.

## 2. Cấu trúc runtime chính

Scene khởi động hiện tại: `res://gungeon_proto/main.tscn`.

Các khối chính:

- `Player`: điều khiển, di chuyển, chiến đấu và các hệ thống vũ khí, nâng cấp, tiền tệ.
- `CoreRuntime`: điều phối dungeon, phòng, encounter, spawn, reward, shop, relic, UI phụ trợ và kiểm tra runtime.
- `DungeonHUD`: minimap, lựa chọn nâng cấp, thông tin phòng, boss và vàng.
- `dungeon_main_m5.gd`: lớp tích hợp cấp cao và điểm nối của nhiều hệ thống cũ; hạn chế tiếp tục phình file này.

Các module quan trọng:

| Miền | Module chính | Trách nhiệm |
| --- | --- | --- |
| Luồng dungeon | `RoomFlowDirector`, `DungeonGenerator`, `RoomDirector` | Sinh tầng, chuyển phòng, quản lý trạng thái phòng |
| Encounter | `EncounterDirector`, `GameplaySpawner` | Chọn wave, tạo quái, boss và vật thể gameplay |
| Phần thưởng | `RewardDirector`, `ShopDirector`, `RelicSystem` | Reward, cửa hàng, relic và tiến trình build |
| Chiến đấu người chơi | `WeaponSystem`, `WeaponSpecialController`, `UpgradeSystem` | Vũ khí, kỹ năng đặc biệt và nâng cấp |
| Không gian phòng | `RoomVisualRenderer`, `RoomBoundaryBlocker`, `RoomNavigation` | Hiển thị phòng, biên va chạm và điều hướng |
| Giao diện | `DungeonHUD`, minimap, weapon HUD, reload UI | Trạng thái chiến đấu và tiến trình dungeon |
| Công cụ | `RuntimeValidator`, `DevTools`, debug overlay | Phát hiện cấu hình sai và hỗ trợ kiểm thử |

Resource dữ liệu phải là nguồn cấu hình ưu tiên cho enemy, weapon, dungeon và room layout; không rải thông số cân bằng trùng lặp trong nhiều script.

## 3. Quy tắc kiến trúc

- Mỗi script chỉ nên có một trách nhiệm chính.
- Khi một hệ thống đã có director/controller riêng, bổ sung logic vào module đó thay vì tiếp tục nhét vào `dungeon_main_m5.gd`.
- Scene chịu trách nhiệm composition; resource chịu trách nhiệm dữ liệu; script chịu trách nhiệm hành vi.
- Kết nối hệ thống qua signal hoặc API công khai rõ ràng. Tránh truy cập sâu vào cây node nếu đã có tham chiếu hoặc hàm trung gian.
- Không tạo singleton/autoload mới nếu chưa có nhu cầu xuyên scene thật sự.
- Không đổi đường dẫn file tùy tiện. Nếu di chuyển file, phải cập nhật toàn bộ `preload`, `load`, `ext_resource` và sidecar liên quan.
- Không giữ hai bản script gần giống nhau làm nguồn sự thật song song.
- Tính năng mới phải chạy được khi node tùy chọn chưa tồn tại, hoặc phải được `RuntimeValidator` báo lỗi rõ ràng.

## 4. Quy ước GDScript và Godot

- Dùng GDScript tương thích Godot 4.x.
- Khai báo kiểu cho biến, tham số và giá trị trả về khi hợp lý.
- Tên file, biến và hàm dùng `snake_case`; tên class dùng `PascalCase`; hằng số dùng `UPPER_SNAKE_CASE`.
- Dùng `_physics_process()` cho chuyển động/vật lý, `_process()` cho hiển thị hoặc logic không phụ thuộc vật lý.
- Mọi `@onready` NodePath phải khớp scene hiện tại; khi sửa scene, kiểm tra lại toàn bộ đường dẫn phụ thuộc.
- Kiểm tra `is_instance_valid()` cho node có thể bị giải phóng trong combat.
- Không gọi `get_nodes_in_group()` hoặc tìm node toàn cây mỗi frame nếu có thể cache tham chiếu.
- Không cấp phát mảng/dictionary lớn, tạo tween hoặc tạo node hàng loạt trong vòng lặp mỗi frame.
- Các timer lặp lại nên dùng `Timer`, bộ đếm delta, pool hoặc scheduler phù hợp; tránh tạo timer tạm với số lượng lớn.
- Effect, damage number, projectile và explosion đông phải có giới hạn, tái sử dụng hoặc cơ chế giảm tải.

## 5. Nguyên tắc gameplay

- Chỉ số và hành vi phải phục vụ vai trò rõ ràng của từng kẻ địch.
- Kẻ địch thường không được sở hữu đồng thời quá nhiều năng lực như bắn xa, chạy trốn, núp và né lăn; hành vi nâng cao dành cho biến thể elite.
- Telegraph phải xuất hiện đủ sớm để người chơi phản ứng, đặc biệt với bomb, lao cảm tử, trap và đòn boss.
- Hit stop, camera shake và VFX phải có cường độ/giới hạn dùng chung; không cộng dồn mất kiểm soát.
- Không sửa feel cận chiến bằng cách khóa cứng chuyển động nếu gây giật khi vừa chạy vừa đánh. Ưu tiên giảm tốc có kiểm soát, impulse ngắn và animation timing rõ ràng.
- Mọi thay đổi cân bằng cần ghi thông số trước/sau trong `update_notes/`.

## 6. Hiệu năng và độ ổn định

Các thay đổi combat phải được kiểm thử ít nhất ở tình huống 1, 5 và nhiều kẻ địch cùng lúc.

Trước khi hoàn tất, kiểm tra:

- Không còn lỗi parser, preload hoặc NodePath.
- Không có scene/resource trỏ đến file đã di chuyển hoặc chưa tồn tại.
- Projectile, bomb, effect và enemy được giải phóng đúng lúc.
- Explosion không tạo lượng node/tween/damage query vượt mức cần thiết.
- Không thực hiện truy vấn vật lý hoặc tìm kiếm cây scene lặp lại cho từng đối tượng nếu có thể gom nhóm.
- Tạm dừng, chuyển phòng, chết và khởi động lượt mới không để lại trạng thái cũ.

Khi tối ưu, giữ nguyên hành vi gameplay trước; nếu cần giảm chất lượng hiệu ứng hoặc thay đổi thiết kế, phải ghi rõ trong update note.

## 7. Quy trình chỉnh sửa qua ChatGPT Bridge

Khi người dùng cung cấp context từ Godot Bridge, mọi thay đổi file phải xuất đúng `CHATGPT_BRIDGE_PATCH_V1` ở cuối câu trả lời.

Phép toán được hỗ trợ:

- `CREATE_FILE`
- `REPLACE_IN_FILE`
- `MOVE_FILE`
- `DELETE_FILE`

Quy tắc bắt buộc:

- Chỉ dùng đường dẫn bắt đầu bằng `res://` và không chứa `..`.
- Không dùng unified diff.
- Mỗi khối `SEARCH` phải sao chép chính xác nội dung hiện tại và chỉ khớp đúng một vị trí.
- Không đoán nội dung file. Nếu thiếu đoạn nguồn cần sửa, yêu cầu người dùng gửi file/context mới.
- Không `CREATE_FILE` nếu file đã tồn tại.
- Không `MOVE_FILE` nếu nguồn không tồn tại hoặc đích đã tồn tại.
- Không `DELETE_FILE` nếu file không tồn tại.
- Không di chuyển hoặc xóa addon ChatGPT Bridge.
- Patch lớn nên tách thành các bước nhỏ, ưu tiên tạo module mới trước rồi mới nối vào runtime.
- Sau mỗi patch, nêu ngắn gọn cách kiểm thử trong Godot và lỗi nào cần gửi lại nếu xuất hiện.

## 8. Update notes

Mọi thay đổi đáng kể từ ngày 26/08/2026 phải được ghi trong `res://update_notes/`.

Quy ước tên file:

```text
YYYY-MM-DD-ten-thay-doi.md
```

Mỗi note tối thiểu gồm:

- Mục tiêu.
- File thêm/sửa/xóa/di chuyển.
- Thay đổi gameplay hoặc kiến trúc.
- Thông số trước/sau nếu có.
- Cách kiểm thử.
- Lỗi hoặc việc còn lại.

Nếu một ngày có nhiều patch cùng chủ đề, cập nhật cùng note. Nếu khác chủ đề, tạo note riêng. Không ghi các chỉnh sửa định dạng thuần túy nếu chúng không ảnh hưởng hành vi.

## 9. Tiêu chí hoàn tất

Một thay đổi chỉ được coi là hoàn tất khi:

1. Project parse và chạy được trong Godot.
2. Không còn reference hỏng ở scene/resource/script liên quan.
3. Hành vi mới đã được kiểm thử trong tình huống thực tế.
4. Không làm giảm hiệu năng rõ rệt khi có nhiều đối tượng.
5. `update_notes/` đã phản ánh thay đổi.
6. Câu trả lời bàn giao nêu rõ đã làm gì, cách kiểm tra và phần còn tồn tại.
