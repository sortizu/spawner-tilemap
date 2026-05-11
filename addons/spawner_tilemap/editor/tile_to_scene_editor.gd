tool
extends WindowDialog

## Dialog that appears when the user presses "Edit Scenes" in a SpawnerTileMap
## It facilitates the process of matching a tile inside a TileMap with a PackedScene using an specialised GUI

# DEPENDENCIES

var tile_to_scene_row: PackedScene = preload("res://addons/spawner_tilemap/editor/tile_to_scene_row.tscn")
const SceneSettings: GDScript = preload("res://addons/spawner_tilemap/node/scene_settings.gd")
var editor_interface: EditorInterface
var spawner_tilemap: SpawnerTileMap
var undo_redo: UndoRedo

# CHILD NODES

onready var main_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/MarginContainer/MainContainer
onready var clean_button: Button = $MarginContainer/VBoxContainer/SearchButtons/ClearButton
onready var search_button: Button = $MarginContainer/VBoxContainer/SearchButtons/SearchButton
onready var search_bar: LineEdit = $MarginContainer/VBoxContainer/SearchBar
onready var filters_options = $MarginContainer/VBoxContainer/VBoxContainer/FiltersOptions
onready var page_number_line_edit = $MarginContainer/VBoxContainer/VBoxContainer/PageNumberLineEdit
onready var total_pages_label = $MarginContainer/VBoxContainer/VBoxContainer/TotalPagesLabel
onready var previous_page_button = $MarginContainer/VBoxContainer/VBoxContainer/PreviousPageButton
onready var next_page_button = $MarginContainer/VBoxContainer/VBoxContainer/NextPageButton

# VARIABLES

var current_page: int = 1
var total_pages: int = -1
var _search_text: String = "*"

# CONSTANTS

const _single_tile_stylebox: StyleBoxFlat = preload("res://addons/spawner_tilemap/editor/single_tile_stylebox.tres")
const _autotile_tile_stylebox: StyleBoxFlat = preload("res://addons/spawner_tilemap/editor/auto_tile_stylebox.tres")
const _atlas_tile_stylebox: StyleBoxFlat = preload("res://addons/spawner_tilemap/editor/atlas_tile_stylebox.tres")
const tiles_per_page: int = 10
enum FilterOptions {NONE, ASSIGNED_TILES, UNASSIGNED_TILES}

signal copy_scene_settings_pressed(_copied_scene_settings)
signal paste_scene_settings_pressed(_previous_scene_settings)

# METHODS

## Updates the icons for each button and add the rows that show information from the [tile_to_scene_dictionary]
func _ready() -> void:
	spawner_tilemap = editor_interface.get_selection().get_selected_nodes()[0]
	# Setting icons for search buttons
	var main_control = editor_interface.get_base_control()
	search_button.icon = main_control.get_icon("Search","EditorIcons")
	clean_button.icon = main_control.get_icon("Clear","EditorIcons")
	# Setting filter options
	filters_options.add_item("None")
	filters_options.add_item("Assigned tiles")
	filters_options.add_item("Unassigned Tiles")
	# Removing connections with signals
	main_container.connect("child_exiting_tree",self,"_on_child_exited_in_main_container")
	show_rows_in_page(current_page, "*", FilterOptions.NONE, true)
	# Connecting signals
	connect("popup_hide",self,"_on_WindowDialog_popup_hide")
	page_number_line_edit.connect("text_entered",self,"_on_PageNumber_text_entered")
	previous_page_button.connect("pressed",self,"_on_PreviousPageButton_pressed")
	next_page_button.connect("pressed",self,"_on_NextPageButton_pressed")
	search_bar.connect("text_entered",self,"_on_search_text_entered")
	search_button.connect("pressed",self,"_on_search_text_entered")
	clean_button.connect("pressed",self,"_on_ClearButton_pressed")
	filters_options.connect("item_selected",self,"_on_filter_selected")

