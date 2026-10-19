import unreal

actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
for a in actor_subsystem.get_all_level_actors():
    cls = a.get_class().get_name()
    if cls == "WorldPartitionHLOD":
        continue
    label = a.get_actor_label()
    loc = a.get_actor_location()
    # Check if around z=0 and large scale, or label contains floor/grid/plane
    if isinstance(a, unreal.StaticMeshActor):
        scale = a.get_actor_scale3d()
        if scale.x > 5 or scale.y > 5 or abs(loc.z) < 20 or "floor" in label.lower() or "grid" in label.lower() or "plane" in label.lower():
            smc = a.static_mesh_component
            sm = smc.static_mesh.get_name() if smc and smc.static_mesh else "None"
            mats = [f"{m.get_name()} ({m.get_path_name()})" if m else "None" for m in smc.get_materials()]
            unreal.log_warning(f"FLOOR CANDIDATE: '{label}' | SM: {sm} | Loc: {loc} | Scale: {scale} | Mats: {mats}")
