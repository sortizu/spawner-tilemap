extends EditorInspectorPlugin

# -------------------------- DEPENDENCIES ---------------------------
var manage_scenes_buttons: PackedScene = preload("res://addons/spawner_tilemap/spawner_tilemap_node/manage_scenes_buttons.tscn")
var tile_to_scene_editor: PackedScene = preload("res://addons/spawner_tilemap/tile_to_scene_editor/tile_to_scene_editor.tscn")
var editor_interface: EditorInterface
var edit_scenes_button:Button
var clean_scenes_button:Button
var spawn_scenes_button:Button
var spawner_tilemap: SpawnerTileMap
	
func can_handle(object: Object) -> bool:
	return object is SpawnerTileMap

func parse_property(object: Object, type: int, path: String, hint: int, hint_text: String, usage: int) -> bool:
	if path == "_manage_buttons":
		spawner_tilemap = editor_interface.get_selection().get_selected_nodes()[0]
		var buttons = manage_scenes_buttons.instance()
		add_custom_control(buttons)
		edit_scenes_button = buttons.get_node_or_null(buttons.edit_scenes_button_path)
		clean_scenes_button = buttons.get_node_or_null(buttons.clean_scenes_button_path)
		spawn_scenes_button = buttons.get_node_or_null(buttons.spawn_scenes_button_path)
		# Customizing and connecting signals from manage scene buttons
		clean_scenes_button.icon = editor_interface.get_base_control().get_icon("Clear","EditorIcons")
		if not clean_scenes_button.is_connected("pressed",spawner_tilemap,"clean_instanced_scenes"):
			clean_scenes_button.connect("pressed",spawner_tilemap,"clean_instanced_scenes")
		edit_scenes_button.icon = editor_interface.get_base_control().get_icon("Edit","EditorIcons")
		if not edit_scenes_button.is_connected("pressed",self,"_show_tile_to_scene_editor"):
			edit_scenes_button.connect("pressed",self,"_show_tile_to_scene_editor")
		if not spawn_scenes_button.is_connected("pressed",spawner_tilemap,"instance_scenes_from_dictionary"):
			spawn_scenes_button.connect("pressed",spawner_tilemap,"instance_scenes_from_dictionary")
		# Connecting SpawnerTileMap signals
		if not spawner_tilemap.is_connected("scenes_instanced",self,"_on_scenes_instanced"):
			spawner_tilemap.connect("scenes_instanced",self,"_on_scenes_instanced")
		if not spawner_tilemap.is_connected("instanced_scenes_cleaned",self,"_on_instanced_scenes_cleaned"):
			spawner_tilemap.connect("instanced_scenes_cleaned",self,"_on_instanced_scenes_cleaned")
		_on_scenes_instanced()
		return true
	return false

func _on_instanced_scenes_cleaned():
	clean_scenes_button.disabled=true
	clean_scenes_button.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_scenes_instanced():
	if spawner_tilemap.container_node:
		if spawner_tilemap.container_node.get_children().size()>0:
			clean_scenes_button.disabled=false
			clean_scenes_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _show_tile_to_scene_editor():
	var editor = tile_to_scene_editor.instance()
	editor.editor_interface = editor_interface
	editor_interface.get_base_control().add_child(editor)
	editor.popup_centered(editor.rect_min_size)
	editor.grab_focus()
