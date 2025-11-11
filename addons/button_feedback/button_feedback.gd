# ####################################################################################
# ##                      This file is part of Button Feedback.                     ##
# ##              https://github.com/ProgrammerOnCoffee/Button-Feedback             ##
# ####################################################################################
# ## Copyright (c) 2025 ProgrammerOnCoffee.                                         ##
# ##                                                                                ##
# ## Permission is hereby granted, free of charge, to any person obtaining a copy   ##
# ## of this software and associated documentation files (the "Software"), to deal  ##
# ## in the Software without restriction, including without limitation the rights   ##
# ## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      ##
# ## copies of the Software, and to permit persons to whom the Software is          ##
# ## furnished to do so, subject to the following conditions:                       ##
# ##                                                                                ##
# ## The above copyright notice and this permission notice shall be included in all ##
# ## copies or substantial portions of the Software.                                ##
# ##                                                                                ##
# ## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     ##
# ## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       ##
# ## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    ##
# ## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         ##
# ## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  ##
# ## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  ##
# ## SOFTWARE.                                                                      ##
# ####################################################################################

@icon("res://addons/button_feedback/icon.svg")
extends Node
## Provides audiovisual feedback when players interact with buttons.
##
## Provides audiovisual feedback when players interact with buttons.

## The volume of button sounds in decibels.
## Note that the hover sound will have [code]6.0[/code] dB subtracted from this number.
const VOLUME_DB: float = -6.0
## The target audio bus of button sounds.
const AUDIO_BUS: StringName = &""
## The pitch scale of button sounds.
const PITCH_SCALE: float = 2.0
## The amount that buttons will be scaled by when hovered.
const HOVER_SCALE: float = 1.1
## The duration of the tween that scales buttons when they are hovered.
const HOVER_SCALE_DURATION: float = 0.05

# [AudioStreamPlayer2D]s are used because of a bug where pitch_scale
# doesn't work on web exports for regular [AudioStreamPlayer]s.
## The [AudioStreamPlayer2D] that plays the button hover sound.
var button_hover_player := AudioStreamPlayer2D.new()
## The [AudioStreamPlayer2D] that plays the button down sound.
var button_down_player := AudioStreamPlayer2D.new()
## The [AudioStreamPlayer2D] that plays the button pressed sound.
var button_pressed_player := AudioStreamPlayer2D.new()

## The [StyleBoxEmpty] that will be set as the focus theme override for clicked
## buttons.[br]
## The default stylebox will be shown if the focus is not from a click
## (e.g. when navigating with a keyboard.)
var _stylebox_empty := StyleBoxEmpty.new()


func _init() -> void:
	button_hover_player.stream = load("res://addons/button_feedback/button_hover.wav") as AudioStreamWAV
	button_hover_player.volume_db = VOLUME_DB - 6.0
	button_down_player.stream = load("res://addons/button_feedback/button_down.wav") as AudioStreamWAV
	button_down_player.volume_db = VOLUME_DB
	button_pressed_player.stream = load("res://addons/button_feedback/button_pressed.wav") as AudioStreamWAV
	button_pressed_player.volume_db = VOLUME_DB


func _ready() -> void:
	for player in [button_hover_player, button_down_player, button_pressed_player] as Array[AudioStreamPlayer2D]:
		player.bus = AUDIO_BUS
		player.pitch_scale = PITCH_SCALE
		player.attenuation = 0.0
		player.max_distance = INF
		player.panning_strength = 0.0
		player.process_mode = PROCESS_MODE_ALWAYS
	
	setup_recursive(get_parent())
	
	add_child(button_hover_player)
	add_child(button_down_player)
	add_child(button_pressed_player)


## Calls [member setup_button] for all [BaseButton]s
## that [param ancestor] is an ancestor of.
func setup_recursive(ancestor: Node) -> void:
	var queue := ancestor.get_children()
	while queue:
		var new_queue: Array[Node] = []
		for node in queue:
			var button := node as BaseButton
			if button:
				setup_button(button)
			new_queue.append_array(node.get_children())
		queue = new_queue


## Sets up audiovisual feedback for [param button].
func setup_button(button: BaseButton) -> void:
	# Return if feedback for button has already been set up
	if button.button_down.is_connected(button_down_player.play):
		return
	
	button.focus_entered.connect(_on_button_focus_entered.bind(button), CONNECT_DEFERRED)
	button.focus_exited.connect(button.remove_theme_stylebox_override.bind(&"focus"))
	button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	button.button_down.connect(button_down_player.play)
	# is_class() won't error if the advanced gui module is disabled
	if not button.is_class("OptionButton"):
		button.pressed.connect(button_pressed_player.play)


func _on_button_focus_entered(button: BaseButton) -> void:
	# Remove focus stylebox if focus is from a click
	if button.button_pressed:
		button.add_theme_stylebox_override(&"focus", _stylebox_empty)


func _on_button_mouse_entered(button: BaseButton) -> void:
	if button.disabled or not button.can_process():
		return
	
	button_hover_player.play()
	# Set pivot offset so that button scales from center
	button.pivot_offset = button.size / 2
	# Kill tween if one is already running
	if button.has_meta(&"_button_feedback_scale_tween"):
		button.get_meta(&"_button_feedback_scale_tween").kill()
	var tween := button.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, ^":scale", Vector2.ONE * HOVER_SCALE,
			# Tween for less time if button is already partially scaled
			remap(button.scale.x, 1.0, HOVER_SCALE, HOVER_SCALE_DURATION, 0.0))
	button.set_meta(&"_button_feedback_scale_tween", tween)


func _on_button_mouse_exited(button: BaseButton) -> void:
	# Kill tween if one is already running
	if button.has_meta(&"_button_feedback_scale_tween"):
		button.get_meta(&"_button_feedback_scale_tween").kill()
	var tween := button.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, ^":scale", Vector2.ONE,
			# Tween for less time if button isn't fully scaled
			remap(button.scale.x, HOVER_SCALE, 1.0, HOVER_SCALE_DURATION, 0.0))
	button.set_meta(&"_button_feedback_scale_tween", tween)
