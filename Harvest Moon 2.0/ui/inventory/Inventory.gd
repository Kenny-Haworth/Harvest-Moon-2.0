#the inventory is responsible for the following:
#	adding items to the inventory
#	removing items from the inventory
#	equipping items
#	telling other scripts what the equipped item is
#	updating item stacks
#	moving items around in the inventory through the following methods:
#		drag and drop items
#		shift-clicking items

extends Control

#for opening the inventory only when the player is not moving or performing an animation
onready var Player = get_parent().get_parent()

#for showing the item the player is dragging
onready var DraggedItem = get_node("Dragged Item")
onready var DraggedItemLabel = get_node("Dragged Item/Dragged Item Label")

#for showing what slot is currently equipped
onready var Indicator = get_node("Equipped Item Indicator")
#the item slot the indicator is currently over, starting with the first slot
var IndicatorSlot = 1
#the initial position of the equipped item
const IndicatorBasePosition = Vector2(50,394)

#the number of pixels the indicator must offset between each item
const InventoryItemSeparation = 111

#for telling the hotbar to mirror the inventory when a stackable item is added to the inventory
onready var Hotbar = get_parent().get_node("Hotbar")

#for mirroring the position and scale of the equipped item indicator on the hotbar
onready var HotbarIndicator = get_parent().get_node("Hotbar/Equipped Item Indicator")

#the offset of the first slot in the inventory
const InventoryOffset = Vector2(50,50)
#the size of the inventory slots
const SlotSize = Vector2(100,100)
#the size of the borders between inventory slots
const borderSize = Vector2(11,11)
#the exact size of the inventory
const InventoryBounds = Vector2(1099, 443)

#a dictionary for saving the [slot, label_text] when clicking and dragging to an invalid location or swapping items
var savedSlot = {}

#a dictionary for holding all [textures, labels] in the inventory
var textures_and_labels = {}

#a dictionary for holding all [stacked_items_in_inventory, number]
var stacked_items = {"StrawberrySeeds":9, "TurnipSeeds":9, "EggplantSeeds":9}
#an array to hold all items that can be stackable
const stackable_items = ["Strawberry", "Turnip", "Eggplant", "StrawberrySeeds", "TurnipSeeds", "EggplantSeeds"]

#for keeping track of the equipped item
var equippedItem = "Watering Can"

#initializes the physics process and gets an array of all texture nodes in the inventory
func _ready():
	set_physics_process(false)
	
	for button in get_node("Inventory Grid Container").get_children():
		var texture_and_label = button.get_children()
		textures_and_labels[texture_and_label[0]] = texture_and_label[1]
	
	for button in get_node("Hotbar Grid Container").get_children():
		var texture_and_label = button.get_children()
		textures_and_labels[texture_and_label[0]] = texture_and_label[1]

func _input(event):
	#show or hide the inventory when tab is pressed
	#show the inventory only when the player is not moving or performing an animation
	#do not hide the inventory if an item is being dragged
	if Input.is_action_pressed("Tab") and Player.speed == 0 and not Player.animationCommit and not DraggedItem.visible:
		if visible:
			visible = false
		else:
			visible = true
			#show the currently equipped item in the inventory
			Indicator.rect_position = Vector2(HotbarIndicator.rect_position.x, 394)
			Indicator.rect_scale = HotbarIndicator.rect_scale
	
	#if the player presses escape and the inventory is opened, and no item is being dragged, close it
	elif Input.is_action_pressed("pause") and visible and not DraggedItem.visible:
		visible = false

func _physics_process(delta):
	DraggedItem.rect_position = get_local_mouse_position() - InventoryOffset
	
	#the player has released their mouse click
	if not Input.is_action_pressed("left_click"):
		set_physics_process(false)
		
		#get the mouses position on the screen, with (0,0) centered on the corner of the first button
		var absolute_location = get_local_mouse_position() - InventoryOffset
		
		#the last bar in the y direction in the inventory is 11 pixels thicker than the other bars, so subtract an offset
		if absolute_location.y > 333:
			absolute_location.y -= 11
		
		#an algorithm to determine if the mouse is lying on one of the borders between inventory spaces
		#if this number is in the range of [1,11], the mouse is lying on a border
		var x_offset_location = (int(absolute_location.x) % 100) - ((int(absolute_location.x/100)-1)*11)
		var y_offset_location = (int(absolute_location.y) % 100) - ((int(absolute_location.y/100)-1)*11)
		
		#return the texture to it's original location if:
		#	the texture is outside the bounds of the inventory
		#	the texture is between a border in the x direction
		#	the texture is between a border in the y direction
		if absolute_location.x > InventoryBounds.x or absolute_location.y > InventoryBounds.y or absolute_location.x < 0 or absolute_location.y < 0 or (x_offset_location >= 1 and x_offset_location <= 11) or absolute_location.x == 0 or (y_offset_location >= 1 and y_offset_location <= 11) or absolute_location.y == 0:
			textures_and_labels.keys()[savedSlot-1].set_texture(DraggedItem.get_texture())
			textures_and_labels.values()[savedSlot-1].set_text(DraggedItemLabel.get_text())
		else: #move the texture to the new location, swapping it with another texture if one is already there
			var mouse_location = ((get_local_mouse_position() - InventoryOffset)/Vector2(111,111)).floor()
			var slot_location = mouse_location.x+1 + (mouse_location.y*10)
			var textures = textures_and_labels.keys() #get only the textures, saved in an array for efficiency
			var labels = textures_and_labels.values() #get the labels
			
			if textures[slot_location-1].get_texture() == null: #the spot is empty, just set the texture and label
				textures[slot_location-1].set_texture(DraggedItem.get_texture())
				labels[slot_location-1].set_text(DraggedItemLabel.get_text())
			else: #items must be swapped
				textures[savedSlot-1].set_texture(textures[slot_location-1].get_texture())
				labels[savedSlot-1].set_text(labels[slot_location-1].get_text())
				textures[slot_location-1].set_texture(DraggedItem.get_texture())
				labels[slot_location-1].set_text(DraggedItemLabel.get_text())
		
		DraggedItem.visible = false

