@tool
extends EditorPlugin

#-----------------------------------------------------------------------------
# VARIABLES
#-----------------------------------------------------------------------------

# We no longer use @export_file. This will be an internal variable.
var gss_file_path: String = ""

# Variables to store the reference to our editor interface
var dock: VBoxContainer
var path_line_edit: LineEdit
var file_dialog: EditorFileDialog

#-----------------------------------------------------------------------------
# PLUGIN LIFECYCLE
#-----------------------------------------------------------------------------

func _enter_tree():
	# --- User Interface Creation ---

	# Main dock container
	dock = VBoxContainer.new()
	dock.name = "GSS Themer"

	# Horizontal container for the LineEdit and search button
	var hbox = HBoxContainer.new()

	path_line_edit = LineEdit.new()
	path_line_edit.placeholder_text = "Select a .gss or .txt file"
	path_line_edit.editable = false # So it can't be manually edited
	path_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(path_line_edit)

	var search_button = Button.new()
	search_button.text = "..."
	hbox.add_child(search_button)

	dock.add_child(hbox)

	# Main button to generate the theme
	var generate_button = Button.new()
	generate_button.text = "Generate Theme from GSS"
	dock.add_child(generate_button)

	# --- File Dialog Creation (initially invisible) ---
	file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.gss", "Godot Stylesheet")
	file_dialog.add_filter("*.txt", "Text File")
	dock.add_child(file_dialog) # It's important to add it to the node tree

	# --- Signal Connection ---
	search_button.pressed.connect(_on_search_button_pressed)
	generate_button.pressed.connect(process_stylesheet)
	file_dialog.file_selected.connect(_on_file_selected)

	# Add our dock to the right side of the editor.
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()

#-----------------------------------------------------------------------------
# UI SIGNAL HANDLERS
#-----------------------------------------------------------------------------

func _on_search_button_pressed():
	# Show the dialog window to select file
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	# This function is activated when the user chooses a file in the dialog.
	# We update our variable and the text in the interface.
	gss_file_path = path
	path_line_edit.text = path

#-----------------------------------------------------------------------------
# MAIN LOGIC (The rest of the code remains the same)
#-----------------------------------------------------------------------------

func process_stylesheet() -> void:
	if gss_file_path == "" or not FileAccess.file_exists(gss_file_path):
		push_error("[GSS] No valid GSS file has been selected.")
		return
	var raw_gss: String = load_file(gss_file_path)
	if raw_gss.strip_edges() == "":
		push_error("[GSS] The GSS file is empty or could not be read.")
		return
	var parser: Dictionary = parse_gss(raw_gss)
	print("GSS Parsed: ", parser)
	apply_styling(parser)

# ... (The rest of functions: load_file, parse_gss, apply_styling, etc., go here unchanged) ...
# Paste the rest of your functions here
func load_file(path: String) -> String:
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var content: String = file.get_as_text()
		return content
	return ""

func parse_gss(gss:String)->Dictionary:
	gss = gss_remove_comments(gss)
	var sorted_rules:Array = gss_sort_rules(gss)
	var styles:Dictionary = {}
	for elem:Array in sorted_rules:
		var property_string:String = elem[1]
		var properties:Array = property_string.split(";", false)
		var property_list:Array = []
		for style:String in properties:
			if style.is_empty() or not ":" in style: continue
			var style_split:PackedStringArray = str(style).split(":", true, 1)
			var property:String = style_split[0].strip_edges().strip_escapes().to_lower()
			var pvalue:String = style_split[1].strip_edges().strip_escapes().to_lower()
			property_list.append( [property, pvalue] )
		styles[elem[0]] = property_list
	return styles

func gss_remove_comments(gss:String)->String:
	var regex:RegEx = RegEx.new()
	regex.compile(r'/\*.*?\*/')
	gss = regex.sub(gss, '', true)
	return gss

