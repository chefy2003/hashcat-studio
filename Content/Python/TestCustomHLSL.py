import unreal

package_path = "/Game"
asset_name = "M_Ultron_DigitalHolo"

mat = unreal.load_asset(f"{package_path}/{asset_name}.{asset_name}")
unreal.MaterialEditingLibrary.delete_all_material_expressions(mat)

# Create Custom HLSL expression
custom_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionCustom, -200, 0)
custom_node.set_editor_property("description", "UltronHoloPattern")
custom_node.set_editor_property("output_type", unreal.CustomMaterialOutputType.CMOT_FLOAT1)

# Code
hlsl = """
float2 p = UV * 2.0 - 1.0;
float r = length(p);
float theta = atan2(p.y, p.x);

// Concentric rings
float rings = smoothstep(0.88, 0.98, sin(r * 40.0 - Time * 1.5) * 0.5 + 0.5);

// Radial ticks
float ticks_fine = smoothstep(0.90, 0.98, sin(theta * 48.0)) * step(0.25, r) * step(r, 0.95);
float ticks_major = smoothstep(0.85, 0.98, sin(theta * 12.0)) * step(0.5, r) * step(r, 0.98);

// Segmented arcs
float arc_break = step(0.1, sin(theta * 4.0 + Time * 0.8));
float track1 = smoothstep(0.03, 0.0, abs(r - 0.88)) * arc_break;
float track2 = smoothstep(0.02, 0.0, abs(r - 0.62)) * step(0.0, sin(theta * 6.0 - Time));
float track3 = smoothstep(0.02, 0.0, abs(r - 0.35));

// Digital node points
float dots = step(0.95, sin(theta * 24.0)) * step(0.95, sin(r * 45.0));

float core_glow = exp(-r * 3.5) * 2.0;

return saturate(rings * 0.5 + ticks_fine * 0.8 + ticks_major * 1.2 + track1 * 1.5 + track2 * 1.3 + track3 + dots * 2.0 + core_glow);
"""
custom_node.set_editor_property("code", hlsl)

# Inputs: UV and Time
# Create TextureCoordinate
tex_coord = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionTextureCoordinate, -500, -100)
# Create Time
time_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionTime, -500, 100)

# Add inputs to custom node
inp_uv = unreal.CustomInput()
inp_uv.set_editor_property("input_name", "UV")
inp_time = unreal.CustomInput()
inp_time.set_editor_property("input_name", "Time")

custom_node.set_editor_property("inputs", [inp_uv, inp_time])

# Connect inputs
unreal.MaterialEditingLibrary.connect_material_expressions(tex_coord, "", custom_node, "UV")
unreal.MaterialEditingLibrary.connect_material_expressions(time_node, "", custom_node, "Time")

# Fresnel node
fresnel_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionFresnel, -200, 250)
fresnel_node.set_editor_property("exponent", 2.0)
fresnel_node.set_editor_property("base_reflect_fraction", 0.3)

# Add Pattern + Fresnel
add_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionAdd, 50, 100)
unreal.MaterialEditingLibrary.connect_material_expressions(custom_node, "", add_node, "A")
unreal.MaterialEditingLibrary.connect_material_expressions(fresnel_node, "", add_node, "B")

# Holo Color
color_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionVectorParameter, 50, -150)
color_node.set_editor_property("parameter_name", "HoloColor")
color_node.set_editor_property("default_value", unreal.LinearColor(25.0, 9.5, 0.8, 1.0))

# Multiply Color * (Pattern + Fresnel)
mult_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionMultiply, 250, 0)
unreal.MaterialEditingLibrary.connect_material_expressions(color_node, "", mult_node, "A")
unreal.MaterialEditingLibrary.connect_material_expressions(add_node, "", mult_node, "B")

# Connect to Emissive
unreal.MaterialEditingLibrary.connect_material_property(mult_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

unreal.MaterialEditingLibrary.recompile_material(mat)
unreal.EditorAssetLibrary.save_loaded_asset(mat)
unreal.log_warning("[TestCustomHLSL] Successfully compiled advanced HLSL digital hologram shader!")
