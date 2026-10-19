import unreal

actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
for a in actor_subsystem.get_all_level_actors():
    cls = a.get_class().get_name()
    if cls == "WorldPartitionHLOD":
        continue
    label = a.get_actor_label()
    loc = a.get_actor_location()
    if isinstance(a, unreal.StaticMeshActor):
        smc = a.static_mesh_component
        sm = smc.static_mesh.get_name() if smc and smc.static_mesh else "None"
        mats = [f"{m.get_name()} ({m.get_path_name()})" if m else "None" for m in smc.get_materials()]
        unreal.log_warning(f"ACTOR: '{label}' | SM: {sm} | Loc: {loc} | Mats: {mats}")
    else:
        unreal.log_warning(f"OTHER: '{label}' ({cls}) | Loc: {loc}")
