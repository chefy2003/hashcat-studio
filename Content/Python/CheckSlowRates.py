import unreal

actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

for actor in actor_subsystem.get_all_level_actors():
    label = actor.get_actor_label()
    if label.startswith("Ultron_"):
        rot_comps = actor.get_components_by_class(unreal.RotatingMovementComponent)
        for i, rc in enumerate(rot_comps):
            rate = rc.get_editor_property("rotation_rate")
            auto_act = rc.get_editor_property("auto_activate")
            unreal.log_warning(f"CHECK {label} [comp {i}]: rate=({rate.pitch:.1f}, {rate.yaw:.1f}, {rate.roll:.1f}), auto={auto_act}")
