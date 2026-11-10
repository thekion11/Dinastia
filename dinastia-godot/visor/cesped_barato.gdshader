// EL CÉSPED BARATO (10-11-2026, `ModoRendimiento`, propuesta E4 de `rendimiento_movil_2026-11-10.md`): el mismo campo (dibujo del club, franjas con brillo según el ángulo, manchas y desgaste de
// `cesped_comun.gdshaderinc`) pero SIN la brizna fina, los mechones ni el relieve (NORMAL_MAP) de `cesped.gdshader`, que son ~10 llamadas a ruido por píxel y 4 `fbm` más para las normales.
// Medido: el campo con material plano ahorra 5-15 % del fotograma en MEDIA; esto recupera una parte. Solo se usa con el modo rendimiento encendido, de MEDIA hacia abajo.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

#include "res://visor/cesped_comun.gdshaderinc"

varying vec3 v_mundo;

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 w = v_mundo.xz;
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	ALBEDO = cesped_color(w, UV, v_mundo, cam);
	ROUGHNESS = 0.93;
	SPECULAR = 0.08;
}
