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

# Map event nodes by button name
event_nodes = {}
for n in BlueprintTools.find_nodes(graph):
    ni = BlueprintTools._get_node_info(n)
    for b in [
        'Btn_ScalLow', 'Btn_ScalMed', 'Btn_ScalHigh', 'Btn_ScalEpic',
        'Btn_Res1080', 'Btn_Res1440', 'Btn_Res4K', 'Btn_Res720',
        'Btn_Fullscreen', 'Btn_Windowed',
        'Btn_FPS60', 'Btn_FPS120', 'Btn_FPSMax'
    ]:
        if b in ni.type_id:
            event_nodes[b] = n
            break

print("Found bound events:", len(event_nodes))

# For each event, examine its then pin connections
for bname, ev_node in event_nodes.items():
    p_ev_then = get_pin(ev_node, 'then', unreal.EdGraphPinDirection.EGPD_OUTPUT)
    if not p_ev_then:
        continue
    
    connected = list(p_ev_then.list_connected_pins())
    # Find which connected node is GetGameUserSettings or has self connected to GetGameUserSettings
    gus_node = None
    target_node = None
    
    for cpin in connected:
        cnode = cpin.get_owning_node()
        cni = BlueprintTools._get_node_info(cnode)
        if 'GetGameUserSettings' in cni.type_id:
            gus_node = cnode
        else:
            target_node = cnode
            
    # If gus_node is not directly connected to ev, search for the gus_node that feeds target_node:self
    if not gus_node and target_node:
        p_self = get_pin(target_node, 'self', unreal.EdGraphPinDirection.EGPD_INPUT)
        if p_self and p_self.list_connected_pins():
            source_p = p_self.list_connected_pins()[0]
            if 'GetGameUserSettings' in BlueprintTools._get_node_info(source_p.get_owning_node()).type_id:
                gus_node = source_p.get_owning_node()
                
    if gus_node and target_node:
        # Break all connections from ev
        p_ev_then.break_pin_links()
        
        # Connect ev -> gus:execute
        p_gus_exec = get_pin(gus_node, 'execute', unreal.EdGraphPinDirection.EGPD_INPUT)
        p_ev_then.try_create_connection(p_gus_exec)
        
        # Connect gus:then -> target:execute
        p_gus_then = get_pin(gus_node, 'then', unreal.EdGraphPinDirection.EGPD_OUTPUT)
        p_target_exec = get_pin(target_node, 'execute', unreal.EdGraphPinDirection.EGPD_INPUT)
        p_gus_then.break_pin_links()
        p_gus_then.try_create_connection(p_target_exec)
        
        print(f"Fixed {bname}: {ev_node.get_name()} -> {gus_node.get_name()} -> {target_node.get_name()}")

