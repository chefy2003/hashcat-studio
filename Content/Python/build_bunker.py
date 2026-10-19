import unreal

subsys = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
cube_mesh = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/Cube")
base_mat = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/BasicShapeMaterial")

# 1. ЗАТЪМНЯВАНЕ НА СЛЪНЦЕТО
for actor in subsys.get_all_level_actors():
    name = actor.get_actor_label()
    if "DirectionalLight" in name:
        comp = actor.get_component_by_class(unreal.DirectionalLightComponent)
        if comp: comp.set_intensity(0.0)
    elif "SkyLight" in name:
        comp = actor.get_component_by_class(unreal.SkyLightComponent)
        if comp: comp.set_intensity(0.02)
    elif "VolumetricCloud" in name:
        actor.set_actor_hidden_in_game(True)

# 2. БЕТОНЕН ПОД
floor = subsys.spawn_actor_from_class(unreal.StaticMeshActor, unreal.Vector(0.0, 0.0, -5.0))
floor.set_actor_label("Bunker_Floor_ConcreteBase")
floor.static_mesh_component.set_static_mesh(cube_mesh)
floor.set_actor_scale3d(unreal.Vector(16.0, 16.0, 0.1))
if base_mat:
    mat = floor.static_mesh_component.create_dynamic_material_instance(0, base_mat)
    mat.set_vector_parameter_value("Color", unreal.LinearColor(0.022, 0.025, 0.028, 1.0))

# 3. ЗЕЛЕНА МРЕЖА (Void Grid)
for idx, pos in enumerate(range(-700, 701, 200)):
    # Надлъжни линии по X
    line_x = subsys.spawn_actor_from_class(unreal.StaticMeshActor, unreal.Vector(0.0, float(pos), 0.5))
    line_x.set_actor_label(f"VoidGrid_X_{idx:02d}")
    line_x.static_mesh_component.set_static_mesh(cube_mesh)
    line_x.set_actor_scale3d(unreal.Vector(16.0, 0.035, 0.015))
    if base_mat:
        g_mat = line_x.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        g_mat.set_vector_parameter_value("Color", unreal.LinearColor(0.0, 1.0, 0.35, 1.0))

    # Напречни линии по Y
    line_y = subsys.spawn_actor_from_class(unreal.StaticMeshActor, unreal.Vector(float(pos), 0.0, 0.5))
    line_y.set_actor_label(f"VoidGrid_Y_{idx:02d}")
    line_y.static_mesh_component.set_static_mesh(cube_mesh)
    line_y.set_actor_scale3d(unreal.Vector(0.035, 16.0, 0.015))
    if base_mat:
        g_mat = line_y.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        g_mat.set_vector_parameter_value("Color", unreal.LinearColor(0.0, 1.0, 0.35, 1.0))

# 4. СТЕНИ И ТАВАН НА 6.4m
walls = [
    ("Wall_North", unreal.Vector(0.0, 800.0, 320.0), unreal.Vector(16.0, 0.3, 6.4)),
    ("Wall_East", unreal.Vector(800.0, 0.0, 320.0), unreal.Vector(0.3, 16.0, 6.4)),
    ("Wall_West", unreal.Vector(-800.0, 0.0, 320.0), unreal.Vector(0.3, 16.0, 6.4)),
    ("Ceiling_Roof", unreal.Vector(0.0, 0.0, 640.0), unreal.Vector(16.0, 16.0, 0.3)),
    ("Wall_South_Left", unreal.Vector(-520.0, -800.0, 320.0), unreal.Vector(5.6, 0.3, 6.4)),
    ("Wall_South_Right", unreal.Vector(520.0, -800.0, 320.0), unreal.Vector(5.6, 0.3, 6.4)),
    ("Wall_South_Lintel", unreal.Vector(0.0, -800.0, 520.0), unreal.Vector(4.8, 0.3, 2.4)),
    ("Blast_Bulkhead_Door", unreal.Vector(0.0, -785.0, 200.0), unreal.Vector(4.4, 0.45, 4.0)),
    ("Door_LED", unreal.Vector(0.0, -760.0, 410.0), unreal.Vector(3.8, 0.08, 0.12))
]

for name, loc, scale in walls:
    w = subsys.spawn_actor_from_class(unreal.StaticMeshActor, loc)
    w.set_actor_label(name)
    w.static_mesh_component.set_static_mesh(cube_mesh)
    w.set_actor_scale3d(scale)
    if base_mat:
        mat = w.static_mesh_component.create_dynamic_material_instance(0, base_mat)
        if "LED" in name:
            mat.set_vector_parameter_value("Color", unreal.LinearColor(1.0, 0.45, 0.0, 1.0))
        elif "Door" in name:
            mat.set_vector_parameter_value("Color", unreal.LinearColor(0.06, 0.07, 0.08, 1.0))
        else:
            mat.set_vector_parameter_value("Color", unreal.LinearColor(0.015, 0.018, 0.022, 1.0))

# 5. ТАВАННИ ЛАМПИ И СИНИ ЪПЛАЙТОВЕ
lights = [(-320.0, -450.0), (-320.0, 0.0), (-320.0, 450.0), (320.0, -450.0), (320.0, 0.0), (320.0, 450.0)]
for idx, (lx, ly) in enumerate(lights):
    pl = subsys.spawn_actor_from_class(unreal.PointLight, unreal.Vector(lx, ly, 590.0))
    pl.set_actor_label(f"Overhead_Light_{idx:02d}")
    comp = pl.get_component_by_class(unreal.PointLightComponent)
    if comp:
        comp.set_intensity(3500.0)
        comp.set_light_color(unreal.LinearColor(0.95, 0.98, 1.0, 1.0))
        comp.set_attenuation_radius(750.0)

uplights = [(-350.0, -250.0), (-350.0, 250.0), (350.0, -250.0), (350.0, 250.0)]
for idx, (ux, uy) in enumerate(uplights):
    ul = subsys.spawn_actor_from_class(unreal.PointLight, unreal.Vector(ux, uy, 500.0))
    ul.set_actor_label(f"TrussUpLight_{idx:02d}")
    comp = ul.get_component_by_class(unreal.PointLightComponent)
    if comp:
        comp.set_intensity(2200.0)
        comp.set_light_color(unreal.LinearColor(0.0, 0.35, 1.0, 1.0))
        comp.set_attenuation_radius(550.0)

print("=== [SPATIAL OS] БУНКЕРЪТ Е НАПЪЛНО ЗАТВОРЕН И СВЕТНА! ===")
