#ifndef SYNACK_REFLECTIONS
#define SYNACK_REFLECTIONS

#include "UnityPBSLighting.cginc"

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

struct BoxProjectData {
	float3 direction;
	float3 position;
	float4 cubemapPosition;
	float3 boxMin;
	float3 boxMax;
};

float3 BoxProject(BoxProjectData i) {
	float3 direction = i.direction;
	#if UNITY_SPECCUBE_BOX_PROJECTION
		[branch] if (i.cubemapPosition.w > 0) {
			float3 factors = ((i.direction > 0 ? i.boxMax : i.boxMin) - i.position) / i.direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = i.direction * scalar + (i.position - i.cubemapPosition);
		}
	#endif
	return direction;
}

#ifdef BLANK_CUBE_DETECTION
	float calcProbeVal(float3 lightContrib, float atten) {
		float3 testProbe = 0;
		for (int i = 0; i < 6; i++) testProbe += UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, cubeDirections[i], 1).rgb;
		return max(0, 1 - (testProbe.r + testProbe.g + testProbe.b) / (atten * (lightContrib.r + lightContrib.g + lightContrib.b) * 2));
	}
#endif

fixed3 calcProbe(float3 viewDir, float3 normal, float3 posWorld, float3 lightCol, float roughness, float atten) {
	fixed3 probe = 0;

	BoxProjectData bpd;
	bpd.direction = reflect(-viewDir, normal);
	bpd.position = posWorld;
	bpd.cubemapPosition = unity_SpecCube0_ProbePosition;
	bpd.boxMin = unity_SpecCube0_BoxMin;
	bpd.boxMax = unity_SpecCube0_BoxMax;

	Unity_GlossyEnvironmentData envData;
	envData.roughness = roughness;
	#ifdef BLANK_CUBE_DETECTION
		envData.reflUVW = bpd.direction;
		float3 lightContrib = lightCol + ShadeSH9(half4(0,0,0,1));
		float probeVal = calcProbeVal(lightCol, atten);
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
		probe += probe2 * probeVal * lightContrib * atten;
	#endif

	return probe;
}

fixed3 refractProbe(float3 viewDir, float3 normal, float3 posWorld, float3 lightCol, float clarity, float indexOfRefraction, float atten) {
	fixed3 probe = 0;

	BoxProjectData bpd;
	bpd.direction = refract(-viewDir, normal, indexOfRefraction);
	bpd.position = posWorld;
	bpd.cubemapPosition = unity_SpecCube0_ProbePosition;
	bpd.boxMin = unity_SpecCube0_BoxMin;
	bpd.boxMax = unity_SpecCube0_BoxMax;

	Unity_GlossyEnvironmentData envData;
	envData.roughness = 1 - clarity;
	#ifdef BLANK_CUBE_DETECTION
		envData.reflUVW = bpd.direction;
		float3 lightContrib = lightCol + ShadeSH9(half4(0,0,0,1));
		float probeVal = calcProbeVal(lightCol, atten);
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
		probe += probe2 * probeVal * lightContrib * atten;
	#endif

	return probe;
}

#endif