func gss_sort_rules(gss:String)->Array:
	var regex_rule:String = "([#.a-zA-Z\\d0-9-:]+\\s*){([\\sa-z-:;0-9#\\(\\),-\\\\]*)}"
	var regex:RegEx = RegEx.new()
	regex.compile(regex_rule)
	var rule_arr:Array = []
	var matched_arr:Array[RegExMatch] = regex.search_all(gss)
	for i in matched_arr:
		rule_arr.append(
				[i.get_string(1).strip_edges(),
				i.get_string(2).strip_escapes().strip_edges()
				])
	return rule_arr

var selector_current:String
var property_current:String

func apply_styling(stylesheet:Dictionary)->void:
	var theme:Theme = Theme.new()
	var selectors:Array = stylesheet.keys()
	for selector:String in selectors:
		selector_current = selector
		var stylebox_current:StyleBoxFlat = StyleBoxFlat.new()
		match(selector.to_lower()):
			"button":
				if(theme.has_stylebox("normal", "Button")): stylebox_current = theme.get_stylebox("normal", "Button").duplicate()
				theme.set_stylebox("normal", "Button", create_styleboxflat(stylesheet.get(selector), stylebox_current) )
				if(property_list_get(stylesheet.get(selector), "font-color") != ""): theme.set_color("font_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-color")))
				if(property_list_get(stylesheet.get(selector), "font-size") != ""): theme.set_font_size("font_size", "Button", int(property_list_get(stylesheet.get(selector), "font-size").trim_suffix("px")) )
			"button:hover":
				if(theme.has_stylebox("hover", "Button")): stylebox_current = theme.get_stylebox("hover", "Button").duplicate()
				theme.set_stylebox("hover", "Button", create_styleboxflat(stylesheet.get(selector), stylebox_current) )
				if(property_list_get(stylesheet.get(selector), "font-color") != ""): theme.set_color("font_hover_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-color")))
			"button:pressed":
				if(theme.has_stylebox("pressed", "Button")): stylebox_current = theme.get_stylebox("pressed", "Button").duplicate()
				theme.set_stylebox("pressed", "Button", create_styleboxflat(stylesheet.get(selector), stylebox_current) )
				if(property_list_get(stylesheet.get(selector), "font-color") != ""): theme.set_color("font_pressed_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-color")))
			"button:disabled":
				if(theme.has_stylebox("disabled", "Button")): stylebox_current = theme.get_stylebox("disabled", "Button").duplicate()
				theme.set_stylebox("disabled", "Button", create_styleboxflat(stylesheet.get(selector), stylebox_current) )
				if(property_list_get(stylesheet.get(selector), "font-color") != ""): theme.set_color("font_disabled_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-color")))
	var save_path := "res://my_generated_theme.theme"
	var result := ResourceSaver.save(theme, save_path)
	if result == OK:
		print("Theme saved successfully at: ", save_path)
	else:
		push_error("[GSS] Error saving theme at: " + save_path)

func create_styleboxflat(styling:Array, stylebox:StyleBoxFlat = StyleBoxFlat.new())->StyleBoxFlat:
	for style:Array in styling:
		var property:String = style[0]
		var pvalue:String = style[1]
		match(property):
			"background-color": stylebox.bg_color = set_valid_colour(pvalue)
			"border-radius": apply_radius(stylebox, pvalue)
	return stylebox

func apply_radius(stylebox:StyleBoxFlat, values:String)->void:
	var arr:Array = values.split(" ", false, 0)
	if arr.size() == 1:
		var r = set_valid_radius(arr[0])
		stylebox.set_corner_radius_all(r)

func set_valid_radius(size:String)->int:
	return int(size.trim_suffix("px"))

func set_valid_colour(colour:String)->Color:
	return Color.from_string(colour, Color.BLACK)

func property_list_get(list:Array, item:String)->String:
	for i:Array in list:
		if(i[0] == item):
			return i[1]
	return ""