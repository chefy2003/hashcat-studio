import unreal

actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

rates = {
    "Nucleus": (0.0, 10.0, 0.0),
    "WaveformBelt": (0.0, 2.5, 0.0),
    "WaveformBelt_Inner": (0.0, -3.5, 0.0),
    "Gimbal_HoopA": (3.0, 6.0, 2.0),
    "Gimbal_HoopB": (-2.5, -7.0, -1.5),
    "Gimbal_EquatorialDial": (0.0, 4.0, 0.0),
    "AtomicOrbitA": (2.0, 4.5, 1.2),
    "AtomicOrbitB": (-2.2, -5.0, 2.0),
    "AtomicOrbitC": (3.5, -3.0, 4.0),
    "InnerHelixSphere": (4.0, -7.0, 3.0),
    "MidNeuralSphere": (-2.0, 3.5, -2.5)
}

updated_count = 0
for actor in actor_subsystem.get_all_level_actors():
    label = actor.get_actor_label()
    for key, rate in rates.items():
        if f"Ultron_{key}" == label:
            rot_comps = actor.get_components_by_class(unreal.RotatingMovementComponent)
            for rc in rot_comps:
                rc.set_editor_property("rotation_rate", unreal.Rotator(rate[0], rate[1], rate[2]))
                unreal.log_warning(f"Updated {label} rotation rate to majestic slow: {rate}")
                updated_count += 1

unreal.log_warning(f"[UpdateRotationRates_CinematicSlow] Successfully updated {updated_count} components!")
