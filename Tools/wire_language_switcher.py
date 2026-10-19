import unreal
from editor_toolset.toolsets.blueprint import BlueprintTools

bp = unreal.load_object(None, "/Game/WBP_SettingsMenu.WBP_SettingsMenu")
graph = unreal.load_object(None, "/Game/WBP_SettingsMenu.WBP_SettingsMenu:EventGraph")
bp_editor = unreal.BlueprintGraphEditor.get_graph_editor(graph)

def get_pin(node, name, direction=None):
    for p in node.list_all_pins():
        if str(p.get_pin_name()) == name:
            if direction is None or p.get_pin_direction() == direction:
                return p
    return None

LANGUAGE_STRINGS = {
    'Btn_LangToggle_Text': {
        'BG': '[ 🌐 ЕЗИК: BG 🇧🇬 ]',
        'EN': '[ 🌐 LANG: EN 🇬🇧 ]'
    },
    'BufferLabel': {
        'BG': '[::] БУФЕР:',
        'EN': '[::] BUFFER:'
    },
    'FooterCaption': {
        'BG': '● МРЕЖОВ СТАТУС: НОРМАЛЕН // LINUX NUMA 0,1 // VULKAN SM5 // 1080p',
        'EN': '● NET_STATUS: NOMINAL // LINUX NUMA 0,1 // VULKAN SM5 // 1080p'
    },
    'SidebarHeading': {
        'BG': '[::] ИЗБОР НА ПОДСИСТЕМЕН ДЕМОН',
        'EN': '[::] SELECT SUBSYSTEM DAEMON'
    },
    'Btn_NavDisplay_Title': {
        'BG': '01 // ДИСПЛЕЙ & РЕЗОЛЮЦИЯ',
        'EN': '01 // DISPLAY & RESOLUTION'
    },
    'Btn_NavDisplay_Sub': {
        'BG': 'Резолюция, Режим на прозореца',
        'EN': 'Display Mode, Resolution Matrix'
    },
    'Btn_NavGraphics_Title': {
        'BG': '02 // ГРАФИЧЕН РЕНДЕР',
        'EN': '02 // GRAPHICS & RENDER'
    },
    'Btn_NavGraphics_Sub': {
        'BG': 'Качество, Ограничение на кадри',
        'EN': 'Scalability Presets, Framerate Cap'
    },
    'Btn_NavControls_Title': {
        'BG': '03 // КОНТРОЛИ & КЛАВИАТУРА',
        'EN': '03 // CONTROLS & BINDINGS'
    },
    'Btn_NavControls_Sub': {
        'BG': 'Чувствителност и клавишни връзки',
        'EN': 'Look Sensitivity & Key Bindings'
    },
    'Btn_NavAudio_Title': {
        'BG': '04 // ЗВУК & КАЛИБРАЦИЯ',
        'EN': '04 // AUDIO & CALIBRATION'
    },
    'Btn_NavAudio_Sub': {
        'BG': 'Главна сила на звука и ефекти',
        'EN': 'Master Volume & Audio Calibration'
    },
    'SecTxt_Disp': {
        'BG': '[::] SEQUENCE REQUIRED // 01: ДИСПЛЕЙ & РЕЗОЛЮЦИЯ НА ЕКРАНА',
        'EN': '[::] SEQUENCE REQUIRED // 01: DISPLAY & SCREEN RESOLUTION'
    },
    'Txt_ResLabel': {
        'BG': '>> ИЗБОР НА РЕЗОЛЮЦИЯ (DISPLAY RESOLUTION MATRIX):',
        'EN': '>> DISPLAY RESOLUTION MATRIX:'
    },
    'Txt_CurrentRes': {
        'BG': '» АКТИВНА РЕЗОЛЮЦИЯ: 1920 x 1080 (FHD)',
        'EN': '» ACTIVE RESOLUTION: 1920 x 1080 (FHD)'
    },
    'Txt_DispLabel': {
        'BG': '>> РЕЖИМ НА ЕКРАНА (DISPLAY MODE):',
        'EN': '>> SCREEN DISPLAY MODE:'
    },
    'Btn_Fullscreen_Text': {
        'BG': 'ЦЯЛ ЕКРАН / FULLSCREEN (F11)',
        'EN': 'FULLSCREEN MODE (F11)'
    },
    'Btn_Windowed_Text': {
        'BG': 'В ПРОЗОРЕЦ / WINDOWED (1080p)',
        'EN': 'WINDOWED MODE (1080p)'
    },
    'SecTxt_Gfx': {
        'BG': '[::] SEQUENCE REQUIRED // 02: ГРАФИЧЕН РЕНДЕР & SCALABILITY',
        'EN': '[::] SEQUENCE REQUIRED // 02: GRAPHICS RENDER & SCALABILITY'
    },
    'Txt_ScalLabel': {
        'BG': '>> СТЕПЕН НА ГРАФИЧНО ОФОРМЛЕНИЕ (QUALITY PRESET):',
        'EN': '>> GRAPHICS QUALITY PRESET:'
    },
    'Txt_CurrentScal': {
        'BG': '» АКТИВЕН ПРЕСЕТ: HIGH (ВИСОКО) [100% SCALE]',
        'EN': '» ACTIVE PRESET: HIGH (OPTIMAL) [100% SCALE]'
    },
    'Btn_ScalLow_Text': {
        'BG': 'LOW (НИСКО)',
        'EN': 'LOW (PERFORMANCE)'
    },
    'Btn_ScalMed_Text': {
        'BG': 'MEDIUM (СРЕДНО)',
        'EN': 'MEDIUM (BALANCED)'
    },
    'Btn_ScalHigh_Text': {
        'BG': 'HIGH (ВИСОКО)',
        'EN': 'HIGH (OPTIMAL)'
    },
    'Btn_ScalEpic_Text': {
        'BG': 'EPIC (ЕПИЧНО)',
        'EN': 'EPIC (CINEMATIC MAX)'
    },
    'Txt_FpsLabel': {
        'BG': '>> ОГРАНИЧЕНИЕ НА КАДРИ (FRAMERATE LIMIT):',
        'EN': '>> FRAMERATE LIMIT (FPS CAP):'
    },
    'Btn_FPSMax_Text': {
        'BG': 'БЕЗ ЛИМИТ / UNCAPPED',
        'EN': 'MAX / UNCAPPED'
    },
    'SecTxt_Ctrl': {
        'BG': '[::] SEQUENCE REQUIRED // 03: КОНТРОЛИ & ЧУВСТВИТЕЛНОСТ НА МИШКАТА',
        'EN': '[::] SEQUENCE REQUIRED // 03: CONTROLS & LOOK SENSITIVITY'
    },
    'Txt_SensLabel': {
        'BG': '>> ЧУВСТВИТЕЛНОСТ НА МИШКАТА (LOOK SENSITIVITY):',
        'EN': '>> MOUSE LOOK SENSITIVITY:'
    },
    'Txt_KeysHeader': {
        'BG': '>> ДИНАМИЧНО ПЕРСОНАЛИЗИРАНЕ НА КЛАВИШИ (DYNAMIC OPERATOR BINDINGS):',
        'EN': '>> OPERATOR KEYBOARD BINDINGS (REBINDABLE):'
    },
    'Btn_Bind_Fwd_Desc': {
        'BG': 'ДВИЖЕНИЕ НАПРЕД (MOVE FORWARD)',
        'EN': 'MOVE FORWARD (NAVIGATION)'
    },
    'Btn_Bind_Back_Desc': {
        'BG': 'ДВИЖЕНИЕ НАЗАД (MOVE BACKWARD)',
        'EN': 'MOVE BACKWARD (NAVIGATION)'
    },
    'Btn_Bind_Left_Desc': {
        'BG': 'ДВИЖЕНИЕ НАЛЯВО (MOVE LEFT / STRAFE)',
        'EN': 'MOVE LEFT (STRAFE)'
    },
    'Btn_Bind_Right_Desc': {
        'BG': 'ДВИЖЕНИЕ НАДЯСНО (MOVE RIGHT / STRAFE)',
        'EN': 'MOVE RIGHT (STRAFE)'
    },
    'Btn_Bind_Jump_Desc': {
        'BG': 'СКАЧАНЕ И ПРЕОДОЛЯВАНЕ НА ПРЕПЯТСТВИЯ (JUMP)',
        'EN': 'JUMP & VAULT OBSTACLES'
    },
    'Btn_Bind_Sprint_Desc': {
        'BG': 'СПРИНТ / ТАКТИЧЕСКО БЯГАНЕ (TACTICAL SPRINT)',
        'EN': 'TACTICAL SPRINT'
    },
    'Btn_Bind_Interact_Desc': {
        'BG': 'ВЗАИМОДЕЙСТВИЕ С ТЕРМИНАЛИ & ОБЕКТИ (INTERACT / USE)',
        'EN': 'INTERACT WITH TERMINALS & RIGS'
    },
    'Btn_Bind_Menu_Desc': {
        'BG': 'МЕНЮ НАСТРОЙКИ & ПАУЗА (TOGGLE MENU)',
        'EN': 'SETTINGS MENU / PAUSE TOGGLE'
    },
    'Btn_ResetControls_Text': {
        'BG': '<< ВЪЗСТАНОВИ СТАНДАРТНИТЕ КОНТРОЛИ (RESET TO DEFAULTS) >>',
        'EN': '<< RESET ALL CONTROLS TO FACTORY DEFAULTS >>'
    },
    'SecTxt_Aud': {
        'BG': '[::] SEQUENCE REQUIRED // 04: ЗВУКОВА СИСТЕМА & ИЗХОДНО НИВО',
        'EN': '[::] SEQUENCE REQUIRED // 04: AUDIO SUBSYSTEM & MASTER GAIN'
    },
    'Txt_VolLabel': {
        'BG': '>> ГЛАВНА СИЛА НА ЗВУКА (MASTER AUDIO OUTPUT):',
        'EN': '>> MASTER AUDIO OUTPUT LEVEL:'
    },
    'Btn_Resume_Text': {
        'BG': '[ ESC ] ВЪРНИ СЕ КЪМ ХАШКАТ (RESUME)',
        'EN': '[ ESC ] RESUME OPERATOR PROTOCOL'
    },
    'Btn_Quit_Text': {
        'BG': '[ Q ] ИЗХОД ОТ СИСТЕМАТА (QUIT)',
        'EN': '[ Q ] DISCONNECT / QUIT TO DESKTOP'
    }
}

