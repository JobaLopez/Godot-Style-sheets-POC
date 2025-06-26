## Validates GSS properties and values.
class_name GSSValidator

## Dictionary defining all valid properties and their expected value types.
const VALID_PROPERTIES: Dictionary = {
    "background-color": "color",
    "background-colour": "color",
    "font-color": "color",
    "color": "color",
    "font-size": "size",
    "border-color": "color",
    "border-colour": "color",
    "border-top": "size",
    "border-right": "size",
    "border-bottom": "size",
    "border-left": "size",
    "border": "border_shorthand",
    "border-radius": "size_shorthand",
    "corner-radius": "size_shorthand",
    "shadow": "shadow_shorthand",
    "padding": "size_shorthand",
    "content-margin": "size_shorthand"
}

## Checks if a property exists in our dictionary.
static func is_property_valid(property: String) -> bool:
    return property in VALID_PROPERTIES

## Main validation function. Delegates to more specific functions.
static func is_value_valid_for_property(property: String, value: String) -> bool:
    if not is_property_valid(property):
        return false

    var value_type: String = VALID_PROPERTIES[property]
    match value_type:
        "color":
            return _is_valid_color(value)
        "size":
            return _is_valid_pixel_size(value)
        "size_shorthand":
            var parts = value.split(" ", false)
            for part in parts:
                if not _is_valid_pixel_size(part):
                    return false
            return true
        "border_shorthand", "shadow_shorthand":
            return true
        _:
            return false

static func _is_valid_pixel_size(value: String) -> bool:
    if not value.ends_with("px"):
        return false
    var number_part = value.trim_suffix("px")
    return number_part.is_valid_int()

static func _is_valid_color(value: String) -> bool:
    if value.begins_with("#"):
        var hex = value.substr(1)
        return hex.is_valid_hex_number() and (hex.length() == 6 or hex.length() == 8)
    if value.begins_with("rgb"):
        var components_str = value.get_slice("(", 1).get_slice(")", 0)
        if components_str.is_empty():
            return false
        var components = components_str.split(",")
        if components.size() < 3 or components.size() > 4:
            return false
        for component in components:
            if not component.strip_edges().is_valid_float():
                return false
        return true
    return Color.from_string(value, Color(-1, -1, -1)) != Color(-1, -1, -1)
