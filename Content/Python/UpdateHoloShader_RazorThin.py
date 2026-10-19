import unreal

package_path = "/Game"
asset_name = "M_Ultron_DigitalHolo"

mat = unreal.load_asset(f"{package_path}/{asset_name}.{asset_name}")
unreal.MaterialEditingLibrary.delete_all_material_expressions(mat)

mat.set_editor_property("blend_mode", unreal.BlendMode.BLEND_ADDITIVE)
mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
mat.set_editor_property("two_sided", True)

# Create Custom HLSL expression
custom_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionCustom, -100, 0)
custom_node.set_editor_property("description", "UltronRazorThinHUD")
custom_node.set_editor_property("output_type", unreal.CustomMaterialOutputType.CMOT_FLOAT1)

# Pure zero-background, razor-thin digital HUD shader
hlsl = """
float2 p = UV * 2.0 - 1.0;
float r = length(p);
float theta = atan2(p.y, p.x); // [-PI, PI]

if (r > 0.99) return 0.0;

// 1. Razor-thin concentric rings (fine HUD reticles)
float r_rings = abs(sin(r * 55.0 - Time * 0.8));
float rings = step(0.96, r_rings) * 0.7;

// 2. High-density radial tick marks (compass / azimuth dial)
// Fine ticks on outer rim
float t_fine = abs(sin(theta * 90.0));
float ticks_fine = step(0.92, t_fine) * step(0.80, r) * step(r, 0.96) * 1.2;

// Major heading ticks (longer, every 30 deg)
float t_major = abs(sin(theta * 12.0));
float ticks_major = step(0.88, t_major) * step(0.65, r) * step(r, 0.97) * 2.0;

// Inner quadrant ticks
float t_quad = abs(sin(theta * 24.0));
float ticks_quad = step(0.92, t_quad) * step(0.35, r) * step(r, 0.45) * 1.5;

// 3. Segmented broken orbital tracks
float arc1 = step(0.0, sin(theta * 3.0 + Time * 1.2)) * step(abs(r - 0.92), 0.008) * 2.5;
float arc2 = step(0.2, sin(theta * 5.0 - Time * 0.9)) * step(abs(r - 0.78), 0.006) * 2.0;
float arc3 = step(0.0, sin(theta * 8.0 + Time * 2.0)) * step(abs(r - 0.58), 0.006) * 1.8;
float arc4 = step(abs(r - 0.38), 0.005) * 1.5;
float outer_rim = step(abs(r - 0.97), 0.007) * 2.2;

// 4. Digital matrix nodes / synaptic points
float dot_radial = step(0.97, abs(sin(theta * 36.0)));
float dot_circ = step(0.97, abs(sin(r * 70.0)));
float nodes = dot_radial * dot_circ * step(0.2, r) * step(r, 0.95) * 3.5;

// 5. Delicate center core glow
float core = exp(-r * 6.0) * 1.5;

float total = rings + ticks_fine + ticks_major + ticks_quad + arc1 + arc2 + arc3 + arc4 + outer_rim + nodes + core;
return saturate(total);
"""
custom_node.set_editor_property("code", hlsl)

# Create TextureCoordinate & Time
tex_coord = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionTextureCoordinate, -400, -100)
time_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionTime, -400, 100)

inp_uv = unreal.CustomInput()
inp_uv.set_editor_property("input_name", "UV")
inp_time = unreal.CustomInput()
inp_time.set_editor_property("input_name", "Time")
custom_node.set_editor_property("inputs", [inp_uv, inp_time])

unreal.MaterialEditingLibrary.connect_material_expressions(tex_coord, "", custom_node, "UV")
unreal.MaterialEditingLibrary.connect_material_expressions(time_node, "", custom_node, "Time")

# Holo Color Parameter (Fiery Amber Gold: 30.0, 11.0, 0.8)
color_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionVectorParameter, -100, -200)
color_node.set_editor_property("parameter_name", "HoloColor")
color_node.set_editor_property("default_value", unreal.LinearColor(32.0, 11.5, 0.8, 1.0))

# Multiply Color * Custom Output
mult_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionMultiply, 150, -50)
unreal.MaterialEditingLibrary.connect_material_expressions(color_node, "", mult_node, "A")
unreal.MaterialEditingLibrary.connect_material_expressions(custom_node, "", mult_node, "B")

# Connect to Emissive
unreal.MaterialEditingLibrary.connect_material_property(mult_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

unreal.MaterialEditingLibrary.recompile_material(mat)
unreal.EditorAssetLibrary.save_loaded_asset(mat)
unreal.log_warning("[UpdateHoloShader_RazorThin] SUCCESS: Recompiled razor-thin digital HUD shader!")
