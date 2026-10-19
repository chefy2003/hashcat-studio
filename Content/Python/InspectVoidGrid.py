import unreal

actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
grid_actors = []
for a in actor_subsystem.get_all_level_actors():
    label = a.get_actor_label()
    if "voidgrid" in label.lower() or "grid" in label.lower():
        grid_actors.append(a)

unreal.log_warning(f"Found {len(grid_actors)} grid actors!")
if grid_actors:
    a0 = grid_actors[0]
    smc = a0.static_mesh_component
    mats = smc.get_materials()
    unreal.log_warning(f"Sample actor: {a0.get_actor_label()}")
    if mats and mats[0]:
        m = mats[0]
        unreal.log_warning(f"Material: {m.get_name()}, Class: {m.get_class().get_name()}, Path: {m.get_path_name()}")
        if isinstance(m, unreal.MaterialInstanceDynamic) or isinstance(m, unreal.MaterialInstanceConstant):
            unreal.log_warning(f"Parent material: {m.get_editor_property('parent')}")

for a in sorted(grid_actors, key=lambda x: x.get_actor_label()):
    loc = a.get_actor_location()
    scale = a.get_actor_scale3d()
    unreal.log_warning(f"  {a.get_actor_label()}: Loc=({loc.x:.1f}, {loc.y:.1f}, {loc.z:.1f}), Scale=({scale.x:.3f}, {scale.y:.3f}, {scale.z:.3f})")