# 1. Find LangToggle event node
ev_node = None
for n in BlueprintTools.find_nodes(graph):
    ni = BlueprintTools._get_node_info(n)
    if "Btn_LangToggle" in ni.type_id and "OnClicked" in ni.type_id:
        ev_node = n
        break

if not ev_node:
    raise RuntimeError("Could not find Btn_LangToggle OnClicked event node!")

pos = BlueprintTools._get_node_info(ev_node).position
x_base, y_base = int(pos.x), int(pos.y)

# 2. Add Branch node
branch_node = bp_editor.add_branch_node()
get_bIsEnglish = bp_editor.add_get_member_variable_node("bIsEnglish", "")

# Connect ev_node:then -> branch_node:execute
p_ev_then = get_pin(ev_node, "then", unreal.EdGraphPinDirection.EGPD_OUTPUT)
p_br_exec = get_pin(branch_node, "execute", unreal.EdGraphPinDirection.EGPD_INPUT)
p_ev_then.try_create_connection(p_br_exec)

# Connect get_bIsEnglish -> branch_node:Condition
p_get_bool = get_pin(get_bIsEnglish, "bIsEnglish", unreal.EdGraphPinDirection.EGPD_OUTPUT)
p_br_cond = get_pin(branch_node, "Condition", unreal.EdGraphPinDirection.EGPD_INPUT)
p_get_bool.try_create_connection(p_br_cond)

