extends CanvasLayer

onready var item = get_node("TextureRect")
onready var ItemList = get_node("ItemList")
var item2 = preload("res://player/hammer/hammerDown1.png")
var item3 = preload("res://player/seeds/seeds1.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	ItemList.max_columns = 9
	ItemList.fixed_icon_size = Vector2(32,32)
	ItemList.icon_mode = ItemList.ICON_MODE_TOP
	ItemList.select_mode = ItemList.SELECT_SINGLE
	ItemList.same_column_width = true
	ItemList.fixed_column_width = 50
	#add some items to item list to get it to work.
	ItemList.add_item("PLACEHOLDER",item2,true)
	ItemList.add_item("PLACEHOLDER2",item3,true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for i in range(0, ItemList.get_item_count ()):
		if ItemList.is_selected(i):
			item.set_texture(ItemList.get_item_icon(i))
