tool
extends EditorPlugin

var plugin

func _enter_tree() -> void:
	plugin = preload("res://addons/spawner_tilemap/editor_spawner_tilemap.gd").new()
	plugin.connect("edit_scenes_pressed",self,"show_plugin_window_dialog")
	add_inspector_plugin(plugin)


func _exit_tree() -> void:
	remove_inspector_plugin(plugin)

func show_plugin_window_dialog(window_dialog:WindowDialog):
	get_editor_interface().get_base_control().add_child(window_dialog)
	window_dialog.popup_centered(window_dialog.rect_min_size)
	
