tool
extends WindowDialog

## Dialog that appears when the user presses "Edit Scenes" in a SpawnerTileMap
## It facilitates the process of matching a tile inside a TileMap with a PackedScene using a visual format and specialised UI elements

# DEPENDENCIES

var tile_to_scene_row: PackedScene = preload("res://addons/spawner_tilemap/editor/tile_to_scene_row.tscn")
var scene_meta: GDScript = preload("res://addons/spawner_tilemap/node/scene_meta.gd")
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
func add_row(texture:Texture,tile_region:Rect2,tile_id:int,scene:PackedScene):
	var row = tile_to_scene_row.instance()
	# Setting atlas texture to get an accurate previsualization of the tile
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = texture
	atlas_texture.region = tile_region
	# Setting the new values to the row
	main_container.add_child(row)
	row.set_texture(atlas_texture)
	row.set_id(tile_id)
	row.scene_resource_picker.edited_resource = scene
	row.scene_resource_picker.undo_redo = undo_redo
#	print(undo_redo,row.scene_resource_picker.undo_redo)
	row.edit_meta_button.icon = editor_interface.get_base_control().get_icon("Edit","EditorIcons")
	row.connect("edit_meta_pressed",self,"on_edit_meta_pressed")
	row.connect("row_changed",self,"_on_row_changed")

## Shows all the information inside the [tile_to_scene_dictionary] stored by the SpawnTileMap using rows that are created by [add_row]
func update_rows():
	var tile_set: TileSet = spawner_tilemap.tile_set
	var tile_to_scene_dictionary = spawner_tilemap.tile_to_scene_dictionary
	if tile_set:
		for tile_id in tile_set.get_tiles_ids():
			var _scene_data: Array = tile_to_scene_dictionary.dictionary.get(tile_id,[null,null])
			add_row(tile_set.tile_get_texture(tile_id),tile_set.tile_get_region(tile_id),tile_id,_scene_data[0])

func on_edit_meta_pressed(_tile_id: int):
	var tile_to_scene_dictionary = spawner_tilemap.tile_to_scene_dictionary
	var _scene_data: Array = tile_to_scene_dictionary.dictionary.get(_tile_id,[null,null])
	var _scene_meta: Resource = _scene_data[1]
	if not _scene_meta:
		_scene_meta = scene_meta.new()
		_scene_data[1] = _scene_meta
		tile_to_scene_dictionary.dictionary[_tile_id] = _scene_data
	#editor_interface.inspect_object(_scene_meta,"metadata")
	editor_interface.edit_resource(_scene_meta)
	queue_free()

## Updates the [tile_to_scene_dictionary] when an scene is changed inside a row
func _on_row_changed(_id: int, _scene: PackedScene) -> void:
	var _dictionary: Dictionary = spawner_tilemap.tile_to_scene_dictionary.dictionary
	var _scene_data: Array = _dictionary.get(_id,[null,null])
	var _new_scene_data: Array = [_scene, _scene_data[1]]
	if not (_new_scene_data[0] or _new_scene_data[1]):
		_dictionary.erase(_id)
		return
	_dictionary[_id] = _new_scene_data

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
		node.disconnect("edit_meta_pressed",self,"on_edit_meta_pressed")

func _on_WindowDialog_popup_hide():
	queue_free()
