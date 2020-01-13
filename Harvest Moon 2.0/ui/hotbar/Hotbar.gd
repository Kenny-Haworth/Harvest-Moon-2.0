#the hotbar mirrors the last row of the inventory and is always hidden when the inventory is shown
#this script is responsible for this as well as telling the inventory to equip the proper item
#when the following controls are used on the hotbar:
#	the numbers 1 to 0 on the keyboard
#	holding shift and using the arrow keys
#	using the mouse scroll wheel
#	clicking directly on the item

extends Control

#for hiding the hotbar only when the player is not moving or performing an animation
onready var Player = get_parent().get_parent()

#for telling the inventory what item to equip
onready var Inventory = get_parent().get_node("Inventory")

#for disabling the Hotbar when the shop menu is open
onready var ShopMenu = get_node("/root/Game/Menus/Shop Menu")

#for moving the indicator for the currently equipped item
onready var Indicator = get_node("Equipped Item Indicator")
#the item slot the indicator is currently over, starting with the first slot
var IndicatorSlot = 1
#the initial position of the equipped item
const IndicatorBasePosition = Vector2(50,50)

#the number of pixels the indicator must offset between each item
const HotbarItemSeparation = 111

#a dictionary for holding all [textures, labels] on the hotbar
var textures_and_labels = {}

#a dictionary for holding all [textures, labels] in the last inventory row
var inventory_textures_and_labels = {}

#initializes an array containing all the textures of the buttons on the hotbar
func _ready():
	#get all the hotbar slot textures
	for button in get_node("Hotbar Grid Container").get_children():
		#disable the button's ability to grab focus and accept keyboard input
		#though this is set in the editor, it appears to be a glitch and must be done manually
		button.set_focus_mode(0)
		var texture_and_label = button.get_children()
		textures_and_labels[texture_and_label[0]] = texture_and_label[1]
	
	#get all the textures of the slots in the last inventory row
	for button in get_parent().get_node("Inventory/Hotbar Grid Container").get_children():
		var texture_and_label = button.get_children()
		inventory_textures_and_labels[texture_and_label[0]] = texture_and_label[1]

#ensures the hotbar is visible and mirroring the inventory when being forced to sleep
#note that the Inventory must process this call first, so this class is called
#directly from the Inventory class
func force_sleep():
	visible = true
	mirror_inventory()
	_equip() #equip whatever item was selected in the inventory

func _input(event):
	#show or hide the hotbar only when the player is not moving or performing an animation, the player is not dragging an item, and the shop menu is not open
	if Input.is_action_pressed("Tab") and Player.speed == 0 and not Player.animationCommit and not Inventory.DraggedItem.visible and not ShopMenu.visible:
		if visible:
			visible = false
		else:
			visible = true
			mirror_inventory()
			_equip() #equip whatever item was selected in the inventory
	
	#if the player presses escape and the inventory is opened (meaning the hotbar is hidden), show the hotbar again
	elif Input.is_action_pressed("pause") and not visible and not Inventory.DraggedItem.visible:
		visible = true
	#move the indicator and change the equipped item. The inventory must not be open
	elif visible and (Input.is_action_pressed("shift_left_arrow") or Input.is_action_pressed("scroll_down")):
		if IndicatorSlot == 1:
			IndicatorSlot = 10
		else:
			IndicatorSlot -= 1
		_move_indicator()
		_equip()
	elif visible and (Input.is_action_pressed("shift_right_arrow") or Input.is_action_pressed("scroll_up")):
		if IndicatorSlot == 10:
			IndicatorSlot = 1
		else:
			IndicatorSlot += 1
		_move_indicator()
		_equip()

#equips the item that is in the slot the hotbar was clicked on
func _button_pressed(number):
	IndicatorSlot = number
	_move_indicator()
	_equip()

#moves the equipped item indicator to the IndicatorSlot
#the position is a multiple of the pixel distance between items on the hotbar
func _move_indicator():
	Indicator.rect_position = Vector2(IndicatorBasePosition.x + ((IndicatorSlot-1) * HotbarItemSeparation), IndicatorBasePosition.y)
	
	#to avoid a visual glitch where the square is not large enough to fill the outline of the item slot
	#in the third slot, increase the scale and shift it over slightly
	if IndicatorSlot == 3:
		Indicator.rect_scale = Vector2(1.01, 1.01)
		var currentPosition = Indicator.rect_position
		Indicator.rect_position = Vector2(currentPosition.x-1, currentPosition.y)
	else:
		Indicator.rect_scale = Vector2(1,1)

#equips the item selected on the hotbar based upon the position of the indicator slot
#the name of the texture in this item slot is sent to the inventory
#script to equip this item
func _equip():
	var itemToEquip
	var currentTexture = textures_and_labels.keys()[IndicatorSlot-1].get_texture()
	
	if currentTexture != null:
		var textureNameCutoff = currentTexture.get_load_path().get_file().find(".")
		itemToEquip = currentTexture.get_load_path().get_file().substr(0, textureNameCutoff)
	else:
		itemToEquip = "None"
	
	Inventory.equip(itemToEquip)

#makes the hotbar mirror the last row of the inventory
func mirror_inventory():
	for i in range(10):
		textures_and_labels.keys()[i].set_texture(inventory_textures_and_labels.keys()[i].get_texture())
		textures_and_labels.values()[i].set_text(inventory_textures_and_labels.values()[i].get_text())