extends EditorInspectorPlugin

# DEPENDENCIES

var manage_scenes_buttons: PackedScene = preload("res://addons/spawner_tilemap/node/manage_scenes_buttons.tscn")
var tile_to_scene_editor: PackedScene = preload("res://addons/spawner_tilemap/editor/tile_to_scene_editor.tscn")
var editor_interface: EditorInterface
var undo_redo: UndoRedo
var buttons: Control
var edit_scenes_button: Button
var clean_scenes_button: Button
var spawn_scenes_button: Button

# METHODS

func can_handle(object: Object) -> bool:
	return object is SpawnerTileMap

func parse_property(object: Object, type: int, path: String, hint: int, hint_text: String, usage: int) -> bool:
	var selected_nodes: Array = editor_interface.get_selection().get_selected_nodes()
	if selected_nodes.size()>0 and path == "_manage_buttons":
		var spawner_tilemap: SpawnerTileMap = selected_nodes[0]
		buttons = manage_scenes_buttons.instance()
		buttons.connect("tree_exiting",self,"_on_buttons_removed")
		add_custom_control(buttons)
		edit_scenes_button = buttons.get_node(buttons.edit_scenes_button_path)
		clean_scenes_button = buttons.get_node(buttons.clean_scenes_button_path)
		spawn_scenes_button = buttons.get_node(buttons.spawn_scenes_button_path)
		# Customizing and connecting signals from manage scene buttons
		clean_scenes_button.icon = editor_interface.get_base_control().get_icon("Clear","EditorIcons")
		if not clean_scenes_button.is_connected("pressed",self,"_on_clean_scenes_pressed"):
			clean_scenes_button.connect("pressed",self,"_on_clean_scenes_pressed", [buttons, spawner_tilemap])
		edit_scenes_button.icon = editor_interface.get_base_control().get_icon("Edit","EditorIcons")
		if not edit_scenes_button.is_connected("pressed",self,"_show_tile_to_scene_editor"):
			edit_scenes_button.connect("pressed",self,"_show_tile_to_scene_editor", [spawner_tilemap])
		if not spawn_scenes_button.is_connected("pressed",self,"_on_spawn_scenes_pressed"):
			spawn_scenes_button.connect("pressed",self,"_on_spawn_scenes_pressed", [buttons, spawner_tilemap])
		return true
	return false

func _on_spawn_scenes_pressed(buttons, spawner_tilemap: SpawnerTileMap):
	var _state: Dictionary = spawner_tilemap._get_state()
	var _instanced_scenes: Array = spawner_tilemap.instance_scenes()
	undo_redo.create_action("Spawn scenes")
	undo_redo.add_do_method(spawner_tilemap, "_add_instanced_scenes", _instanced_scenes)
	for _scene in _instanced_scenes:
		undo_redo.add_do_reference(_scene)
	undo_redo.add_undo_method(spawner_tilemap, "clean_instanced_scenes", _instanced_scenes, false)
	undo_redo.add_undo_method(spawner_tilemap, "_restore_state", _state)
	undo_redo.commit_action()

func _on_clean_scenes_pressed(buttons, spawner_tilemap: SpawnerTileMap):
	var _instanced_scenes: Array = spawner_tilemap._get_instances_in_container_node()
	undo_redo.create_action("Delete instanced scenes")
	undo_redo.add_do_method(spawner_tilemap, "clean_instanced_scenes", _instanced_scenes, false)
	for _scene in _instanced_scenes:
		undo_redo.add_undo_reference(_scene)
	undo_redo.add_undo_method(spawner_tilemap, "_add_instanced_scenes", _instanced_scenes)
	undo_redo.commit_action()

func _show_tile_to_scene_editor(spawner_tilemap: SpawnerTileMap):
	var editor = tile_to_scene_editor.instance()
	editor.editor_interface = editor_interface
	editor.undo_redo = undo_redo
	editor.spawner_tilemap = spawner_tilemap
	editor_interface.get_base_control().add_child(editor)
	editor.popup_centered(editor.rect_min_size)
	editor.grab_focus()

func _on_buttons_removed():
	if clean_scenes_button and clean_scenes_button.is_connected("pressed",self,"_on_clean_scenes_pressed"):
		clean_scenes_button.disconnect("pressed",self,"_on_clean_scenes_pressed")
	if edit_scenes_button and edit_scenes_button.is_connected("pressed",self,"_show_tile_to_scene_editor"):
		edit_scenes_button.disconnect("pressed",self,"_show_tile_to_scene_editor")
	if spawn_scenes_button and spawn_scenes_button.is_connected("pressed",self,"_on_spawn_scenes_pressed"):
		spawn_scenes_button.disconnect("pressed",self,"_on_spawn_scenes_pressed")
	buttons.disconnect("tree_exiting",self,"_on_buttons_removed")
