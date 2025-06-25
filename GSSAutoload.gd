@tool
extends EditorPlugin

#-----------------------------------------------------------------------------
# VARIABLES
#-----------------------------------------------------------------------------
var gss_file_path: String = ""
var dock: VBoxContainer
var path_line_edit: LineEdit
var file_dialog: EditorFileDialog

#-----------------------------------------------------------------------------
# PLUGIN LIFECYCLE
#-----------------------------------------------------------------------------

func _enter_tree():
    # El código de la UI no cambia
    dock = VBoxContainer.new()
    dock.name = "GSS Themer"
    var hbox = HBoxContainer.new()
    path_line_edit = LineEdit.new()
    path_line_edit.placeholder_text = "Select a .gss or .txt file"
    path_line_edit.editable = false
    path_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.add_child(path_line_edit)
    var search_button = Button.new()
    search_button.text = "..."
    hbox.add_child(search_button)
    dock.add_child(hbox)
    var generate_button = Button.new()
    generate_button.text = "Generate Theme from GSS"
    dock.add_child(generate_button)
    file_dialog = EditorFileDialog.new()
    file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
    file_dialog.add_filter("*.gss", "Godot Stylesheet")
    file_dialog.add_filter("*.txt", "Text File")
    dock.add_child(file_dialog)
    search_button.pressed.connect(_on_search_button_pressed)
    generate_button.pressed.connect(process_stylesheet)
    file_dialog.file_selected.connect(_on_file_selected)
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree():
    remove_control_from_docks(dock)
    dock.free()

#-----------------------------------------------------------------------------
# UI SIGNAL HANDLERS
#-----------------------------------------------------------------------------

func _on_search_button_pressed():
    file_dialog.popup_centered()

func _on_file_selected(path: String):
    gss_file_path = path
    path_line_edit.text = path

#-----------------------------------------------------------------------------
# LÓGICA PRINCIPAL (Ahora mucho más limpia)
#-----------------------------------------------------------------------------

func process_stylesheet() -> void:
    # 1. Validar el archivo de entrada
    if gss_file_path.is_empty() or not FileAccess.file_exists(gss_file_path):
        push_error("[GSS] No valid GSS file has been selected.")
        return
        
    var raw_gss := FileAccess.open(gss_file_path, FileAccess.READ).get_as_text()
    if raw_gss.strip_edges().is_empty():
        push_error("[GSS] The GSS file is empty or could not be read.")
        return

    # 2. Usar el Parser para obtener datos estructurados
    var parsed_data: Dictionary = GSSParser.parse_stylesheet(raw_gss)
    print("GSS Parsed: ", parsed_data)

    # 3. Usar el Themer para generar el recurso Theme
    var new_theme: Theme = GSSThemer.create_theme_from_styles(parsed_data)

    # 4. Guardar el resultado
    var save_path := "res://my_generated_theme.theme"
    var result := ResourceSaver.save(new_theme, save_path)

    if result == OK:
        print("Theme saved successfully at: ", save_path)
    else:
        push_error("[GSS] Error saving theme at: " + save_path)