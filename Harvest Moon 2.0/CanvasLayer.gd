extends CanvasLayer

onready var item = get_node("TextureRect")
onready var ItemList = get_node("ItemList")


# Called when the node enters the scene tree for the first time.
func _ready():
	ItemList.max_columns = 9
	ItemList.fixed_icon_size = Vector2(32,32)
	ItemList.icon_mode = ItemList.ICON_MODE_TOP
	ItemList.select_mode = ItemList.SELECT_SINGLE
	ItemList.same_column_width = true
	
	#add some items to item list to get it to work.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if ItemList.is_anything_selected() == true:
		for i in ItemList.get_selected_items():
			if ItemList.is_selected(i):
				item.set_texture(ItemList.get_item_icon(i))
