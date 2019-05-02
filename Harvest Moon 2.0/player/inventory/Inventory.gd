extends Panel

onready var itemList = get_node("ItemList")
var inventoryOpen = false
var activeItem = 0

func _ready():
	set_process_unhandled_key_input(true)
	set_physics_process(true)
	itemList.connect("item_activated", self, "on_ItemList_item_activated")
	itemList.set_max_columns(10)
	itemList.set_fixed_icon_size(Vector2(24,24))
	itemList.set_icon_mode(ItemList.ICON_MODE_TOP)
	itemList.set_select_mode(ItemList.SELECT_SINGLE)
	itemList.set_same_column_width(true)
	
	add_to_list("res://player/inventory/Inventory_Scythe.png")
	itemList.set_item_metadata(0, "Scythe")
	add_to_list("res://player/inventory/Inventory_Hoe.png")
	add_to_list("res://player/inventory/Inventory_Hammer.png")
	add_to_list("res://player/inventory/Inventory_Axe.png")
	add_to_list("res://player/inventory/Inventory_Water.png")
	add_to_list("res://player/inventory/Inventory_TurnipSeeds.png")
	add_to_list("res://player/inventory/Inventory_Strawberry.png")
	#add_to_list("res://player/inventory/Inventory_Pineapple.png")
	#add_to_list("res://player/inventory/Inventory_Orange.png")
	add_to_list("res://player/inventory/Inventory_Eggplant.png")
	
	itemList.select(0, true)

func _physics_process(delta):
	if !inventoryOpen:
		set_process(false)
		hide()

func on_ItemList_item_activated(index):
	#print(itemList.get_item_metadata(index))
	activeItem = index

func _input(event):
	#open the inventory if it is closed
	if Input.is_action_pressed("I") and not inventoryOpen:
		inventoryOpen = true
	#close the inventory if an item is chosen
	elif Input.is_action_pressed("ui_accept") and inventoryOpen:
		inventoryOpen = false

func _get_activeItem():
	return activeItem

func _open_inventory():
	show()
	itemList.grab_focus()
	set_process(true)
	inventoryOpen = true

func add_to_list(image):
	var icon = ResourceLoader.load(image)
	itemList.add_item("", icon, true)