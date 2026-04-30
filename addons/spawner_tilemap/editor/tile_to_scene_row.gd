tool
extends HFlowContainer

## Shows an specific relation between a tile id an a PackedScene inside the [tile_to_scene_dictionary]

const SceneSettings: GDScript = preload("res://addons/spawner_tilemap/node/scene_settings.gd")

#  VARIABLES

var scene_path: String
var tile_id: int
var dict_id: String
var tile_mode: int
var coord: Vector2 setget set_coord
var undo_redo: UndoRedo
var tts_dict: Dictionary setget set_tts_dict
var scene_settings: SceneSettings setget set_scene_settings
var spawner_tilemap: SpawnerTileMap
var editor_interface: EditorInterface

# Classes

const EditorScenePicker: GDScript = preload("res://addons/spawner_tilemap/editor/editor_scene_picker.gd").EditorScenePicker
onready var editor_scene_picker: EditorScenePicker

# CHILD NODES

onready var id_value_label: Label = $DataContainer/TileData/IdValueLabel
onready var scene_name_label = $DataContainer/DataContainer/SceneDataAndSettings/SceneNameLabel
onready var data_container: Control = $DataContainer
onready var tile_texture: NinePatchRect = $TileTexture
onready var scene_settings_button: MenuButton = $DataContainer/DataContainer/SceneDataAndSettings/SceneSettingsButton
onready var tile_mode_label: Label = $DataContainer/TileData/TileModeLabel
onready var subtile_coord_label = $DataContainer/TileData/SubtileCoordLabel
onready var base_atlas_settings_cbox = $DataContainer/DataContainer/FastSettings/BaseAtlasSettingsCbox

# SIGNALS

signal scene_settings_pressed(_tile_id, _dict_id, _texture,_region)
signal copy_scene_settings_pressed(_copied_scene_settings, _row)
signal paste_scene_settings_pressed(_previous_scene_settings,_row)

# METHODS

func _ready() -> void:
	if Engine.editor_hint:
		if editor_interface:
			scene_settings_button.icon = editor_interface.get_base_control().get_icon("GuiTabMenu","EditorIcons")
		editor_scene_picker = EditorScenePicker.new()
		data_container.add_child(editor_scene_picker)
		editor_scene_picker.connect("resource_changed",self,"_on_resource_changed")
		scene_settings_button.get_popup().connect("id_pressed",self,"_on_popup_menu_id_pressed")
		base_atlas_settings_cbox.connect("pressed",self,"_on_base_atlas_settings_cbox_pressed")

func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		scene_settings_button.get_popup().disconnect("id_pressed",self,"_on_popup_menu_id_pressed")

func set_tilemode(_tile_mode: int, _tile_mode_name: String, _style_box: StyleBoxFlat):
	tile_mode_label.set("custom_styles/normal",_style_box)
	tile_mode_label.text = _tile_mode_name
	tile_mode = _tile_mode

func set_autotile_checkbox_value(cbox_value):
	base_atlas_settings_cbox.pressed = cbox_value

func set_tts_dict(new_tts_dict: Dictionary):
	tts_dict = new_tts_dict

func change_texture(new_texture: Texture, rect: Rect2):
	tile_texture.texture = new_texture
	tile_texture.region_rect = rect

func set_scene_settings(_new_scene_settings, update_dict: bool = false):
	scene_settings = _new_scene_settings
	if scene_settings:
		if update_dict: tts_dict[dict_id] = scene_settings
		(scene_settings_button.get_popup() as PopupMenu).set_item_disabled(1,false)
		base_atlas_settings_cbox.pressed = scene_settings.use_base_autotile_settings
		editor_scene_picker.edited_resource = scene_settings.selected_scene
	else:
		(scene_settings_button.get_popup() as PopupMenu).set_item_disabled(1,true)
		base_atlas_settings_cbox.pressed = false
		editor_scene_picker.edited_resource = null
	update_scene_name()

func set_id(new_tile_id: int, new_dict_id: String):
	tile_id = new_tile_id
	dict_id = new_dict_id
	var tooltip: String = "TILE ID: " + str(new_tile_id)
	if tile_mode != TileSet.SINGLE_TILE:
		tooltip += "\nDICTIONARY ID: " + str(new_dict_id)
	id_value_label.text = str(new_tile_id)
	id_value_label.hint_tooltip = tooltip

func set_coord(_coord: Vector2):
	coord = _coord
	if tile_mode != TileSet.SINGLE_TILE and dict_id.count("-") > 0:
		subtile_coord_label.show()
		base_atlas_settings_cbox.show()
		subtile_coord_label.text = str(coord)
	else:
		base_atlas_settings_cbox.hide()
		subtile_coord_label.hide()

func set_scene_name(new_scene_name: String):
	scene_name_label.text = "Scene: "
	if new_scene_name.empty():
		scene_name_label.text += "Not selected"
		scene_name_label.set("custom_colors/font_color",Color.darkgray)
	else:
		scene_name_label.text += new_scene_name
		scene_name_label.set("custom_colors/font_color",Color.white)

func update_scene_name():
	if scene_settings and scene_settings.selected_scene:
		scene_path = scene_settings.selected_scene.resource_path
		set_scene_name(scene_path.get_file())
	else:
		set_scene_name("")

func _on_resource_changed(_resource: Resource):
	if _resource and not _resource is PackedScene:
		return
	if not scene_settings:
		scene_settings = SceneSettings.new()
		scene_settings.subtile_coord = coord
		scene_settings.tile_mode = spawner_tilemap.tile_set.tile_get_tile_mode(tile_id) 
		scene_settings.tile_id = tile_id
		tts_dict[dict_id] = scene_settings
	if undo_redo:
		undo_redo.create_action("Set scene to tile")
		undo_redo.add_do_property(editor_scene_picker,"edited_resource",_resource)
		undo_redo.add_do_property(scene_settings,"selected_scene",_resource)
		undo_redo.add_do_method(self,"update_scene_name",null)
		undo_redo.add_undo_property(scene_settings,"selected_scene",scene_settings.selected_scene)
		undo_redo.add_undo_property(editor_scene_picker,"edited_resource",scene_settings.selected_scene)
		undo_redo.add_undo_method(self,"update_scene_name",null)
		undo_redo.commit_action()

func _on_popup_menu_id_pressed(id: int):
	match id:
		0:
			emit_signal("scene_settings_pressed",tile_id, dict_id, coord, tile_texture.texture, tile_texture.region_rect)
		1:
			emit_signal("copy_scene_settings_pressed",scene_settings, self)
		_:
			emit_signal("paste_scene_settings_pressed",scene_settings, self)

func _on_base_atlas_settings_cbox_pressed():
	var new_cbox_value: bool = base_atlas_settings_cbox.pressed
	if not scene_settings:
		scene_settings = SceneSettings.new()
		scene_settings.subtile_coord = coord
		scene_settings.tile_mode = spawner_tilemap.tile_set.tile_get_tile_mode(tile_id) 
		scene_settings.tile_id = tile_id
		tts_dict[dict_id] = scene_settings
	if undo_redo:
		undo_redo.create_action("Set value to use_base_autotile_settings")
		undo_redo.add_do_property(scene_settings,"use_base_autotile_settings",new_cbox_value)
		undo_redo.add_do_property(base_atlas_settings_cbox,"pressed",new_cbox_value)
		undo_redo.add_undo_property(scene_settings,"use_base_autotile_settings",not new_cbox_value)
		undo_redo.add_undo_property(base_atlas_settings_cbox,"pressed",not new_cbox_value)
		undo_redo.commit_action()
