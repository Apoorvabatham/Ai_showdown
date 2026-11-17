extends RefCounted
## Per-fighter moveset overrides for the AI Showdown roster (docs/ROADMAP.md §1).
##
## tools/build_showdown_roster.gd copies each fighter's kit (data/kits/), renames the
## specials (ROSTER `moves`) and scales the damage (ROSTER `damage`). Then it applies the
## entry here, so a fighter can play differently from its kit. Owner: Claude (TASKS.md §2).
##
## Entry keys (all optional), applied in this order:
##   remove: Array of kit move files (e.g. "dragon_barrage") to drop. Drop a super's
##           follow-ups along with it.
##   tweak:  {move_file: {MoveData field: value}}: set fields on a kept move. Values are
##           final (no damage scaling).
##   add:    {new_file: {from = "<moves folder>/<file>", set = {field: value}}}: a new move
##           cloned from any move in data/moves/ (a kit's or a fighter's), then `set`
##           applied. `damage` / `chip_damage` are scaled by the ROSTER `damage` unless `set`
##           gives them. Give it a `name` and an `input`.
##   stats:  {CharacterData field: value}: applied after the ROSTER `stats`.
##   trials: Array of combo trials replacing the kit's (same format as data/kits/*.tres).
##           Without it, the kit's trials are kept minus any that use a removed input.
##
## A fighter with an entry here should also get its own CPU personality
## (AIController.PERSONALITIES) and showcase routine (FighterShowcase.ROUTINES), keyed by
## its id: CharacterData.lookup() prefers the fighter's entry over the kit's.

const MOVESETS := {
}
