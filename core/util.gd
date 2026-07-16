class_name Util


# For debug purposes
static func print_dictionary(dict : Dictionary) -> String:
	var formatted : String = "Formatted dictionary print:\n"

	for key in dict:
		formatted += "%s = %s\n" % [str(key), str(dict[key])]

	return formatted
