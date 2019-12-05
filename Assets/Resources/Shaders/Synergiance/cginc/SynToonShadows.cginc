#if !defined(SYN_TOON_SHADOWS)
#define SYN_TOON_SHADOWS

#include "UnityCG.cginc"

float4 _Color;
sampler2D _MainTex;
float4 _MainTex_ST;
float _Cutoff;
float _Dither;
sampler3D _DitherMaskLOD;

struct VertexData {
	float4 position : POSITION;
	float3 normal   : NORMAL;
	float2 uv       : TEXCOORD0;
};

struct VertexOutput {
	float4 position : SV_POSITION;
	float2 uv : TEXCOORD0;
	#if defined(SHADOWS_CUBE)
		float3 lightVec : TEXCOORD1;
	#endif
};

struct FragmentInput {
	UNITY_VPOS_TYPE vpos : VPOS;
	float2 uv : TEXCOORD0;
	#if defined(SHADOWS_CUBE)
		float3 lightVec : TEXCOORD1;
	#endif
};

VertexOutput vert (VertexData v) {
	VertexOutput i;
	#if defined(SHADOWS_CUBE)
		i.position = UnityObjectToClipPos(v.position);
		i.lightVec = mul(unity_ObjectToWorld, v.position).xyz - _LightPositionRange.xyz;
	#else
		i.position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
		i.position = UnityApplyLinearShadowBias(i.position);
	#endif
	i.uv = TRANSFORM_TEX(v.uv, _MainTex);
	return i;
}

half4 frag (FragmentInput i) : SV_TARGET {
	float alpha = tex2D(_MainTex, i.uv.xy).a * _Color.a;
	#if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
		clip (alpha - _Cutoff);
	#endif
	
	#if defined(_ALPHABLEND_ON)
		float dither = tex3D(_DitherMaskLOD, float3(i.vpos.xy * 0.25, alpha * 0.9375)).a;
		clip (dither - 0.01);
	#elif defined(_ALPHATEST_ON)
		float clipVal = 1;
		[branch] if (_Dither) {
			float dither = tex3D(_DitherMaskLOD, float3(i.vpos.xy * 0.25, alpha * 0.9375)).a;
			clipVal = dither - 0.01;
		}
		clip(clipVal);
	#endif
	
	#if defined(SHADOWS_CUBE)
		float depth = length(i.lightVec) + unity_LightShadowBias.x;
		depth *= _LightPositionRange.w;
		return UnityEncodeCubeShadowDepth(depth);
	#else
		return 0;
	#endif
}

#endif
