import unreal

actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
for a in actor_subsystem.get_all_level_actors():
    if a.get_actor_label() == "VoidGrid_X_00":
        smc = a.static_mesh_component
        for i, m in enumerate(smc.get_materials()):
            unreal.log_warning(f"Material {i}: {m.get_name()} ({m.get_class().get_name()}) Path: {m.get_path_name()}")
            if isinstance(m, unreal.MaterialInstanceDynamic) or isinstance(m, unreal.MaterialInstance):
                unreal.log_warning(f"  Parent: {m.get_editor_property('parent')}")
