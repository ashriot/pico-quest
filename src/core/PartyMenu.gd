extends Control
# PARTY MENU

onready var tooltip = $Tooltip
onready var player_panels = $PlayerPanels
onready var main_menu = $MainMenu
onready var stats_panel = $Stats

onready var items_panel = $Items
onready var popup = $Items/PopupMenu
onready var tab1 = $Items/BG/HBoxContainer/Tab1
onready var tab2 = $Items/BG/HBoxContainer/Tab2
onready var item_buttons = $Items/BG/Items

onready var inv_panel = $Inventory
onready var inv_preview = $Inventory/PreviewBtn
#onready var inv_popup = $Inventory/PopupMenu
onready var inv_filters = $Inventory/BG/Filters
onready var inv_buttons = $Inventory/BG/Items
onready var page_label = $Inventory/BG/Pages/Label

var game
var players
var cur_player: PlayerMenuPanel
var cur_menu: Control

var cur_page: int
var total_pages: int
var cur_tab: int setget set_cur_tab
var cur_btn: Button setget set_cur_btn

func init(_game) -> void:
	hide()
	tooltip.hide()
	items_panel.hide()
	stats_panel.hide()
	inv_panel.hide()
	game = _game
	players = game.players
	inv_preview.hide()
	main_menu.show()
	for child in player_panels.get_children(): child.init(self)
	for child in item_buttons.get_children(): child.init(self)
	for child in inv_buttons.get_children(): child.init(self)

func open_menu() -> void:
	cur_page = 0
	cur_menu = null
	main_menu.show()
	update_menu_data()
	update_inv_data()
	show()

func _on_CloseButton_pressed() -> void:
	AudioController.back()
	if inv_preview.visible:
		inv_preview.hide()
		inv_panel.hide()
		return
	if cur_menu != null:
		stats_panel.hide()
		cur_menu.hide()
		cur_menu = null
		main_menu.show()
	else: game.close_menu()

func update_menu_data() -> void:
	var i = 0
	for child in player_panels.get_children():
		if players[i] == null: continue
		child.setup(players[i])
		if cur_player == null:
			cur_player = child
			cur_player.select(true)
		i += 1

func update_stat_data() -> void:
	stats_panel.show()
	if cur_player == null:
		cur_player = player_panels.get_child(0)
		cur_player.select(true)
	$Stats/Sprite.frame = cur_player.unit.frame + 20
	$Stats/Name.text = cur_player.unit.name
	$Stats/Job.text = cur_player.unit.job
	$Stats/HP.text = str(cur_player.unit.hp_cur) + "\n/" + \
		str(cur_player.unit.hp_max)
	$Stats/Stats/STR/Value.text = str(cur_player.unit.strength)
	$Stats/Stats/AGI/Value.text = str(cur_player.unit.agility)
	$Stats/Stats/INT/Value.text = str(cur_player.unit.intellect)
	$Stats/Stats/DEF/Value.text = str(cur_player.unit.defense)

func update_item_data():
	var i = 0
	for child in item_buttons.get_children():
		if cur_player.unit.items.has(i):
			child.setup(cur_player.unit, cur_player.unit.items[i])
		else: child.setup(cur_player.unit, null)
		i += 1
	self.cur_tab = cur_player.tab
	$Items/BG/HBoxContainer/Tab2/Label.text = cur_player.unit.job_tab
	$Items/BG/HBoxContainer/Tab2/ColorRect/Label.text = cur_player.unit.job_tab

func set_cur_tab(value) -> void:
	cur_tab = value
	cur_player.tab = value
	var other_tab = (cur_tab + 1) % 2
	for j in range((other_tab * 4), (other_tab * 4) + 4):
		item_buttons.get_child(j).hide()
	for j in range((cur_tab * 4), (cur_tab * 4) + 4):
		item_buttons.get_child(j).show()
	if other_tab == 0:
		$Items/BG/HBoxContainer/Tab1/ColorRect.hide()
		$Items/BG/HBoxContainer/Tab2/ColorRect.show()
	else:
		$Items/BG/HBoxContainer/Tab1/ColorRect.show()
		$Items/BG/HBoxContainer/Tab2/ColorRect.hide()

