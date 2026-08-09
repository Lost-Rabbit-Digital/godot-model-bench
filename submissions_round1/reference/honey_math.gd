extends RefCounted

const BOTTLE_SIZE: float = 250.0

static func bottles_for(honey: float) -> int:
	return maxi(int(floor(honey / BOTTLE_SIZE)), 0)

static func jar_price(bottles: int, base: float = 3.5) -> float:
	var b: int = maxi(bottles, 0)
	var total: float = 0.0
	var full: int = mini(b, 12)
	total += float(full) * base
	b -= full
	var mid: int = mini(b, 36)
	total += float(mid) * base * 0.9
	b -= mid
	total += float(b) * base * 0.8
	return roundf(total * 100.0) / 100.0

static func short_label(amount: float) -> String:
	if amount < 1000.0:
		return "%d g" % [maxi(int(floor(amount)), 0)]
	return "%.2f kg" % [amount / 1000.0]
