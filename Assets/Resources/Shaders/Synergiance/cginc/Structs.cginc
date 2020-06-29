#ifndef ACKSTRUCTS
#define ACKSTRUCTS

#include "UnityCG.cginc"
#include "AutoLight.cginc"

// Modified versions of Unity macros, designed to allow shadows to be moved within geometry functions unaltered
#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
	#define LOC_SHADOWCOORD unityShadowCoord4 _ShadowCoord;
	#define SYN_TRANSFER_SHADOW(src, dest) dest._ShadowCoord = src._ShadowCoord;
#elif defined(SHADOWS_SCREEN) && !defined(LIGHTMAP_ON) && !defined(UNITY_NO_SCREENSPACE_SHADOWS)
	#define LOC_SHADOWCOORD unityShadowCoord4 _ShadowCoord;
	#define SYN_TRANSFER_SHADOW(src, dest) dest._ShadowCoord = src._ShadowCoord;
#else
	#if defined(SHADOWS_SHADOWMASK)
		#define LOC_SHADOWCOORD unityShadowCoord4 _ShadowCoord;
		#define SYN_TRANSFER_SHADOW(src, dest) dest._ShadowCoord = src._ShadowCoord;
	#else
		#define LOC_SHADOWCOORD
		#define SYN_TRANSFER_SHADOW(src, dest)
	#endif
#endif

struct shadingData {
	float3 color;
	#ifdef _EMISSION
		float3 emission;
	#endif // _EMISSION
	#ifdef USEALPHA
		float alpha;
	#endif
	float3 lightDir;
	float3 lightCol;
	float3 light;
	float3 viewDir;
	float3 normal;
	#ifdef HASSPECULAR
		float3 specular;
	#endif
	float4 posWorld;
	LOC_SHADOWCOORD
	float3 vertLight;
	#ifdef _NORMALMAP
		float3 tangent;
		float3 bitangent;
	#endif
	float2 uv;
	#ifdef HAS_MATCAP
		float2 uvCap;
	#endif
};

#endif // ACKSTRUCTS
