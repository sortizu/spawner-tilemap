class EditorScenePicker extends EditorResourcePicker:
	
	## Custom PackedScene resource picker

	var _popup_menu: PopupMenu
	
	## SIGNALS
	
	signal scene_changed(scene)
	signal show_in_filesystem_selected
	
	## METHODS
	
	func _init() -> void:
		base_type = "PackedScene"
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle_mode=false
#		connect("resource_changed",self,"_on_resource_changed")
		
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			if is_connected("resource_changed",self,"_on_resource_changed"):
				disconnect("resource_changed",self,"_on_resource_changed")
	
	func set_create_options(menu_node):
		if edited_resource:
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

