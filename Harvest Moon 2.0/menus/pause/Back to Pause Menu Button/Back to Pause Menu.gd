extends Control

func _on_Button_pressed():
	get_parent().visible = false #hide the currently shown menu
	get_parent().get_parent().get_node("Buttons").visible = true #show the pause menu
	
	#set focus on the last clicked-on button
	if get_parent().name == "Controls":
		get_parent().get_parent().get_node("Buttons/Controls").grab_focus()