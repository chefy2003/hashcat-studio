import unreal

subsys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
base_mat = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/BasicShapeMaterial")

print("=== [POST-PROCESS & NEON FIX] ЗАКЛЮЧВАНЕ НА ЕКСПОЗИЦИЯТА И НЕОНОВ БЛЯСЪК ===")

# 1. ТЪРСЕНЕ ИЛИ СЪЗДАВАНЕ НА POST-PROCESS VOLUME
pp_actor = None
for actor in subsys.get_all_level_actors():
    if actor.get_actor_label() == "Bunker_PostProcess_Controller":
        pp_actor = actor
        break

if not pp_actor:
    pp_actor = subsys.spawn_actor_from_class(unreal.PostProcessVolume, unreal.Vector(0, 0, 0))
    pp_actor.set_actor_label("Bunker_PostProcess_Controller")

# Задаваме Unbound през безопасния редакторски рефлекшън
pp_actor.set_editor_property("bUnbound", True)

# Взимаме копие на структурата Settings
pp_settings = pp_actor.get_editor_property("Settings")

# Активираме override флаговете и заключваме експозицията
pp_settings.set_editor_property("bOverride_AutoExposureMethod", True)
pp_settings.set_editor_property("AutoExposureMethod", unreal.AutoExposureMethod.AEM_MANUAL)

pp_settings.set_editor_property("bOverride_CameraISO", True)
pp_settings.set_editor_property("CameraISO", 100.0)

pp_settings.set_editor_property("bOverride_CameraShutterSpeed", True)
pp_settings.set_editor_property("CameraShutterSpeed", 60.0)

# Пускаме Bloom за неоновия ореол
pp_settings.set_editor_property("bOverride_BloomIntensity", True)
pp_settings.set_editor_property("BloomIntensity", 3.0)

# Записваме променената структура обратно в актьора
pp_actor.set_editor_property("Settings", pp_settings)

# 2. ПОТЪМНЯВАНЕ НА БЕТОННИЯ ПОД
for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    
    # Бетонът става плътен графитен обсидиан
    if label == "Bunker_Floor_ConcreteBase":
        mat = actor.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        mat.set_vector_parameter_value("Color", unreal.LinearColor(0.004, 0.005, 0.007, 1.0))
        
    # Зелената мрежа скача в 15x HDR емисия
    elif label.startswith("VoidGrid_"):
        mat = actor.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        mat.set_vector_parameter_value("Color", unreal.LinearColor(0.0, 15.0, 3.5, 1.0))

    # Свиваме таванните лампи до 250 лумена, за да няма застъпване в средата
    elif label.startswith("Overhead_Light_"):
        comp = actor.get_component_by_class(unreal.PointLightComponent)
        if comp:
            comp.set_intensity(250.0)
            comp.set_attenuation_radius(420.0)

print("=== [POST-PROCESS] Контрастът е закован успешно! ===")
