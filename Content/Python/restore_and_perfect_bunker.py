import unreal

subsys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
base_mat = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/BasicShapeMaterial")

print("=== [RESTORATION] ВРЪЩАНЕ НА СВЕТЛИНАТА И ПЕРФЕКТЕН КИБЕРПЪНК БАЛАНС ===")

# 1. ПРЕМАХВАНЕ / СКРИВАНЕ НА СТАРИЯ ОСТРОВ (LANDSCAPE)
for actor in subsys.get_all_level_actors():
    cls_name = actor.get_class().get_name()
    label = actor.get_actor_label()
    if "Landscape" in cls_name or "Landscape" in label:
        subsys.destroy_actor(actor)
        print("[+] Островът (Landscape) е премахнат от сцената.")

# 2. ОПРАВЯНЕ НА КАМЕРАТА И ЕКСПОЗИЦИЯТА (Атмосферен сумрак)
for actor in subsys.get_all_level_actors():
    if actor.get_actor_label() == "Bunker_PostProcess_Controller":
        pp_actor = actor
        pp_actor.set_editor_property("bUnbound", True)
        settings = pp_actor.get_editor_property("Settings")
        
        # Връщаме адаптивна експозиция с лек тъмен филмов уклон (-0.7 EV)
        settings.set_editor_property("bOverride_AutoExposureMethod", True)
        settings.set_editor_property("AutoExposureMethod", unreal.AutoExposureMethod.AEM_HISTOGRAM)
        
        settings.set_editor_property("bOverride_AutoExposureBias", True)
        settings.set_editor_property("AutoExposureBias", -0.7)
        
        settings.set_editor_property("bOverride_BloomIntensity", True)
        settings.set_editor_property("BloomIntensity", 1.8)
        
        pp_actor.set_editor_property("Settings", settings)
        print("[+] Експозицията е балансирана в кинематографичен режим.")
        break

# 3. ОСВЕТЛЕНИЕ: 1200 ЛУМЕНА ТАВАННИ ТЕЛА + 600 ЛУМЕНА СИНИ ЪПЛАЙТОВЕ
for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    if label.startswith("Overhead_Light_"):
        comp = actor.get_component_by_class(unreal.PointLightComponent)
        if comp:
            comp.set_intensity(1200.0)
            comp.set_attenuation_radius(650.0)
            comp.set_light_color(unreal.LinearColor(0.92, 0.96, 1.0, 1.0)) # Студено бяло
    elif label.startswith("TrussUpLight_"):
        comp = actor.get_component_by_class(unreal.PointLightComponent)
        if comp:
            comp.set_intensity(600.0)
            comp.set_attenuation_radius(500.0)
            comp.set_light_color(unreal.LinearColor(0.0, 0.35, 1.0, 1.0)) # Дълбоко кобалтово синьо

# 4. ПОД: БЕТОННИЯТ ПОД СЕ КАЧВА НА Z=1.0 (ТЪМЕН АНТРАЦИТ)
for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    if label == "Bunker_Floor_ConcreteBase":
        actor.set_actor_location(unreal.Vector(0.0, 0.0, 1.0), False, False)
        actor.set_actor_scale3d(unreal.Vector(16.0, 16.0, 0.2))
        mat = actor.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        mat.set_vector_parameter_value("Color", unreal.LinearColor(0.018, 0.021, 0.025, 1.0))

# 5. ЗЕЛЕНАТА МРЕЖА ЛЯГА НА Z=2.2 (ТОЧНО ВЪРХУ БЕТОНА)
for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    if label.startswith("VoidGrid_"):
        loc = actor.get_actor_location()
        actor.set_actor_location(unreal.Vector(loc.x, loc.y, 2.2), False, False)
        mat = actor.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        mat.set_vector_parameter_value("Color", unreal.LinearColor(0.0, 1.0, 0.3, 1.0))

# 6. ФОТОННИТЕ ШИНИ СЕ КАЧВАТ НА Z=3.0 (НАД МРЕЖАТА)
for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    if label in ["ConduitStorageToTerminal", "ConduitStorageToCore"]:
        loc = actor.get_actor_location()
        actor.set_actor_location(unreal.Vector(loc.x, loc.y, 3.0), False, False)

print("=== [SPATIAL OS] БУНКЕРЪТ ВЕЧЕ Е ЖИВ, ВИДИМ И БАЛАНСИРАН! ===")
