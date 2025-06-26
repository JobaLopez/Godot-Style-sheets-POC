class_name GSSParser

# Load the validator to use its static functions.
const GSSValidator = preload("res://addons/gss_plugin/GSSValidator.gd")

## Parses GSS text and returns a structured dictionary with styles and errors.
# The function now returns a dictionary with two keys:
# "data": Contains the valid styles.
# "errors": Contains a list of validation errors found.
static func parse_stylesheet(gss_text: String) -> Dictionary:
    var cleaned_gss: String = _remove_comments(gss_text)
    var sorted_rules: Array = _sort_rules(cleaned_gss)

    var styles: Dictionary = {}
    var errors: Array = [] # Array to store error messages.

    for elem: Array in sorted_rules:
        var selector: String = elem[0]
        var property_string: String = elem[1]
        var properties: Array = property_string.split(";", false)
        var property_list: Array = []

        for style: String in properties:
            if style.is_empty() or not ":" in style:
                continue
            
            var style_split: PackedStringArray = str(style).split(":", true, 1)
            var property: String = style_split[0].strip_edges().strip_escapes().to_lower()
            var pvalue: String = style_split[1].strip_edges().strip_escapes().to_lower()

            # --- START OF VALIDATION! ---
            # Check if the property and value are valid using GSSValidator.
            if GSSValidator.is_value_valid_for_property(property, pvalue):
                # If they are valid, add them to the selector's property list.
                property_list.append([property, pvalue])
            else:
                # If they are not valid, create an error message and add it to the error list.
                var error_message = "In selector '%s' -> Property '%s' or value '%s' invalid." % [selector, property, pvalue]
                errors.append(error_message)
            # --- END OF VALIDATION ---
        
        if not property_list.is_empty():
            styles[selector] = property_list
            
    # Return a dictionary that contains both styles and errors.
    return {
        "data": styles,
        "errors": errors
    }

static func _remove_comments(gss: String) -> String:
    var regex := RegEx.new()
    regex.compile("/\\*.*?\\*/")
    return regex.sub(gss, "", true)

static func _sort_rules(gss: String) -> Array:
    var regex_rule := "([#.a-zA-Z\\d0-9-:]+\\s*){([\\sa-z-:;0-9#\\(\\),-\\\\]*)}"
    var regex := RegEx.new()
    regex.compile(regex_rule)
    
    var rule_arr: Array = []
    var matched_arr: Array[RegExMatch] = regex.search_all(gss)
    
    for match in matched_arr:
        rule_arr.append([
            match.get_string(1).strip_edges(),
            match.get_string(2).strip_escapes().strip_edges()
        ])
        
    return rule_arr