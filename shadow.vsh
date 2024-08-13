#version 120
#extension GL_EXT_gpu_shader4 : enable

#include "lib/shadow_param.glsl"

varying vec2 texcoord;

void main() {

	gl_Position = BiasShadowProjection(ftransform());
	gl_Position.z /= 3.0;


	texcoord = gl_MultiTexCoord0.xy;
}
