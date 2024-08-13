#version 120
#extension GL_EXT_gpu_shader4 : enable
//#define TONEMAP_ACES


varying vec4 texcoord;
flat varying vec4 fogColor;
flat varying vec3 flareColor;
uniform sampler2D depthtex0;
uniform sampler2D colortex1;
uniform int isEyeInWater;
uniform mat4 gbufferProjectionInverse;

#include "lib/color_transforms.glsl"


#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define  projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)

vec3 toScreenSpace(vec3 p) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
  vec3 p3 = p * 2. - 1.;
  vec4 fragposition = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
  return fragposition.xyz / fragposition.w;
}
float interleaved_gradientNoise(){
	return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y));
}
vec3 int8Dither(vec3 color){
	float dither = interleaved_gradientNoise();
	return color + dither*exp2(-8.0);
}
vec3 Tonemap_Unreal(vec3 x) {
    // Unreal 3, Documentation: "Color Grading"
    // Adapted to be close to Tonemap_ACES, with similar range
    // Gamma 2.2 correction is baked in, don't use with sRGB conversion!
    return x / (0.98135426889 * x + 0.154*0.98135426889) ;
}

void main() {
/* DRAWBUFFERS:0 */
	vec3 color = texture2D(colortex1,texcoord.xy).rgb;
	float z = texture2D(depthtex0,texcoord.xy).x;
	if (z < 1.0 || isEyeInWater == 1){
		vec2 fragposition = gbufferProjectionInverse[2].zw * z + gbufferProjectionInverse[3].zw;
		float dist = fragposition.x/fragposition.y;
		float fogFactorScat = exp2(dist*fogColor.a);
		color = mix(fogColor.rgb,color,fogFactorScat);
	}
	// Glow around sun (lorentz curve 1/(1+d²))
	color += (1.0/(1+dot(texcoord.zw, texcoord.zw)))*flareColor;
	//tonemap
	#ifndef TONEMAP_ACES
		gl_FragData[0].rgb = int8Dither(Tonemap_Unreal(color));
	#endif
	#ifdef TONEMAP_ACES
		gl_FragData[0].rgb = int8Dither(ACESFilm(color));
	#endif
}
                                           
