import unreal
subsystem = unreal.get_engine_subsystem(unreal.SubobjectDataSubsystem)
methods = [m for m in dir(subsystem) if not m.startswith('_')]
unreal.log_warning("SubobjectDataSubsystem methods: " + ", ".join(methods))

lib_methods = [m for m in dir(unreal.SubobjectDataBlueprintFunctionLibrary) if not m.startswith('_')]
unreal.log_warning("SubobjectDataBlueprintFunctionLibrary methods: " + ", ".join(lib_methods))
