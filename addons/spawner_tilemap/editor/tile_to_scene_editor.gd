tool
extends WindowDialog

## Dialog that appears when the user presses "Edit Scenes" in a SpawnerTileMap
## It facilitates the process of matching a tile inside a TileMap with a PackedScene using an specialised GUI

# DEPENDENCIES

var tile_to_scene_row: PackedScene = preload("res://addons/spawner_tilemap/editor/tile_to_scene_row.tscn")
var scene_settings: GDScript = preload("res://addons/spawner_tilemap/node/scene_settings.gd")
var editor_interface: EditorInterface
var spawner_tilemap: SpawnerTileMap
var undo_redo: UndoRedo

# CHILD NODES

onready var main_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MainContainer
onready var clean_button: Button = $MarginContainer/VBoxContainer/SearchButtons/ClearButton
onready var search_button: Button = $MarginContainer/VBoxContainer/SearchButtons/SearchButton
onready var search_bar: LineEdit = $MarginContainer/VBoxContainer/SearchBar

# METHODS

## Updates the icons for each button and add the rows that show information from the [tile_to_scene_dictionary]
func _ready() -> void:
	spawner_tilemap = editor_interface.get_selection().get_selected_nodes()[0]
	# Setting icons for search buttons
	var main_control = editor_interface.get_base_control()
	search_button.icon = main_control.get_icon("Search","EditorIcons")
	clean_button.icon = main_control.get_icon("Clear","EditorIcons")
	# Removing connections with signals
	main_container.connect("child_exiting_tree",self,"_on_child_exited_in_main_container")
	update_rows()

## Removes the signals still connected before destroying the editor
func _notification(what: int):
	if what == NOTIFICATION_EXIT_TREE:
		main_container.disconnect("child_exiting_tree",self,"_on_child_exited_in_main_container")

## Adds a row to the main container, which contains the image of the tile, the name of the scene and a PackedScene resource picker
func add_row(texture: Texture, region: Rect2, tile_id: int, dict_id: String, scene: PackedScene, tile_mode: int):
	var row = tile_to_scene_row.instance()
	var _atlas_texture: AtlasTexture  = AtlasTexture.new()
	_atlas_texture.atlas = texture
	_atlas_texture.region = region
	# Setting the new values to the row
	main_container.add_child(row)
	row.set_tilemode(tile_mode)
	row.set_texture(_atlas_texture)
	row.set_id(tile_id, dict_id)
	row.scene_resource_picker.edited_resource = scene
	row.scene_resource_picker.undo_redo = undo_redo
	row.scene_settings_button.icon = editor_interface.get_base_control().get_icon("TripleBar","EditorIcons")
	row.connect("scene_settings_pressed",self,"on_scene_settings_pressed")
	row.scene_resource_picker.connect("show_in_filesystem_selected",self,"queue_free")
	row.connect("row_changed",self,"_on_row_changed")

## Shows all the information inside the [tile_to_scene_dictionary] stored by the SpawnTileMap using rows that are created by [add_row]
func update_rows():
	var tile_set: TileSet = spawner_tilemap.tile_set
	if tile_set:
		var tile_to_scene_dictionary = spawner_tilemap.tile_to_scene_dictionary
		var _tile_mode: int
		var _scene_data: Array
		var _texture: Texture
		var _region: Rect2
		for tile_id in tile_set.get_tiles_ids():
			_tile_mode = spawner_tilemap.tile_set.tile_get_tile_mode(tile_id)
			_texture = tile_set.tile_get_texture(tile_id)
			_region = tile_set.tile_get_region(tile_id)
			if _tile_mode == TileSet.AUTO_TILE or _tile_mode == TileSet.ATLAS_TILE:
				var _subtile_size: Vector2 = tile_set.autotile_get_size(tile_id)
				var icount: int = _region.size.x/_subtile_size.x
				var dict_id: String
				for j in _region.size.y/_subtile_size.y:
					for i in icount:
						dict_id = "%d-%d-%d"%[tile_id,i,j]
						_scene_data = tile_to_scene_dictionary.dictionary.get(dict_id,[null,null])
						add_row(_texture,Rect2(i*_subtile_size.x,j*_subtile_size.y,_subtile_size.x,_subtile_size.y), tile_id, dict_id,_scene_data[0],_tile_mode)
			else:
				_scene_data = tile_to_scene_dictionary.dictionary.get(str(tile_id),[null,null])
				add_row(_texture, _region, tile_id, str(tile_id), _scene_data[0], _tile_mode)

## Creates a custom resource to add data to each scene and to customize their spawning process
func on_scene_settings_pressed(_tile_id: int, _dict_id: String, _texture: Texture):
	var tile_to_scene_dictionary = spawner_tilemap.tile_to_scene_dictionary
	var _scene_data: Array = tile_to_scene_dictionary.dictionary.get(_dict_id,[null,null])
	var _scene_settings: Resource = _scene_data[1]
	if not _scene_settings:
		_scene_settings = scene_settings.new()
		_scene_settings.tile_mode = spawner_tilemap.tile_set.tile_get_tile_mode(_tile_id)
		_scene_settings.set_tile(_texture)
		_scene_data[1] = _scene_settings
		tile_to_scene_dictionary.dictionary[_dict_id] = _scene_data
	editor_interface.edit_resource(_scene_settings)
	queue_free()

## Updates the [tile_to_scene_dictionary] when an scene is changed inside a row
func _on_row_changed(_tile_id: int, _dict_id: String, _scene: PackedScene) -> void:
	var _dictionary: Dictionary = spawner_tilemap.tile_to_scene_dictionary.dictionary
	var _scene_data: Array = _dictionary.get(_dict_id,[null,null])
	var _new_scene_data: Array = [_scene, _scene_data[1]]
	if not (_new_scene_data[0] or _new_scene_data[1]):
		_dictionary.erase(_dict_id)
		return
	_dictionary[_dict_id] = _new_scene_data

## Filters the rows based on the tile id and the name of the scene
func _on_SearchButton_pressed() -> void:
	for row in main_container.get_children():
		var search_text: String = "*" +search_bar.text + "*"
		if not (row.scene_path.get_file().matchn(search_text) or str(row.tile_id).matchn(search_text)):
			row.hide()
		else:
			row.show()

## Cleans the text in the search bar
func _on_ClearButton_pressed() -> void:
	search_bar.text = ""
	for row in main_container.get_children():
		row.show()

## Calls the search function when the users presses the ENTER KEY
func _unhandled_key_input(event: InputEventKey) -> void:
	if search_bar:
		if search_bar.has_focus():
			if event.scancode == KEY_ENTER:
				_on_SearchButton_pressed()

## Removes the conection between [row_changed] and every row added to the main container
func _on_child_exited_in_main_container(node: Node):
	if node.has_signal("row_changed") and node.is_connected("row_changed",self,"_on_row_changed"):
		node.disconnect("row_changed",self,"_on_row_changed")
		node.disconnect("scene_settings_pressed",self,"on_scene_settings_pressed")

func _on_WindowDialog_popup_hide():
	queue_free()
