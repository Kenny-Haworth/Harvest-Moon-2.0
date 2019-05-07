extends Panel

onready var itemList = get_node("ItemList")
onready var draggedItem = get_node("DraggedItem")
var inventoryOpen = false
var activeItem = 0
var equippedItem = 0
var equippedItemSlot = -1
var slot1 = 0 
var slot2 = 0
var moving = false
onready var isDraggingItem = false
onready var mouseButtonReleased = true
var draggedItemSlot = -1
onready var initial_mousePos = Vector2()
onready var cursor_insideItemList = true


func _ready():
	set_process_unhandled_key_input(true)
	set_physics_process(true)
	#itemList.connect("item_activated", self, "_on_ItemList_item_activated")
	itemList.connect("item_selected", self, "_on_ItemList_item_selected")
	itemList.set_max_columns(10)
	itemList.set_fixed_icon_size(Vector2(20,20))
	itemList.set_icon_mode(itemList.ICON_MODE_TOP)
	itemList.set_select_mode(itemList.SELECT_SINGLE)
	itemList.set_same_column_width(true)
	
	itemList.clear()
	
	PlayerInventory_Script.empty_data()
	
	PlayerInventory_Script.inventory_addItem(1)
	PlayerInventory_Script.inventory_addItem(2)
	PlayerInventory_Script.inventory_addItem(3)
	PlayerInventory_Script.inventory_addItem(4)
	PlayerInventory_Script.inventory_addItem(5)
	PlayerInventory_Script.inventory_addItems(6, 100)
	PlayerInventory_Script.inventory_addItems(7, 100)
	PlayerInventory_Script.inventory_addItems(8, 100)
	
	
	load_items()
	
	itemList.select(0, true)
	equipItem()
	

func _physics_process(delta):
	if !inventoryOpen:
		set_process(false)
		hide()

	if(isDraggingItem):
		draggedItem.global_position = get_viewport().get_mouse_position()
		
	
func _on_ItemList_item_selected(index):
	activeItem = index

func _input(event):
	if Input.is_action_pressed("S") and inventoryOpen and not moving:
		slot1 = activeItem
		moving = true
	elif Input.is_action_pressed("S") and inventoryOpen and moving:
		slot2 = activeItem
		if slot1 == equippedItemSlot:
			equippedItemSlot = slot2
		elif slot2 == equippedItemSlot:
			equippedItemSlot = slot1
			
		PlayerInventory_Script.inventory_moveItem(slot1, slot2)
		load_items()
		itemList.select(activeItem, true)
		moving = false 
		
	if Input.is_action_pressed("E") and inventoryOpen and not moving:
		if(activeItem >= 0):
			equipItem()
	
	#resets the inventory
#	if Input.is_action_pressed("R") and inventoryOpen and not moving:
#		reset_inventory()
#		activeItem = 0
	
	#drops an item
#	if Input.is_action_pressed("D") and inventoryOpen and not moving:
#		PlayerInventory_Script.inventory_removeItem(activeItem)
#		load_items()
#		itemList.select(activeItem)
#		if activeItem == equippedItemSlot:
#			equipItem()
			
	if Input.is_action_pressed("mouse_leftbtn") and inventoryOpen and not moving:
		mouseButtonReleased = false
		initial_mousePos = get_viewport().get_mouse_position()
		begin_drag_item(activeItem)
	
	if event.is_action_released("mouse_leftbtn") and inventoryOpen and moving:
		if draggedItemSlot >= 0 and activeItem >= 0:
			if draggedItemSlot == equippedItemSlot:
				equippedItemSlot = activeItem
			elif activeItem == equippedItemSlot:
				equippedItemSlot = draggedItemSlot
		
		move_item()
		end_drag_item()
		
	if event.is_action_released("mouse_rightbtn") and inventoryOpen and not moving:
		if(activeItem >= 0):
			equipItem()
			inventoryOpen = false
	
	if (event is InputEventMouseMotion):
		activeItem = itemList.get_item_at_position(itemList.get_local_mouse_position(), true)
		if(activeItem >= 0):
			itemList.select(activeItem, true)
		

		
	#open the inventory if it is closed
	if Input.is_action_pressed("Tab") and not inventoryOpen and not moving:
		inventoryOpen = true
	#close the inventory if an item is chosen
	if Input.is_action_pressed("E") and inventoryOpen and not moving:
		inventoryOpen = false
	if Input.is_action_pressed("Tab") and inventoryOpen and not moving:
		inventoryOpen = false

func load_items():
	itemList.clear()
	for slot in range(0, PlayerInventory_Script.maxSlots):
		itemList.add_item("", null, false)
		update(slot)

func update(slot):
	if (slot < 0):
			return
	var inventoryItem = PlayerInventory_Script.inventory[String(slot)]
	var itemData = Global_ItemData.get_item(inventoryItem["id"])
	var icon = ResourceLoader.load(itemData["icon"])
	var amount = int(inventoryItem["amount"])
	
	itemData["amount"] = amount
	if !itemData["stackable"]: amount = " "
	itemList.set_item_text(slot, String(amount))
	itemList.set_item_icon(slot, icon)
	itemList.set_item_selectable(slot, int(inventoryItem["id"]) >= 0)
	itemList.set_item_metadata(slot, itemData)
	itemList.set_item_tooltip(slot, itemData["name"])
	

func _get_activeItem():
	return activeItem

func _open_inventory():
	show()
	itemList.grab_focus()
	set_process(true)
	inventoryOpen = true

func add_to_list(image):
	var icon = ResourceLoader.load(image)
	itemList.add_item("1", icon, true)

func equipItem():
	var inventoryItem = PlayerInventory_Script.inventory[String(activeItem)]
	equippedItem = inventoryItem["id"]
	equippedItemSlot = activeItem
	
func move_item():
	if(draggedItemSlot < 0):
		return
	if(activeItem < 0):
		update(draggedItemSlot)
		return
	if(activeItem == draggedItemSlot):
		update(draggedItemSlot)
	else:
		PlayerInventory_Script.inventory_moveItem(draggedItemSlot, activeItem)
		update(draggedItemSlot)
		update(activeItem)
	
func begin_drag_item(index):
	if (isDraggingItem):
		return
	if (index < 0):
		return
		
	set_process(true)
	#draggedItem.texture = itemList.get_item_icon(index)
	#draggedItem.show()
	
	itemList.set_item_text(index, " ")
	itemList.set_item_icon(index, ResourceLoader.load(Global_ItemData.get_item("0")["icon"]))
	
	draggedItemSlot = index
	isDraggingItem = true
	moving = true
	mouseButtonReleased = false
	draggedItem.global_translate(get_viewport().get_mouse_position())
	
func end_drag_item():
	set_process(false)
	draggedItemSlot = -1
	#draggedItem.hide()
	mouseButtonReleased = true
	isDraggingItem = false
	moving = false
	load_items()

