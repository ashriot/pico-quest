extends Control
class_name BattlePanel

signal done
signal died(panel)
signal show_dmg(text)
signal show_text(text, pos, display)

onready var button: = $Button
onready var hp_percent: = $TextureProgress
onready var target: = $Target
onready var sprite: = $Sprite
onready var anim: = $AnimationPlayer

onready var status = $Status

var enabled: bool
var alive: bool setget, get_alive
var unit = null
var hp_cur: int setget set_hp_cur
var hp_max: int
var valid_target: bool
var pos: Vector2

var hexes: Array
var boons: Array
var statuses: = []
var delay: = 0.0
var status_ptr: int
var blocking: int setget set_blocking

func init(battle) -> void:
	anim.playback_speed = 1 / GameManager.spd
	pos = rect_global_position
	pos.x -= 23
	pos.y += rect_size.y / 2
# warning-ignore:return_value_discarded
	connect("show_dmg", battle, "show_dmg_text")
# warning-ignore:return_value_discarded
	connect("show_text", battle, "show_text")

func setup(_unit):
	anim.stop()
	sprite.visible = true
	enabled = true
	sprite.frame = unit.frame
	self.hp_max = unit.hp_max
	self.hp_cur = unit.hp_max
	hp_percent.max_value = hp_max
	hp_percent.value = hp_max
	blocking = 0
	hexes.clear()
	boons.clear()
	statuses.clear()
	update_status()

func clear():
	enabled = false
	hide()

func _physics_process(delta: float) -> void:
	if statuses.size() == 0: return
	if delay < 0.1:
		status_ptr = (status_ptr + 1) % statuses.size()
		status.frame = statuses[status_ptr][1]
		delay = float(1 * GameManager.spd)
	else: delay -= 1.0 * delta

func get_stat(stat) -> int:
	return unit.get_stat(stat)

func take_hit(hit: Hit) -> void:
	var item = hit.item
	var fx = item.sound_fx
	var hit_and_crit = get_hit_and_crit_chance(hit)
	var hit_chance = hit_and_crit[0]
	var crit_chance = hit_and_crit[1]
	var lifesteal = hit.item.lifesteal
	var miss = false
	var hit_roll = randi() % 100 + 1
	print(unit.name, " uses ", hit.item.name, ": ", 100 - hit_roll, " < ", hit_chance, "%? = ", miss)
	if hit_roll > hit_chance: miss = true
	var dmg = int((item.multiplier * hit.atk) + hit.bonus_dmg) * (1 + hit.dmg_mod)
	var def = get_stat(item.stat_vs)
	var rel_def = float(def * 1.2) / float(hit.level + 10 + def)
	var def_mod = 1.0 - rel_def
	dmg = int(dmg * def_mod)
	var lifesteal_heal = int(float(min(dmg, hp_cur)) * lifesteal)
	var dmg_text = ""
	print(unit.name, " DEF: ", unit.defense, " Base dmg: ", (item.multiplier * hit.atk), " dmg taking: ", dmg)
	if not miss:
		self.hp_cur -= dmg
		dmg_text = str(dmg)
		anim.play("Hit")
	else:
		dmg_text = "MISS"
		fx = "miss"
	emit_signal("show_dmg", dmg_text, pos)
	if lifesteal_heal > 0:
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
		hit.user.take_healing(lifesteal_heal)
	if item.target_type >= Enum.TargetType.ONE_ENEMY \
		and item.target_type <= Enum.TargetType.ONE_BACK:
		AudioController.play_sfx(fx)
	if item.inflict_hexes.size() > 0 and not miss and self.alive:
		for hex in item.inflict_hexes:
			if randi() % 100 + 1 > hex[2]: continue
			yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
			var success = gain_hex(hex[0], hex[1])
			if success: emit_signal("show_text", "+" + hex[0].name, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")

func take_friendly_hit(user: BattlePanel, item: Item) -> void:
	var dmg = int(item.multiplier * user.get_stat(item.stat_used))
	var def = int(get_stat(item.stat_vs) * item.multiplier)
	var dmg_text = ""
	AudioController.play_sfx(item.sound_fx)
	if item.damage_type == Enum.DamageType.HEAL:
		dmg += def
		self.hp_cur += dmg
		dmg_text = str(dmg)
	elif item.sub_type == Enum.SubItemType.SHIELD:
		dmg_text = "Block:" + str(dmg)
		self.blocking += dmg
	if dmg > 0: emit_signal("show_text", "+" + dmg_text, pos)
	if item.inflict_hexes.size() > 0:
		for hex in item.inflict_hexes:
			if randi() % 100 + 1 > hex[2]: continue
			var success = gain_hex(hex[0], hex[1])
			if success: emit_signal("show_text", "+" + hex[0].name, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd, false), "timeout")
	if item.inflict_boons.size() > 0:
		for boon in item.inflict_boons:
			if randi() % 100 + 1 > boon[2]: continue
			var success = gain_boon(boon[0], boon[1])
			if success: emit_signal("show_text", "+" + boon[0].name, pos)
			if item.inflict_boons.find(boon) < item.inflict_boons.size() - 1:
				yield(get_tree().create_timer(0.25 * GameManager.spd, false), "timeout")
	yield(get_tree().create_timer(0.25 * GameManager.spd, false), "timeout")
	emit_signal("done")

