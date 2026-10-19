import unreal

subsys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
base_mat = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/BasicShapeMaterial")

print("=== [UNBURYING] ИЗВАЖДАНЕ НА ТЕХНИКАТА ОТ БЕТОНА И ОПРАВЯНЕ НА СВЕТЛИНАТА ===")

# 1. ПОДЪТ СЛИЗА ТАКА, ЧЕ ПОВЪРХНОСТТА МУ ДА Е НА КОТА Z = 0.0
for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    if label == "Bunker_Floor_ConcreteBase":
        # Център на -10, дебелина 20 -> горно лице точно на Z = 0.0
        actor.set_actor_location(unreal.Vector(0.0, 0.0, -10.0), False, False)
        actor.set_actor_scale3d(unreal.Vector(16.0, 16.0, 0.2))
        mat = actor.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        mat.set_vector_parameter_value("Color", unreal.LinearColor(0.012, 0.015, 0.018, 1.0))
        print("[+] Бетонният под е закован на кота нула (Z=0.0).")

# 2. ПИЕДЕСТАЛЪТ СТЪПВА ВЪРХУ ПОДА (от Z=0 до Z=20)
for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    if label in ["HashcatStudioPro_Matrix_Pedestal", "Hashcat_Matrix_Pedestal"]:
        actor.set_actor_label("HashcatStudioPro_Matrix_Pedestal")
        actor.set_actor_location(unreal.Vector(0.0, 0.0, 10.0), False, False)
        actor.set_actor_scale3d(unreal.Vector(3.0, 3.0, 0.2))
        mat = actor.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        mat.set_vector_parameter_value("Color", unreal.LinearColor(0.05, 0.06, 0.07, 1.0))
        print("[+] Пиедесталът изплува от замазката!")

# 3. ЗЕЛЕНАТА МРЕЖА ЛЯГА НА Z = 0.6 (ТОЧНО ВЪРХУ ПЛОЧИТЕ)
for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    if label.startswith("VoidGrid_"):
        loc = actor.get_actor_location()
        actor.set_actor_location(unreal.Vector(loc.x, loc.y, 0.6), False, False)
        mat = actor.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        # Свежо Matrix зелено
        mat.set_vector_parameter_value("Color", unreal.LinearColor(0.0, 1.0, 0.35, 1.0))

# 4. ФОТОННИТЕ ШИНИ ЛЯГАТ НА Z = 1.2
for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    if label == "ConduitStorageToTerminal":
        loc = actor.get_actor_location()
        actor.set_actor_location(unreal.Vector(loc.x, loc.y, 1.2), False, False)
        mat = actor.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        mat.set_vector_parameter_value("Color", unreal.LinearColor(1.0, 0.65, 0.05, 1.0))
    elif label == "ConduitStorageToCore":
        loc = actor.get_actor_location()
        actor.set_actor_location(unreal.Vector(loc.x, loc.y, 1.2), False, False)
        mat = actor.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        mat.set_vector_parameter_value("Color", unreal.LinearColor(0.0, 0.92, 1.0, 1.0))

# 5. ОТРЯЗВАНЕ НА СИВАТА МЪГЛА (УБИВАМЕ АВТОМАТИЧНОТО ИЗБЕЛВАНЕ)
for actor in subsys.get_all_level_actors():
    if actor.get_actor_label() == "Bunker_PostProcess_Controller":
        settings = actor.get_editor_property("Settings")
        settings.set_editor_property("bOverride_AutoExposureBias", True)
        settings.set_editor_property("AutoExposureBias", -2.5) # Сваляме експозицията, за да изпъкне мракът
        actor.set_editor_property("Settings", settings)
        print("[+] Сивата пелена е премахната.")

# 6. ТАВАННИТЕ ЛАМПИ СЛИЗАТ НА 350 ЛУМЕНА (МЕК КИБЕРПЪНК)
for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    if label.startswith("Overhead_Light_"):
        comp = actor.get_component_by_class(unreal.PointLightComponent)
        if comp:
            comp.set_intensity(350.0)
            comp.set_attenuation_radius(450.0)
    elif label.startswith("TrussUpLight_"):
        comp = actor.get_component_by_class(unreal.PointLightComponent)
        if comp:
            comp.set_intensity(250.0)
            comp.set_attenuation_radius(350.0)

print("=== [SPATIAL OS] ВСИЧКО Е ИЗВАДЕНО НА ПОВЪРХНОСТТА И СВЕТИ ПО ПЛАН! ===")
