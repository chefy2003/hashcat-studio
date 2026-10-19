import unreal

ar = unreal.AssetRegistryHelpers.get_asset_registry()
niagara_assets = ar.get_assets_by_class(unreal.TopLevelAssetPath('/Script/Niagara', 'NiagaraSystem'))

unreal.log_warning("=== NIAGARA SYSTEMS IN PROJECT ===")
for a in niagara_assets:
    unreal.log_warning(f"  {a.package_name}")

mats = ar.get_assets_by_class(unreal.TopLevelAssetPath('/Script/Engine', 'Material'))
unreal.log_warning("=== SOME MATERIALS ===")
for m in list(mats)[:30]:
    unreal.log_warning(f"  {m.package_name}")
