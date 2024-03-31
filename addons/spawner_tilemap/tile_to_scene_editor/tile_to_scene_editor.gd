tool
extends WindowDialog

# ---------------------------- DEPENDENCIES ------------------------------------
var tile_to_scene_row: PackedScene = preload("res://addons/spawner_tilemap/tile_to_scene_editor/tile_to_scene_row.tscn")
var editor_interface: EditorInterface
var spawner_tilemap: SpawnerTileMap
# Child nodes
onready var main_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MainContainer
onready var clean_button: Button = $MarginContainer/VBoxContainer/SearchButtons/ClearButton
onready var search_button: Button = $MarginContainer/VBoxContainer/SearchButtons/SearchButton
onready var save_button: Button = $MarginContainer/VBoxContainer/SaveButton
onready var search_bar: LineEdit = $MarginContainer/VBoxContainer/SearchBar


func _ready() -> void:
	spawner_tilemap = editor_interface.get_selection().get_selected_nodes()[0]
	# Setting icons for search buttons
	var main_control = editor_interface.get_base_control()
	search_button.icon = main_control.get_icon("Search","EditorIcons")
	clean_button.icon = main_control.get_icon("Clear","EditorIcons")
	save_button.icon = main_control.get_icon("Save","EditorIcons")
	update_rows()
## 
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
	#row._on_resource_changed(scene)
##
func update_rows():
	var tile_set: TileSet = spawner_tilemap.tile_set
	var tile_to_scene_dictionary: TileToSceneDictionary = spawner_tilemap.tile_to_scene_dictionary
	if tile_set:
		for tile_id in tile_set.get_tiles_ids():
			var scene: PackedScene = null
			if tile_to_scene_dictionary.dictionary.has(tile_id):
				scene = tile_to_scene_dictionary.dictionary[tile_id]
			add_row(tile_set.tile_get_texture(tile_id),tile_set.tile_get_region(tile_id),tile_id,scene)

func _on_SaveButton_pressed() -> void:
	var tile_to_scene_dictionary: TileToSceneDictionary = spawner_tilemap.tile_to_scene_dictionary
	for row in main_container.get_children():
		var tile_id = row.tile_id
		var scene = row.scene_resource_picker.edited_resource
		tile_to_scene_dictionary.dictionary[tile_id] = scene
	print("TileToSceneEditor: Scenes saved successfully")
	queue_free()

func _on_SearchButton_pressed() -> void:
	for row in main_container.get_children():
		var search_text: String = "*" +search_bar.text + "*"
		if not (row.scene_path.get_file().matchn(search_text) or str(row.tile_id).matchn(search_text)):
			row.hide()
		else:
			row.show()

func _on_ClearButton_pressed() -> void:
	search_bar.text = ""
	for row in main_container.get_children():
		row.show()
	
func _unhandled_key_input(event: InputEventKey) -> void:
	if search_bar:
		if search_bar.has_focus():
			if event.scancode == KEY_ENTER:
				_on_SearchButton_pressed()