## Removes the signals still connected before destroying the editor
func _notification(what: int):
	if what == NOTIFICATION_EXIT_TREE:
		main_container.disconnect("child_exiting_tree",self,"_on_child_exited_in_main_container")
		disconnect("popup_hide",self,"_on_WindowDialog_popup_hide")
		page_number_line_edit.disconnect("text_entered",self,"_on_PageNumber_text_entered")
		next_page_button.disconnect("pressed",self,"_on_NextPageButton_pressed")
		search_bar.disconnect("text_entered",self,"_on_search_text_entered")
		search_button.disconnect("pressed",self,"_on_search_text_entered")
		filters_options.disconnect("item_selected",self,"_on_filter_selected")
		clean_button.disconnect("pressed",self,"_on_ClearButton_pressed")

## Adds a row to the main container, which contains the image of the tile, the name of the scene and a PackedScene resource picker
func set_row_data(_row_index: int,texture: Texture, region: Rect2, tile_id: int, dict_id: String, coord: Vector2, scene_settings: SceneSettings, tile_mode: int):
	var row: Control
	if _row_index >= main_container.get_child_count():
		for i in _row_index - main_container.get_child_count() + 1:
			row = tile_to_scene_row.instance()
			row.editor_interface = editor_interface
			main_container.add_child(row)
			row.connect("scene_settings_pressed",self,"on_scene_settings_pressed")
			row.connect("copy_scene_settings_pressed",self,"on_copy_scene_settings_pressed")
			row.connect("paste_scene_settings_pressed",self,"on_paste_scene_settings_pressed")
			row.editor_scene_picker.connect("show_in_filesystem_selected",self,"queue_free")
	else:
		row = main_container.get_child(_row_index)
		row.visible = true
	# Setting the new values to the row
	if tile_mode == TileSet.SINGLE_TILE:
		row.set_tilemode(tile_mode, "SINGLE TILE", _single_tile_stylebox)
	elif tile_mode == TileSet.AUTO_TILE:
		if dict_id.count("-")>0:
			row.set_tilemode(tile_mode,"AUTO TILE", _autotile_tile_stylebox)
		else:
			row.set_tilemode(tile_mode,"BASE AUTO TILE", _autotile_tile_stylebox)
	else:
		if dict_id.count("-")>0:
			row.set_tilemode(tile_mode, "ATLAS TILE", _atlas_tile_stylebox)
		else:
			row.set_tilemode(tile_mode, "BASE ATLAS TILE", _atlas_tile_stylebox)
	row.change_texture(texture, region)
	row.set_id(tile_id, dict_id)
	row.spawner_tilemap = spawner_tilemap
	row.coord = coord
	row.undo_redo = undo_redo
	row.tts_dict = spawner_tilemap.tile_to_scene_dictionary.dictionary
	row.scene_settings = scene_settings

## TODO Documentation
func update_scene_settings_in_row(updated_scene_settings: SceneSettings, row: Control):
	undo_redo.create_action("Paste scene settings")
	undo_redo.add_do_method(row,"set_scene_settings",updated_scene_settings,true)
	undo_redo.add_undo_method(row,"set_scene_settings",row.scene_settings,true)
	undo_redo.commit_action()

