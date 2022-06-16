#ifndef ACKLIGHTINGTOONSPEC
#define ACKLIGHTINGTOONSPEC

#define LIGHTSPECOVERRIDE
#define HASSPECULAR
#include "Toon.cginc"
#include "Specular.cginc"

fixed _SpecFeather;
fixed _SpecPower;
fixed _ReflPower;
Texture2D _ReflPowerTex;

void calcSpecular(inout shadingData s) {
	s.glossiness = GET_GLOSSINESS;

	float3 halfVector = normalize(s.lightDir + s.viewDir);
	float specular = pow(saturate(dot(s.normal, halfVector)), s.glossiness * 100);
	specular *= smoothstep(-0.01, 0, dot(s.normal, s.lightDir));
	
	fixed feather = max(_SpecFeather, fwidth(specular));
	fixed ref = (1 - feather) * lerp(0.5, 0.95, s.glossiness);
	specular = smoothstep(ref, ref + feather, specular * s.light.g);
	
	fixed3 probe = 0;
	UNITY_BRANCH
	if (_ReflPower > 0.00001) probe = calcProbe(s.viewDir, s.normal, s.posWorld, s.lightCol, 1 - s.glossiness, s.light.g);
	
	#ifdef HASMETALLIC
		s.specular += (specular * s.lightCol * s.light.g * _SpecPower + probe * _ReflPower * _ReflPowerTex.Sample(sampler_MainTex, s.uv.xy).b) * lerp(smoothstep(0.2, 0.8, s.glossiness), 1, s.metallic);
	#else
		s.specular += (specular * s.lightCol * s.light.g * _SpecPower + probe * _ReflPower * _ReflPowerTex.Sample(sampler_MainTex, s.uv.xy).b) * smoothstep(0.2, 0.8, s.glossiness);
	#endif
}

#endif // ACKLIGHTINGTOONSPEC
