extends Control

func _on_Button_pressed():
	get_parent().visible = false #hide the new save menu
	get_parent().get_parent().get_node("Save Menu").visible = true #show the save menu
	get_parent().get_parent().get_node("Save Menu/Save Options/New Save").grab_focus()