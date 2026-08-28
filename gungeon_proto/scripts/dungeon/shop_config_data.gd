class_name ShopConfigData
extends Resource


@export_group("Offers")
@export var choice_count: int = 3

@export var offer_positions: Array[Vector2] = [
	Vector2(-145.0, 20.0),
	Vector2(0.0, 20.0),
	Vector2(145.0, 20.0),
]

@export_group("Prices")
@export var common_price: int = 15
@export var rare_price: int = 28
@export var epic_price: int = 45

@export var floor_price_increment: int = 3


func get_price(
	rarity: String,
	floor_number: int
) -> int:
	var base_price: int = common_price

	match rarity:
		"RARE":
			base_price = rare_price

		"EPIC":
			base_price = epic_price

	return (
		base_price
		+ maxi(
			0,
			floor_number - 1
		) * floor_price_increment
	)