import unreal

package_path = "/Game"

# 1. Update M_Ultron_WaveformBelt (Smooth, organic equalizer)
mat_belt = unreal.load_asset(f"{package_path}/M_Ultron_WaveformBelt.M_Ultron_WaveformBelt")
if mat_belt:
    unreal.MaterialEditingLibrary.delete_all_material_expressions(mat_belt)
    custom_node = unreal.MaterialEditingLibrary.create_material_expression(mat_belt, unreal.MaterialExpressionCustom, -100, 0)
    custom_node.set_editor_property("description", "SmoothWaveformBelt")
    custom_node.set_editor_property("output_type", unreal.CustomMaterialOutputType.CMOT_FLOAT1)
    
    hlsl_belt = """
    float u = UV.x;
    float v = UV.y * 2.0 - 1.0;
    
    // 240 fine vertical bars
    float bar_pattern = abs(sin(u * 3.14159 * 240.0));
    float bar_mask = step(0.35, bar_pattern);
    
    // Slow, organic breathing waves (reduced ~3.5x for natural motion)
    float wave1 = sin(u * 3.14159 * 6.0 + Time * 1.6);
    float wave2 = sin(u * 3.14159 * 12.0 - Time * 2.2);
    float wave3 = sin(u * 3.14159 * 24.0 + Time * 3.2);
    float wave4 = sin(Time * 0.9);
    
    float height_envelope = 0.25 + 0.30 * abs(wave1) + 0.18 * abs(wave2) + 0.12 * abs(wave3 * wave4);
    float in_wave = step(abs(v), height_envelope);
    float center_line = step(abs(v), 0.04) * 2.2;
    float edge_fade = 1.0 - smoothstep(height_envelope * 0.7, height_envelope, abs(v));
    
    return saturate((bar_mask * in_wave * edge_fade * 2.5) + center_line);
    """
    custom_node.set_editor_property("code", hlsl_belt)
    
    tex_coord = unreal.MaterialEditingLibrary.create_material_expression(mat_belt, unreal.MaterialExpressionTextureCoordinate, -400, -100)
    time_node = unreal.MaterialEditingLibrary.create_material_expression(mat_belt, unreal.MaterialExpressionTime, -400, 100)
    inp_uv = unreal.CustomInput()
    inp_uv.set_editor_property("input_name", "UV")
    inp_time = unreal.CustomInput()
    inp_time.set_editor_property("input_name", "Time")
    custom_node.set_editor_property("inputs", [inp_uv, inp_time])
    unreal.MaterialEditingLibrary.connect_material_expressions(tex_coord, "", custom_node, "UV")
    unreal.MaterialEditingLibrary.connect_material_expressions(time_node, "", custom_node, "Time")
    
    color_node = unreal.MaterialEditingLibrary.create_material_expression(mat_belt, unreal.MaterialExpressionVectorParameter, -100, -200)
    color_node.set_editor_property("parameter_name", "BeltColor")
    color_node.set_editor_property("default_value", unreal.LinearColor(38.0, 14.5, 1.2, 1.0))
    
    mult_node = unreal.MaterialEditingLibrary.create_material_expression(mat_belt, unreal.MaterialExpressionMultiply, 150, -50)
    unreal.MaterialEditingLibrary.connect_material_expressions(color_node, "", mult_node, "A")
    unreal.MaterialEditingLibrary.connect_material_expressions(custom_node, "", mult_node, "B")
    unreal.MaterialEditingLibrary.connect_material_property(mult_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    unreal.MaterialEditingLibrary.recompile_material(mat_belt)
    unreal.EditorAssetLibrary.save_loaded_asset(mat_belt)

# 2. Update M_Ultron_AtomicOrbit (Smooth gliding electron beads)
mat_orbit = unreal.load_asset(f"{package_path}/M_Ultron_AtomicOrbit.M_Ultron_AtomicOrbit")
if mat_orbit:
    unreal.MaterialEditingLibrary.delete_all_material_expressions(mat_orbit)
    custom_node = unreal.MaterialEditingLibrary.create_material_expression(mat_orbit, unreal.MaterialExpressionCustom, -100, 0)
    custom_node.set_editor_property("description", "SmoothAtomicOrbit")
    custom_node.set_editor_property("output_type", unreal.CustomMaterialOutputType.CMOT_FLOAT1)
    
    hlsl_orbit = """
    float2 p = UV * 2.0 - 1.0;
    float r = length(p);
    if (r > 0.99) return 0.0;
    float theta = atan2(p.y, p.x);
    float track_dist = abs(r - 0.88);
    
    float dot_pattern = abs(sin(theta * 60.0));
    float dotted_ring = step(0.85, dot_pattern) * step(track_dist, 0.008) * 1.5;
    float fine_line = step(track_dist, 0.003) * 0.8;
    
    // Slow gliding speed: Time * 0.7 instead of 2.5
    float bead1 = pow(saturate(sin(theta - Time * 0.7)), 32.0) * step(track_dist, 0.025) * 5.0;
    float bead2 = pow(saturate(sin(theta - Time * 0.7 + 2.094)), 32.0) * step(track_dist, 0.025) * 4.5;
    float bead3 = pow(saturate(sin(theta - Time * 0.7 + 4.188)), 32.0) * step(track_dist, 0.025) * 4.5;
    float tail = smoothstep(-0.2, 0.8, sin(theta - Time * 0.7)) * step(track_dist, 0.007) * 1.0;
    
    return saturate(dotted_ring + fine_line + bead1 + bead2 + bead3 + tail);
    """
    custom_node.set_editor_property("code", hlsl_orbit)
    
    tex_coord = unreal.MaterialEditingLibrary.create_material_expression(mat_orbit, unreal.MaterialExpressionTextureCoordinate, -400, -100)
    time_node = unreal.MaterialEditingLibrary.create_material_expression(mat_orbit, unreal.MaterialExpressionTime, -400, 100)
    inp_uv = unreal.CustomInput()
    inp_uv.set_editor_property("input_name", "UV")
    inp_time = unreal.CustomInput()
    inp_time.set_editor_property("input_name", "Time")
    custom_node.set_editor_property("inputs", [inp_uv, inp_time])
    unreal.MaterialEditingLibrary.connect_material_expressions(tex_coord, "", custom_node, "UV")
    unreal.MaterialEditingLibrary.connect_material_expressions(time_node, "", custom_node, "Time")
    
    color_node = unreal.MaterialEditingLibrary.create_material_expression(mat_orbit, unreal.MaterialExpressionVectorParameter, -100, -200)
    color_node.set_editor_property("parameter_name", "OrbitColor")
    color_node.set_editor_property("default_value", unreal.LinearColor(35.0, 13.0, 1.0, 1.0))
    
    mult_node = unreal.MaterialEditingLibrary.create_material_expression(mat_orbit, unreal.MaterialExpressionMultiply, 150, -50)
    unreal.MaterialEditingLibrary.connect_material_expressions(color_node, "", mult_node, "A")
    unreal.MaterialEditingLibrary.connect_material_expressions(custom_node, "", mult_node, "B")
    unreal.MaterialEditingLibrary.connect_material_property(mult_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    unreal.MaterialEditingLibrary.recompile_material(mat_orbit)
    unreal.EditorAssetLibrary.save_loaded_asset(mat_orbit)

# 3. Update M_Ultron_DigitalHolo (Smooth, majestic HUD dials)
mat_holo = unreal.load_asset(f"{package_path}/M_Ultron_DigitalHolo.M_Ultron_DigitalHolo")
if mat_holo:
    unreal.MaterialEditingLibrary.delete_all_material_expressions(mat_holo)
    custom_node = unreal.MaterialEditingLibrary.create_material_expression(mat_holo, unreal.MaterialExpressionCustom, -100, 0)
    custom_node.set_editor_property("description", "SmoothDigitalHUD")
    custom_node.set_editor_property("output_type", unreal.CustomMaterialOutputType.CMOT_FLOAT1)
    
    hlsl_holo = """
    float2 p = UV * 2.0 - 1.0;
    float r = length(p);
    if (r > 0.99) return 0.0;
    float theta = atan2(p.y, p.x);
    
    // Slow, stately rotation rates (~4x slower)
    float theta_fast = theta + Time * 0.22;
    float theta_mid  = theta - Time * 0.12;
    float theta_slow = theta + Time * 0.05;
    float theta_pulse = theta + sin(Time * 0.5) * 0.12;
    
    // Smooth expanding waves
    float wave = sin(r * 45.0 - Time * 0.9);
    float rings = step(0.95, abs(wave)) * 0.85;
    float rings_fine = step(0.97, abs(sin(r * 80.0))) * 0.5;
    
    float t_outer = abs(sin(theta_slow * 72.0));
    float ticks_outer = step(0.92, t_outer) * step(0.82, r) * step(r, 0.96) * 1.5;
    
    float t_major = abs(sin(theta_slow * 12.0));
    float ticks_major = step(0.86, t_major) * step(0.68, r) * step(r, 0.97) * 2.2;
    
    float t_inner = abs(sin(theta_mid * 36.0));
    float ticks_inner = step(0.90, t_inner) * step(0.38, r) * step(r, 0.52) * 1.8;
    
    // Segmented broken arcs orbiting slowly
    float arc1 = step(0.15, sin(theta_fast * 3.0)) * step(abs(r - 0.91), 0.009) * 2.8;
    float arc2 = step(0.10, sin(theta_mid * 5.0)) * step(abs(r - 0.76), 0.008) * 2.4;
    float arc3 = step(0.25, sin(theta_pulse * 7.0)) * step(abs(r - 0.60), 0.007) * 2.0;
    float arc4 = step(0.00, sin(theta_fast * 11.0)) * step(abs(r - 0.32), 0.006) * 1.8;
    float outer_rim = step(abs(r - 0.97), 0.007) * 2.5;
    
    // Synapse nodes
    float dot_angle = abs(sin(theta_fast * 24.0));
    float dot_radius = abs(sin(r * 60.0 - Time * 0.8));
    float sparkle = sin(Time * 2.5 + theta * 12.0) * 0.5 + 0.5;
    float nodes = step(0.96, dot_angle) * step(0.96, dot_radius) * step(0.22, r) * step(r, 0.95) * (2.2 + sparkle * 2.5);
    
    // Gentle breathing pulse
    float core_pulse = 1.0 + 0.15 * sin(Time * 1.8);
    float core = exp(-r * 6.5) * (2.0 * core_pulse);
    
    float total = rings + rings_fine + ticks_outer + ticks_major + ticks_inner + arc1 + arc2 + arc3 + arc4 + outer_rim + nodes + core;
    return saturate(total);
    """
    custom_node.set_editor_property("code", hlsl_holo)
    
    tex_coord = unreal.MaterialEditingLibrary.create_material_expression(mat_holo, unreal.MaterialExpressionTextureCoordinate, -400, -100)
    time_node = unreal.MaterialEditingLibrary.create_material_expression(mat_holo, unreal.MaterialExpressionTime, -400, 100)
    inp_uv = unreal.CustomInput()
    inp_uv.set_editor_property("input_name", "UV")
    inp_time = unreal.CustomInput()
    inp_time.set_editor_property("input_name", "Time")
    custom_node.set_editor_property("inputs", [inp_uv, inp_time])
    unreal.MaterialEditingLibrary.connect_material_expressions(tex_coord, "", custom_node, "UV")
    unreal.MaterialEditingLibrary.connect_material_expressions(time_node, "", custom_node, "Time")
    
    color_node = unreal.MaterialEditingLibrary.create_material_expression(mat_holo, unreal.MaterialExpressionVectorParameter, -100, -200)
    color_node.set_editor_property("parameter_name", "HoloColor")
    color_node.set_editor_property("default_value", unreal.LinearColor(32.0, 11.5, 0.8, 1.0))
    
    mult_node = unreal.MaterialEditingLibrary.create_material_expression(mat_holo, unreal.MaterialExpressionMultiply, 150, -50)
    unreal.MaterialEditingLibrary.connect_material_expressions(color_node, "", mult_node, "A")
    unreal.MaterialEditingLibrary.connect_material_expressions(custom_node, "", mult_node, "B")
    unreal.MaterialEditingLibrary.connect_material_property(mult_node, "", unreal.MaterialProperty.MP_EMISSIVE_COLOR)
    unreal.MaterialEditingLibrary.recompile_material(mat_holo)
    unreal.EditorAssetLibrary.save_loaded_asset(mat_holo)

unreal.log_warning("[UpdateHoloShader_SmoothSlow] SUCCESS: Recompiled all 3 materials with smooth, stately motion!")
