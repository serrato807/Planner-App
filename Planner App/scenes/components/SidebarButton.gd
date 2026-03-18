extends Button

var is_active: bool = false:
	set(value):
		is_active = value
		if is_node_ready():
			_apply_style()

func _ready() -> void:
	custom_minimum_size = Vector2(176, 40)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flat = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_constant_override("h_separation", 0)
	add_theme_font_size_override("font_size", 14)
	_apply_style()

func _apply_style() -> void:
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if is_active:
		add_theme_color_override("font_color", ThemeManager.ACCENT)
		# Rounded pill background with left accent bar
		var sb := StyleBoxFlat.new()
		sb.bg_color = ThemeManager.ACCENT_LIGHT
		sb.border_color = ThemeManager.ACCENT
		sb.border_width_left   = 3
		sb.border_width_right  = 0
		sb.border_width_top    = 0
		sb.border_width_bottom = 0
		sb.corner_radius_top_left     = 0
		sb.corner_radius_bottom_left  = 0
		sb.corner_radius_top_right    = ThemeManager.RADIUS_SM
		sb.corner_radius_bottom_right = ThemeManager.RADIUS_SM
		sb.content_margin_left   = 16.0
		sb.content_margin_right  = 12.0
		sb.content_margin_top    = 10.0
		sb.content_margin_bottom = 10.0
		add_theme_stylebox_override("normal",  sb)
		add_theme_stylebox_override("hover",   sb)
		add_theme_stylebox_override("pressed", sb)
	else:
		add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)
		var sb_normal := StyleBoxFlat.new()
		sb_normal.bg_color = Color(0, 0, 0, 0)
		sb_normal.set_border_width_all(0)
		sb_normal.set_corner_radius_all(ThemeManager.RADIUS_SM)
		sb_normal.content_margin_left   = 16.0
		sb_normal.content_margin_right  = 12.0
		sb_normal.content_margin_top    = 10.0
		sb_normal.content_margin_bottom = 10.0
		add_theme_stylebox_override("normal", sb_normal)
		var sb_hover := StyleBoxFlat.new()
		sb_hover.bg_color = ThemeManager.BORDER
		sb_hover.set_border_width_all(0)
		sb_hover.set_corner_radius_all(ThemeManager.RADIUS_SM)
		sb_hover.content_margin_left   = 16.0
		sb_hover.content_margin_right  = 12.0
		sb_hover.content_margin_top    = 10.0
		sb_hover.content_margin_bottom = 10.0
		add_theme_stylebox_override("hover",   sb_hover)
		add_theme_stylebox_override("pressed", sb_hover)
