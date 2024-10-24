class_name Debug

enum ColorRange {
	BlackWhite,
	RedBlue,
}

static func color_range(max, actual, range = ColorRange.BlackWhite) -> Color:
	var start_color: Color
	var end_color: Color
	
	match range:
		ColorRange.BlackWhite:
			start_color = Color.BLACK
			end_color = Color.WHITE
		ColorRange.RedBlue:
			start_color = Color.BLUE
			end_color = Color.RED
	return lerp(start_color, end_color, inverse_lerp(0, max, actual))
