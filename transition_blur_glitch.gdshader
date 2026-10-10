shader_type canvas_item;

// Интензитет на изкривяването (променя се динамично през Tween в GDScript)
uniform float transition_progress : hint_range(0.0, 1.0) = 0.0;
uniform float blur_amount : hint_range(0.0, 5.0) = 0.0;

// Функция за псевдо-произволен шум (Noise) за технологичен ефект
float random(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    
    if (transition_progress > 0.0) {
        // 1. Изкривяване по Х оста (Glitch), което се засилва в средата на прехода
        float glitch_wave = sin(uv.y * 40.0) * 0.1 * transition_progress;
        // Добавяме малко цифров шум
        float noise = (random(vec2(floor(uv.y * 80.0), transition_progress)) - 0.5) * 0.08 * transition_progress;
        
        uv.x += glitch_wave + noise;
    }
    
    // 2. Взимаме цвета от текстурата с променените координати
    vec4 tex_color = texture(TEXTURE, uv);
    
    // 3. Прилагаме деликатно хроматично разсейване (RGB Split) по краищата при движение
    if (transition_progress > 0.0) {
        float r = texture(TEXTURE, uv + vec2(0.01 * transition_progress, 0.0)).r;
        float g = tex_color.g;
        float b = texture(TEXTURE, uv - vec2(0.01 * transition_progress, 0.0)).b;
        tex_color = vec4(r, g, b, tex_color.a);
    }
    
    COLOR = tex_color;
}
