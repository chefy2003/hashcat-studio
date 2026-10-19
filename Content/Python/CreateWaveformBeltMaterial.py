import unreal

package_path = "/Game"
asset_name = "M_Ultron_WaveformBelt"

asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
mat = unreal.load_asset(f"{package_path}/{asset_name}.{asset_name}")
if not mat:
    factory = unreal.MaterialFactoryNew()
    mat = asset_tools.create_asset(asset_name, package_path, unreal.Material, factory)

mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_ADDITIVE)
mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
mat.set_editor_property("two_sided", True)

unreal.MaterialEditingLibrary.delete_all_material_expressions(mat)

# Custom HLSL for dynamic vibrating equalizer/waveform belt
custom_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionCustom, -100, 0)
custom_node.set_editor_property("description", "WaveformEqualizerBelt")
custom_node.set_editor_property("output_type", unreal.CustomMaterialOutputType.CMOT_FLOAT1)

hlsl = """
// UV.x = circumference (0 to 1), UV.y = height (-0.5 to 0.5)
float u = UV.x;
float v = UV.y * 2.0 - 1.0; // [-1.0, 1.0]

// 1. High frequency vertical spectral bars (240 bars around circumference)
float bar_pattern = abs(sin(u * 3.14159 * 240.0));
float bar_mask = step(0.35, bar_pattern);

// 2. Dynamic acoustic/data wave modulation along circumference
float wave1 = sin(u * 3.14159 * 8.0 + Time * 6.0);
float wave2 = sin(u * 3.14159 * 16.0 - Time * 9.0);
float wave3 = sin(u * 3.14159 * 32.0 + Time * 14.0);
float wave4 = sin(Time * 3.5);

// Combined height envelope
float height_envelope = 0.25 + 0.35 * abs(wave1) + 0.20 * abs(wave2) + 0.15 * abs(wave3 * wave4);

// 3. Cut off bars outside envelope
float in_wave = step(abs(v), height_envelope);

// 4. Center intense baseline
float center_line = step(abs(v), 0.04) * 2.5;

// 5. Edge decay
float edge_fade = 1.0 - smoothstep(height_envelope * 0.7, height_envelope, abs(v));

float intensity = (bar_mask * in_wave * edge_fade * 2.8) + center_line;
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

# Holo Color (High-intensity radiant amber-gold: 40.0, 15.0, 1.2)
color_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionVectorParameter, -100, -200)
color_node.set_editor_property("parameter_name", "BeltColor")
color_node.set_editor_property("default_value", unreal.LinearColor(42.0, 15.5, 1.2, 1.0))

mult_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionMultiply, 150, -50)
unreal.MaterialEditingLibrary.connect_material_expressions(color_node, "", mult_node, "A")
unreal.MaterialEditingLibrary.connect_material_expressions(custom_node, "", mult_node, "B")

unreal.MaterialEditingLibrary.connect_material_property(mult_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

unreal.MaterialEditingLibrary.recompile_material(mat)
unreal.EditorAssetLibrary.save_loaded_asset(mat)
unreal.log_warning("[CreateWaveformBeltMaterial] SUCCESS: Compiled M_Ultron_WaveformBelt!")
