extends Control

func _on_Button_pressed():
	var pauseNode = get_node("/root/Game/Farm/Player/Camera2D/Pause")
	pauseNode.visible = true
	visible = false