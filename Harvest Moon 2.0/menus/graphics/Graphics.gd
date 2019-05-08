extends Control

func _on_Res_Drop_Down_item_selected(ID):
	if ID == 0:
		OS.set_window_size(Vector2(1280,800))
	if ID == 1:
		OS.set_window_size(Vector2(1024,576))
	if ID == 2:
		OS.set_window_size(Vector2(800,600))
	if ID == 3:
		OS.set_window_size(Vector2(1920,1080))
	if ID == 4:
		OS.set_window_size(Vector2(3840,2160))

func _on_Back_pressed():
	get_tree().change_scene("res://menus/main/MainMenu.tscn")