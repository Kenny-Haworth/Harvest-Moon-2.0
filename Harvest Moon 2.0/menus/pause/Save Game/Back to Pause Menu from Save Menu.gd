extends Control

func _on_Button_pressed():
	get_parent().visible = false #hide the currently shown menu
	get_parent().get_parent().get_parent().get_node("Buttons").visible = true #show the pause menu
	
	if get_parent().get_parent().callingNode == "Quit to Main Menu":
		get_parent().get_parent().get_parent().get_node("Buttons/Quit to Main Menu").grab_focus()
	else: #callingNode is Quit to Desktop
		get_parent().get_parent().get_parent().get_node("Buttons/Quit to Desktop").grab_focus()