import unreal

actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
sub_subsystem = unreal.get_engine_subsystem(unreal.SubobjectDataSubsystem)

rates = {
    "Nucleus": (0.0, 8.0, 0.0),
    "WaveformBelt": (0.0, 2.0, 0.0),
    "WaveformBelt_Inner": (0.0, -3.0, 0.0),
    "Gimbal_HoopA": (2.5, 5.0, 1.5),
    "Gimbal_HoopB": (-2.0, -6.0, -1.2),
    "Gimbal_EquatorialDial": (0.0, 3.5, 0.0),
    "AtomicOrbitA": (1.8, 3.5, 1.0),
    "AtomicOrbitB": (-1.8, -4.0, 1.5),
    "AtomicOrbitC": (2.8, -2.5, 3.0),
    "InnerHelixSphere": (3.0, -5.5, 2.5),
    "MidNeuralSphere": (-1.5, 3.0, -2.0)
}

for actor in actor_subsystem.get_all_level_actors():
    label = actor.get_actor_label()
    for key, rate in rates.items():
        if f"Ultron_{key}" == label:
            rot_comps = actor.get_components_by_class(unreal.RotatingMovementComponent)
            unreal.log_warning(f"{label} has {len(rot_comps)} RotatingMovementComponents")
            for i, rc in enumerate(rot_comps):
                if i == 0:
                    rc.set_editor_property("rotation_rate", unreal.Rotator(rate[0], rate[1], rate[2]))
                    unreal.log_warning(f"Set primary component for {label} to {rate}")
                else:
                    # Disable any duplicates completely
                    rc.set_editor_property("rotation_rate", unreal.Rotator(0.0, 0.0, 0.0))
                    rc.set_editor_property("auto_activate", False)
                    unreal.log_warning(f"Zeroed and deactivated duplicate #{i} for {label}")

unreal.EditorLoadingAndSavingUtils.save_dirty_packages(True, True)
unreal.log_warning("Done fixing components and saved level!")
