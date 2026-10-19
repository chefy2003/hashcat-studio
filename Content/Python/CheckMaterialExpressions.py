import unreal

for name in dir(unreal):
    if "MaterialExpression" in name and ("Scale" in name or "Bounds" in name or "Position" in name or "Actor" in name or "Object" in name):
        unreal.log_warning(f"Found expr: {name}")
