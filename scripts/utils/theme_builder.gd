class_name ThemeBuilder
extends RefCounted

## Professional Cyberpunk Obsidian / Emerald Studio Theme Builder for Godot 4.
## Clean, sharp, high-legibility desktop UI inspired by high-end developer tools.
## Palette: Deep Obsidian (#0B0F19), Slate Surface (#111827), Sub-pixel Borders (#1E293B / #263346),
## Vibrant Emerald (#10B981), Electric Cyan (#06B6D4), Warning Amber (#F59E0B), Crimson (#EF4444).

const COLOR_BG_DARK       = Color("#0B0F19") # Deep Obsidian Void
const COLOR_PANEL_BG      = Color("#111827") # Dark Slate / Card Surface
const COLOR_PANEL_BORDER  = Color("#1F2937") # Structural Sub-pixel Border
const COLOR_PANEL_BORDER_LIGHT = Color("#334155") # Interactive Border
const COLOR_CARD_BG       = Color("#162032") # Elevated Inset Card Surface
const COLOR_BUTTON_BG     = Color("#1E293B") # Slate 800 Interactive Button
const COLOR_BUTTON_HOVER  = Color("#2D3B55") # Hover Highlight
const COLOR_ACCENT_GREEN  = Color("#10B981") # Cyber Emerald 500
const COLOR_ACCENT_CYAN   = Color("#06B6D4") # Electric Cyan 500
const COLOR_ACCENT_AMBER  = Color("#F59E0B") # Warning Amber 500
const COLOR_ACCENT_RED    = Color("#EF4444") # Crimson Red 500
const COLOR_TEXT_MAIN     = Color("#F8FAFC") # Crisp Slate 50 Typography
const COLOR_TEXT_MUTED    = Color("#94A3B8") # Cool Slate 400 Secondary Text

static func apply_cyberpunk_theme(root_control: Control = null) -> Theme:
	var custom_theme: Theme = Theme.new()
	_apply_base_colors(custom_theme)
	_apply_panel_styles(custom_theme)
	_apply_button_styles(custom_theme)
	_apply_line_edit_styles(custom_theme)
	_apply_scroll_styles(custom_theme)
	_apply_tab_styles(custom_theme)
	_apply_popup_styles(custom_theme)
	_apply_tree_styles(custom_theme)
	_apply_separator_styles(custom_theme)
	_apply_progress_styles(custom_theme)

	if root_control != null:
		root_control.theme = custom_theme
	return custom_theme

static func _apply_base_colors(t: Theme) -> void:
	t.set_color("font_color", "Label", COLOR_TEXT_MAIN)
	t.set_color("font_color", "Button", COLOR_TEXT_MAIN)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", COLOR_ACCENT_GREEN)
	t.set_color("font_disabled_color", "Button", Color(COLOR_TEXT_MUTED, 0.5))
	t.set_color("font_color", "LineEdit", COLOR_TEXT_MAIN)
	t.set_color("font_placeholder_color", "LineEdit", COLOR_TEXT_MUTED)
	t.set_color("font_color", "TextEdit", COLOR_TEXT_MAIN)
	t.set_color("font_color", "CheckBox", COLOR_TEXT_MAIN)
	t.set_color("font_pressed_color", "CheckBox", COLOR_ACCENT_GREEN)

# Modern rounded cards with crisp borders and subtle soft drop-shadow
static func _apply_panel_styles(t: Theme) -> void:
	var style_panel: StyleBoxFlat = StyleBoxFlat.new()
	style_panel.bg_color = COLOR_PANEL_BG
	style_panel.set_corner_radius_all(10)
	style_panel.border_width_left = 1
	style_panel.border_width_top = 1
	style_panel.border_width_right = 1
	style_panel.border_width_bottom = 1
	style_panel.border_color = COLOR_PANEL_BORDER
	style_panel.shadow_color = Color(0, 0, 0, 0.35)
	style_panel.shadow_size = 6
	style_panel.shadow_offset = Vector2(0, 3)
	style_panel.set_content_margin_all(10.0)

	t.set_stylebox("panel", "Panel", style_panel)
	t.set_stylebox("panel", "PanelContainer", style_panel)
	t.set_stylebox("panel", "PopupPanel", style_panel)

