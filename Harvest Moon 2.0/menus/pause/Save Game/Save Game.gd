extends Control

#so the script can return focus to the button that called it
var callingNode

#quits the game without savnig
func _on_Quit_without_Saving_pressed():
	quit_game()

#takes the user to the new save menu
func _on_New_Save_pressed():
	get_node("Save Menu").visible = false
	get_node("New Save Menu").visible = true
	get_node("New Save Menu/New Save").grab_focus()

#save the game, then quit
func _on_New_Save_text_entered(save_file):
	#ignore blank save names
	if save_file == "":
		return
	GameManager.save_game(save_file)
	quit_game()

#quits the game to either the main menu or the desktop
func quit_game():
	if callingNode == "Quit to Main Menu":
		get_tree().change_scene("res://menus/main/MainMenu.tscn") #switch scenes
		get_tree().paused = false #resume the scene
	else: #callingNode is Quit to Desktop
		get_tree().quit()

func _on_Overwrite_pressed():
	GameManager.save_game(GameManager.file_name)
	quit_game()