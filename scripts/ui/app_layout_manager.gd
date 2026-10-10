class_name AppLayoutManager
extends RefCounted

## Fluid Tween Layout Transition Manager for Hashcat Intelligence Studio.
## Provides modern, gentle, seamless transitions between:
## - 🛠️ SETUP WORKSPACE (Inputs, Presets, Rules, Flags)
## - 🎛️ LIVE COCKPIT (Maximized Graph, Real-Time Hashrate, Telemetry & Cracked Matches)

enum ViewMode { SETUP, COCKPIT }

var _current_mode: ViewMode = ViewMode.SETUP
var _main_ui: Control = null
var _main_split: Control = null
var _bottom_deck: Control = null
var _tab_container: TabContainer = null
var _btn_start: Button = null
var _btn_stop: Button = null
var _btn_view_setup: Button = null
var _btn_view_cockpit: Button = null

func init(main_ui: Control, main_split: Control, bottom_deck: Control, tab_container: TabContainer, btn_start: Button, btn_stop: Button, btn_view_setup: Button, btn_view_cockpit: Button) -> void:
	_main_ui = main_ui
	_main_split = main_split
	_bottom_deck = bottom_deck
	_tab_container = tab_container
	_btn_start = btn_start
	_btn_stop = btn_stop
	_btn_view_setup = btn_view_setup
	_btn_view_cockpit = btn_view_cockpit
	_update_nav_button_styles()

func get_current_mode() -> ViewMode:
	return _current_mode

## Smoothly transitions to Live Cockpit Mode (Real-Time Monitoring)
func switch_to_cockpit(animate: bool = true) -> void:
	if _current_mode == ViewMode.COCKPIT:
		return
	_current_mode = ViewMode.COCKPIT
	_update_nav_button_styles()

	if not animate or _main_ui == null:
		if _main_split != null:
			_main_split.visible = false
			_main_split.modulate.a = 0.0
		if _tab_container != null and _tab_container.current_tab == 2:
			_tab_container.current_tab = 0
		return

	var tween: Tween = _main_ui.create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _main_split != null:
		tween.tween_property(_main_split, "modulate:a", 0.0, 0.25)
	if _bottom_deck != null:
		_bottom_deck.modulate.a = 0.8
		tween.tween_property(_bottom_deck, "modulate:a", 1.0, 0.3)
	tween.chain().tween_callback(func():
		if _main_split != null and _current_mode == ViewMode.COCKPIT:
			_main_split.visible = false
		if _tab_container != null and _tab_container.current_tab == 2:
			_tab_container.current_tab = 0
	)

## Smoothly transitions back to Setup Workspace Mode
func switch_to_setup(animate: bool = true) -> void:
	if _current_mode == ViewMode.SETUP:
		return
	_current_mode = ViewMode.SETUP
	_update_nav_button_styles()

	if _main_split != null:
		_main_split.visible = true

	if not animate or _main_ui == null:
		if _main_split != null:
			_main_split.modulate.a = 1.0
		return

	var tween: Tween = _main_ui.create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _main_split != null:
		_main_split.modulate.a = 0.0
		tween.tween_property(_main_split, "modulate:a", 1.0, 0.3)

## Gentle button click scale feedback
func pulse_button(btn: Button) -> void:
	if btn == null or _main_ui == null:
		return
	btn.pivot_offset = btn.size / 2.0
	var tween: Tween = _main_ui.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.12)

func _update_nav_button_styles() -> void:
	if _btn_view_setup != null:
		if _current_mode == ViewMode.SETUP:
			_btn_view_setup.add_theme_color_override("font_color", ThemeBuilder.COLOR_ACCENT_GREEN)
		else:
			_btn_view_setup.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_MUTED)
	if _btn_view_cockpit != null:
		if _current_mode == ViewMode.COCKPIT:
			_btn_view_cockpit.add_theme_color_override("font_color", ThemeBuilder.COLOR_ACCENT_GREEN)
		else:
			_btn_view_cockpit.add_theme_color_override("font_color", ThemeBuilder.COLOR_TEXT_MUTED)
