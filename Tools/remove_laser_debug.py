import unreal
from editor_toolset.toolsets.blueprint import BlueprintTools

bp = unreal.load_object(None, '/Game/BP_operator.BP_operator')
graph = unreal.load_object(None, '/Game/BP_operator.BP_operator:EventGraph')

count = 0
for n in BlueprintTools.find_nodes(graph):
    ni = BlueprintTools._get_node_info(n)
    if 'LineTrace' in ni.type_id:
        for p in n.list_all_pins():
            if str(p.get_pin_name()) == 'DrawDebugType':
                old_val = p.get_pin_value()
                p.set_pin_value('None')
                print(f"Set DrawDebugType on {n.get_name()} from '{old_val}' to '{p.get_pin_value()}'")
                count += 1

print(f"Updated {count} LineTrace nodes to DrawDebugType = 'None' (Laser completely removed).")

# Compile BP_operator
unreal.EditorAssetLibrary.save_loaded_asset(bp)
print("Saved BP_operator asset.")