# Modern rounded buttons with hover/pressed states and clean focus
static func _apply_button_styles(t: Theme) -> void:
	var style_btn_normal: StyleBoxFlat = StyleBoxFlat.new()
	style_btn_normal.bg_color = COLOR_BUTTON_BG
	style_btn_normal.set_corner_radius_all(8)
	style_btn_normal.border_width_left = 1
	style_btn_normal.border_width_top = 1
	style_btn_normal.border_width_right = 1
	style_btn_normal.border_width_bottom = 1
	style_btn_normal.border_color = COLOR_PANEL_BORDER_LIGHT
	style_btn_normal.content_margin_left = 12
	style_btn_normal.content_margin_right = 12
	style_btn_normal.content_margin_top = 7
	style_btn_normal.content_margin_bottom = 7

	var style_btn_hover: StyleBoxFlat = style_btn_normal.duplicate() as StyleBoxFlat
	style_btn_hover.bg_color = COLOR_BUTTON_HOVER
	style_btn_hover.border_color = Color("#475569")
	style_btn_hover.shadow_color = Color(0, 0, 0, 0.2)
	style_btn_hover.shadow_size = 4

	var style_btn_pressed: StyleBoxFlat = style_btn_normal.duplicate() as StyleBoxFlat
	style_btn_pressed.bg_color = Color("#0F172A")
	style_btn_pressed.border_color = COLOR_ACCENT_GREEN

	var style_btn_disabled: StyleBoxFlat = style_btn_normal.duplicate() as StyleBoxFlat
	style_btn_disabled.bg_color = Color(COLOR_BUTTON_BG, 0.4)
	style_btn_disabled.border_color = Color(COLOR_PANEL_BORDER, 0.4)

	t.set_stylebox("normal", "Button", style_btn_normal)
	t.set_stylebox("hover", "Button", style_btn_hover)
	t.set_stylebox("pressed", "Button", style_btn_pressed)
	t.set_stylebox("disabled", "Button", style_btn_disabled)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	t.set_stylebox("normal", "OptionButton", style_btn_normal)
	t.set_stylebox("hover", "OptionButton", style_btn_hover)
	t.set_stylebox("pressed", "OptionButton", style_btn_pressed)
	t.set_stylebox("disabled", "OptionButton", style_btn_disabled)
	t.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())

# Modern rounded input fields with glowing Emerald focus border
static func _apply_line_edit_styles(t: Theme) -> void:
	var style_input: StyleBoxFlat = StyleBoxFlat.new()
	style_input.bg_color = Color("#070B12") # Inset deep dark
	style_input.set_corner_radius_all(6)
	style_input.border_width_left = 1
	style_input.border_width_top = 1
	style_input.border_width_right = 1
	style_input.border_width_bottom = 1
	style_input.border_color = COLOR_PANEL_BORDER_LIGHT
	style_input.content_margin_left = 10
	style_input.content_margin_right = 10
	style_input.content_margin_top = 7
	style_input.content_margin_bottom = 7

	var style_input_focus: StyleBoxFlat = style_input.duplicate() as StyleBoxFlat
	style_input_focus.border_color = COLOR_ACCENT_GREEN
	style_input_focus.shadow_color = Color(COLOR_ACCENT_GREEN, 0.25)
	style_input_focus.shadow_size = 5

	var style_input_readonly: StyleBoxFlat = style_input.duplicate() as StyleBoxFlat
	style_input_readonly.bg_color = Color("#070B12", 0.7)
	style_input_readonly.border_color = Color(COLOR_PANEL_BORDER, 0.6)

	t.set_stylebox("normal", "LineEdit", style_input)
	t.set_stylebox("focus", "LineEdit", style_input_focus)
	t.set_stylebox("read_only", "LineEdit", style_input_readonly)

	t.set_stylebox("normal", "TextEdit", style_input)
	t.set_stylebox("focus", "TextEdit", style_input_focus)
	t.set_stylebox("read_only", "TextEdit", style_input_readonly)

	# Clean terminal RichTextLabel
	var sb_rtl: StyleBoxFlat = StyleBoxFlat.new()
	sb_rtl.bg_color = Color("#070B12")
	sb_rtl.set_corner_radius_all(6)
	sb_rtl.set_border_width_all(1)
	sb_rtl.border_color = COLOR_PANEL_BORDER
	sb_rtl.set_content_margin_all(8.0)
	t.set_stylebox("normal", "RichTextLabel", sb_rtl)
	t.set_stylebox("focus", "RichTextLabel", StyleBoxEmpty.new())

