extends Node2D

onready var Game = get_node("/root/Game")
onready var TweenMorningOut = $Morning/TweenMorningOut
onready var TweenAfternoonIn = $Afternoon/TweenAfternoonIn
onready var TweenAfternoonOut = $Afternoon/TweenAfternoonOut
onready var TweenEveningIn = $Evening/TweenEveningIn
onready var TweenEveningOut = $Evening/TweenEveningOut
onready var TweenNightIn = $Night/TweenNightIn

var tweenerDuration #the duration to fade in and out different times of day - morning, afternoon, evening, and night

const viewport_size = Vector2(480, 270) #based on camera, 1366x768 * .35 zoom

#for the first day of the game, morning has to be manually called to fade out
func _ready():
	set_process(true)
	fade_in_shader("afternoon")

#position the shaders directly over the player
func _process(delta):
	position = Vector2(Game.player.position.x - viewport_size.x/2, Game.player.position.y - viewport_size.y/2) + Game.player_location.position

#resets the tweeners for a new day and begins fading in the afternoon
func new_day():
	_reset_tweeners()
	fade_in_shader("afternoon")

#fades in tweeners based upon the time of day
func fade_in_shader(time):
	
	#only get the tweenerDuration once. It cannot be calculated in _ready(), as the timer node is readied after the Shaders node
	if tweenerDuration == null:
		#calculates the tweenerDuration based on the Timer node
		#shaders fade in and out in sets of 5 hours
		tweenerDuration = get_node("/root/Game/Farm/Player/UI/Dashboard/TimeManager/Time/Timer").wait_time * 300 #300 minutes is 5 hours, 5*60 = 300
	
	if time == "afternoon":
		TweenMorningOut.interpolate_property($Morning, "color", Color(0.79,0.79,0.32,.35), Color(0.79,0.79,0.32,0), tweenerDuration, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenMorningOut.start() #fade out the morning
		TweenAfternoonIn.interpolate_property($Afternoon, "color", Color(1,1,1,0), Color(1,1,1,0), tweenerDuration, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenAfternoonIn.start() #fade in the afternoon
	
	elif time == "evening":
		TweenAfternoonOut.interpolate_property($Afternoon, "color", Color(1,1,1,0), Color(1,1,1,0), tweenerDuration, Tween.TRANS_LINEAR, Tween.EASE_IN)
		TweenAfternoonOut.start() #fade out the afternoon
		TweenEveningIn.interpolate_property($Evening, "color", Color(1,.33,0,0), Color(1,.33,0,.25), tweenerDuration, Tween.TRANS_LINEAR, Tween.EASE_IN)
		TweenEveningIn.start() #fade in the evening
	
	elif time == "night":
		TweenEveningOut.interpolate_property($Evening, "color", Color(1,.33,0,.25), Color(1,.33,0,0), tweenerDuration, Tween.TRANS_LINEAR, Tween.EASE_IN)
		TweenEveningOut.start() #fade out the evening
		TweenNightIn.interpolate_property($Night, "color", Color(0.05,0.09,0.15,0), Color(0.05,0.09,0.15,.75), tweenerDuration, Tween.TRANS_LINEAR, Tween.EASE_IN)
		TweenNightIn.start() #fade in the night

#resets the tweeners for a new day
func _reset_tweeners():
	TweenMorningOut.stop_all()
	TweenAfternoonIn.stop_all()
	TweenAfternoonOut.stop_all()
	TweenEveningOut.stop_all()
	TweenEveningIn.stop_all()
	TweenNightIn.stop_all()
	
	#reset any shaders on the screen, setting the morning to full brightness
	$Morning.color = Color(0.79,0.79,0.32,.35)
	$Afternoon.color = Color(1,1,1,0)
	$Evening.color = Color(1,.33,0,0)
	$Night.color = Color(0.05,0.09,0.15,0)

#show shaders if they were hidden or hides them if they were shown (for indoor vs. outdoor settings)
func toggle_shaders():
	if visible:
		visible = false
	else:
		visible = true