func set_cur_btn(value) -> void:
	if value == null:
		cur_btn.selected = false
		popup.hide()
		return
	if cur_btn == value:
		AudioController.back()
		cur_btn.selected = false
		cur_btn = null
		popup.hide()
		return
	AudioController.select()
	if cur_btn != null: cur_btn.selected = false
	cur_btn = value
	cur_btn.selected = true
	popup.rect_global_position = cur_btn.rect_global_position - Vector2(-1, popup.rect_size.y * 1)
	popup.show()

func _on_Items_pressed() -> void:
	AudioController.click()
	cur_menu = items_panel
	main_menu.hide()
	popup.hide()
	update_stat_data()
	update_item_data()
	items_panel.show()

func _on_PlayerMenuPanel_pressed(panel) -> void:
	if cur_player != null and cur_player == panel: return
	AudioController.confirm()
	cur_player.select(false)
	cur_player = panel
	cur_player.select(true)
	update_stat_data()
	if cur_menu == items_panel: update_item_data()

func _on_ItemButton_clicked(button) -> void:
	if button.empty:
		AudioController.select()
		equip_item(button)
	else:
		self.cur_btn = button

func equip_item(button) -> void:
	cur_btn = button
	inv_preview.setup(cur_player, button)
	inv_preview.show()
	inv_panel.show()

func _on_ItemButton_long_pressed(button) -> void:
	AudioController.click()
	if button.empty:
		print("Equip new item!")
	else:
		tooltip.setup(button.item.name, button.item.desc)

func _on_InfoButton_pressed() -> void:
	pass # Replace with function body.

func _on_Tab1_pressed() -> void:
	AudioController.confirm()
	self.cur_tab = 0

func _on_Tab2_pressed() -> void:
	AudioController.confirm()
	self.cur_tab = 1

func _on_Swap_pressed() -> void:
	AudioController.confirm()
	inv_preview.setup(cur_player, cur_btn.item)
	inv_preview.show()
	inv_panel.show()

#### INVENTORY ####

func _on_Inventory_pressed() -> void:
	AudioController.click()
	cur_menu = inv_panel
	update_inv_data()
	inv_panel.show()

func update_inv_data():
	update_page_data()
	var size = game.inventory.items.size()
	var lo = cur_page * 10
	var hi = min((cur_page * 10) + 9, size)
	var items = game.inventory.items.slice(lo, hi)
	var i = cur_page * 10
	for child in inv_buttons.get_children():
		if i < game.inventory.items.size():
			var item = game.inventory.items[i]
			child.setup(item)
		else: child.setup(null)
		i += 1
	page_label.text = str(cur_page + 1) + "/" + str(total_pages)
	if total_pages > 1:
		$Inventory/BG/Pages/Left.modulate.a = 1.0
		$Inventory/BG/Pages/Right.modulate.a = 1.0
	else:
		$Inventory/BG/Pages/Left.modulate.a = 0.3
		$Inventory/BG/Pages/Right.modulate.a = 0.3

func _on_InvButton_remove_item(item: Item) -> void:
	game.inventory.remove_item(item)

func _on_InvButton_clicked(button) -> void:
	if inv_preview.visible:
		AudioController.click()
		var item = button.item
		game.inventory.remove_item(item)
		cur_player.unit.add_item(item, cur_btn.get_index())
		if !cur_btn.empty: game.inventory.add_item(cur_btn.item.name)
		cur_btn.setup(cur_player.unit, item)
		cur_btn.selected = false
		cur_btn = null
		popup.hide()
		inv_preview.hide()
		inv_panel.hide()
		update_inv_data()
	else:
		self.cur_btn = button

func update_page_data():
	var size = game.inventory.items.size()
	total_pages = max(ceil(size / 10.0), 1)
	if cur_page < 0: cur_page = total_pages - 1
	elif cur_page >= total_pages: cur_page = 0

func _on_Left_pressed():
	if total_pages == 1: return 
	AudioController.click()
	cur_page -= 1
	update_inv_data()
	
func _on_Right_pressed():
	if total_pages == 1: return
	AudioController.click()
	cur_page += 1
	update_inv_data()
