#ifndef ACKLIGHTINGCORE
#define ACKLIGHTINGCORE

#if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
	#define USEALPHA
#endif

#ifdef _NORMALMAP
	#define USE_TANGENTS
#endif

#ifdef _ALPHATEST_ON
	#define BEGIN_ALPHATEST_BLOCK(alpha) if (alpha > _Cutoff) {
	#define END_ALPHATEST_BLOCK }
#else
	#define BEGIN_ALPHATEST_BLOCK(alpha)
	#define END_ALPHATEST_BLOCK
#endif

// Extendible macros
#ifndef CALC_PRELIGHT
	#define CALC_PRELIGHT
#endif
#ifndef CALC_POSTLIGHT
	#define CALC_POSTLIGHT
#endif
#ifndef CALC_VERT
	#define CALC_VERT
#endif

#ifdef HAS_MATCAP
	#include "../Matcap.cginc"
#endif

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
#include "../Structs.cginc"
#include "Helpers.cginc"

#ifndef ITPL
	#define ITPL v2f
#endif

#ifndef CUSTOM_INTERPOLATORS
struct v2f {
	float4 pos : SV_POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
	float4 posWorld : TEXCOORD2;
	#ifdef USE_TANGENTS
		float4 tangent : TEXCOORD3;
	#endif
	float3 vertLight : TEXCOORD4;
	float4 color : TEXCOORD5;
	SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)
	#ifdef NEEDS_UVW
		float3 uvw : TEXCOORD8;
	#endif
	UNITY_VERTEX_OUTPUT_STEREO
};
#endif

SamplerState sampler_MainTex;
Texture2D _MainTex;
float4 _MainTex_ST;
float4 _Color;

Texture2D _OcclusionMap;
float _OcclusionStrength;

float _Exposure;

#ifdef _EMISSION
	Texture2D _EmissionMap;
	float4 _EmissionColor;
#endif // _EMISSION

#ifdef _NORMALMAP
	Texture2D _BumpMap;
	float _BumpScale;
#endif

#ifdef _ALPHATEST_ON
	float _Cutoff;
#endif

#ifdef USESHADE
	uint _ShadeMode;
#endif

#ifdef VERTEX_COLORS_TOGGLE
	float _VertexColors;
#endif

#ifndef CUSTOM_VERT
ITPL vert (appdata_full v) {
	ITPL o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_OUTPUT(v2f, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.normal = UnityObjectToWorldNormal(v.normal);
	#ifdef USE_TANGENTS
		o.tangent = float4(normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz), v.tangent.w);
	#endif
	TRANSFER_SHADOW(o)
	UNITY_TRANSFER_FOG(o, o.pos);
	#if defined(VERTEXLIGHT_ON)
		o.vertLight = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, o.posWorld, UnityObjectToWorldNormal(o.normal)
		);
	#else
		o.vertLight = 0;
	#endif
	#ifdef VERTEX_COLORS_TOGGLE
		o.color = lerp(1, v.color, _VertexColors) * _Color;
	#else
		o.color = v.color * _Color;
	#endif
	return o;
};
#endif

#if !defined(NO_INITIALIZE) && !defined(SHADER_STAGE_VERTEX)
void initializeStruct(inout shadingData s, inout ITPL i) {
	s.uv = i.uv.xy;
	s.color = _MainTex.Sample(sampler_MainTex, s.uv.xy).rgb * i.color.rgb;
	#ifdef USEALPHA
		s.alpha = _MainTex.Sample(sampler_MainTex, s.uv.xy).a   * i.color.a;
	#endif
	#ifdef _ALPHATEST_ON
		clip(s.alpha - _Cutoff);
	#endif
	s.normal = normalize(i.normal);
	#ifdef USE_TANGENTS
		s.tangent = normalize(i.tangent.xyz);
		s.bitangent = normalize(cross(s.normal, s.tangent) * i.tangent.w);
	#endif
	s.lightDir = _WorldSpaceLightPos0.rgb;
	#ifdef _EMISSION
		s.emission = _EmissionMap.Sample(sampler_MainTex, s.uv.xy).rgb * _EmissionColor.rgb;
	#endif // _EMISSION
	s.light = 1;
	s.posWorld = i.posWorld;
	s.viewDir = normalize(_WorldSpaceCameraPos - s.posWorld.xyz);
	#ifdef HASSPECULAR
		s.specular = 0;
		s.glossiness = 0;
		#ifdef HASMETALLIC
			s.metallic = _Metallic * _MetallicGlossMap.Sample(sampler_MainTex, s.uv.xy).r;
		#endif
	#endif
	SYN_TRANSFER_SHADOW(i,s)
	SYN_TRANSFER_FOG(i,s)
	s.vertLight = i.vertLight;
	s.lightCol = _LightColor0;
	#ifdef HAS_MATCAP
		s.uvCap = calcMatcapCoords(s.viewDir, s.normal);
	#endif
}
#endif // NO_INITIALIZE

