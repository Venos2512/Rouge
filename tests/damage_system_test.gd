extends SceneTree


const DamageInfoScript = preload(
	"res://gungeon_proto/scripts/combat/damage_info.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)


class LegacyReceiver:
	extends Node
	var health: int = 10

	func take_damage(amount: int) -> void:
		health = maxi(health - amount, 0)


func _initialize() -> void:
	var failures: Array[String] = []
	_test_multiplier_and_armor(failures)
	_test_delivery_tag(failures)
	_test_legacy_fallback(failures)

	if failures.is_empty():
		print("DAMAGE_SYSTEM_TEST_OK")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	quit(1)


func _test_multiplier_and_armor(failures: Array[String]) -> void:
	var target := Node.new()
	var info: RefCounted = DamageInfoScript.create(4, &"fire")
	var result: RefCounted = DamageResolverScript.resolve_amount(
		target,
		info,
		{&"fire": 1.5},
		1
	)
	if result.final_amount != 5:
		failures.append("Fire 4 x1.5 trừ 1 armor phải còn 5 damage.")
	target.free()


func _test_delivery_tag(failures: Array[String]) -> void:
	var info: RefCounted = DamageInfoScript.create(
		1,
		&"shock",
		[&"explosion"]
	)
	if not info.has_delivery_tag(&"explosion"):
		failures.append("DamageInfo không giữ delivery tag explosion.")


func _test_legacy_fallback(failures: Array[String]) -> void:
	var target := LegacyReceiver.new()
	get_root().add_child(target)
	var result: RefCounted = DamageResolverScript.apply_simple_damage(
		target,
		3,
		&"physical",
		[&"projectile"]
	)
	if target.health != 7 or not result.used_legacy_receiver:
		failures.append("Fallback take_damage(amount) không giữ tương thích.")
	target.queue_free()
