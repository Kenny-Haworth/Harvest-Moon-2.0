extends Panel

func _ready():
	get_tree().paused = true

func _on_Close_pressed():
	visible = false
	get_tree().paused = false