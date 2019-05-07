extends Node

onready var itemData = Global_Parser.load_data("res://inventory/Data_Items.json")
	
	
func get_item(id):
	
	itemData[(id)]["id"] = (id)
	
	return itemData[(id)] 
	