## Shows all the information inside the [tile_to_scene_dictionary] stored by the SpawnTileMap using rows that are created by [set_row_data]
func show_rows_in_page(_selected_page: int, _search_text: String = "*", _filter_option: int = -1, update_total_pages: bool = false, ignore_filters: bool = true):
	var tile_set: TileSet = spawner_tilemap.tile_set
	if tile_set:
		for _row in main_container.get_children():
			_row.visible = false
		var tile_to_scene_dictionary = spawner_tilemap.tile_to_scene_dictionary
		var _tile_mode: int
		var _scene_settings: SceneSettings 
		var _texture: Texture
		var _region: Rect2
		var _icount: int
		var _jcount: int
		var _row_index: int = 0
		var _subtile_size: Vector2
		var _dict_id: String
		var _page_count: int = 1
		var stop_autotile_loop: bool = false
		var filtered_by_text: bool
		var filtered_by_option: bool
		var _searched: bool
		for tile_id in tile_set.get_tiles_ids():
			_tile_mode = spawner_tilemap.tile_set.tile_get_tile_mode(tile_id)
			_region = tile_set.tile_get_region(tile_id)
			if _tile_mode != TileSet.SINGLE_TILE:
				_subtile_size = tile_set.autotile_get_size(tile_id)
				_icount = _region.size.x/_subtile_size.x
				_jcount = _region.size.y/_subtile_size.y
				var j: int = 0
				var i: int = 0
				var show_base_autotile: bool = true
				while j < _jcount:
					i = 0
					while i < _icount:
						if _page_count > _selected_page and not update_total_pages:
							stop_autotile_loop = true
							break
						if show_base_autotile:
							_dict_id = str(tile_id)
						else:
							_dict_id = "%d-%d-%d"%[tile_id,i,j]
						if not ignore_filters:
							_scene_settings = tile_to_scene_dictionary.dictionary.get(_dict_id)
							_searched = true
							filtered_by_text =  _dict_id.matchn(_search_text) or (_scene_settings and _scene_settings.selected_scene.resource_path.get_file().matchn(_search_text))
							if _filter_option == FilterOptions.ASSIGNED_TILES:
								filtered_by_option = _scene_settings and _scene_settings.selected_scene != null
							elif _filter_option == FilterOptions.UNASSIGNED_TILES:
								filtered_by_option = not _scene_settings or _scene_settings.selected_scene == null
							else:
								filtered_by_option = true
						if ignore_filters or (filtered_by_text and filtered_by_option):
							if not _searched:
								_scene_settings = tile_to_scene_dictionary.dictionary.get(_dict_id,null)
								_searched = false
							if _page_count == _selected_page:
								if show_base_autotile:
									set_row_data(_row_index, tile_set.tile_get_texture(tile_id), _region, tile_id, _dict_id,Vector2(i,j),_scene_settings,_tile_mode)
								else:
									set_row_data(_row_index, tile_set.tile_get_texture(tile_id), Rect2(_region.position.x + i*_subtile_size.x,_region.position.y + j*_subtile_size.y,_subtile_size.x,_subtile_size.y), tile_id, _dict_id,Vector2(i,j),_scene_settings,_tile_mode)
							if show_base_autotile:
								show_base_autotile = false
							else:
								i += 1
						else: 
							i += 1
							if show_base_autotile:
								show_base_autotile = false
							continue
						_row_index += 1
						if _row_index == tiles_per_page:
							_row_index = 0
							_page_count += 1
					if stop_autotile_loop: 
						stop_autotile_loop = false
						break
					j += 1
			else:
				if _page_count > _selected_page and not update_total_pages:
					break
				if not ignore_filters:
					_scene_settings = tile_to_scene_dictionary.dictionary.get(str(tile_id))
					_searched = true
					filtered_by_text =  str(tile_id).matchn(_search_text) or (_scene_settings and _scene_settings.selected_scene.resource_path.get_file().matchn(_search_text))
					if _filter_option == FilterOptions.ASSIGNED_TILES:
						filtered_by_option = _scene_settings and _scene_settings.selected_scene != null
					elif _filter_option == FilterOptions.UNASSIGNED_TILES:
						filtered_by_option = not _scene_settings or _scene_settings.selected_scene == null
					else:
						filtered_by_option = true
				if ignore_filters or (filtered_by_text and filtered_by_option):
					if not _searched:
						_scene_settings = tile_to_scene_dictionary.dictionary.get(str(tile_id))
						_searched = false
					if _page_count == _selected_page:
						set_row_data(_row_index, tile_set.tile_get_texture(tile_id), _region, tile_id, str(tile_id), Vector2(0,0), _scene_settings, _tile_mode)
				else: continue
				_row_index += 1
				if _row_index == tiles_per_page:
					_row_index = 0
					_page_count += 1
		if update_total_pages:
			if _row_index == 0 and _page_count > 1:
				set_total_pages(_page_count - 1)
			else:
				set_total_pages(_page_count)
	call_deferred("set_current_page",_selected_page)
