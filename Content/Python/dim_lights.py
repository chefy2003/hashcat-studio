import unreal

subsys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

print("=== [LIGHTING] ДИМВАНЕ НА ОСВЕТЛЕНИЕТО ЗА КОНТРАСТ НА ПОДА ===")

for actor in subsys.get_all_level_actors():
    label = actor.get_actor_label()
    comp = actor.get_component_by_class(unreal.PointLightComponent)
    if not comp:
        continue
        
    # Таванните осветителни тела: сваляме от 3500 на 650 (мека студена светлина)
    if label.startswith("Overhead_Light_"):
        comp.set_intensity(450.0)
        comp.set_attenuation_radius(600.0)
        
    # Сините ъплайтове към фермите: сваляме от 2200 на 450 (дълбок сумрачен контраст горе)
    elif label.startswith("TrussUpLight_"):
        comp.set_intensity(450.0)
        comp.set_attenuation_radius(450.0)

print("=== [LIGHTING] Осветлението е превключено в Combat / Stealth режим! ===")
