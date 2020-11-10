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

#ifdef BLANK_CUBE_DETECTION
	TextureCube _ReflBackupCube;
	SamplerState sampler_ReflBackupCube;

	static float3 cubeDirections[6] = {
		float3( 1, 0, 0),
		float3(-1, 0, 0),
		float3( 0, 1, 0),
		float3( 0,-1, 0),
		float3( 0, 0, 1),
		float3( 0, 0,-1)
	};
#endif

void calcSpecular(inout shadingData s) {
	#if defined(_METALLICGLOSSMAP) && defined(HASMETALLIC)
		float glossiness = _GlossMapScale * (_SmoothnessTextureChannel == 0 ? _MetallicGlossMap.Sample(sampler_MainTex, s.uv.xy).a : _MainTex.Sample(sampler_MainTex, s.uv.xy).a);
	#else
		float glossiness = _Glossiness;
	#endif

	float3 halfVector = normalize(s.lightDir + s.viewDir);
	float specular = pow(saturate(dot(s.normal, halfVector)), glossiness * 100);
	specular *= smoothstep(-0.01, 0, dot(s.normal, s.lightDir));
	
	fixed feather = max(_SpecFeather, ddx(specular) + ddy(specular));
	fixed ref = (1 - feather) * lerp(0.5, 0.95, glossiness);
	specular = smoothstep(ref, ref + feather, specular * s.light.g);
	
	fixed3 probe = 0;
	UNITY_BRANCH
	if (_ReflPower > 0.00001) {
		BoxProjectData bpd;
		bpd.direction = reflect(-s.viewDir, s.normal);
		bpd.position = s.posWorld;
		bpd.cubemapPosition = unity_SpecCube0_ProbePosition;
		bpd.boxMin = unity_SpecCube0_BoxMin;
		bpd.boxMax = unity_SpecCube0_BoxMax;
		
		Unity_GlossyEnvironmentData envData;
		envData.roughness = 1 - glossiness;
		#ifdef BLANK_CUBE_DETECTION
			envData.reflUVW = bpd.direction;
			float3 testProbe = 0;
			for (int i = 0; i < 6; i++) testProbe += _ReflBackupCube.SampleLevel(sampler_ReflBackupCube, cubeDirections[i], 1).rgb;
			float probeVal = smoothstep(s.light.g * (s.lightCol.r + s.lightCol.g + s.lightCol.b) * 9, 0, testProbe.r + testProbe.g + testProbe.b);
			float3 probe2 = Unity_GlossyEnvironment(_ReflBackupCube, sampler_ReflBackupCube, unity_SpecCube0_HDR, envData);
		#endif
		envData.reflUVW = BoxProject(bpd);
		float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
		#if UNITY_SPECCUBE_BLENDING
			float interpolator = unity_SpecCube0_BoxMin.w;
			UNITY_BRANCH
			if (interpolator < 0.99999) {
				bpd.cubemapPosition = unity_SpecCube1_ProbePosition;
				bpd.boxMin = unity_SpecCube1_BoxMin;
				bpd.boxMax = unity_SpecCube1_BoxMax;
				envData.reflUVW = BoxProject(bpd);
				float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube0_HDR, envData);
				probe = lerp(probe1, probe0, interpolator);
			} else {
				probe = probe0;
			}
		#else
			probe = probe0;
		#endif
		#ifdef BLANK_CUBE_DETECTION
			probe += probe2 * probeVal * s.lightCol * s.light.g;
		#endif
	}
	
	#ifdef HASMETALLIC
		s.specular += (specular * s.lightCol * s.light.g * _SpecPower + probe * _ReflPower * _ReflPowerTex.Sample(sampler_MainTex, s.uv.xy).b) * lerp(smoothstep(0.2, 0.8, glossiness), 1, s.metallic);
	#else
		s.specular += (specular * s.lightCol * s.light.g * _SpecPower + probe * _ReflPower * _ReflPowerTex.Sample(sampler_MainTex, s.uv.xy).b) * smoothstep(0.2, 0.8, glossiness);
	#endif
}

#endif // ACKLIGHTINGTOONSPEC
