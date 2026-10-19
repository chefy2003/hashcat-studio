import unreal
ar = unreal.AssetRegistryHelpers.get_asset_registry()
textures = ar.get_assets_by_class(unreal.TopLevelAssetPath('/Script/Engine', 'Texture2D'))
matches = []
for t in textures:
    name = str(t.package_name).lower()
    if any(k in name for k in ['holo', 'circle', 'ring', 'scan', 'dial', 'reticle', 'radial']):
        matches.append(str(t.package_name))

unreal.log_warning(f"Holo textures found ({len(matches)}):")
for m in matches:
    unreal.log_warning(f"  {m}")
