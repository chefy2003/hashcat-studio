import unreal
ar = unreal.AssetRegistryHelpers.get_asset_registry()
textures = ar.get_assets_by_class(unreal.TopLevelAssetPath('/Script/Engine', 'Texture2D'))
unreal.log_warning(f"Total Textures: {len(textures)}")
matches = []
for t in textures:
    name = str(t.package_name).lower()
    if any(k in name for k in ['grid', 'circle', 'ring', 'noise', 'scan', 'dial', 'hud', 'reticle', 'radial', 'flare']):
        matches.append(str(t.package_name))

unreal.log_warning(f"Matching textures ({len(matches)}):")
for m in matches[:40]:
    unreal.log_warning(f"  {m}")
