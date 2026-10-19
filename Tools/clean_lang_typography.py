import unreal
from editor_toolset.toolsets.blueprint import BlueprintTools

bp = unreal.load_object(None, "/Game/WBP_SettingsMenu.WBP_SettingsMenu")
graph = unreal.load_object(None, "/Game/WBP_SettingsMenu.WBP_SettingsMenu:EventGraph")

updated = 0
for n in BlueprintTools.find_nodes(graph):
    for p in n.list_all_pins():
        if str(p.get_pin_name()) == "InText":
            val = p.get_pin_value()
            if "🌐" in str(val) or "🇧🇬" in str(val) or "🇬🇧" in str(val):
                if "BG" in str(val):
                    p.set_pin_value("[ ЕЗИК: БЪЛГАРСКИ (BG) ]")
                    print(f"Updated BG Lang text on {n.get_name()}")
                    updated += 1
                elif "EN" in str(val):
                    p.set_pin_value("[ LANG: ENGLISH (EN) ]")
                    print(f"Updated EN Lang text on {n.get_name()}")
                    updated += 1

# Also update the default text on the widget itself
w = unreal.load_object(None, "/Game/WBP_SettingsMenu.WBP_SettingsMenu:WidgetTree.Btn_LangToggle_Text")
if w:
    w.set_editor_property("Text", unreal.Text("[ ЕЗИК: БЪЛГАРСКИ (BG) ]"))
    print("Updated widget default text to clean typography")

unreal.BlueprintEditorLibrary.compile_blueprint(bp)
unreal.EditorAssetLibrary.save_loaded_asset(bp)
print(f"Updated {updated} pins, status: {bp.get_editor_property('status')}")
