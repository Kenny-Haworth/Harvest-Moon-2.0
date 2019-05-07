extends Sprite

# To change the weather icon in player class use
# $UI/Date/Weather.set_weather("x")
# where x is cloudy, sunny, night, or raining
# example usage in player class
# $UI/Date/Weather.set_weather("night")

var cloud = preload("res://ui/weather/Cloudy.png")
var sun = preload("res://ui/weather/Sunny.png")
var night = preload("res://ui/weather/Night.png")
var raining = preload("res://ui/weather/Raining.png")
var cur

func _ready():
	cur = sun
	

func _process(delta):
	set_texture(cur)
	
func set_weather(w):
	if w == "cloudy":
		cur = cloud
	if w == "sunny":
		cur = sun
	if w == "night":
		cur = night
	if w == "raining":
		cur = raining
	
