import unreal
ar = unreal.AssetRegistryHelpers.get_asset_registry()
mats = ar.get_assets_by_class(unreal.TopLevelAssetPath('/Script/Engine', 'Material'))
matches = []
for m in mats:
    name = str(m.package_name).lower()
    if any(k in name for k in ['holo', 'grid', 'wire', 'scan', 'shield', 'hud', 'glow']):
        matches.append(str(m.package_name))

unreal.log_warning(f"Holo / Grid materials found ({len(matches)}):")
for m in matches:
    unreal.log_warning(f"  {m}")
