import unreal

package_path = "/Game"
mat = unreal.load_asset(f"{package_path}/M_VoidGrid_Pulsing.M_VoidGrid_Pulsing")
if not mat:
    raise RuntimeError("M_VoidGrid_Pulsing not found!")

unreal.MaterialEditingLibrary.delete_all_material_expressions(mat)
mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
mat.set_editor_property("two_sided", True)

custom_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionCustom, 0, 0)
custom_node.set_editor_property("description", "CinematicPulsingGrid")
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

// Smooth phase ripple across lines (adjacent lines lag slightly)
float line_offset = perp * 0.0006;

// Pulse traveling smoothly from u=0 to u=1
// One main sweeping pulse packet plus trailing harmonic
float wave_coord = (u * 1.0) - (Time * Speed) + line_offset;
float cycle = frac(wave_coord);

// Packet envelope: 40% tail length with smooth energetic falloff
float tail_len = 0.42;
float pulse = 0.0;
if (cycle > (1.0 - tail_len)) {
    float t = (cycle - (1.0 - tail_len)) / tail_len; // 0 to 1
    pulse = pow(t, 2.0); // smooth crescendo
}

// Leading spark bead at the pulse crest
float spark = smoothstep(0.92, 1.0, cycle);

// Color gradient: base neon green-cyan -> electric turquoise -> brilliant white-cyan core
float3 base_color = Color.rgb;
float3 pulse_color = lerp(base_color, float3(0.1, 1.0, 0.8), 0.7);
float3 spark_color = float3(2.0, 3.5, 3.0);

float3 emissive = (base_color * BaseIntensity) + 
                  (pulse_color * pulse * PulseIntensity) + 
                  (spark_color * spark * (PulseIntensity * 1.6));

return emissive;
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
speed_node.set_editor_property("default_value", 0.32) # ~3.1 seconds to traverse 16 meters

base_int_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -450, 550)
base_int_node.set_editor_property("parameter_name", "BaseIntensity")
base_int_node.set_editor_property("default_value", 1.0)

pulse_int_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -450, 700)
pulse_int_node.set_editor_property("parameter_name", "PulseIntensity")
pulse_int_node.set_editor_property("default_value", 65.0) # High-energy radiant bloom

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
unreal.EditorLoadingAndSavingUtils.save_dirty_packages(True, True)
unreal.log_warning("[TuneGridPulse] Recompiled and tuned M_VoidGrid_Pulsing successfully!")
