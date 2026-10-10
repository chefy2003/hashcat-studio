#!/usr/bin/env python3
import re

# 1. Transform scenes/main.tscn
with open("scenes/main.tscn", "r", encoding="utf-8") as f:
    tscn = f.read()

# Fix MainUI grow direction:
tscn = re.sub(r'(\[node name="MainUI"[^\]]*\]\s*layout_mode = 3\s*anchors_preset = 15\s*anchor_right = 1\.0\s*anchor_bottom = 1\.0\s*)grow_horizontal = 2\s*grow_vertical = 2',
              r'\1grow_horizontal = 1\ngrow_vertical = 1', tscn)

# Fix VBox grow direction:
tscn = re.sub(r'(\[node name="VBox"[^\]]*\]\s*layout_mode = 1\s*anchors_preset = 15\s*anchor_right = 1\.0\s*anchor_bottom = 1\.0\s*)grow_horizontal = 2\s*grow_vertical = 2',
              r'\1grow_horizontal = 1\ngrow_vertical = 1', tscn)

# Add clip_text = true to Header buttons if not present
for btn_name in ["BtnViewSetup", "BtnViewCockpit", "BtnOpenFlagsGuide", "BtnLang", "BtnFullscreen", "BtnEmergency"]:
    pattern = rf'(\[node name="{btn_name}" type="Button" parent="VBox/Header/HBox"\]\s*layout_mode = 2\s*text = [^\n]+)'
    if re.search(pattern, tscn) and f'clip_text = true' not in tscn[tscn.find(f'name="{btn_name}"'):tscn.find(f'name="{btn_name}"') + 120]:
        tscn = re.sub(pattern, r'\1\nclip_text = true', tscn)

# Add clip_text = true to preset and browse buttons
for btn_name in ["BtnBrowseHash", "BtnQuickExample", "BtnBrowseWordlist", "BtnPresetMD5", "BtnPresetNTLM", "BtnPresetWPA2", "BtnPresetBcrypt"]:
    pattern = rf'(\[node name="{btn_name}" type="Button"[^\]]*\]\s*layout_mode = 2\s*text = [^\n]+)'
    if re.search(pattern, tscn):
        tscn = re.sub(pattern, r'\1\nclip_text = true', tscn)

# Add clip_text = true and fit_to_longest_item = false to OptionButtons
for opt_name in ["OptCategory", "OptAttackMode", "OptWorkload", "OptHashType"]:
    pattern = rf'(\[node name="{opt_name}" type="OptionButton"[^\]]*\]\s*layout_mode = 2[^\n]*)'
    tscn = re.sub(pattern, r'\1\nfit_to_longest_item = false', tscn)

# Transform Zone 1: wrap with Scroll1
zone1_old = '''[node name="Zone1_Left" type="PanelContainer" parent="VBox/WorkSplit/MainSplit"]
custom_minimum_size = Vector2(240, 0)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="VBox/WorkSplit/MainSplit/Zone1_Left"]'''

zone1_new = '''[node name="Zone1_Left" type="PanelContainer" parent="VBox/WorkSplit/MainSplit"]
custom_minimum_size = Vector2(260, 0)
layout_mode = 2

[node name="Scroll1" type="ScrollContainer" parent="VBox/WorkSplit/MainSplit/Zone1_Left"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
horizontal_scroll_mode = 0
vertical_scroll_mode = 1

[node name="VBox" type="VBoxContainer" parent="VBox/WorkSplit/MainSplit/Zone1_Left/Scroll1"]
size_flags_horizontal = 3'''

tscn = tscn.replace(zone1_old, zone1_new)
tscn = tscn.replace('parent="VBox/WorkSplit/MainSplit/Zone1_Left/VBox"', 'parent="VBox/WorkSplit/MainSplit/Zone1_Left/Scroll1/VBox"')
tscn = tscn.replace('parent="VBox/WorkSplit/MainSplit/Zone1_Left/VBox/', 'parent="VBox/WorkSplit/MainSplit/Zone1_Left/Scroll1/VBox/')

# Transform Zone 2: wrap with Scroll2
zone2_old = '''[node name="Zone2_Center" type="PanelContainer" parent="VBox/WorkSplit/MainSplit/CenterRightSplit"]
layout_mode = 2
size_flags_horizontal = 3

[node name="VBox" type="VBoxContainer" parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center"]'''

zone2_new = '''[node name="Zone2_Center" type="PanelContainer" parent="VBox/WorkSplit/MainSplit/CenterRightSplit"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Scroll2" type="ScrollContainer" parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
horizontal_scroll_mode = 0
vertical_scroll_mode = 1

[node name="VBox" type="VBoxContainer" parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/Scroll2"]
size_flags_horizontal = 3'''

tscn = tscn.replace(zone2_old, zone2_new)
tscn = tscn.replace('parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/VBox"', 'parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/Scroll2/VBox"')
tscn = tscn.replace('parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/VBox/', 'parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/Scroll2/VBox/')

# Transform Zone 3: wrap with Scroll3
zone3_old = '''[node name="Zone3_Right" type="PanelContainer" parent="VBox/WorkSplit/MainSplit/CenterRightSplit"]
custom_minimum_size = Vector2(260, 0)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right"]'''

zone3_new = '''[node name="Zone3_Right" type="PanelContainer" parent="VBox/WorkSplit/MainSplit/CenterRightSplit"]
custom_minimum_size = Vector2(280, 0)
layout_mode = 2

[node name="Scroll3" type="ScrollContainer" parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
horizontal_scroll_mode = 0
vertical_scroll_mode = 1

[node name="VBox" type="VBoxContainer" parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/Scroll3"]
size_flags_horizontal = 3'''

tscn = tscn.replace(zone3_old, zone3_new)
tscn = tscn.replace('parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/VBox"', 'parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/Scroll3/VBox"')
tscn = tscn.replace('parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/VBox/', 'parent="VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/Scroll3/VBox/')

with open("scenes/main.tscn", "w", encoding="utf-8") as f:
    f.write(tscn)
print("[OK] scenes/main.tscn updated.")

# 2. Transform scripts/ui/main_ui.gd
with open("scripts/ui/main_ui.gd", "r", encoding="utf-8") as f:
    gd = f.read()

gd = gd.replace("$VBox/WorkSplit/MainSplit/Zone1_Left/VBox/", "$VBox/WorkSplit/MainSplit/Zone1_Left/Scroll1/VBox/")
gd = gd.replace("$VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/VBox/", "$VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/Scroll2/VBox/")
gd = gd.replace("$VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/VBox/", "$VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/Scroll3/VBox/")

with open("scripts/ui/main_ui.gd", "w", encoding="utf-8") as f:
    f.write(gd)
print("[OK] scripts/ui/main_ui.gd updated.")
