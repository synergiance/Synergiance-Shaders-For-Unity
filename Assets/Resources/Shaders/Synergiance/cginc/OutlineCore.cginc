#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
#include "VrHelpers.cginc"
#include "Lighting/Helpers.cginc"

#ifdef OUTLINE_TEXTURE
sampler2D _OutlineMap;
int _OutlineMapCol;
#endif

float4 _OutlineColor;
float _OutlineWidth;
int _OutlineScreen;
int _OutlineSpace;
int _OutlineColorMode;

#ifdef ALPHA_TOGGLE
int _OutlineAlpha;
#endif

struct v2f {
	float4 pos : SV_POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
	float4 posWorld : TEXCOORD1;
	float3 vertLight : TEXCOORD2;
	float4 color : TEXCOORD3;
	SHADOW_COORDS(4)
	UNITY_FOG_COORDS(5)
	UNITY_VERTEX_OUTPUT_STEREO
};

#define CUSTOM_VERT
#define CUSTOM_INTERPOLATORS
#include "Lighting/Toon.cginc"

v2f vert (appdata_full v) {
	v2f o;
	float actualWidth = _OutlineWidth * 0.001;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_OUTPUT(v2f, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	#ifdef OUTLINE_TEXTURE
	float2 widthMultiplier = tex2Dlod(_OutlineMap, float4(o.uv, 0, 0)).ra;
	actualWidth *= lerp(widthMultiplier.x, widthMultiplier.y, _OutlineMapCol);
	#endif
	o.normal = UnityObjectToWorldNormal(v.normal);
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.pos = lerp(mul(unity_ObjectToWorld, v.vertex + float4(normalize(v.normal), 0) * actualWidth),
		o.posWorld + float4(normalize(o.normal), 0) * actualWidth, _OutlineSpace);
	o.pos = UnityWorldToClipPos(lerp(o.posWorld, o.pos, lerp(1, distance(o.posWorld, _WorldSpaceCameraCenterPos), _OutlineScreen)));
	#ifdef VERTEX_COLORS_TOGGLE
	o.color = _OutlineColor * lerp(_Color * lerp(1, v.color, _VertexColors), 1, _OutlineColorMode);
	#else
	o.color = _OutlineColor * lerp(_Color * v.color, 1, _OutlineColorMode);
	#endif
	#if defined(VERTEXLIGHT_ON)
	o.vertLight = Shade4PointLightsStyled(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb,
		unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, o.posWorld, o.normal * 0.5
	);
	#else
	o.vertLight = 0;
	#endif
	return o;
}

#ifndef SHADER_STAGE_VERTEX
float4 frag (v2f i) : COLOR {
	i.normal = normalize(i.normal);
	float4 col = i.color * lerp(_MainTex.Sample(sampler_MainTex, i.uv), 1, _OutlineColorMode);
	#ifdef OUTLINE_TEXTURE
	col.rgb *= lerp(1, tex2D(_OutlineMap, i.uv).rgb, _OutlineMapCol);
	#endif
	float3 lightDir = normalize(_WorldSpaceLightPos0.xyz - i.posWorld.xyz * _WorldSpaceLightPos0.w);
	float atten = calcLightAttenuationInternal(i.posWorld.xyz);
	float ndotl = dot(i.normal, lightDir) * 0.5 + 0.5;
	float shade = UNITY_SHADOW_ATTENUATION(i, i.posWorld.xyz);
	float3 lightColor = _LightColor0 * stylizeAtten(ndotl * shade, _ToonFeather, _ToonCoverage) * atten;
	#ifdef BASE_PASS
	lightColor += i.vertLight + ShadeSH9(float4(i.normal * 0.5, 1));
	#endif
	col.rgb *= lightColor;
	#ifdef ALPHA_TOGGLE
	col.a = _OutlineAlpha == 0 ? 1 : col.a;
	#endif
	return col;
}
#endif
