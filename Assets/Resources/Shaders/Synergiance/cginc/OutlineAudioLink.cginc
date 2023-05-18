#include "Imports/AudioLink.cginc"
#include "UnityShaderVariables.cginc"

float3 _OutlineAudioLinkColor;
float _OutlineAudioLinkEffect;
float _OutlineAudioLinkTheme;
float _OutlineAudioLinkBright;
float _OutlineAudioLinkDim;

const static uint2 audioLinkThemeIndices[4] = {
	ALPASS_THEME_COLOR0,
	ALPASS_THEME_COLOR1,
	ALPASS_THEME_COLOR2,
	ALPASS_THEME_COLOR3
};

float3 GetThemeColorMod(uint2 alTexCoord) {
	return lerp(_OutlineAudioLinkColor, AudioLinkData(alTexCoord).rgb, _OutlineAudioLinkTheme);
}

float GetSpinnyMod(uint index, float3 normal) {
	float2 spinnyLocations[4] = {
		float2( 1,  0),
		float2( 0,  1),
		float2(-1,  0),
		float2( 0, -1)
	};

	float sine, cosine;
	sincos(_Time.y + normal.y * 3.14159265, sine, cosine);
	float2x2 spinnyMat = { cosine, -sine, sine, cosine };
	float2 spunLocation = mul(spinnyMat, spinnyLocations[index]);
	return dot(normalize(normal.xz), spunLocation) * 0.5 + 0.5;
}

void GetAudioLinkEmission(inout float3 emission, float3 normal) {
	if (_OutlineAudioLinkEffect < 0.00001 || !AudioLinkIsAvailable()) return;

	float3 alEmission = 0;
	for (uint i = 0; i < 4; i++) alEmission += GetThemeColorMod(audioLinkThemeIndices[i]) * GetSpinnyMod(i, normal);

	float autoCorrelation = AudioLinkLerp(ALPASS_AUTOCORRELATOR + float2(abs(normal.y) * AUDIOLINK_WIDTH, 0 ) ).r;

	alEmission *= _OutlineAudioLinkBright * 0.5;
	emission *= 1 - _OutlineAudioLinkDim;
	emission = lerp(emission, alEmission, _OutlineAudioLinkEffect * autoCorrelation);
}
