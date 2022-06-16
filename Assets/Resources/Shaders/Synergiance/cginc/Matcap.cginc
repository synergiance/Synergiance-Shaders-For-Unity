#ifndef SYNMATCAP
#define SYNMATCAP

#include "Structs.cginc"

SamplerState matcapLinearMirrorOnce;

Texture2D _MatCapAdd;
Texture2D _MatCapMul;
Texture2D _MatCapMaskAdd;
Texture2D _MatCapMaskMul;

void applyMatcapAdd(inout float3 col, inout shadingData s, SamplerState texSampler) {
	float3 matAdd = _MatCapAdd.Sample(matcapLinearMirrorOnce, s.uvCap);
	float3 maskAdd = _MatCapMaskAdd.Sample(texSampler, s.uv);
	matAdd *= maskAdd;
	col += matAdd * s.light;
}

void applyMatcapMul(inout float3 col, inout shadingData s, SamplerState texSampler) {
	float3 matMul = _MatCapMul.Sample(matcapLinearMirrorOnce, s.uvCap);
	float3 maskMul = _MatCapMaskMul.Sample(texSampler, s.uv);
	matMul = lerp(1, matMul, maskMul);
	col *= matMul;
}

void applyMatcap(inout float3 col, inout shadingData s, SamplerState texSampler) {
	applyMatcapMul(col, s, texSampler);
	applyMatcapAdd(col, s, texSampler);
}

float2 calcMatcapCoords(float3 viewDir, float3 normal) {
	float3 tangent = normalize(cross(viewDir, float3(0.0, 1.0, 0.0)));
	float3 bitangent = normalize(cross(tangent, viewDir));
	float3 viewNormal = normalize(mul(float3x3(tangent, bitangent, viewDir), normal));
	return viewNormal.xy * 0.5 + 0.5;
}

#endif // SYNMATCAP
