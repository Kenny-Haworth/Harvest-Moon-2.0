extends Control

func _on_Resolution_Drop_Down_item_selected(ID):
	if ID == 0:
		OS.set_window_size(Vector2(800,600))
	elif ID == 1:
		OS.set_window_size(Vector2(1024,576))
	elif ID == 2:
		OS.set_window_size(Vector2(1280,800))
	elif ID == 3:
		OS.set_window_size(Vector2(1366,768))
	elif ID == 4:
		OS.set_window_size(Vector2(1920,1080))
	elif ID == 5:
		OS.set_window_size(Vector2(3840,2160))

func _on_Window_Drop_Down_item_selected(ID):
	if ID == 0:
		OS.window_fullscreen = false
		OS.window_borderless = false
	elif ID == 1:
		OS.window_fullscreen = true
		OS.window_borderless = true
	elif ID == 2:
		OS.window_fullscreen = true
		OS.window_borderless = false