#returns true if the given string is the currently equipped item
func is_equipped(item):
	return item == equippedItem

#returns true if the given item is in the inventory, false otherwise
func _contains(item):
	for texture_node in textures_and_labels.keys():
		var texture = texture_node.get_texture()
		
		if texture != null:
			var textureNameCutoff = texture.get_load_path().get_file().find(".")
			if item == texture.get_load_path().get_file().substr(0, textureNameCutoff):
				return true
	return false

#returns the number of the requested item in the inventory, for stackable items
func get_amount(item):
	if stacked_items.has(item):
		return stacked_items[item]
	else:
		return 0

#equips the requested item on the hotbar
func equip(item):
	equippedItem = item

#adds the requested item to the inventory
#if the item is already in the inventory and is stackable,
#it will be added to the existing amount
func add(item): #TODO amount=1 next default parameter for a shop
	#check if the item is stackable
	if stackable_items.has(item):
		if _contains(item): #if the inventory already has one of these items, update the label accordingly
			var number = stacked_items[item] #get the number of current items
			stacked_items.erase(item) #update the number of current items
			stacked_items[item] = number+1
			
			#set the label accordingly
			for texture_node in textures_and_labels.keys():
				var texture = texture_node.get_texture()
				
				if texture != null:
					var textureNameCutoff = texture.get_load_path().get_file().find(".")
					if item == texture.get_load_path().get_file().substr(0, textureNameCutoff):
						textures_and_labels[texture_node].set_text(str(number+1))
			
			Hotbar.mirror_inventory() #update the hotbar
		else: #this is the first of these items in the inventory
			stacked_items[item] = 1
			for texture in textures_and_labels.keys():
				if texture.get_texture() == null:
					texture.set_texture(load("res://ui/inventory/tools and items/" + item + ".png"))
					break
	else: #the item is not stackable, so add it to the first available slot in the inventory
		for texture in textures_and_labels.keys():
			if texture.get_texture() == null:
				texture.set_texture(load("res://ui/inventory/tools and items/" + item + ".png"))
				break

#removes the requested item from the inventory
#if the item is stackable, it will be subtracted from the count
#if the item is not stackable or there is only 1 in the stack,
#it will be removed from the inventory
#if the item is currently equipped, it will be unequipped
func remove(item): #TODO amount=1 next default parameter for a shop
	#check if the item is stacked
	if stacked_items.has(item):
		var number = stacked_items[item] #get the number of current items
		
		#subtract one from the item
		if number > 1:
			stacked_items.erase(item) #update the number of current items
			stacked_items[item] = number-1
			
			#set the label accordingly TODO generalize into a method, other parts of the code do this
			for texture_node in textures_and_labels.keys():
				var texture = texture_node.get_texture()
				
				if texture != null:
					var textureNameCutoff = texture.get_load_path().get_file().find(".")
					if item == texture.get_load_path().get_file().substr(0, textureNameCutoff):
						textures_and_labels[texture_node].set_text(str(number-1))
						Hotbar.mirror_inventory() #update the hotbar
						return
		
		#remove the item from the list of stacked items, then remove the item
		else:
			stacked_items.erase(item)

	#remove the item
	for texture_node in textures_and_labels.keys():
		var texture = texture_node.get_texture()
		
		if texture != null:
			var textureNameCutoff = texture.get_load_path().get_file().find(".")
			if item == texture.get_load_path().get_file().substr(0, textureNameCutoff):
				texture_node.set_texture(null)
				textures_and_labels[texture_node].set_text("")
				Hotbar.mirror_inventory() #update the hotbar
				break

#this function handles the following:
#	the drag and drop system
#		when a button is pressed, it is set to invisible and its texture
#		is copied onto the dragged item. When the item is released,
#		its texture will be copied onto the button it was released over.
#		do nothing if there is no item on the button pressed
#	the shift-click system
#		if shift was held when the player pressed the button, move the
#		inventory item into the first available slot in the hotbar, or
#		the hotbar item into the first available slot in the inventory.
#		do nothing if a slot is not available
func _on_button_pressed(number):
	var textures = textures_and_labels.keys() #get the textures in an array
	var labels = textures_and_labels.values() #get the labels in an array
	
	#the user was holding shift when they clicked the button
	if Input.is_action_pressed("shift"):
		#move the item to the first open hotbar location
		if number <= 30:
			for i in range (30, 40): #check all the hotbar locations
				if textures[i].get_texture() == null:
					textures[i].set_texture(textures[number-1].get_texture())
					labels[i].set_text(labels[number-1].get_text())
					textures[number-1].set_texture(null)
					labels[number-1].set_text("")
					break
		else: #move the item to the first open inventory location
			for i in range (30): #check all the inventory locations
				if textures[i].get_texture() == null:
					textures[i].set_texture(textures[number-1].get_texture())
					labels[i].set_text(labels[number-1].get_text())
					textures[number-1].set_texture(null)
					labels[number-1].set_text("")
					break
	#the user clicked a button with a texture on it
	elif textures[number-1] != null:
		savedSlot = number #save the current slot location
		
		DraggedItem.set_texture(textures[number-1].get_texture()) #copy the texture onto the dragged item
		DraggedItemLabel.set_text(labels[number-1].get_text())
		DraggedItem.visible = true
		
		textures[number-1].set_texture(null) #delete the item left in the slot
		labels[number-1].set_text("")
		
		set_physics_process(true)