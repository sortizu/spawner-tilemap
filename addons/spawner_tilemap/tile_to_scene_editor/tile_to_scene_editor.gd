extends WindowDialog
class_name TileToSceneEditor

# ---------------------------- DEPENDENCIES ------------------------------------
var tile_to_scene_row:PackedScene = preload("res://addons/spawner_tilemap/tile_to_scene_editor/tile_to_scene_row.tscn")
# Child nodes
onready var main_container = $MarginContainer/VBoxContainer

## 
func add_row(texture:Texture,tile_id:int,scene_path:String):
	main_container.add_child(tile_to_scene_row.instance())
