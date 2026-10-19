import unreal

actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
for a in actor_subsystem.get_all_level_actors():
    label = a.get_actor_label()
    if label.startswith("VoidGrid_") or "conduit" in label.lower():
        if isinstance(a, unreal.StaticMeshActor):
            smc = a.static_mesh_component
            m = smc.get_material(0)
            unreal.log_warning(f"{label}: Mat={m.get_name() if m else 'None'} ({m.get_class().get_name() if m else 'None'})")
