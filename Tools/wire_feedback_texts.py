import unreal
from editor_toolset.toolsets.blueprint import BlueprintTools

bp = unreal.load_object(None, '/Game/WBP_SettingsMenu.WBP_SettingsMenu')
graph = unreal.load_object(None, '/Game/WBP_SettingsMenu.WBP_SettingsMenu:EventGraph')
bp_editor = unreal.BlueprintGraphEditor.get_graph_editor(graph)

def get_pin(node, name, direction=None):
    for p in node.list_all_pins():
        if str(p.get_pin_name()) == name:
            if direction is None or p.get_pin_direction() == direction:
                return p
    return None

def connect(node_a, pin_name_a, node_b, pin_name_b):
    pin_a = get_pin(node_a, pin_name_a, unreal.EdGraphPinDirection.EGPD_OUTPUT)
    pin_b = get_pin(node_b, pin_name_b, unreal.EdGraphPinDirection.EGPD_INPUT)
    if not pin_a or not pin_b:
        print(f"Error finding pins: {node_a.get_name()}:{pin_name_a} -> {node_b.get_name()}:{pin_name_b}")
        return False
    ok = pin_a.try_create_connection(pin_b)
    return ok

# Text labels mapping
scal_labels = {
    'Btn_ScalLow':  '» АКТИВЕН ПРЕСЕТ: LOW (НИСКО) [66% SCALE]',
    'Btn_ScalMed':  '» АКТИВЕН ПРЕСЕТ: MEDIUM (СРЕДНО) [75% SCALE]',
    'Btn_ScalHigh': '» АКТИВЕН ПРЕСЕТ: HIGH (ВИСОКО) [100% SCALE]',
    'Btn_ScalEpic': '» АКТИВЕН ПРЕСЕТ: EPIC (ЕПИЧНО) [MAX QUALITY]',
}

res_labels = {
    'Btn_Res1080':   '» АКТИВНА РЕЗОЛЮЦИЯ: 1920 x 1080 (FHD)',
    'Btn_Res1440':   '» АКТИВНА РЕЗОЛЮЦИЯ: 2560 x 1440 (2K)',
    'Btn_Res4K':     '» АКТИВНА РЕЗОЛЮЦИЯ: 3840 x 2160 (4K UHD)',
    'Btn_Res720':    '» АКТИВНА РЕЗОЛЮЦИЯ: 1280 x 720 (HD)',
    'Btn_Fullscreen':'» РЕЖИМ НА ЕКРАНА: ЦЯЛ ЕКРАН (FULLSCREEN)',
    'Btn_Windowed':  '» РЕЖИМ НА ЕКРАНА: В ПРОЗОРЕЦ (WINDOWED)',
}

# Find all events and trace their final node in the chain
for n in BlueprintTools.find_nodes(graph):
    ni = BlueprintTools._get_node_info(n)
    for bname, text_val in {**scal_labels, **res_labels}.items():
        if bname in ni.type_id:
            # Trace to the last node
            curr = n
            while True:
                p_then = get_pin(curr, 'then', unreal.EdGraphPinDirection.EGPD_OUTPUT)
                if p_then and p_then.list_connected_pins():
                    curr = p_then.list_connected_pins()[0].get_owning_node()
                else:
                    break
            
            # Now curr is the last node (e.g. ExecuteConsoleCommand)
            pos = BlueprintTools._get_node_info(curr).position
            x, y = int(pos.x) + 260, int(pos.y)
            
            # Create SetText node
            n_set_txt = bp_editor.create_node_from_name('Widget|SetText(Text)', unreal.Vector2D(x, y), [], None)
            p_intext = get_pin(n_set_txt, 'InText')
            if p_intext:
                p_intext.set_pin_value(text_val)
                
            # Get variable
            target_var = 'Txt_CurrentScal' if bname in scal_labels else 'Txt_CurrentRes'
            n_get_var = bp_editor.add_get_member_variable_node(target_var, '')
            
            connect(curr, 'then', n_set_txt, 'execute')
            connect(n_get_var, target_var, n_set_txt, 'self')
            print(f"Attached SetText to {bname}: {text_val}")

