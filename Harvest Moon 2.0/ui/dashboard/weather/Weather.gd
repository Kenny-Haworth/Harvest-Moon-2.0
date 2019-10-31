extends TextureRect

#for telling the farm to till soil when it rains
onready var Farm = get_node("/root/Game/Farm")

#for controlling weather sounds
onready var SoundManager = get_node("/root/Game/Sound")

#weather nodes
onready var Rain = get_parent().get_parent().get_parent().get_node("Rain")

var sunny = preload("res://ui/dashboard/weather/Sunny.png")
var cloudy = preload("res://ui/dashboard/weather/Cloudy.png") #TODO this is unused
var raining = preload("res://ui/dashboard/weather/Raining.png")
var night = preload("res://ui/dashboard/weather/Night.png")

#rolls for a chance of weather on a new day
func new_day():
	var rainChance = randi() % 4 + 1 #1-4
	if rainChance == 1: #25% chance of rain
		if not Rain.emitting: #if it is already raining, don't change anything. Otherwise toggle the rain
			Rain.set_one_shot(false)
			Rain.set_emitting(true)
			SoundManager.play_music("rain")
		Farm.simulate_rain() #water tilled squares for rain
		_set_weather("raining") #change the UI's shown weather
	else: #turns the rain off
		Rain.set_one_shot(true)
		SoundManager.stop_music("rain")
		_set_weather("sunny")

#changes the weather to night if it is not raining
func set_weather_to_night():
	if not Rain.emitting:
		_set_weather("night")

#show weather if it was hidden or hides it if it was shown (for indoor vs. outdoor settings)
func toggle_weather():
	if Rain.visible:
		Rain.visible = false
	else:
		Rain.visible = true

#sets the weather
func _set_weather(new_weather):
	if new_weather == "sunny":
		set_texture(sunny)
	elif new_weather == "cloudy":
		set_texture(cloudy)
	elif new_weather == "raining":
		set_texture(raining)
	elif new_weather == "night":
		set_texture(night)