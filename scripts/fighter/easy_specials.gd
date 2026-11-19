class_name EasySpecials
## One-button specials (the parody wants them easy): the Power button fires a fighter's
## specials and the Super button their super, with no motions to learn.
##   Power            -> the signature power move (the special that throws something)
##   Forward + Power  -> the next special
##   Back + Power     -> the next
##   Down + Power     -> the next
##   Super            -> the super (still needs a full meter)
## The classic motion inputs (236P, ...) keep working; this only adds shortcuts. Pure
## function of the CharacterData, so the simulation, the move list and character select
## all agree, and it is deterministic (no state).

## Numpad directions of the Power slots, in the order specials fill them.
const SLOTS := [5, 6, 4, 2]
const SLOT_NAMES := {5: "", 6: "→ + ", 4: "← + ", 2: "↓ + "}


## {numpad dir: MoveData} for the Power button, plus "super": MoveData (or absent).
static func slots(data: CharacterData) -> Dictionary:
	var out := {}
	if data == null:
		return out
	var specials: Array[MoveData] = []
	for move in data.moves:
		if move.super_move:
			if not out.has("super"):
				out["super"] = move
			continue
		if move.is_special() and not move.input.begins_with("~") and not move.input.begins_with("j."):
			specials.append(move)
	# The power move first: the special whose shots have their own look (search bars,
	# GPUs, containers...), else any projectile, else the first special.
	var signature: MoveData = null
	for move in specials:
		if move.projectile_look != &"":
			signature = move
			break
	if signature == null:
		for move in specials:
			if move.fires_projectile():
				signature = move
				break
	var ordered: Array[MoveData] = []
	if signature != null:
		ordered.append(signature)
	for move in specials:
		if move != signature:
			ordered.append(move)
	for i in mini(ordered.size(), SLOTS.size()):
		out[SLOTS[i]] = ordered[i]
	return out


## The easy input for `move` as shown to players ("→ + Power"), or "" if it has none.
static func label(data: CharacterData, move: MoveData) -> String:
	var s := slots(data)
	if s.get("super") == move:
		return "Super"
	for dir in SLOTS:
		if s.get(dir) == move:
			return SLOT_NAMES[dir] + "Power"
	return ""


## The easy specials in slot order as [MoveData, label] pairs, super last; `power` and
## `super_name` replace the button words (e.g. the bound keys "O" / "P").
static func listing(data: CharacterData, power := "Power", super_name := "Super") -> Array:
	var s := slots(data)
	var out := []
	for dir in SLOTS:
		if s.has(dir):
			out.append([s[dir], SLOT_NAMES[dir] + power])
	if s.has("super"):
		out.append([s["super"], super_name])
	return out
