extends Resource

class_name Hit

var item: Resource
var hit_chance: int
var crit_chance: int
var bonus_dmg: int
var dmg_mod: float
var atk: int
var stat_hit: int
var level: int

func init(_item, _hit_chance, _crit_chance, _bonus_dmg, _dmg_mod, _atk, _level):
	item = _item
	hit_chance = _hit_chance
	crit_chance = _crit_chance
	bonus_dmg = _bonus_dmg + item.bonus_damage
	dmg_mod = _dmg_mod
	atk = _atk
	stat_hit = item.stat_hit
	level = _level
