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

#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
	#define LOC_FOGCOORD float1 fogCoord;
	#define SYN_TRANSFER_FOG(src, dest) dest.fogCoord = src.fogCoord;
	#if (SHADER_TARGET < 30) || defined(SHADER_API_MOBILE)
		// mobile or SM2.0: fog factor was already calculated per-vertex, so just lerp the color
		#define SYN_UNITY_APPEND_FOG_COLOR(coord,col,fogCol) UNITY_FOG_LERP_COLOR(col,fogCol,(coord).x)
	#else
		// SM3.0 and PC/console: calculate fog factor and lerp fog color
		#define SYN_UNITY_APPEND_FOG_COLOR(coord,col,fogCol) UNITY_FOG_LERP_COLOR(col,fogCol,unityFogFactor)
	#endif
#else
	#define LOC_FOGCOORD
	#define SYN_TRANSFER_FOG(src, dest)
	#define SYN_UNITY_APPEND_FOG_COLOR(coord,col,fogCol)
#endif

#ifdef UNITY_PASS_FORWARDADD
	#define SYN_UNITY_APPEND_FOG(coord,col) SYN_UNITY_APPEND_FOG_COLOR(coord,col,fixed4(0,0,0,0))
#else
	#define SYN_UNITY_APPEND_FOG(coord,col) SYN_UNITY_APPEND_FOG_COLOR(coord,col,unity_FogColor)
#endif

#define SYN_UNITY_APPLY_FOG UNITY_APPLY_FOG

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
		#ifdef HASMETALLIC
			float metallic;
		#endif
	#endif
	float4 posWorld;
	LOC_SHADOWCOORD
	LOC_FOGCOORD
	float3 vertLight;
	#ifdef USE_TANGENTS
		float3 tangent;
		float3 bitangent;
	#endif
	float2 uv;
	#ifdef HAS_MATCAP
		float2 uvCap;
	#endif
};

#endif // ACKSTRUCTS
