extends Control

func _on_Button_pressed():
	var pauseNode = get_parent().get_node("Pause")
	pauseNode.visible = true
	visible = false