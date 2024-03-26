extends EditorInspectorPlugin

var manage_scenes_buttons: PackedScene = preload("res://addons/spawner_tilemap/spawner_tilemap_node/manage_scenes_buttons.tscn")
var tile_to_scene_editor: PackedScene = preload("res://addons/spawner_tilemap/tile_to_scene_editor/tile_to_scene_editor.tscn")
signal edit_scenes_pressed(window_dialog)

func can_handle(object: Object) -> bool:
	return object is SpawnerTileMap

func parse_property(object: Object, type: int, path: String, hint: int, hint_text: String, usage: int) -> bool:
	if path == "_spawn_scenes":
		var buttons : Control = manage_scenes_buttons.instance()
		buttons.get_node("EditScenesButton").connect("pressed",self,"open_popup")
		add_custom_control(buttons)
		return true
	return false

func open_popup():
	emit_signal("edit_scenes_pressed",tile_to_scene_editor.instance())
