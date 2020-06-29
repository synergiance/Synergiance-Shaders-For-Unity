// PBR Lighting Core
#ifndef ACKLIGHTINGPBR
#define ACKLIGHTINGPBR

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

#ifndef LDATA
#define LDATA lightData
struct lightData {
	fixed4 color;
	float smoothness;
	float metallic;
	float3 normal;
	float4 position;
	float4 pos;

	#if defined(SHADOWS_SCREEN)
		float4 _ShadowCoord;
	#endif

	#if defined(VERTEXLIGHT_ON)
		float3 vertexLightColor;
	#endif
};
#endif

void computeVertexLightColor (inout LDATA i) {
	#if defined(VERTEXLIGHT_ON)
		i.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, i.position, i.normal
		);
	#endif
}

UnityLight createLight (LDATA i) {
	UnityLight light;
	
	#if defined(POINT) || defined(SPOT)
		light.dir = normalize(_WorldSpaceLightPos0.xyz - i.position);
	#else
		light.dir = _WorldSpaceLightPos0.xyz;
	#endif
	
	UNITY_LIGHT_ATTENUATION(attenuation, i, i.position.xyz);
	light.color = _LightColor0.rgb * attenuation;
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

UnityIndirect createIndirectLight (LDATA i) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = i.vertexLightColor;
	#endif
	
	#if defined(FORWARD_BASE_PASS)
		indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
	#endif
	
	return indirectLight;
}


fixed4 calcLighting(LDATA i) {
	i.normal = normalize(i.normal);
	float3 viewDir = normalize(_WorldSpaceCameraPos - i.position);
	float3 albedo = i.color.rgb;
	
	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(albedo, i.metallic, specularTint, oneMinusReflectivity);
	
	return UNITY_BRDF_PBS(albedo, specularTint, oneMinusReflectivity, i.smoothness, i.normal, viewDir, createLight(i), createIndirectLight(i));
}

#endif // ACKLIGHTINGPBR
