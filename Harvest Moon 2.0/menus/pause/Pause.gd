extends Control

#for getting the player position to position the pause menu properly
onready var Game = get_node("/root/Game")

#for stopping and playing sounds when the game is paused
onready var SoundManager = get_node("/root/Game/Sound")

func _input(event):
	if event.is_action_pressed("pause"):
		
		#the pause menu is already up, resume the game
		if visible:
			_resume_game()
			
		#the pause menu is not up and the inventory is not opened, pause the game
		elif visible == false and get_node("/root/Game").player.Inventory.visible == false:
			_pause_game()

func _on_Resume_pressed():
	_resume_game()

func _on_Controls_pressed():
	$Buttons.visible = false
	$Controls.visible = true
	get_node("Controls/Back to Pause Menu/Container/Button").grab_focus()

func _on_Quit_to_Main_Menu_pressed():
	$Buttons.visible = false
	get_node("Save Game/Save Menu").visible = true
	
	#hide or show the overwrite button depending on the game type
	if GameManager.game_type == "new":
		get_node("Save Game/Save Menu/Save Options/Overwrite").visible = false
		get_node("Save Game/Save Menu/Save Options/New Save").grab_focus()
		
		#center the buttons on the screen
		get_node("Save Game/Save Menu/Save Options").rect_position = Vector2(160, 113)
		
	else: #GameManager.game_type == "loaded"
		get_node("Save Game/Save Menu/Save Options/Overwrite").visible = true
		get_node("Save Game/Save Menu/Save Options/Overwrite").grab_focus()
		
		#center the buttons on the screen
		get_node("Save Game/Save Menu/Save Options").rect_position = Vector2(160, 101)
		
	get_node("Save Game").callingNode = "Quit to Main Menu" #set the calling node so the script knows what button to return to

func _on_Quit_to_Desktop_pressed():
	$Buttons.visible = false
	get_node("Save Game/Save Menu").visible = true
	
	#hide or show the overwrite button depending on the game type
	if GameManager.game_type == "new":
		get_node("Save Game/Save Menu/Save Options/Overwrite").visible = false
		get_node("Save Game/Save Menu/Save Options/New Save").grab_focus()
		
		#center the buttons on the screen
		get_node("Save Game/Save Menu/Save Options").rect_position = Vector2(160, 113)
		
	else: #GameManager.game_type == "loaded"
		get_node("Save Game/Save Menu/Save Options/Overwrite").visible = true
		get_node("Save Game/Save Menu/Save Options/Overwrite").grab_focus()
		
		#center the buttons on the screen
		get_node("Save Game/Save Menu/Save Options").rect_position = Vector2(160, 101)
	
	get_node("Save Game").callingNode = "Quit to Desktop" #set the calling node so the script knows what button to return to

func _resume_game():
	get_tree().paused = false #resume the game
	visible = false #make the pause menu invisible
	SoundManager.resume_all_sounds()

func _pause_game():
	get_tree().paused = true #pause the game
	#set the pause menu directly over the player
	rect_position = Vector2(Game.player.position.x - rect_size.x/2, Game.player.position.y - rect_size.y/2) + Game.player_location.position
	$Buttons/Resume.grab_focus() #enable keyboard controls
	visible = true #make the pause menu visible
	SoundManager.pause_all_sounds()