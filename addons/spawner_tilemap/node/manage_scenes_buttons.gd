tool
extends MarginContainer

export (NodePath) var edit_scenes_button_path
export (NodePath) var clean_scenes_button_path
export (NodePath) var spawn_scenes_button_path
onready var edit_scenes_button: Button = get_node_or_null(edit_scenes_button_path)
onready var clean_scenes_button: Button = get_node_or_null(clean_scenes_button_path)
onready var spawn_scenes_button: Button = get_node_or_null(spawn_scenes_button_path)


func enable_clean_button():
	clean_scenes_button.disabled=false
	clean_scenes_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func disable_clean_button():
	clean_scenes_button.disabled=true
	clean_scenes_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