# Minimalist scrollbars
static func _apply_scroll_styles(t: Theme) -> void:
	var style_grabber: StyleBoxFlat = StyleBoxFlat.new()
	style_grabber.bg_color = Color("#334155")
	style_grabber.set_corner_radius_all(4)

	var style_grabber_hl: StyleBoxFlat = style_grabber.duplicate() as StyleBoxFlat
	style_grabber_hl.bg_color = COLOR_ACCENT_GREEN

	t.set_stylebox("grabber", "VScrollBar", style_grabber)
	t.set_stylebox("grabber_highlight", "VScrollBar", style_grabber_hl)
	t.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	t.set_stylebox("grabber", "HScrollBar", style_grabber)
	t.set_stylebox("grabber_highlight", "HScrollBar", style_grabber_hl)
	t.set_stylebox("scroll", "HScrollBar", StyleBoxEmpty.new())
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

# Modern TabContainer styling: Sleek active pill with bottom emerald highlight
static func _apply_tab_styles(t: Theme) -> void:
	var sb_tab_selected: StyleBoxFlat = StyleBoxFlat.new()
	sb_tab_selected.bg_color = COLOR_PANEL_BG
	sb_tab_selected.set_corner_radius_all(6)
	sb_tab_selected.border_width_bottom = 2
	sb_tab_selected.border_color = COLOR_ACCENT_GREEN
	sb_tab_selected.content_margin_left = 14
	sb_tab_selected.content_margin_right = 14
	sb_tab_selected.content_margin_top = 7
	sb_tab_selected.content_margin_bottom = 7
	t.set_stylebox("tab_selected", "TabContainer", sb_tab_selected)

	var sb_tab_hovered: StyleBoxFlat = sb_tab_selected.duplicate() as StyleBoxFlat
	sb_tab_hovered.bg_color = COLOR_BUTTON_HOVER
	sb_tab_hovered.border_color = Color.WHITE
	t.set_stylebox("tab_hovered", "TabContainer", sb_tab_hovered)

	var sb_tab_unselected: StyleBoxFlat = StyleBoxFlat.new()
	sb_tab_unselected.bg_color = Color("#070B12")
	sb_tab_unselected.set_corner_radius_all(6)
	sb_tab_unselected.content_margin_left = 14
	sb_tab_unselected.content_margin_right = 14
	sb_tab_unselected.content_margin_top = 7
	sb_tab_unselected.content_margin_bottom = 7
	t.set_stylebox("tab_unselected", "TabContainer", sb_tab_unselected)

	var sb_tab_disabled: StyleBoxFlat = sb_tab_unselected.duplicate() as StyleBoxFlat
	sb_tab_disabled.bg_color = Color(COLOR_BG_DARK, 0.4)
	t.set_stylebox("tab_disabled", "TabContainer", sb_tab_disabled)

	t.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())

	# Tab body panel
	var sb_tab_panel: StyleBoxFlat = StyleBoxFlat.new()
	sb_tab_panel.bg_color = COLOR_PANEL_BG
	sb_tab_panel.set_corner_radius_all(8)
	sb_tab_panel.set_border_width_all(1)
	sb_tab_panel.border_color = COLOR_PANEL_BORDER
	sb_tab_panel.set_content_margin_all(8.0)
	t.set_stylebox("panel", "TabContainer", sb_tab_panel)

# Modern PopupMenu styling for OptionButton dropdowns
static func _apply_popup_styles(t: Theme) -> void:
	var sb_popup: StyleBoxFlat = StyleBoxFlat.new()
	sb_popup.bg_color = Color("#0F172A")
	sb_popup.set_corner_radius_all(8)
	sb_popup.set_border_width_all(1)
	sb_popup.border_color = COLOR_PANEL_BORDER_LIGHT
	sb_popup.shadow_color = Color(0, 0, 0, 0.5)
	sb_popup.shadow_size = 12
	sb_popup.set_content_margin_all(6.0)
	t.set_stylebox("panel", "PopupMenu", sb_popup)

	var sb_popup_hover: StyleBoxFlat = StyleBoxFlat.new()
	sb_popup_hover.bg_color = Color("#064E3B") # Emerald 900
	sb_popup_hover.set_corner_radius_all(4)
	sb_popup_hover.set_border_width_all(1)
	sb_popup_hover.border_color = COLOR_ACCENT_GREEN
	sb_popup_hover.set_content_margin_all(6.0)
	t.set_stylebox("hover", "PopupMenu", sb_popup_hover)

	t.set_color("font_color", "PopupMenu", COLOR_TEXT_MAIN)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_color("font_separator_color", "PopupMenu", COLOR_TEXT_MUTED)

