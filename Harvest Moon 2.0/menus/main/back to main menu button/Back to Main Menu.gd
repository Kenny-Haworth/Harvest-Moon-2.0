extends Control

func _on_Button_pressed():
	get_node("/root/MainMenu/Buttons").visible = true #show the main menu buttons
	get_parent().visible = false #hide the current menu
	
	#set focus on the last clicked-on button
	if get_parent().name == "Load Game":
		get_node("/root/MainMenu/Buttons/Load Game").grab_focus()
	elif get_parent().name == "Controls":
		get_node("/root/MainMenu/Buttons/Controls").grab_focus()
	elif get_parent().name == "Graphics":
		get_node("/root/MainMenu/Buttons/Graphics").grab_focus()