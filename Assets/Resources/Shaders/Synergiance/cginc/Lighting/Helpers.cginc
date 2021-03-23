#ifndef SYNACK_HELPERS
#define SYNACK_HELPERS

#include "AutoLight.cginc"

#ifdef LIGHT_IN_VERTEX
    #define SafeTex2D(sampl, uv) tex2Dlod(sampl, float4(uv.xy, 0, 0))
    #define SafeTexCUBE(sampl, uvw) texCUBElod(sampl, float4(uvw.xyz, 0))
#else
    #define SafeTex2D(sampl, uv) tex2D(sampl, uv.xy)
    #define SafeTexCUBE(sampl, uvw) texCUBE(sampl, uvw.xyz)
#endif

#ifndef LIGHTSCALEOVERRIDE
float calcLightAttenuationInternal(float3 posWorld) {
	#if defined(POINT)
		unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(posWorld, 1)).xyz;
		return SafeTex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
	#elif defined(SPOT)
		unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(posWorld, 1));
	#ifndef SHADER_STAGE_FRAGMENT
		return (lightCoord.z > 0) * tex2Dlod(_LightTexture0, float4(lightCoord.xy / lightCoord.w + 0.5, 0, 0)).w * tex2Dlod(_LightTextureB0, float4(dot(lightCoord.xyz, lightCoord.xyz).xx, 0, 0)).r;
	#else
		return (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
	#endif
	#elif defined(POINT_COOKIE)
		unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(posWorld, 1)).xyz;
		return SafeTex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL * SafeTexCUBE(_LightTexture0, lightCoord).w;
	#elif defined(DIRECTIONAL_COOKIE)
		unityShadowCoord2 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(posWorld, 1)).xy;
		return SafeTex2D(_LightTexture0, lightCoord).w;
	#else
		return 1.0;
	#endif
}
#endif

#endif