# Modern Tree styling for Encyclopedia and catalogs
static func _apply_tree_styles(t: Theme) -> void:
	var sb_tree: StyleBoxFlat = StyleBoxFlat.new()
	sb_tree.bg_color = Color("#070B12")
	sb_tree.set_corner_radius_all(6)
	sb_tree.set_border_width_all(1)
	sb_tree.border_color = COLOR_PANEL_BORDER
	sb_tree.set_content_margin_all(6.0)
	t.set_stylebox("panel", "Tree", sb_tree)

	var sb_tree_selected: StyleBoxFlat = StyleBoxFlat.new()
	sb_tree_selected.bg_color = Color("#064E3B") # Emerald 900
	sb_tree_selected.set_corner_radius_all(4)
	sb_tree_selected.set_border_width_all(1)
	sb_tree_selected.border_color = COLOR_ACCENT_GREEN
	t.set_stylebox("selected", "Tree", sb_tree_selected)
	t.set_stylebox("selected_focus", "Tree", sb_tree_selected)

	t.set_stylebox("cursor", "Tree", StyleBoxEmpty.new())
	t.set_stylebox("cursor_unfocused", "Tree", StyleBoxEmpty.new())

	t.set_color("font_color", "Tree", COLOR_TEXT_MAIN)
	t.set_color("font_selected_color", "Tree", Color.WHITE)

# Modern separator styling
static func _apply_separator_styles(t: Theme) -> void:
	var sb_sep: StyleBoxLine = StyleBoxLine.new()
	sb_sep.color = COLOR_PANEL_BORDER
	sb_sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sb_sep)
	t.set_stylebox("separator", "VSeparator", sb_sep)

# Modern Progress Bar styling
static func _apply_progress_styles(t: Theme) -> void:
	var sb_bg: StyleBoxFlat = StyleBoxFlat.new()
	sb_bg.bg_color = Color("#070B12")
	sb_bg.set_corner_radius_all(4)
	sb_bg.set_border_width_all(1)
	sb_bg.border_color = COLOR_PANEL_BORDER

	var sb_fg: StyleBoxFlat = StyleBoxFlat.new()
	sb_fg.bg_color = COLOR_ACCENT_GREEN
	sb_fg.set_corner_radius_all(4)
	sb_fg.shadow_color = Color(COLOR_ACCENT_GREEN, 0.4)
	sb_fg.shadow_size = 4

	t.set_stylebox("background", "ProgressBar", sb_bg)
	t.set_stylebox("fill", "ProgressBar", sb_fg)

