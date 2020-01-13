#handles hiding and showing the shop menu and telling other classes the shop menu is open
#also handles pressing tab to switch between windows

extends Control

#for placing the shop directly over the player
onready var Game = get_node("/root/Game")

#for keeping track of the player's location to know when it is valid to open the shop
onready var Player = get_node("/root/Game/Farm/Player")
onready var Town_Grid = get_node("/root/Game/Town/DummyObject")

onready var Farm_Grid = get_node("/root/Game/Farm/Objects1") #TODO get rid of, only here for testing

#for moving the dashboard above the shop menu to display the time
onready var UI = get_node("/root/Game/Farm/Player/UI")

#for only showing the shop menu when the inventory is closed
onready var Inventory = get_node("/root/Game/Farm/Player/UI/Inventory")

#for telling the hotbar and energy bar to become invisible when the shop menu opens
onready var Hotbar = get_node("/root/Game/Farm/Player/UI/Hotbar")
onready var EnergyBar = get_node("/root/Game/Farm/Player/UI/Energy Bar")

#for showing and hiding the menus and resetting them
onready var Buy = get_node("Buy")
onready var Sell = get_node("Sell")

#connects the sleep signal for telling the shop to close if it is open at 11pm
func _ready():
	get_node("/root/Game/Farm/Player/UI/Dashboard/TimeManager").connect("sleep", self, "_force_sleep")

#handles showing and hiding the shop menu
func _input(event):
	#Show the shop menu if the player presses E, is in the correct spot, and the inventory and shop are not open
	if Input.is_action_pressed("E") and Town_Grid.world_to_map(Player.position) == Vector2(27, 43) and not Inventory.visible and not visible:
		#(Input.is_action_pressed("E") and Farm_Grid.world_to_map(Player.position) == Vector2(19, 9) and not Inventory.visible and not visible) or \
		visible = true
		Hotbar.visible = false
		EnergyBar.visible = false
		UI.z_index = 5
		#place the shop directly over the player
		rect_position = Vector2(Game.player.position.x - ((rect_size.x/2)*rect_scale.x), Game.player.position.y - ((rect_size.y/2)*rect_scale.y) + 13) + Game.player_location.position
	#close the shop
	elif Input.is_action_pressed("pause") and visible:
		_close_shop_menu()
	#switch tabs
	elif Input.is_action_pressed("Tab") and visible:
		switch_tabs()

func _close_shop_menu():
	visible = false
	Buy.visible = true
	Sell.visible = false
	Hotbar.visible = true
	EnergyBar.visible = true
	UI.z_index = 3
	Buy.reset_menu()
	Sell.reset_menu()

#switches between the buy and sell menus
func switch_tabs():
	#switch to Sell
	if Buy.visible:
		Buy.visible = false
		Sell.visible = true
		Sell.update_sell_menu()
	#switch to Buy
	else:
		Buy.visible = true
		Sell.visible = false
		Buy.update_buy_menu()

#closes the shop if it is open, forcing the player to sleep
func _force_sleep():
	if visible:
		_close_shop_menu()
