#ifndef SYN_SHADOW_CORE
#define SYN_SHADOW_CORE

#include "UnityCG.cginc"

#if defined(_ALPHABLEND_ON) || defined(_ALPHATEST_ON)
    #define USES_ALPHA
#endif

#ifdef USES_ALPHA
    float4 _Color;
    sampler2D _MainTex;
    float4 _MainTex_ST;
#endif
#ifdef _ALPHATEST_ON
    float _Cutoff;
#endif
#ifdef _ALPHABLEND_ON
    sampler3D _DitherMaskLOD;
#endif

struct VertexData {
	float4 position : POSITION;
    #ifndef SHADOWS_CUBE
	    float3 normal   : NORMAL;
    #endif
    #ifdef USES_ALPHA
	    float2 uv       : TEXCOORD0;
    #endif
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput {
	float4 position : SV_POSITION;
    #ifdef USES_ALPHA
	    float2 uv : TEXCOORD0;
    #endif
	#ifdef SHADOWS_CUBE
		float3 lightVec : TEXCOORD1;
	#endif
	UNITY_VERTEX_OUTPUT_STEREO
};

struct FragmentInput {
	UNITY_VPOS_TYPE vpos : VPOS;
    #ifdef USES_ALPHA
	    float2 uv : TEXCOORD0;
    #endif
	#ifdef SHADOWS_CUBE
		float3 lightVec : TEXCOORD1;
	#endif
};

VertexOutput vert (VertexData v) {
	VertexOutput i;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_OUTPUT(VertexOutput, i);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(i);
	#ifdef SHADOWS_CUBE
		i.position = UnityObjectToClipPos(v.position);
		i.lightVec = mul(unity_ObjectToWorld, v.position).xyz - _LightPositionRange.xyz;
	#else
		i.position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
		i.position = UnityApplyLinearShadowBias(i.position);
	#endif
    #ifdef USES_ALPHA
	    i.uv = TRANSFORM_TEX(v.uv, _MainTex);
    #endif
	return i;
}

half4 frag (FragmentInput i) : SV_TARGET {
	#ifdef USES_ALPHA
        float alpha = tex2D(_MainTex, i.uv.xy).a * _Color.a;
    #endif
    #ifdef _ALPHATEST_ON
		clip (alpha - _Cutoff);
	#endif
	#ifdef _ALPHABLEND_ON
		float dither = tex3D(_DitherMaskLOD, float3(i.vpos.xy * 0.25, alpha * 0.9375)).a;
		clip (dither - 0.01);
	#endif
	
	#ifdef SHADOWS_CUBE
		float depth = length(i.lightVec) + unity_LightShadowBias.x;
		depth *= _LightPositionRange.w;
		return UnityEncodeCubeShadowDepth(depth);
	#else
		return 0;
	#endif
}

#endif // SYN_SHADOW_CORE
