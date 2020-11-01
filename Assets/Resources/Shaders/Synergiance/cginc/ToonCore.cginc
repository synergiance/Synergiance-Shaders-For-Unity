#ifndef ACKTOONCORE
#define ACKTOONCORE

#ifndef CUSTOM_VERT
	#define USE_TOON_VERT
	#define CUSTOM_VERT
#endif
#include "Lighting/Metallic.cginc"
#include "Lighting/ToonSpecular.cginc"

#ifdef FAKE_LIGHT
	fixed _FakeLight;
	fixed3 _FakeLightCol;
#endif

#if defined(_EMISSION) && defined(EMISSION_FALLOFF)
	fixed _EmissionFalloff;
#endif

#ifdef USE_TOON_VERT
ITPL vert (appdata_full v) {
	ITPL o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.normal = UnityObjectToWorldNormal(v.normal);
	#ifdef _NORMALMAP
		o.tangent = float4(normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz), v.tangent.w);
	#endif
	TRANSFER_SHADOW(o)
	UNITY_TRANSFER_FOG(o, o.pos);
	#if defined(VERTEXLIGHT_ON)
		o.vertLight = Shade4PointLightsStyled(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, o.posWorld, o.normal
		);
	#else
		o.vertLight = 0;
	#endif
	o.color = v.color * _Color;
	CALC_VERT
	return o;
};
#endif

void calcFakeLight(inout shadingData s) {
	#if !defined(USES_GRADIENTS) && !defined(SHADOWRAMP) && !defined(SHADOWMAP) && defined(BASE_PASS) && defined(FAKE_LIGHT)
		float3 shadeCol = _ToonColor.rgb;
		#ifdef SHADE_TEXTURE
			shadeCol *= _ShadeTex.Sample(sampler_MainTex, s.uv.xy).rgb;
			#define BRIGHT_COL lerp(1, s.color, _ShadeMode)
		#else
			#define BRIGHT_COL 1
		#endif
		float ndotl = dot(s.normal.xyz, _FallbackLightDir) * 0.5 + 0.5;
		shadeCol *= lerp(1, s.color, _ToonIntensity);
		shadeCol = lerp(shadeCol, BRIGHT_COL, stylizeAtten(ndotl, _ToonFeather, _ToonCoverage));
		s.light.rgb += _FakeLightCol * _FakeLight * shadeCol;
		#undef BRIGHT_COL
	#endif
}

#if !defined(NO_TOON_FRAG) && !defined(SHADER_STAGE_VERTEX)
fixed4 frag (ITPL i, bool isFrontFace : SV_ISFRONTFACE) : COLOR {
	// Initialize
	shadingData s;
	initializeStruct(s, i);
	
	// Calculations
	calcNormal(s);
	s.normal *= isFrontFace ? 1 : -1;

	CALC_PRELIGHT
	
	calcLightDir(s);
	calcLightScale(s);
	s.light.r = s.light.r * 0.5 + 0.5;
	#ifdef HASSPECULAR
		calcSpecular(s);
	#endif
	calcLightColor(s);
	calcAmbient(s);
	calcFakeLight(s);

	CALC_POSTLIGHT

	#if defined(_EMISSION) && defined(EMISSION_FALLOFF)
		s.emission *= lerp(1 - _EmissionFalloff, 1, max(0, dot(s.viewDir, s.normal)));
	#endif
	
	// Final Blending
	return calcFinalColor(s);
}
#endif

#endif // ACKTOONCORE