# High-Visibility Action Buttons with Glowing Cyberpunk Accents
static func style_action_buttons(btn_start: Button, btn_stop: Button, btn_emergency: Button, btn_benchmark: Button = null) -> void:
	if btn_start != null:
		var sb_start: StyleBoxFlat = StyleBoxFlat.new()
		sb_start.bg_color = Color("#047857") # Emerald 700
		sb_start.set_border_width_all(2)
		sb_start.border_color = COLOR_ACCENT_GREEN
		sb_start.set_corner_radius_all(8)
		sb_start.shadow_color = Color(COLOR_ACCENT_GREEN, 0.35)
		sb_start.shadow_size = 8
		sb_start.set_content_margin_all(9.0)
		btn_start.add_theme_stylebox_override("normal", sb_start)

		var sb_start_hover: StyleBoxFlat = sb_start.duplicate() as StyleBoxFlat
		sb_start_hover.bg_color = Color("#059669")
		sb_start_hover.border_color = Color.WHITE
		btn_start.add_theme_stylebox_override("hover", sb_start_hover)

	if btn_benchmark != null:
		var sb_bench: StyleBoxFlat = StyleBoxFlat.new()
		sb_bench.bg_color = Color("#0369A1") # Sky 700
		sb_bench.set_border_width_all(2)
		sb_bench.border_color = COLOR_ACCENT_CYAN
		sb_bench.set_corner_radius_all(8)
		sb_bench.shadow_color = Color(COLOR_ACCENT_CYAN, 0.3)
		sb_bench.shadow_size = 6
		sb_bench.set_content_margin_all(9.0)
		btn_benchmark.add_theme_stylebox_override("normal", sb_bench)

		var sb_bench_hover: StyleBoxFlat = sb_bench.duplicate() as StyleBoxFlat
		sb_bench_hover.bg_color = Color("#0284C7")
		sb_bench_hover.border_color = Color.WHITE
		btn_benchmark.add_theme_stylebox_override("hover", sb_bench_hover)

	if btn_stop != null:
		var sb_stop: StyleBoxFlat = StyleBoxFlat.new()
		sb_stop.bg_color = Color("#991B1B") # Red 800
		sb_stop.set_border_width_all(2)
		sb_stop.border_color = COLOR_ACCENT_RED
		sb_stop.set_corner_radius_all(8)
		sb_stop.set_content_margin_all(9.0)
		btn_stop.add_theme_stylebox_override("normal", sb_stop)

		var sb_stop_hover: StyleBoxFlat = sb_stop.duplicate() as StyleBoxFlat
		sb_stop_hover.bg_color = Color("#B91C1C")
		sb_stop_hover.border_color = Color.WHITE
		btn_stop.add_theme_stylebox_override("hover", sb_stop_hover)

	if btn_emergency != null:
		var sb_emergency: StyleBoxFlat = StyleBoxFlat.new()
		sb_emergency.bg_color = Color("#7F1D1D") # Deep Crimson
		sb_emergency.set_border_width_all(2)
		sb_emergency.border_color = COLOR_ACCENT_AMBER # Warning border
		sb_emergency.set_corner_radius_all(8)
		sb_emergency.set_content_margin_all(8.0)
		btn_emergency.add_theme_stylebox_override("normal", sb_emergency)

		var sb_emergency_hover: StyleBoxFlat = sb_emergency.duplicate() as StyleBoxFlat
		sb_emergency_hover.bg_color = Color("#DC2626")
		sb_emergency_hover.border_color = Color.WHITE
		btn_emergency.add_theme_stylebox_override("hover", sb_emergency_hover)

# Modern interactive preset quick-launch cards
static func style_preset_buttons(buttons: Array[Button]) -> void:
	for btn in buttons:
		if btn == null:
			continue
		var sb_norm: StyleBoxFlat = StyleBoxFlat.new()
		sb_norm.bg_color = Color("#131C2D")
		sb_norm.set_corner_radius_all(8)
		sb_norm.border_width_left = 3
		sb_norm.border_width_top = 1
		sb_norm.border_width_right = 1
		sb_norm.border_width_bottom = 1
		sb_norm.border_color = Color("#2A3C58")
		sb_norm.border_color = Color("#38BDF8") # Cyan left accent
		sb_norm.set_content_margin_all(8.0)
		btn.add_theme_stylebox_override("normal", sb_norm)

		var sb_hov: StyleBoxFlat = sb_norm.duplicate() as StyleBoxFlat
		sb_hov.bg_color = Color("#1D2B44")
		sb_hov.border_color = Color.WHITE
		btn.add_theme_stylebox_override("hover", sb_hov)

# Modern sidebar buttons with clean left indicator
static func style_sidebar_buttons(buttons: Array[Button], active_button: Button = null) -> void:
	for btn in buttons:
		if btn == null:
			continue
		var is_active: bool = (btn == active_button)
		var sb_norm: StyleBoxFlat = StyleBoxFlat.new()
		sb_norm.bg_color = Color("#162032") if is_active else Color("#0E1626")
		sb_norm.set_corner_radius_all(8)
		sb_norm.border_width_left = 3 if is_active else 1
		sb_norm.border_width_top = 1
		sb_norm.border_width_right = 1
		sb_norm.border_width_bottom = 1
		sb_norm.border_color = COLOR_ACCENT_GREEN if is_active else Color("#1E293B")
		sb_norm.content_margin_left = 12
		sb_norm.content_margin_right = 12
		sb_norm.content_margin_top = 7
		sb_norm.content_margin_bottom = 7
		btn.add_theme_stylebox_override("normal", sb_norm)

		var sb_hov: StyleBoxFlat = sb_norm.duplicate() as StyleBoxFlat
		sb_hov.bg_color = Color("#1E2C42")
		sb_hov.border_color = COLOR_ACCENT_GREEN
		btn.add_theme_stylebox_override("hover", sb_hov)
