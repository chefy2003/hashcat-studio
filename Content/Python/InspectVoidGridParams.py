import unreal

actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
for a in actor_subsystem.get_all_level_actors():
    if a.get_actor_label() == "VoidGrid_X_00":
        smc = a.static_mesh_component
        m = smc.get_material(0)
        unreal.log_warning(f"Inspecting parameters of {m.get_name()}:")
        for p in ["Color", "BaseColor", "Albedo", "Emissive", "EmissiveColor", "Tint"]:
            val = m.get_vector_parameter_value(p)
            unreal.log_warning(f"  Vector param {p}: {val}")
        for p in ["Roughness", "Metallic", "Opacity", "Specular"]:
            val = m.get_scalar_parameter_value(p)
            unreal.log_warning(f"  Scalar param {p}: {val}")
