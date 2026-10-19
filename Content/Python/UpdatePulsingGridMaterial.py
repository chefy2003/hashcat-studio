import unreal

package_path = "/Game"
mat_name = "M_VoidGrid_Pulsing"
mat = unreal.load_asset(f"{package_path}/{mat_name}")
if not mat:
    raise RuntimeError("M_VoidGrid_Pulsing not found!")

unreal.MaterialEditingLibrary.delete_all_material_expressions(mat)

mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
mat.set_editor_property("two_sided", True)

custom_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionCustom, 0, 0)
custom_node.set_editor_property("description", "VibrantPulsingGridLines")
custom_node.set_editor_property("output_type", unreal.CustomMaterialOutputType.CMOT_FLOAT3)

hlsl_code = """
// World and Actor positions
float3 diff = WorldPos - ActorPos;

// Determine orientation: if line is along X or Y
bool is_x_line = abs(diff.x) > abs(diff.y);
float coord = is_x_line ? diff.x : diff.y;
float perp = is_x_line ? ActorPos.y : ActorPos.x;

// Normalized 0.0 to 1.0 along the 1600cm line (-800 to +800)
float u = (coord / 1600.0) + 0.5;
u = clamp(u, 0.0, 1.0);

// Traveling wave from end to end:
// u * 1.25 gives ~1.25 pulses along the 16m line at any time
float wave_coord = (u * 1.25) - (Time * Speed) + (perp * 0.00085);
float cycle = frac(wave_coord);

// Pulse shape: sharp glowing head, smooth exponential comet tail
float tail_len = 0.38;
float pulse_glow = 0.0;
if (cycle > (1.0 - tail_len)) {
    float t = (cycle - (1.0 - tail_len)) / tail_len;
    pulse_glow = pow(t, 2.2);
}

// Intense white-hot photon bead at pulse front
float head_spark = smoothstep(0.94, 1.0, cycle);

// Emissive composition
float3 base_c = Color.rgb * BaseIntensity;
float3 pulse_c = Color.rgb * (PulseIntensity * pulse_glow);
float3 spark_c = float3(2.5, 4.0, 3.2) * (PulseIntensity * 1.8 * head_spark);

return base_c + pulse_c + spark_c;
"""
custom_node.set_editor_property("code", hlsl_code)

world_pos = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionWorldPosition, -450, -200)
actor_pos = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionActorPositionWS, -450, -50)
time_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionTime, -450, 100)

color_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionVectorParameter, -450, 250)
color_node.set_editor_property("parameter_name", "GridColor")
color_node.set_editor_property("default_value", unreal.LinearColor(0.0, 1.0, 0.35, 1.0))

speed_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -450, 400)
speed_node.set_editor_property("parameter_name", "Speed")
speed_node.set_editor_property("default_value", 0.28) # Majestic smooth speed

base_int_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -450, 550)
base_int_node.set_editor_property("parameter_name", "BaseIntensity")
base_int_node.set_editor_property("default_value", 1.2)

pulse_int_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -450, 700)
pulse_int_node.set_editor_property("parameter_name", "PulseIntensity")
pulse_int_node.set_editor_property("default_value", 42.0) # High-energy radiant glow

inputs = []
for name in ["WorldPos", "ActorPos", "Time", "Color", "Speed", "BaseIntensity", "PulseIntensity"]:
    inp = unreal.CustomInput()
    inp.set_editor_property("input_name", name)
    inputs.append(inp)

custom_node.set_editor_property("inputs", inputs)

unreal.MaterialEditingLibrary.connect_material_expressions(world_pos, "", custom_node, "WorldPos")
unreal.MaterialEditingLibrary.connect_material_expressions(actor_pos, "", custom_node, "ActorPos")
unreal.MaterialEditingLibrary.connect_material_expressions(time_node, "", custom_node, "Time")
unreal.MaterialEditingLibrary.connect_material_expressions(color_node, "", custom_node, "Color")
unreal.MaterialEditingLibrary.connect_material_expressions(speed_node, "", custom_node, "Speed")
unreal.MaterialEditingLibrary.connect_material_expressions(base_int_node, "", custom_node, "BaseIntensity")
unreal.MaterialEditingLibrary.connect_material_expressions(pulse_int_node, "", custom_node, "PulseIntensity")

unreal.MaterialEditingLibrary.connect_material_property(custom_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

unreal.MaterialEditingLibrary.recompile_material(mat)
unreal.EditorAssetLibrary.save_loaded_asset(mat)
unreal.log_warning("[UpdatePulsingGridMaterial] Recompiled and saved M_VoidGrid_Pulsing successfully!")
