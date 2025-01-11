tool
extends HFlowContainer

## Shows an specific relation between a tile id an a PackedScene inside the [tile_to_scene_dictionary]

#  VARIABLES

var scene_path: String
var tile_id: int
var dict_id: String
var tile_mode: int
var coord: Vector2

# Classes

const EditorScenePicker: GDScript = preload("res://addons/spawner_tilemap/editor/editor_scene_picker.gd").EditorScenePicker
onready var editor_scene_picker: EditorScenePicker

# CHILD NODES

onready var id_value_label: Label = $DataContainer/TileData/IdValueLabel
onready var scene_name_label: Label = $DataContainer/SceneDataAndSettings/SceneNameLabel
onready var data_container: Control = $DataContainer
onready var tile_texture: NinePatchRect = $TileTexture
onready var scene_settings_button: Button = $DataContainer/SceneDataAndSettings/SceneSettingsButton
onready var tile_mode_label: Label = $DataContainer/TileData/TileModeLabel

# SIGNALS

signal row_changed(_tile_id, _dict_id, scene)
signal scene_settings_pressed(_tile_id, _dict_id, texture)

# METHODS

func _ready() -> void:
	if Engine.editor_hint:
		editor_scene_picker = EditorScenePicker.new()
		data_container.add_child(editor_scene_picker)
		editor_scene_picker.connect("scene_changed",self,"_on_scene_changed")
		scene_settings_button.connect("pressed",self,"_on_scene_settings_pressed")

func set_tilemode(_tile_mode: int, _tile_mode_name: String, _style_box: StyleBoxFlat):
	tile_mode_label.set("custom_styles/normal",_style_box)
	tile_mode_label.text = _tile_mode_name
	tile_mode = _tile_mode

func _notification(what):
	if what  == NOTIFICATION_EXIT_TREE:
		editor_scene_picker.disconnect("scene_changed",self,"_on_scene_changed")
		scene_settings_button.disconnect("pressed",self,"_on_scene_settings_pressed")
		pass

func change_texture(new_texture: Texture, rect: Rect2):
	tile_texture.texture = new_texture
	tile_texture.region_rect = rect
	

func set_id(new_tile_id: int, new_dict_id: String):
	self.tile_id = new_tile_id
	self.dict_id = new_dict_id
	var tooltip: String = "TILE ID: " + str(new_tile_id)
	if tile_mode != TileSet.SINGLE_TILE:
		tooltip += "\nDICTIONARY ID: " + str(new_dict_id)
	id_value_label.text = str(new_tile_id)
	id_value_label.hint_tooltip = tooltip

func set_scene_name(new_scene_name: String):
	scene_name_label.text = "Scene: "
	if new_scene_name.empty():
		scene_name_label.text += "Not selected"
		scene_name_label.set("custom_colors/font_color",Color.darkgray)
	else:
		scene_name_label.text += new_scene_name
		scene_name_label.set("custom_colors/font_color",Color.white)

func _on_scene_changed(scene:PackedScene):
	if scene:
		scene_path = scene.resource_path
		set_scene_name(scene_path.get_file())
	else:
		set_scene_name("")
	emit_signal("row_changed", tile_id, dict_id, scene)

func _on_scene_settings_pressed():
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = tile_texture.texture
	atlas_texture.region = tile_texture.region_rect
	emit_signal("scene_settings_pressed",tile_id, dict_id, coord, atlas_texture)
