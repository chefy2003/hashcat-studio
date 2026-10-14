shader_type particles;

uniform float sphere_radius : hint_range(0.5, 5.0) = 1.0;
uniform float shell_thickness : hint_range(0.05, 1.0) = 0.35;
uniform float flow_speed : hint_range(0.1, 10.0) = 2.8;
uniform float curl_scale : hint_range(0.5, 5.0) = 1.8;
uniform float steering_inertia : hint_range(1.0, 15.0) = 4.5;
uniform float radial_stiffness : hint_range(1.0, 20.0) = 8.0;

uniform vec4 color_calm : source_color = vec4(0.0, 0.85, 1.0, 1.0);
uniform vec4 color_surge : source_color = vec4(1.0, 0.45, 0.05, 1.0);

// Детерминистичен хеш за индивидуално ДНК на всяка частица по INDEX
vec3 hash31(uint n) {
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    uvec3 k = n * uvec3(n, n * 16807U, n * 48271U);
    return vec3(k & uvec3(0x7fffffffU)) / float(0x7fffffff);
}

// Истинско 3D бездивергентно векторно поле (Curl = nabla x Potential)
vec3 sample_curl_velocity(vec3 p, float t, float individual_phase) {
    vec3 q = p * curl_scale + vec3(t * 0.4, -t * 0.3, t * 0.5) + individual_phase;
    
    // Две ортогонални потенциални полета F и G
    vec3 f = sin(q.yzx + cos(q.zxy * 1.7 + t * 0.6));
    vec3 g = cos(q.zxy - sin(q.yzx * 1.3 - t * 0.5));
    
    // Векторното произведение дава вихрови струи без точки на застой
    return normalize(cross(f, g));
}

void start() {
    vec3 dna = hash31(INDEX);
    
    // CUSTOM.x = индивидуален множител на скоростта (0.6 до 1.4)
    // CUSTOM.y = личен радиален слой в пасажа (-0.5 до +0.5)
    // CUSTOM.z = индивидуална фазова честота за вихровото поле
    CUSTOM.x = mix(0.6, 1.4, dna.x);
    CUSTOM.y = (dna.y - 0.5) * shell_thickness;
    CUSTOM.z = dna.z * 6.2831853;
    
    // Първоначално разпределение по сферата само при раждане
    float phi = acos(1.0 - 2.0 * fract(dna.x + float(INDEX) * 0.00002));
    float theta = float(INDEX) * 2.3999632;
    
    vec3 spawn_dir = vec3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta));
    float my_radius = sphere_radius + CUSTOM.y;
    
    TRANSFORM = mat4(1.0);
    TRANSFORM[3].xyz = spawn_dir * my_radius;
    
    // Начален тангенциален импулс
    VELOCITY = normalize(cross(spawn_dir, vec3(0.0, 1.0, 0.1))) * flow_speed * CUSTOM.x;
}

void process() {
    vec3 pos = TRANSFORM[3].xyz;
    float dist = max(length(pos), 0.001);
    vec3 normal = pos / dist;
    
    // 1. Извличаме вектора на течението в ТЕКУЩАТА точка на частицата
    // Важно: фазата CUSTOM.z е малка (0.25), за да се движат групово в общи потоци (пасаж),
    // но с лека индивидуална вариация в траекторията.
    vec3 curl_dir = sample_curl_velocity(pos, TIME, CUSTOM.z * 0.25);
    
    // 2. Проектираме течението тангенциално по сферата + добавяме глобален орбитален дрейф
    vec3 tangent_flow = curl_dir - normal * dot(curl_dir, normal);
    vec3 global_swirl = cross(vec3(0.0, 1.0, 0.2), normal) * 0.35;
    vec3 desired_dir = normalize(tangent_flow + global_swirl);
    
    // 3. Целева скорост според индивидуалния темперамент на частицата (CUSTOM.x)
    vec3 desired_vel = desired_dir * flow_speed * CUSTOM.x;
    
    // 4. Целеви радиус за този слой с органично дишане
    float target_r = sphere_radius + CUSTOM.y + sin(TIME * 1.8 + CUSTOM.z) * (shell_thickness * 0.2);
    
    // Радиален критично демпнат контрол (връща частицата към target_r без трептене)
    float radial_error = dist - target_r;
    float radial_speed = dot(VELOCITY, normal);
    vec3 radial_correction = -normal * (radial_error * radial_stiffness + radial_speed * 6.0);
    
    // 5. Интеграция на скоростта с инерция по тангентата + демпната корекция по радиуса
    vec3 target_velocity = desired_vel + radial_correction;
    VELOCITY = mix(VELOCITY, target_velocity, clamp(DELTA * steering_inertia, 0.0, 1.0));
    
    // Интегрираме позицията
    pos += VELOCITY * DELTA;
    
    // 6. ТВЪРДО ГАРАНТИРАНА СФЕРИЧНА ГРАНИЦА (Zero escapees)
    // Частиците физически никога не могат да напуснат радиалния обем на кълбото!
    float min_allowed_r = max(0.12, sphere_radius - shell_thickness * 0.5);
    float max_allowed_r = sphere_radius + shell_thickness * 0.5;
    float new_dist = length(pos);
    if (new_dist > max_allowed_r) {
        pos = (pos / new_dist) * max_allowed_r;
        float v_out = dot(VELOCITY, pos / max_allowed_r);
        if (v_out > 0.0) {
            VELOCITY -= (pos / max_allowed_r) * v_out;
        }
    } else if (new_dist < min_allowed_r) {
        pos = (pos / new_dist) * min_allowed_r;
        float v_in = dot(VELOCITY, pos / min_allowed_r);
        if (v_in < 0.0) {
            VELOCITY -= (pos / min_allowed_r) * v_in;
        }
    }
    TRANSFORM[3].xyz = pos;
    
    // 7. Ориентираме локалната ос на частицата по посоката й на движение (за издължени следи/streaks)
    vec3 forward = normalize(VELOCITY);
    vec3 ref_axis = abs(normal.y) < 0.95 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 right = cross(forward, normal);
    if (length(right) < 0.001) {
        right = cross(forward, ref_axis);
    }
    right = normalize(right);
    vec3 up = normalize(cross(right, forward));
    
    // Скалираме частицата: фини светещи струи (particle streaks)
    float speed = length(VELOCITY);
    float stretch = clamp(speed * 0.06, 0.6, 2.2);
    TRANSFORM[0].xyz = right * 0.0035;
    TRANSFORM[1].xyz = up * 0.0035;
    TRANSFORM[2].xyz = forward * (0.024 * stretch);
    
    // 8. Динамичен цвят: студен циан при спокойно плуване -> топъл кехлибар при сгъстяване
    float surge = smoothstep(flow_speed * 0.75, flow_speed * 1.35, speed);
    COLOR = mix(color_calm, color_surge, surge);
}
