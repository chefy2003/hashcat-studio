import unreal

subsystem = unreal.get_engine_subsystem(unreal.SubobjectDataSubsystem)
sub_lib = unreal.SubobjectDataBlueprintFunctionLibrary
actor_subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

rates = {
    "Nucleus": (0.0, 45.0, 0.0),
    "WaveformBelt": (0.0, 8.0, 0.0),
    "WaveformBelt_Inner": (0.0, -14.0, 0.0),
    "Gimbal_HoopA": (14.0, 26.0, 8.0),
    "Gimbal_HoopB": (-12.0, -32.0, -6.0),
    "Gimbal_EquatorialDial": (0.0, 18.0, 0.0),
    "AtomicOrbitA": (8.0, 20.0, 5.0),
    "AtomicOrbitB": (-10.0, -24.0, 10.0),
    "AtomicOrbitC": (16.0, -15.0, 18.0),
    "InnerHelixSphere": (18.0, -30.0, 15.0),
    "MidNeuralSphere": (-8.0, 16.0, -10.0)
}

success_count = 0
for actor in actor_subsystem.get_all_level_actors():
    label = actor.get_actor_label()
    for key, rate in rates.items():
        if f"Ultron_{key}" == label:
            try:
                handles = subsystem.k2_gather_subobject_data_for_instance(actor)
                root_handle = handles[0]
                
                params = unreal.AddNewSubobjectParams()
                params.set_editor_property("parent_handle", root_handle)
                params.set_editor_property("new_class", unreal.RotatingMovementComponent)
                
                new_handle, fail_reason = subsystem.add_new_subobject(params)
                if sub_lib.is_handle_valid(new_handle):
                    sub_data = subsystem.k2_find_subobject_data_from_handle(new_handle)
                    comp = sub_lib.get_object(sub_data)
                    if comp:
                        comp.set_editor_property("rotation_rate", unreal.Rotator(rate[0], rate[1], rate[2]))
                        unreal.log_warning(f"SUCCESS: Attached RotatingMovement to {label}: {rate}")
                        success_count += 1
                else:
                    unreal.log_warning(f"Failed to add to {label}: {fail_reason}")
            except Exception as e:
                import traceback
                unreal.log_warning(f"Error on {label}: {traceback.format_exc()}")

unreal.log_warning(f"[AttachAllRotatingMovement] Successfully attached {success_count} components!")
