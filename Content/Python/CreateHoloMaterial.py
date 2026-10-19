import unreal

package_path = "/Game"
asset_name = "M_Ultron_DigitalHolo"

# 1. Create or get Material
asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
mat = unreal.load_asset(f"{package_path}/{asset_name}.{asset_name}")
if not mat:
    factory = unreal.MaterialFactoryNew()
    mat = asset_tools.create_asset(asset_name, package_path, unreal.Material, factory)

mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_ADDITIVE)
mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
mat.set_editor_property("two_sided", True)

# Delete existing expressions
unreal.MaterialEditingLibrary.delete_all_material_expressions(mat)

# Color Parameter (Fiery Amber Ultron)
color_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionVectorParameter, -600, -200)
color_node.set_editor_property("parameter_name", "HoloColor")
color_node.set_editor_property("default_value", unreal.LinearColor(22.0, 8.5, 0.6, 1.0))

# Fresnel Node
fresnel_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionFresnel, -400, 100)
fresnel_node.set_editor_property("exponent", 2.5)
fresnel_node.set_editor_property("base_reflect_fraction", 0.15)

# World Position for Scanlines
world_pos = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionWorldPosition, -800, 300)
mask_z = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionComponentMask, -600, 300)
mask_z.set_editor_property("b", True) # Z component
mask_z.set_editor_property("r", False)
mask_z.set_editor_property("g", False)
unreal.MaterialEditingLibrary.connect_material_expressions(world_pos, "", mask_z, "")

# Frequency multiplier
freq_mult = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionMultiply, -400, 300)
scalar_freq = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionConstant, -550, 450)
scalar_freq.set_editor_property("r", 0.5) # Scanline density
unreal.MaterialEditingLibrary.connect_material_expressions(mask_z, "", freq_mult, "A")
unreal.MaterialEditingLibrary.connect_material_expressions(scalar_freq, "", freq_mult, "B")

# Sine scanlines
sine_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionSine, -250, 300)
unreal.MaterialEditingLibrary.connect_material_expressions(freq_mult, "", sine_node, "")

# Scale sine from [-1, 1] to [0.3, 1.0]
sine_bias = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionLinearInterpolate, -100, 300)
sine_bias.set_editor_property("const_a", 0.4)
sine_bias.set_editor_property("const_b", 1.0)
unreal.MaterialEditingLibrary.connect_material_expressions(sine_node, "", sine_bias, "Alpha")

# Multiply Fresnel * Scanlines
fresnel_scan = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionMultiply, 50, 150)
unreal.MaterialEditingLibrary.connect_material_expressions(fresnel_node, "", fresnel_scan, "A")
unreal.MaterialEditingLibrary.connect_material_expressions(sine_bias, "", fresnel_scan, "B")

# Final Multiply: Color * (Fresnel * Scanlines)
final_mult = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionMultiply, 250, 0)
unreal.MaterialEditingLibrary.connect_material_expressions(color_node, "", final_mult, "A")
unreal.MaterialEditingLibrary.connect_material_expressions(fresnel_scan, "", final_mult, "B")

# Connect to Emissive
unreal.MaterialEditingLibrary.connect_material_property(final_mult, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

unreal.MaterialEditingLibrary.recompile_material(mat)
unreal.EditorAssetLibrary.save_loaded_asset(mat)
unreal.log_warning("[CreateHoloMaterial] Successfully compiled M_Ultron_DigitalHolo!")
