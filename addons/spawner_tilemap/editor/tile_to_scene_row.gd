tool
extends MarginContainer

## Shows an specific relation between a tile id an a PackedScene inside the [tile_to_scene_dictionary]

#  VARIABLES

var scene_path: String
var tile_id: int
var dict_id: String
var tile_mode: int
var coord: Vector2

# CONSTANTS

const _single_tile_stylebox: StyleBoxFlat = preload("res://addons/spawner_tilemap/editor/single_tile_stylebox.tres")
const _autotile_tile_stylebox: StyleBoxFlat = preload("res://addons/spawner_tilemap/editor/auto_tile_stylebox.tres")
const _atlas_tile_stylebox: StyleBoxFlat = preload("res://addons/spawner_tilemap/editor/atlas_tile_stylebox.tres")

# DEPENDENCIES

onready var scene_resource_picker: EditorScenePicker

# CHILD NODES

onready var id_value_label = $HBoxContainer/MarginContainer/Information/HBoxContainer/HBoxContainer/IdValueLabel
onready var scene_name_label = $HBoxContainer/MarginContainer/Information/HBoxContainer2/SceneNameLabel
onready var resource: Control = $HBoxContainer/MarginContainer/Resource
onready var tile_texture: TextureRect = $HBoxContainer/TileTexture
onready var scene_settings_button = $HBoxContainer/MarginContainer/Information/HBoxContainer2/SceneSettingsButton
onready var tile_mode_label = $HBoxContainer/MarginContainer/Information/HBoxContainer/TileModeLabel

# SIGNALS

signal row_changed(_tile_id, _dict_id, scene)
signal scene_settings_pressed(_tile_id, _dict_id, texture)

# METHODS

func _ready() -> void:
	scene_resource_picker = EditorScenePicker.new()
	resource.add_child(scene_resource_picker)
	scene_resource_picker.connect("scene_changed",self,"_on_scene_changed")
	scene_settings_button.connect("pressed",self,"_on_scene_settings_pressed")

func set_tilemode(_tile_mode: int):
	if _tile_mode == TileSet.SINGLE_TILE:
		tile_mode_label.set("custom_styles/normal",_single_tile_stylebox)
		tile_mode_label.text = "SINGLE TILE"
	elif _tile_mode == TileSet.AUTO_TILE:
		tile_mode_label.set("custom_styles/normal",_autotile_tile_stylebox)
		tile_mode_label.text = "AUTO TILE"
	else:
		tile_mode_label.set("custom_styles/normal",_atlas_tile_stylebox)
		tile_mode_label.text = "ATLAS TILE"
	tile_mode = _tile_mode

func _notification(what):
	if what  == NOTIFICATION_EXIT_TREE:
		scene_resource_picker.disconnect("scene_changed",self,"_on_scene_changed")
		scene_settings_button.disconnect("pressed",self,"_on_scene_settings_pressed")

func set_texture(new_texture:AtlasTexture):
	tile_texture.texture = new_texture

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
	emit_signal("scene_settings_pressed",tile_id, dict_id, coord, tile_texture.texture)

class EditorScenePicker extends EditorResourcePicker:
	
	## Custom PackedScene resource picker
	
	var undo_redo: UndoRedo
	var final_scene: PackedScene setget set_final_scene
	var _popup_menu: PopupMenu
	
	## SIGNALS
	
	signal scene_changed(scene)
	signal show_in_filesystem_selected
	
	## METHODS
	
	func _init() -> void:
		base_type = "PackedScene"
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle_mode=false
		connect("resource_changed",self,"_on_resource_changed")
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			if is_connected("resource_changed",self,"_on_resource_changed"):
				disconnect("resource_changed",self,"_on_resource_changed")
	
	func set_create_options(menu_node):
		if final_scene:
			_popup_menu = menu_node as PopupMenu
			if _popup_menu.is_connected("index_pressed",self,"id_pressed"):
				return
			_popup_menu.connect("index_pressed",self,"id_pressed")
	
	func id_pressed(_index: int):
		if not is_instance_valid(_popup_menu):
			return
		if not edited_resource or edited_resource.resource_path.empty():
			return
		if _index != 7:
			return
		emit_signal("show_in_filesystem_selected")
	
	func _set(property: String, value) -> bool:
		if property=="edited_resource":
			set_final_scene(value)
		return false
	
	func set_final_scene(_scene: PackedScene):
		final_scene = _scene
		if edited_resource != final_scene:
			edited_resource = final_scene
		emit_signal("scene_changed",final_scene)
	
	func _on_resource_changed(resource):
		if undo_redo:
			undo_redo.create_action("Set scene to tile")
			undo_redo.add_do_property(self,"final_scene",resource)
			undo_redo.add_undo_property(self,"final_scene",final_scene)
			undo_redo.commit_action()
