class_name GSSThemer

## Creates a Theme resource from parsed GSS stylesheet data.
static func create_theme_from_styles(stylesheet: Dictionary) -> Theme:
    var theme := Theme.new()
    var selectors: Array = stylesheet.keys()

    for selector: String in selectors:
        var properties: Array = stylesheet[selector]
        var stylebox_current := StyleBoxFlat.new()
        
        match selector.to_lower():
            "button":
                if theme.has_stylebox("normal", "Button"): stylebox_current = theme.get_stylebox("normal", "Button").duplicate()
                theme.set_stylebox("normal", "Button", _create_styleboxflat(properties, stylebox_current))
                _apply_font_styles(theme, "Button", "normal", properties)

            "button:hover":
                if theme.has_stylebox("hover", "Button"): stylebox_current = theme.get_stylebox("hover", "Button").duplicate()
                theme.set_stylebox("hover", "Button", _create_styleboxflat(properties, stylebox_current))
                _apply_font_styles(theme, "Button", "hover", properties)

            "button:pressed":
                if theme.has_stylebox("pressed", "Button"): stylebox_current = theme.get_stylebox("pressed", "Button").duplicate()
                theme.set_stylebox("pressed", "Button", _create_styleboxflat(properties, stylebox_current))
                _apply_font_styles(theme, "Button", "pressed", properties)

            "button:disabled":
                if theme.has_stylebox("disabled", "Button"): stylebox_current = theme.get_stylebox("disabled", "Button").duplicate()
                theme.set_stylebox("disabled", "Button", _create_styleboxflat(properties, stylebox_current))
                _apply_font_styles(theme, "Button", "disabled", properties)
            
            "button:focus":
                if theme.has_stylebox("focus", "Button"): stylebox_current = theme.get_stylebox("focus", "Button").duplicate()
                theme.set_stylebox("focus", "Button", _create_styleboxflat(properties, stylebox_current))
                _apply_font_styles(theme, "Button", "focus", properties)

    return theme

## Applies font styles (color, size) to a control type and state.
static func _apply_font_styles(theme: Theme, type: String, state: String, properties: Array):
    var color_prop := _property_list_get(properties, "font-color", "color")
    if not color_prop.is_empty():
        var color_state_name := "font_%s_color" % state
        if state == "normal": color_state_name = "font_color"
        
        if theme.has_color(color_state_name, type):
            theme.set_color(color_state_name, type, _set_valid_colour(color_prop))

    var size_prop := _property_list_get(properties, "font-size")
    if not size_prop.is_empty():
        if theme.has_font_size("font_size", type):
            theme.set_font_size("font_size", type, int(size_prop.trim_suffix("px")))

## Creates and configures a StyleBoxFlat from a property list.
static func _create_styleboxflat(styling: Array, stylebox: StyleBoxFlat = StyleBoxFlat.new()) -> StyleBoxFlat:
    for style: Array in styling:
        var property: String = style[0]
        var pvalue: String = style[1]
        match property:
            "background-color", "background-colour": stylebox.bg_color = _set_valid_colour(pvalue)
            "border-color", "border-colour": _set_border_colour(stylebox, pvalue)
            "border-top": stylebox.border_width_top = _set_valid_width(pvalue)
            "border-right": stylebox.border_width_right = _set_valid_width(pvalue)
            "border-bottom": stylebox.border_width_bottom = _set_valid_width(pvalue)
            "border-left": stylebox.border_width_left = _set_valid_width(pvalue)
            "border": _apply_border(stylebox, pvalue)
            "border-top-left-radius": stylebox.corner_radius_top_left = _set_valid_radius(pvalue)
            "border-top-right-radius": stylebox.corner_radius_top_right = _set_valid_radius(pvalue)
            "border-bottom-right-radius": stylebox.corner_radius_bottom_right = _set_valid_radius(pvalue)
            "border-bottom-left-radius": stylebox.corner_radius_bottom_left = _set_valid_radius(pvalue)
            "border-radius", "corner-radius": _apply_radius(stylebox, pvalue)
            "shadow": _apply_shadow(stylebox, pvalue)
            "padding", "content-margin": _apply_padding(stylebox, pvalue)
    return stylebox

static func _apply_border(stylebox: StyleBoxFlat, values: String) -> void:
    var arr: Array = values.split(" ", false)
    if arr.size() == 0 or arr.size() > 4: return
    if arr.size() >= 1: stylebox.border_width_top = _set_valid_width(arr[0])
    if arr.size() >= 2: stylebox.border_width_right = _set_valid_width(arr[1])
    if arr.size() >= 3: stylebox.border_width_bottom = _set_valid_width(arr[2])
    if arr.size() == 4: stylebox.border_width_left = _set_valid_width(arr[3])
    # CSS shorthand logic
    if arr.size() == 1:
        stylebox.border_width_right = stylebox.border_width_top
        stylebox.border_width_bottom = stylebox.border_width_top
        stylebox.border_width_left = stylebox.border_width_top
    if arr.size() == 2:
        stylebox.border_width_bottom = stylebox.border_width_top
        stylebox.border_width_left = stylebox.border_width_right
    if arr.size() == 3:
        stylebox.border_width_left = stylebox.border_width_right