func take_healing(amt: int) -> void:
	self.hp_cur += amt
	if amt > 0: emit_signal("show_text", "+" + str(amt), pos)

func gain_hex(hex: Effect, duration: int) -> bool:
	if hexes.has(hex.name): return false
	hexes.append([hex.name, duration])
	add_status([hex.name, hex.frame])
	if hex.name == "Dull": unit.int_mods.append(0.75)
	elif hex.name == "Frail": unit.def_mods.append(0.75)
	elif hex.name == "Slow": unit.agi_mods.append(0.75)
	elif hex.name == "Weak": unit.str_mods.append(0.75)
	return true

func gain_boon(boon: Effect, duration: int) -> bool:
	var found = false
	for b in boons: if b[0].name == boon.name:
		found = true
		if b[1] < duration: b[1] = duration
		else: return false
	if not found:
		boons.append([boon, duration])
		add_status([boon.name, boon.frame])
		if boon.name == "Bold": unit.str_mods.append(1.25)
		elif boon.name == "Fast": unit.agi_mods.append(1.25)
		elif boon.name == "Safe": unit.def_mods.append(1.25)
		elif boon.name == "Wise": unit.int_mods.append(1.25)
	return true

func decrement_boons(timing: String) -> void:
	for boon in boons:
		if (boon[0].turn_end and timing == "End") or \
			(boon[0].turn_start and timing == "Start"):
				print(boon[0].name, " -> ", boon[1])
				boon[1] -= 1
				if boon[1] == 0:
					remove_boon(boon[0])

func decrement_hexes(timing: String) -> void:
	for hex in hexes:
		if (hex[0].turn_end and timing == "End") or \
			(hex[0].turn_start and timing == "Start"):
				print(hex[0].name, " -> ", hex[1])
				hex[1] -= 1
				if hex[1] == 0:
					remove_boon(hex[0])

func remove_boon(find: Effect) -> void:
	for boon in boons:
		if boon[0] == find:
			boons.remove(boons.find(boon))
			break
	for s in statuses:
		if s[0] == find.name:
			remove_status(find.name)
			break
	if find.name == "Bold": unit.str_mods.remove(unit.str_mods.find(1.25))
	elif find.name == "Fast": unit.agi_mods.remove(unit.agi_mods.find(1.25))
	elif find.name == "Safe": unit.def_mods.remove(unit.def_mods.find(1.25))
	elif find.name == "Wise": unit.int_mods.remove(unit.int_mods.find(1.25))

func add_status(value: Array) -> void:
	statuses.append(value)
	update_status()

func remove_status(value: String) -> void:
	for s in statuses:
		if s[0] == value:
			statuses.remove(statuses.find(s))
			emit_signal("show_text", "-" + value, pos)
			break
	update_status()

func update_status() -> void:
	status_ptr = 0
	delay = 0

func targetable(value: bool, display = true):
	if not enabled: return
	if not self.alive: value = false
	valid_target = value
	if valid_target:
		if display: target.show()
	else: target.hide()

func get_hit_and_crit_chance(hit: Hit) -> Array:
	var hit_roll = 100
	var crit_roll = 0
	if hit.atk != Enum.StatType.NA:
		hit_roll = clamp(hit.hit_chance - (get_stat(hit.atk) * 3), 0, 100)
		crit_roll = hit.crit_chance
	return [hit_roll, crit_roll]

func die():
	emit_signal("died")

func set_hp_cur(value: int):
	hp_cur = int(clamp(value, 0, hp_max))
	hp_percent.value = value
	if hp_cur <= 0: die()

func set_blocking(value: int) -> void:
	print("Blocking: ", value, " martial damage.")
	blocking = value
	if blocking > 0: add_status(["Block", 79])
	else: remove_status("Block")

func get_alive() -> bool:
	return hp_cur > 0

func has_perk(perk_name: String) -> bool:
	return unit.has_perk(perk_name)
