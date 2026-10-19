import unreal
ar = unreal.AssetRegistryHelpers.get_asset_registry()
assets = ar.get_assets_by_path('/Game', recursive=True)
unreal.log_warning("=== ALL /Game ASSETS ===")
for a in assets:
    unreal.log_warning(f"{a.asset_class_path.asset_name}: {a.package_name}")