#ifndef NO_FINALIZE
fixed4 calcFinalColor(shadingData s) {
	#ifdef _ALPHABLEND_ON
		fixed4 color = fixed4(s.color, s.alpha);
	#else
		fixed4 color = fixed4(s.color, 1);
	#endif
	#ifdef USESHADE
		color.rgb = lerp(color.rgb * s.light, s.light, _ShadeMode) * _Exposure;
	#else
		color.rgb *= s.light * _Exposure;
	#endif
	#ifdef HASMETALLIC
		color.rgb *= lerp(1, 0.8, s.metallic * s.glossiness);
	#endif
	#ifdef _EMISSION
		color.rgb += s.emission;
	#endif // _EMISSION
	#ifdef _ALPHAPREMULTIPLY_ON
		SYN_UNITY_APPLY_FOG(s.fogCoord, color);
		color.rgb *= color.a;
	#endif
	#ifdef HASSPECULAR
		#ifdef HASMETALLIC
			fixed3 metallicColor = s.color;
		#endif
	#endif
	#ifdef HAS_MATCAP
		applyMatcap(color.rgb, s, sampler_MainTex);
	#endif
	#ifdef HASSPECULAR
		fixed3 specular = s.specular;
		#ifdef HASMETALLIC
			specular *= lerp(1, (s.color.rgb * (s.color.rgb + 0.1) * 2 + 0.1) * s.glossiness, s.metallic);
		#endif
		#ifdef _ALPHAPREMULTIPLY_ON
			fixed3 speccolor = fixed3(specular * _Exposure);
			SYN_UNITY_APPEND_FOG(s.fogCoord, speccolor);
			color.rgb += speccolor.rgb;
		#else
			color.rgb += specular * _Exposure;
		#endif
	#endif // HASSPECULAR
	#ifndef _ALPHAPREMULTIPLY_ON
		SYN_UNITY_APPLY_FOG(s.fogCoord, color);
	#endif
	return color;
}
#endif // NO_FINALIZE

// Default Shading
#ifndef LIGHTDIROVERRIDE
float3 calcLightDirectionInternal(float3 posWorld) {
	return normalize(_WorldSpaceLightPos0.xyz - posWorld * _WorldSpaceLightPos0.w);
}

void calcLightDir(inout shadingData s) {
	s.lightDir = calcLightDirectionInternal(s.posWorld.xyz);
}
#endif // LIGHTDIROVERRIDE

#ifndef LIGHTSCALEOVERRIDE
void calcLightScale(inout shadingData s) {
	s.light.r = dot(s.normal, s.lightDir);
	s.light.g = calcLightAttenuationInternal(s.posWorld.xyz);
	#ifdef LIGHT_IN_VERTEX
		s.light.b = 1;
	#else
		s.light.b = UNITY_SHADOW_ATTENUATION(s, s.posWorld.xyz);
	#endif
}
#endif // LIGHTSCALEOVERRIDE

#ifndef LIGHTCOLOROVERRIDE
void calcLightColor(inout shadingData s) {
	s.light.rgb = max(0, s.light.r) * s.light.g * s.light.b * s.lightCol;
}
#endif // LIGHTCOLOROVERRIDE

#ifndef LIGHTAMBIENTOVERRIDE
void calcAmbient(inout shadingData s) {
	#ifdef BASE_PASS
		s.light.rgb += ShadeSH9(half4(s.normal, 1.0)) * lerp(1.0, _OcclusionMap.Sample(sampler_MainTex, s.uv.xy).g, _OcclusionStrength);
		s.light.rgb += s.vertLight;
	#endif // BASE_PASS
}
#endif // LIGHTAMBIENTOVERRIDE

#ifndef NORMALOVERRIDE
void calcNormal(inout shadingData s) {
	#ifdef _NORMALMAP
		float3x3 tangentTransform = float3x3(s.tangent, s.bitangent, s.normal);
		float3 bump = UnpackScaleNormal(_BumpMap.Sample(sampler_MainTex, s.uv.xy), _BumpScale);
		s.normal = normalize(mul(bump, tangentTransform));
	#endif // _NORMALMAP
}
#endif // NORMALOVERRIDE

#endif //ACKLIGHTINGCORE