# 3. IF TRUE: bIsEnglish was True -> set to False (Bulgarian)
set_false = bp_editor.add_set_member_variable_node("bIsEnglish", "")
p_br_true = get_pin(branch_node, "then", unreal.EdGraphPinDirection.EGPD_OUTPUT)
p_sf_exec = get_pin(set_false, "execute", unreal.EdGraphPinDirection.EGPD_INPUT)
p_br_true.try_create_connection(p_sf_exec)
p_sf_val = get_pin(set_false, "bIsEnglish", unreal.EdGraphPinDirection.EGPD_INPUT)
if p_sf_val:
    p_sf_val.set_pin_value("false")

# 4. IF FALSE: bIsEnglish was False -> set to True (English)
set_true = bp_editor.add_set_member_variable_node("bIsEnglish", "")
p_br_false = get_pin(branch_node, "else", unreal.EdGraphPinDirection.EGPD_OUTPUT)
p_st_exec = get_pin(set_true, "execute", unreal.EdGraphPinDirection.EGPD_INPUT)
p_br_false.try_create_connection(p_st_exec)
p_st_val = get_pin(set_true, "bIsEnglish", unreal.EdGraphPinDirection.EGPD_INPUT)
if p_st_val:
    p_st_val.set_pin_value("true")

def build_chain(start_node, lang_key, y_offset):
    curr = start_node
    curr_pin = get_pin(curr, "then", unreal.EdGraphPinDirection.EGPD_OUTPUT)
    for i, (wname, text_dict) in enumerate(LANGUAGE_STRINGS.items()):
        text_val = text_dict[lang_key]
        n_set = bp_editor.create_node_from_name("Widget|SetText(Text)", unreal.Vector2D(x_base + 300 + i * 180, y_base + y_offset), [], None)
        p_intext = get_pin(n_set, "InText", unreal.EdGraphPinDirection.EGPD_INPUT)
        if p_intext:
            p_intext.set_pin_value(text_val)
        
        n_var = bp_editor.add_get_member_variable_node(wname, "")
        p_var_out = get_pin(n_var, wname, unreal.EdGraphPinDirection.EGPD_OUTPUT)
        p_set_self = get_pin(n_set, "self", unreal.EdGraphPinDirection.EGPD_INPUT)
        p_var_out.try_create_connection(p_set_self)
        
        p_set_exec = get_pin(n_set, "execute", unreal.EdGraphPinDirection.EGPD_INPUT)
        curr_pin.try_create_connection(p_set_exec)
        curr_pin = get_pin(n_set, "then", unreal.EdGraphPinDirection.EGPD_OUTPUT)
    return curr_pin

print("Building Bulgarian text chain...")
build_chain(set_false, 'BG', -400)

print("Building English text chain...")
build_chain(set_true, 'EN', 400)

unreal.BlueprintEditorLibrary.compile_blueprint(bp)
unreal.EditorAssetLibrary.save_loaded_asset(bp)
print("Successfully wired complete language switcher! Status:", bp.get_editor_property("status"))
