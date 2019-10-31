#TODO overlap seed sounds when adding power moves in (1x1, 3x1, 3x3)

extends Node2D

#for pausing the game - holds [paused node, playback position]
var sound_dictionary = {}

#plays the requested sound effect
func play_effect(sound_to_play):
	for effect in $Effects.get_children():
		if effect.name == sound_to_play:
			effect.play()

#plays the requested music track
func play_music(sound_to_play):
	for music in $Music.get_children():
		if music.name == sound_to_play:
			music.play()

#plays the requested tool sound
func play_tool(sound_to_play):
	for tool_sound in $Tools.get_children():
		if tool_sound.name == sound_to_play:
			tool_sound.play()

#stops the requested music track
func stop_music(sound_to_stop):
	for music in $Music.get_children():
		if music.name == sound_to_stop:
			music.stop()

#sets the requested music track to the requested decibel volume
func set_music_volume(sound_to_set, amount):
	for music in $Music.get_children():
		if music.name == sound_to_set:
			music.volume_db = amount

#returns true if the sound is currently playing, and false otherwise
#checks all sounds
#TODO this shouldn't be called often at all. Throw in a statement that will crash, then backtrace each piece of code that calls this
#TODO most code should not rely on this logic for game events - think about it this way, if the sound effect were changed to be longer
#TODO or shorter, would the code still work? If not, it needs to be changed
func is_playing(sound_to_check):
	for node in self.get_children():
		var sounds = node.get_children()
		for sound in sounds:
			if sound.name == sound_to_check:
				if sound.playing:
					return true
				else:
					return false

#pauses all sounds
func pause_all_sounds():
	#loop through all sounds. Save any audio players currently playing as well as their playback position,
	#so audio can resume when the game is unpaused
	for node in self.get_children():
		for sound in node.get_children():
			if sound.playing:
				sound_dictionary[sound] = sound.get_playback_position()
				sound.stop()

#resumes all sounds from where they left off
func resume_all_sounds():
	for sound_player in sound_dictionary.keys():
		var playback_position = sound_dictionary[sound_player]
		sound_player.play(playback_position)
	
	sound_dictionary.clear()