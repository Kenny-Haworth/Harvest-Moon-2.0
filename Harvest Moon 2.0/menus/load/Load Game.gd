extends Control

#for adding preset buttons
var button = preload("res://menus/load/Load Save Button.tscn")

#for positioning the buttons on the center of the screen
onready var Saves = get_node("Saves")

#for adding dynamic buttons for loading saves
onready var Buttons = get_node("Saves/Buttons")

#generates a button for each save file to load
#if there are too many save files to display on the screen at one time,
#they are stored in a list that can be scrolled through
func list_saves():
	#remove any previously generated buttons
	for child in Buttons.get_children():
		child.free()
	
	var dir = Directory.new()
	dir.open("user://")
	dir.list_dir_begin(true)
	
	var index = 0
	
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		else:
			var instanced_button = button.instance()
			instanced_button.set_text(file_name.substr(0, file_name.length()-4))
			instanced_button.connect("pressed", self, "_on_button_pressed", [index])
			Buttons.add_child(instanced_button)
			index+=1
	
	dir.list_dir_end()
	
	var num_buttons = Buttons.get_children().size()
	
	#TODO if there are no buttons, display an error saying the user has no saves
	#and set the focus on the back to main menu button
	if num_buttons == 0:
		var instanced_button = button.instance()
		instanced_button.set_text("You currently have no saves")
		Buttons.add_child(instanced_button)
		
		#manually set the offset, grab focus on the back to main menu button, and return
		Saves.rect_size = Vector2(202, 32)
		Saves.rect_position = Vector2(380, 336)
		get_node("Back to Main Menu/Container/Button").grab_focus()
		return
	
	#center the saves node based on the number of buttons generated
	var buttons_length = Buttons.get_child(0).rect_size.x
	var buttons_height = (num_buttons*20) + ((num_buttons-1) * 4)
	
	Buttons.rect_size = Vector2(buttons_length, buttons_height)
	Saves.scroll_horizontal_enabled = false
	
	#no scroll bar is required
	if num_buttons <= 10:
		Saves.scroll_vertical_enabled = false
		Saves.rect_size = Vector2(buttons_length, buttons_height)
	else: #num_buttons > 10
		Saves.scroll_vertical_enabled = true
		Saves.rect_size = Vector2(buttons_length+12, 236)
	
	Saves.rect_position = Vector2((1366/2)-((Saves.rect_scale.x*Saves.rect_size.x)/2), (768/2) - ((Saves.rect_scale.y*Saves.rect_size.y)/2))

	#place the focus on the first button
	Buttons.get_child(0).grab_focus()

#load the save clicked on based upon the button's index
func _on_button_pressed(index):
	GameManager.load_game(Buttons.get_children()[index].get_text())
	GameManager.set_game_type("loaded") #sets the game type to a loaded game