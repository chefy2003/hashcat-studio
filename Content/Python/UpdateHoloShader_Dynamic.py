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
custom_node.set_editor_property("description", "UltronDynamicHUD")
custom_node.set_editor_property("output_type", unreal.CustomMaterialOutputType.CMOT_FLOAT1)

# Dynamic, continuously moving, pulsing, rotating digital HUD shader
hlsl = """
float2 p = UV * 2.0 - 1.0;
float r = length(p);
if (r > 0.99) return 0.0;

float theta = atan2(p.y, p.x); // [-PI, PI]

// 1. Dynamic Angular Rotations (Different speeds and directions)
float theta_fast = theta + Time * 0.85;
float theta_mid  = theta - Time * 0.45;
float theta_slow = theta + Time * 0.22;
float theta_pulse = theta + sin(Time * 1.5) * 0.35;

// 2. Outward/Inward Expanding Digital Data Waves
float wave = sin(r * 45.0 - Time * 3.0);
float rings = step(0.95, abs(wave)) * 0.9;
float rings_fine = step(0.97, abs(sin(r * 80.0))) * 0.5;

// 3. Spinning Azimuth Tick Marks (Compass Dials)
float t_outer = abs(sin(theta_slow * 72.0));
float ticks_outer = step(0.92, t_outer) * step(0.82, r) * step(r, 0.96) * 1.6;

float t_major = abs(sin(theta_slow * 12.0));
float ticks_major = step(0.86, t_major) * step(0.68, r) * step(r, 0.97) * 2.4;

float t_inner = abs(sin(theta_mid * 36.0));
float ticks_inner = step(0.90, t_inner) * step(0.38, r) * step(r, 0.52) * 2.0;

// 4. Orbiting Segmented Broken Arcs (Radar Sweeps)
float arc1 = step(0.15, sin(theta_fast * 3.0)) * step(abs(r - 0.91), 0.009) * 3.2;
float arc2 = step(0.10, sin(theta_mid * 5.0)) * step(abs(r - 0.76), 0.008) * 2.6;
float arc3 = step(0.25, sin(theta_pulse * 7.0)) * step(abs(r - 0.60), 0.007) * 2.2;
float arc4 = step(0.00, sin(theta_fast * 11.0)) * step(abs(r - 0.32), 0.006) * 2.0;
float outer_rim = step(abs(r - 0.97), 0.007) * 2.8;

// 5. Scintillating Neural Synapse Dots (Orbiting data packets)
float dot_angle = abs(sin(theta_fast * 24.0));
float dot_radius = abs(sin(r * 60.0 - Time * 2.5));
float sparkle = sin(Time * 8.0 + theta * 12.0) * 0.5 + 0.5;
float nodes = step(0.96, dot_angle) * step(0.96, dot_radius) * step(0.22, r) * step(r, 0.95) * (2.5 + sparkle * 3.0);

// 6. Pulsing Energetic Core Singularity
float core_pulse = 1.0 + 0.3 * sin(Time * 4.5);
float core = exp(-r * 6.5) * (2.2 * core_pulse);

float total = rings + rings_fine + ticks_outer + ticks_major + ticks_inner + arc1 + arc2 + arc3 + arc4 + outer_rim + nodes + core;
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

# Holo Color Parameter (Fiery Amber Gold)
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
unreal.log_warning("[UpdateHoloShader_Dynamic] SUCCESS: Recompiled dynamic animated HLSL shader!")
