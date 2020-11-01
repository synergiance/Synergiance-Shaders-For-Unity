#ifndef SYN_EFFECTS
#define SYN_EFFECTS

#ifdef _EMISSION
	#define EMISSION_EFFECTS
	#define NEEDS_UVW
    #define CALC_PRELIGHT calcPreEffects(s);
    #define CALC_POSTLIGHT calcPostEffects(s, i.uvw);
    #define CALC_VERT calcVertEffects(o, v);
#endif

#ifdef COLOR_EFFECTS
	#include "HSB.cginc"
	float _Vivid;
	float _Speed;
#endif

#ifdef EMISSION_EFFECTS
	#include "Perlin.cginc"
	#include "GoldenRatio.cginc"
	float _EmissionNoise;
	float _EmissionNoiseSpeed;
	float _EmissionNoiseDensity;
	int _EmissionIterations;
	int _EmissionNoiseCoords;
	int _EmissionNoise3DUV;
#endif

#define CUSTOM_VERT
#ifndef NO_TOON_VERT
	#define USE_TOON_VERT
#endif
#include "Lighting/Metallic.cginc"
#include "Lighting/ToonSpecular.cginc"

#ifdef EMISSION_EFFECTS
float calcPerlin2D(float2 uv) {
	float3 perlInput;
	perlInput.xy = uv * _EmissionNoiseDensity;
	perlInput.z = 0;
	if (_EmissionNoiseSpeed > 0) perlInput.z = _Time[1] * _EmissionNoiseSpeed * _EmissionNoiseSpeed * _EmissionNoiseSpeed;
	float perlin = perlin3D(perlInput);
	float amplitude = 1;
	float frequency = 1;
	for (int c = 1; c < _EmissionIterations; c++) {
		amplitude *= lPhi;
		frequency *= bPhi;
		perlin += perlin3D(perlInput * frequency) * amplitude;
	}
	return max(0, perlin * 0.5 + 0.5);
}

float calcPerlin3D(float3 uvw) {
	float3 perlInput = uvw * _EmissionNoiseDensity;
	float time = 0;
	if (_EmissionNoiseSpeed > 0) time = _Time[1] * _EmissionNoiseSpeed * _EmissionNoiseSpeed * _EmissionNoiseSpeed;
	float perlin = perlin3DOffset(perlInput, time);
	float amplitude = 1;
	float frequency = 1;
	for (int c = 1; c < _EmissionIterations; c++) {
		amplitude *= lPhi;
		frequency *= bPhi;
		perlin += perlin3DOffset(perlInput * frequency, time * frequency) * amplitude;
	}
	return max(0, perlin * 0.5 + 0.5);
}
#endif

void calcVertEffects(inout ITPL o, appdata_full v) {
	#ifdef EMISSION_EFFECTS
		switch (_EmissionNoiseCoords) {
			case 0:
				o.uvw = o.posWorld.xyz;
				break;
			case 1:
				o.uvw = v.vertex.xyz;
				break;
			case 2:
				o.uvw = v.texcoord.xyz;
				break;
			case 3:
				o.uvw = v.texcoord1.xyz;
				break;
			case 4:
				o.uvw = v.texcoord2.xyz;
				break;
			case 5:
				o.uvw = v.texcoord3.xyz;
				break;
			default:
				o.uvw = 0;
				break;
		}
	#endif
}

void calcPreEffects(inout shadingData s) {
	#ifdef COLOR_EFFECTS
	[branch] if (_Vivid > 0) {
		float3 hsvcol = RGBtoHSV(s.color.rgb);
		hsvcol.y *= 1 + _Vivid;
		s.color.rgb = HSVtoRGB(hsvcol);
	}
	[branch] if (_Speed > 0) s.color.rgb = applyHue(s.color.rgb, _Time[1] * _Speed * _Speed * _Speed);
	#endif
}

void calcPostEffects(inout shadingData s, float3 uvw) {
	#ifdef EMISSION_EFFECTS
	[branch] if (_EmissionNoise > 0 && any(s.emission > 0)) {
		float perlin;
		[branch] if (_EmissionNoise3DUV == 0 && _EmissionNoiseCoords >= 2) perlin = calcPerlin2D(uvw.xy);
		else perlin = calcPerlin3D(uvw.xyz);
		s.emission *= lerp(1, perlin, _EmissionNoise);
	}
	#endif
}

#include "ToonCore.cginc"

#endif