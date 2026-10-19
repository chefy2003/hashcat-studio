import unreal

# Let's inspect ActorPositionWS for VoidGrid_X_04
actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
for a in actor_subsystem.get_all_level_actors():
    label = a.get_actor_label()
    if label == "VoidGrid_X_04":
        loc = a.get_actor_location()
        scale = a.get_actor_scale3d()
        unreal.log_warning(f"VoidGrid_X_04: Loc={loc}, Scale={scale}")
    if label == "VoidGrid_Y_04":
        loc = a.get_actor_location()
        scale = a.get_actor_scale3d()
        unreal.log_warning(f"VoidGrid_Y_04: Loc={loc}, Scale={scale}")
