import unreal

package_path = "/Game"
mat_name = "M_VoidGrid_Pulsing"
asset_tools = unreal.AssetToolsHelpers.get_asset_tools()

existing = unreal.load_asset(f"{package_path}/{mat_name}")
if not existing:
    mat = asset_tools.create_asset(mat_name, package_path, unreal.Material, unreal.MaterialFactoryNew())
else:
    mat = existing

unreal.MaterialEditingLibrary.delete_all_material_expressions(mat)

# Shading Model: Unlit or DefaultLit with Emissive
mat.set_editor_property("shading_model", unreal.MaterialShadingModel.MSM_UNLIT)
mat.set_editor_property("two_sided", True)

custom_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionCustom, 0, 0)
custom_node.set_editor_property("description", "PulsingGridLines")
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

// Phase offset per line based on its perpendicular position (-700 to +700)
// Normalize perp (-700..700) to 0..1 wave delay
float line_phase = (perp + 800.0) / 1600.0 * 0.6;

// Pulse timing: traveling from u=0 to u=1
// Cycle repeats every (1.0 / speed) seconds
float cycle = frac(Time * Speed - line_phase);

// Distance from pixel u to pulse head
float d = u - cycle;

// Tail calculation: pulse travels in positive direction (head at cycle, tail trailing behind)
float tail_len = TailLength;
float pulse_glow = 0.0;

// Pulse head and comet tail
if (d <= 0.0 && d > -tail_len) {
    float norm_d = -d / tail_len; // 0 at head, 1 at tail
    pulse_glow = pow(1.0 - norm_d, 2.2);
}
// Smooth front edge glow
if (d > 0.0 && d < 0.04) {
    pulse_glow = max(pulse_glow, (1.0 - d / 0.04) * 0.8);
}

// Emissive composition
float3 base_c = Color.rgb;
// White-hot core at the peak of the pulse
float3 pulse_c = lerp(base_c * PulseIntensity, float3(2.5, 4.0, 3.2) * (PulseIntensity * 1.5), pow(pulse_glow, 2.5));

float3 final_emissive = (base_c * BaseIntensity) + (pulse_c * pulse_glow);
return final_emissive;
"""
custom_node.set_editor_property("code", hlsl_code)

# Inputs
world_pos = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionWorldPosition, -450, -200)
actor_pos = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionActorPositionWS, -450, -50)
time_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionTime, -450, 100)

color_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionVectorParameter, -450, 250)
color_node.set_editor_property("parameter_name", "GridColor")
color_node.set_editor_property("default_value", unreal.LinearColor(0.0, 1.0, 0.35, 1.0))

speed_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -450, 400)
speed_node.set_editor_property("parameter_name", "Speed")
speed_node.set_editor_property("default_value", 0.30)

tail_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -450, 550)
tail_node.set_editor_property("parameter_name", "TailLength")
tail_node.set_editor_property("default_value", 0.22)

base_int_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -450, 700)
base_int_node.set_editor_property("parameter_name", "BaseIntensity")
base_int_node.set_editor_property("default_value", 1.2)

pulse_int_node = unreal.MaterialEditingLibrary.create_material_expression(mat, unreal.MaterialExpressionScalarParameter, -450, 850)
pulse_int_node.set_editor_property("parameter_name", "PulseIntensity")
pulse_int_node.set_editor_property("default_value", 18.0)

inputs = []
for name in ["WorldPos", "ActorPos", "Time", "Color", "Speed", "TailLength", "BaseIntensity", "PulseIntensity"]:
    inp = unreal.CustomInput()
    inp.set_editor_property("input_name", name)
    inputs.append(inp)

custom_node.set_editor_property("inputs", inputs)

unreal.MaterialEditingLibrary.connect_material_expressions(world_pos, "", custom_node, "WorldPos")
unreal.MaterialEditingLibrary.connect_material_expressions(actor_pos, "", custom_node, "ActorPos")
unreal.MaterialEditingLibrary.connect_material_expressions(time_node, "", custom_node, "Time")
unreal.MaterialEditingLibrary.connect_material_expressions(color_node, "", custom_node, "Color")
unreal.MaterialEditingLibrary.connect_material_expressions(speed_node, "", custom_node, "Speed")
unreal.MaterialEditingLibrary.connect_material_expressions(tail_node, "", custom_node, "TailLength")
unreal.MaterialEditingLibrary.connect_material_expressions(base_int_node, "", custom_node, "BaseIntensity")
unreal.MaterialEditingLibrary.connect_material_expressions(pulse_int_node, "", custom_node, "PulseIntensity")

unreal.MaterialEditingLibrary.connect_material_property(custom_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)

unreal.MaterialEditingLibrary.recompile_material(mat)
unreal.EditorAssetLibrary.save_loaded_asset(mat)
unreal.log_warning("[TestCreatePulsingGridMaterial] Successfully compiled M_VoidGrid_Pulsing!")
