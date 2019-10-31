extends Control

#grab focus on the start button for keyboard input
func _ready():
	get_node("Buttons/New Game").grab_focus()

func _on_New_Game_pressed():
	$Buttons.visible = false
	$Dialogue.visible = true
	get_node("Dialogue/To the game button").grab_focus()
	GameManager.set_game_type("new") #sets the game type to a new game

func _on_Load_Game_pressed():
	$Buttons.visible = false
	get_node("Load Game").visible = true
	get_node("Load Game").list_saves()

func _on_Controls_pressed():
	$Buttons.visible = false
	$Controls.visible = true
	get_node("Controls/Back to Main Menu/Container/Button").grab_focus()

func _on_Graphics_pressed():
	$Buttons.visible = false
	$Graphics.visible = true
	get_node("Graphics/Graphics Container/Resolution Container/Resolution Drop Down").grab_focus()

func _on_Quit_to_Desktop_pressed():
	get_tree().quit()