#	set_current_page(_selected_page)

## Creates a custom resource to add data to each scene and to customize their spawning process
func on_scene_settings_pressed(_tile_id: int, _dict_id: String, coord: Vector2, _texture: Texture, _region: Rect2):
	var tile_to_scene_dictionary = spawner_tilemap.tile_to_scene_dictionary
	var _scene_settings: SceneSettings = tile_to_scene_dictionary.dictionary.get(_dict_id)
	if not _scene_settings:
		_scene_settings = SceneSettings.new()
		tile_to_scene_dictionary.dictionary[_dict_id] = _scene_settings
	_scene_settings.tile_mode = spawner_tilemap.tile_set.tile_get_tile_mode(_tile_id) 
	_scene_settings.subtile_coord = coord
	_scene_settings.tile_id = _tile_id
	if not _scene_settings.tile:
		var atlas_texture: AtlasTexture = AtlasTexture.new()
		atlas_texture.atlas = _texture
		atlas_texture.region = _region
		_scene_settings.set_tile(atlas_texture)
	editor_interface.edit_resource(_scene_settings)
	queue_free()

func on_copy_scene_settings_pressed(_copied_scene_settings: SceneSettings, row: Control):
	emit_signal("copy_scene_settings_pressed",_copied_scene_settings,row)

func on_paste_scene_settings_pressed(_previous_scene_settings: SceneSettings, row: Control):
	emit_signal("paste_scene_settings_pressed",_previous_scene_settings,row)

## Filters the rows based on the tile id and the name of the scene
func _on_search_text_entered(new_text: String = search_bar.text) -> void:
	_search_text = "*"+new_text+"*"
	show_rows_in_page(1,_search_text,filters_options.selected,true,false)

## Cleans the text in the search bar
func _on_ClearButton_pressed() -> void:
	search_bar.text = ""
	_search_text = "*"
	show_rows_in_page(1,_search_text,filters_options.selected,true,false)

func _on_filter_selected(index: int):
	show_rows_in_page(1, _search_text, index,true,false)

## Removes the conection between [row_changed] and every row added to the main container
func _on_child_exited_in_main_container(node: Node):
	if node.has_signal("scene_settings_pressed") and node.is_connected("scene_settings_pressed",self,"on_scene_settings_pressed"):
		node.disconnect("scene_settings_pressed",self,"on_scene_settings_pressed")
		node.disconnect("copy_scene_settings_pressed",self,"on_copy_scene_settings_pressed")
		node.disconnect("paste_scene_settings_pressed",self,"on_paste_scene_settings_pressed")

func _on_WindowDialog_popup_hide():
	queue_free()

func _on_PageNumber_text_entered(new_text: String):
	if new_text.is_valid_integer():
		show_rows_in_page(clamp(int(new_text),1,total_pages),_search_text,filters_options.selected,false,false)
	else:
		page_number_line_edit.text = str(current_page)

func _on_PreviousPageButton_pressed():
	show_rows_in_page(current_page - 1,_search_text,filters_options.selected,false,false)

func _on_NextPageButton_pressed():
	show_rows_in_page(current_page + 1,_search_text,filters_options.selected,false,false)

func set_total_pages(_total_pages: int):
	total_pages = _total_pages
	total_pages_label.text = "/ %d "% total_pages

func set_current_page(_current_page: int):
	current_page = _current_page
	page_number_line_edit.text = str(current_page)
	if total_pages == 1:
		previous_page_button.disabled = true
		next_page_button.disabled = true
	elif current_page == 1:
		previous_page_button.disabled = true
		next_page_button.disabled = false
	elif current_page == total_pages:
		next_page_button.disabled = true
		previous_page_button.disabled = false
	else:
		previous_page_button.disabled = false
		next_page_button.disabled = false
