import unreal

subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
ns_asset = unreal.load_asset("/Game/NS_MatrixEnergyCore.NS_MatrixEnergyCore")
unreal.log_warning(f"Loaded NS asset: {ns_asset}")

if ns_asset:
    # Test spawning
    actor = subsystem.spawn_actor_from_class(unreal.Actor, unreal.Vector(0, 0, 165))
    actor.set_actor_label("Ultron_Niagara_Core")
    actor.tags.append("UltronCore")
    
    comp = unreal.NiagaraFunctionLibrary.spawn_system_attached(
        ns_asset,
        actor.root_component,
        unreal.Name("None"),
        unreal.Vector(0, 0, 0),
        unreal.Rotator(0, 0, 0),
        unreal.AttachLocation.KEEP_RELATIVE_OFFSET,
        True
    )
    unreal.log_warning(f"Spawned Niagara component: {comp}")
