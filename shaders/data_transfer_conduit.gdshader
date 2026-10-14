shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

// 0 = STANDBY, 1 = FILE READ (Amber Burst), 2 = ATTACK / STREAMING (Cyan Flow)
uniform int bus_mode : hint_range(0, 2) = 0;
uniform float transfer_speed : hint_range(0.0, 25.0) = 6.0;
uniform float packet_density : hint_range(1.0, 30.0) = 10.0;
uniform float lane_count : hint_range(2.0, 16.0) = 8.0;
uniform float emission_energy : hint_range(1.0, 20.0) = 8.5;

uniform vec4 glass_tint : source_color = vec4(0.02, 0.04, 0.07, 1.0);
uniform vec4 standby_color : source_color = vec4(0.0, 0.35, 0.45, 1.0);
uniform vec4 amber_burst_color : source_color = vec4(1.0, 0.65, 0.05, 1.0);
uniform vec4 cyan_stream_color : source_color = vec4(0.0, 0.92, 1.0, 1.0);

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

void fragment() {
    // Разделяме шината по ширина (UV.x) на паралелни оптични писти (lanes)
    float lane_coord = UV.x * lane_count;
    float lane_id = floor(lane_coord);
    float lane_uv = fract(lane_coord);
    
    // Тънки разделители между отделните писти и метален кант в краищата
    float lane_mask = smoothstep(0.08, 0.18, lane_uv) * smoothstep(0.92, 0.82, lane_uv);
    float border_frame = smoothstep(0.0, 0.04, UV.x) * smoothstep(1.0, 0.96, UV.x);
    
    // Индивидуална скорост и фазов офсет за всяка паралелна писта
    float lane_seed = hash11(lane_id + 17.0);
    float speed_variation = mix(0.75, 1.35, lane_seed);
    
    // Движение по дължината на шината (UV.y: от StorageRack3D към Ядрото/Терминала)
    float flow_coord = UV.y * packet_density - TIME * transfer_speed * speed_variation + lane_seed * 10.0;
    float packet_cell = floor(flow_coord);
    float packet_fract = fract(flow_coord);
    
    // Остра глава на фотонния пакет и плавно затихване на опашката (trail)
    float packet_tail = pow(packet_fract, 3.5) * smoothstep(1.0, 0.88, packet_fract);
    
    // Случайно пропускане на слотове, за да изглежда като реален асинхронен битов трафик
    float active_bit = step(0.35, hash11(packet_cell + lane_id * 53.0));
    
    vec3 final_emission = vec3(0.0);
    
    if (bus_mode == 0) {
        // STANDBY: Тих базов пулс по крайните шини
        float pulse = 0.25 + 0.15 * sin(TIME * 2.0 + UV.y * 6.0);
        final_emission = standby_color.rgb * lane_mask * pulse * 0.6;
    } 
    else if (bus_mode == 1) {
        // READING FILE: Жълто-кехлибарени пакетни залпове
        float burst = packet_tail * active_bit * lane_mask;
        final_emission = amber_burst_color.rgb * burst * emission_energy;
    } 
    else {
        // STREAMING / ATTACK: Високочестотен непрекъснат циан поток
        float stream = (packet_tail * 0.85 + 0.15) * lane_mask;
        final_emission = cyan_stream_color.rgb * stream * (emission_energy * 1.25);
    }
    
    // Физични свойства на опушеното покривно стъкло над шината
    ALBEDO = glass_tint.rgb * border_frame;
    METALLIC = 0.85;
    ROUGHNESS = 0.12;
    SPECULAR = 0.9;
    EMISSION = final_emission * border_frame;
}
