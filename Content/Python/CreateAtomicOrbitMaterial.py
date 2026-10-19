import unreal

package_path = "/Game"
asset_name = "M_Ultron_AtomicOrbit"

asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
mat = unreal.load_asset(f"{package_path}/{asset_name}.{asset_name}")
if not mat:
    factory = unreal.MaterialFactoryNew()
    mat = asset_tools.create_asset(asset_name, package_path, unreal.Material, factory)

mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_ADDITIVE)
mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
mat.set_editor_property("two_sided", True)

unreal.MaterialEditingLibrary.delete_all_material_expressions(mat)

# Custom HLSL for dotted celestial atomic orbit with circulating electron beads
custom_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionCustom, -100, 0)
custom_node.set_editor_property("description", "AtomicOrbitalParticleTrack")
custom_node.set_editor_property("output_type", unreal.CustomMaterialOutputType.CMOT_FLOAT1)

hlsl = """
float2 p = UV * 2.0 - 1.0;
float r = length(p);
if (r > 0.99) return 0.0;

float theta = atan2(p.y, p.x); // [-PI, PI]

// Elliptical or circular track at radius ~0.88
float track_dist = abs(r - 0.88);

// 1. Dotted starlight path (120 fine dots along the circumference)
float dot_pattern = abs(sin(theta * 60.0));
float dotted_ring = step(0.85, dot_pattern) * step(track_dist, 0.008) * 1.5;

// Continuous fine baseline ring
float fine_line = step(track_dist, 0.003) * 0.8;

// 2. Circulating bright electron data beads (3 beads traveling along orbit)
float bead_pos1 = sin(theta * 1.0 - Time * 2.5);
float bead1 = pow(saturate(bead_pos1), 32.0) * step(track_dist, 0.025) * 6.0;

float bead_pos2 = sin(theta * 1.0 - Time * 2.5 + 2.094); // 120 deg offset
float bead2 = pow(saturate(bead_pos2), 32.0) * step(track_dist, 0.025) * 5.0;

float bead_pos3 = sin(theta * 1.0 - Time * 2.5 + 4.188); // 240 deg offset
float bead3 = pow(saturate(bead_pos3), 32.0) * step(track_dist, 0.025) * 5.0;

// Trailing comet tail behind beads
float tail = smoothstep(-0.2, 0.8, sin(theta * 1.0 - Time * 2.5)) * step(track_dist, 0.007) * 1.2;

float intensity = dotted_ring + fine_line + bead1 + bead2 + bead3 + tail;
return saturate(intensity);
"""
custom_node.set_editor_property("code", hlsl)

# Connect UV and Time
tex_coord = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionTextureCoordinate, -400, -100)
time_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionTime, -400, 100)

inp_uv = unreal.CustomInput()
inp_uv.set_editor_property("input_name", "UV")
inp_time = unreal.CustomInput()
inp_time.set_editor_property("input_name", "Time")
custom_node.set_editor_property("inputs", [inp_uv, inp_time])

unreal.MaterialEditingLibrary.connect_material_expressions(tex_coord, "", custom_node, "UV")
unreal.MaterialEditingLibrary.connect_material_expressions(time_node, "", custom_node, "Time")

# Radiant Golden Color (35.0, 13.0, 1.0)
color_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionVectorParameter, -100, -200)
color_node.set_editor_property("parameter_name", "OrbitColor")
color_node.set_editor_property("default_value", unreal.LinearColor(38.0, 14.0, 1.0, 1.0))

mult_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionMultiply, 150, -50)
unreal.MaterialEditingLibrary.connect_material_expressions(color_node, "", mult_node, "A")
unreal.MaterialEditingLibrary.connect_material_expressions(custom_node, "", mult_node, "B")

unreal.MaterialEditingLibrary.connect_material_property(mult_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

unreal.MaterialEditingLibrary.recompile_material(mat)
unreal.EditorAssetLibrary.save_loaded_asset(mat)
unreal.log_warning("[CreateAtomicOrbitMaterial] SUCCESS: Compiled M_Ultron_AtomicOrbit!")