static func _set_valid_width(size: String) -> int:
    if size.ends_with("px"): return int(size.trim_suffix("px"))
    return 0

static func _set_border_colour(stylebox: StyleBoxFlat, values: String) -> void:
    var arr: Array = values.split(" ", false)
    if arr.size() > 0: stylebox.border_color = _set_valid_colour(arr[0])
    if arr.size() > 1 and str(arr[1]).to_lower() == "blend":
        stylebox.border_blend = true
    else:
        stylebox.border_blend = false

static func _apply_radius(stylebox: StyleBoxFlat, values: String) -> void:
    var arr: Array = values.split(" ", false)
    if arr.size() == 0 or arr.size() > 4: return
    if arr.size() >= 1: stylebox.corner_radius_top_left = _set_valid_radius(arr[0])
    if arr.size() >= 2: stylebox.corner_radius_top_right = _set_valid_radius(arr[1])
    if arr.size() >= 3: stylebox.corner_radius_bottom_right = _set_valid_radius(arr[2])
    if arr.size() == 4: stylebox.corner_radius_bottom_left = _set_valid_radius(arr[3])
    # CSS shorthand logic
    if arr.size() == 1:
        stylebox.set_corner_radius_all(stylebox.corner_radius_top_left)
    if arr.size() == 2:
        stylebox.corner_radius_bottom_right = stylebox.corner_radius_top_left
        var radius_val := _set_valid_radius(arr[1])
        stylebox.corner_radius_top_right = radius_val
        stylebox.corner_radius_bottom_left = radius_val
    if arr.size() == 3:
        stylebox.corner_radius_bottom_left = stylebox.corner_radius_top_right

static func _set_valid_radius(size: String) -> int:
    if size.ends_with("px"): return int(size.trim_suffix("px"))
    return 0

static func _apply_shadow(stylebox: StyleBoxFlat, values: String) -> void:
    var vals: PackedStringArray = values.split(" ")
    if vals.size() == 0: return
    if vals.size() >= 1: stylebox.shadow_color = _set_valid_colour(vals[0])
    if vals.size() >= 2: stylebox.shadow_size = _set_valid_width(vals[1])
    if vals.size() >= 3: stylebox.shadow_offset.x = _set_valid_offset(vals[2])
    if vals.size() >= 4: stylebox.shadow_offset.y = _set_valid_offset(vals[3])

static func _set_valid_offset(size: String) -> float:
    if size.ends_with("px"): return float(size.trim_suffix("px"))
    return 0.0

static func _apply_padding(stylebox: StyleBoxFlat, values: String) -> void:
    var arr: Array = values.split(" ", false)
    if arr.size() == 0 or arr.size() > 4: return
    if arr.size() >= 1: stylebox.content_margin_top = _set_valid_width(arr[0])
    if arr.size() >= 2: stylebox.content_margin_right = _set_valid_width(arr[1])
    if arr.size() >= 3: stylebox.content_margin_bottom = _set_valid_width(arr[2])
    if arr.size() == 4: stylebox.content_margin_left = _set_valid_width(arr[3])
    # CSS shorthand logic
    if arr.size() == 1:
        stylebox.content_margin_right = stylebox.content_margin_top
        stylebox.content_margin_bottom = stylebox.content_margin_top
        stylebox.content_margin_left = stylebox.content_margin_top
    if arr.size() == 2:
        stylebox.content_margin_bottom = stylebox.content_margin_top
        stylebox.content_margin_left = stylebox.content_margin_right
    if arr.size() == 3:
        stylebox.content_margin_left = stylebox.content_margin_right

static func _set_valid_colour(colour: String) -> Color:
    var named_color := Color.from_string(colour, Color.BLACK)
    if named_color != Color.BLACK or colour.to_lower() == "black":
        return named_color

    # Handle rgb() and rgba() functions
    var clean_str := colour.to_lower().replace(" ", "").trim_prefix("rgba").trim_prefix("rgb").trim_prefix("(").trim_suffix(")")
    var parts := clean_str.split(",")
    if parts.size() < 3: return Color.MAGENTA

    var r := float(parts[0]) / 255.0
    var g := float(parts[1]) / 255.0
    var b := float(parts[2]) / 255.0
    var a := 1.0
    if parts.size() == 4:
        a = float(parts[3])

    return Color(r, g, b, a)

## Searches for a property in a list. Allows an alternate name.
static func _property_list_get(list: Array, item: String, alternate_item: String = "") -> String:
    for i: Array in list:
        if i[0] == item: return i[1]
        if not alternate_item.is_empty() and i[0] == alternate_item: return i[1]
    return ""