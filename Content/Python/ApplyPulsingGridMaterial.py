import unreal

package_path = "/Game"
mat = unreal.load_asset(f"{package_path}/M_VoidGrid_Pulsing.M_VoidGrid_Pulsing")
if not mat:
    unreal.log_error("Could not load M_VoidGrid_Pulsing!")
else:
    actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    assigned_count = 0
    for a in actor_subsystem.get_all_level_actors():
        label = a.get_actor_label()
        if label.startswith("VoidGrid_"):
            if isinstance(a, unreal.StaticMeshActor):
                smc = a.static_mesh_component
                smc.set_material(0, mat)
                assigned_count += 1
                unreal.log_warning(f"Assigned M_VoidGrid_Pulsing to {label}")

    unreal.EditorLoadingAndSavingUtils.save_dirty_packages(True, True)
    unreal.log_warning(f"[ApplyPulsingGridMaterial] Successfully assigned to {assigned_count} grid lines and saved level!")
