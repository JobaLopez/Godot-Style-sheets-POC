@tool
extends EditorPlugin

#-----------------------------------------------------------------------------
# VARIABLES
#-----------------------------------------------------------------------------
var txt_file_path: String = ""
var dock: VBoxContainer
var path_line_edit: LineEdit
var file_dialog: EditorFileDialog
var output_name_line_edit: LineEdit
var output_folder_line_edit: LineEdit
var folder_dialog: EditorFileDialog

#-----------------------------------------------------------------------------
# PLUGIN LIFECYCLE
#-----------------------------------------------------------------------------

func _enter_tree():
    dock = VBoxContainer.new()
    dock.name = "GSS Themer"

    # INPUT FILE UI
    var hbox = HBoxContainer.new()
    path_line_edit = LineEdit.new()
    path_line_edit.placeholder_text = "Select a .txt file"
    path_line_edit.editable = false
    path_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.add_child(path_line_edit)
    var search_button = Button.new()
    search_button.text = "..."
    hbox.add_child(search_button)
    dock.add_child(hbox)

    # OUTPUT FOLDER UI
    var folder_box = HBoxContainer.new()
    var folder_label = Label.new()
    folder_label.text = "Output Folder:"
    folder_box.add_child(folder_label)

    output_folder_line_edit = LineEdit.new()
    output_folder_line_edit.placeholder_text = "res:// (Default)"
    output_folder_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    output_folder_line_edit.editable = false
    folder_box.add_child(output_folder_line_edit)

    var folder_browse_button = Button.new()
    folder_browse_button.text = "..."
    folder_box.add_child(folder_browse_button)
    dock.add_child(folder_box)

    folder_dialog = EditorFileDialog.new()
    folder_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
    dock.add_child(folder_dialog)

    folder_browse_button.pressed.connect(_on_folder_browse_pressed)
    folder_dialog.dir_selected.connect(_on_folder_selected)

    # OUTPUT THEME NAME UI
    var out_name_box = HBoxContainer.new()
    var out_label = Label.new()
    out_label.text = "Output Theme Name:"
    out_name_box.add_child(out_label)
    output_name_line_edit = LineEdit.new()
    output_name_line_edit.placeholder_text = "e.g. my_ui_theme"
    output_name_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    out_name_box.add_child(output_name_line_edit)
    dock.add_child(out_name_box)

    # GENERATE THEME BUTTON
    var generate_button = Button.new()
    generate_button.text = "Generate Theme from GSS"
    dock.add_child(generate_button)
    file_dialog = EditorFileDialog.new()
    file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
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
    txt_file_path = path
    path_line_edit.text = path

func _on_folder_browse_pressed():
    folder_dialog.popup_centered()

func _on_folder_selected(folder_path: String):
    output_folder_line_edit.text = folder_path

#-----------------------------------------------------------------------------
# MAIN LOGIC
#-----------------------------------------------------------------------------

func process_stylesheet() -> void:
    if txt_file_path.is_empty():
        push_error("[GSS] No .txt file has been selected.")
        return

    if not FileAccess.file_exists(txt_file_path):
        push_error("[GSS] Selected file does not exist: " + txt_file_path)
        return

    var file := FileAccess.open(txt_file_path, FileAccess.READ)
    if not file:
        push_error("[GSS] Cannot open file: " + txt_file_path)
        return

    var output_dir := output_folder_line_edit.text.strip_edges()
    if output_dir.is_empty():
        output_dir = "res://"


    var user_theme_name := output_name_line_edit.text.strip_edges()
    
    if user_theme_name.is_empty():
        push_error("[GSS] Output theme name cannot be empty.")
        return
    
    if not user_theme_name.ends_with(".theme"):
        user_theme_name += ".theme"

    var raw_gss := file.get_as_text()
    file.close()

    if raw_gss.strip_edges().is_empty():
        push_error("[GSS] The .txt file is empty or could not be read.")
        return

    print("[GSS] Processing file: ", txt_file_path)
    print("[GSS] File content length: ", raw_gss.length())

    var parse_result: Dictionary = GSSParser.parse_stylesheet(raw_gss)

    # La única y correcta comprobación de errores.
    if not parse_result.errors.is_empty():
        push_error("[GSS] Errors found in file. Theme generation stopped. See details in Output.")
        for error_message in parse_result.errors:
            print("[GSS Validation Error] ", error_message)
        return

    # Obtenemos los datos de parseo de la clave 'data'.
    var parsed_data: Dictionary = parse_result.data

    print("GSS Parsed successfully: ", parsed_data)

    # Si parsed_data está vacío, significa que no se encontraron estilos válidos.
    if parsed_data.is_empty():
        push_warning("[GSS] No valid styles were found in the file. Theme not generated.")
        return

    var new_theme: Theme = GSSThemer.create_theme_from_styles(parsed_data)

    var save_path := output_dir.path_join(user_theme_name)

    var result := ResourceSaver.save(new_theme, save_path)

    if result == OK:
        print("Theme saved successfully at: ", save_path)
    else:
        push_error("[GSS] Error saving theme at: " + save_path)
