import unreal

actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
actors = actor_subsystem.get_all_level_actors()

unreal.log_warning(f"=== TOTAL ACTORS: {len(actors)} ===")
for actor in actors:
    label = actor.get_actor_label()
    cls = actor.get_class().get_name()
    if isinstance(actor, unreal.StaticMeshActor):
        smc = actor.static_mesh_component
        sm = smc.static_mesh
        sm_name = sm.get_name() if sm else "None"
        mats = [f"{m.get_name()} ({m.get_path_name()})" if m else "None" for m in smc.get_materials()]
        loc = actor.get_actor_location()
        scale = actor.get_actor_scale3d()
        unreal.log_warning(f"ACTOR: {label} | Mesh: {sm_name} | Loc: {loc} | Scale: {scale} | Mats: {mats}")
    else:
        unreal.log_warning(f"ACTOR: {label} ({cls})")
