#ifndef ACKLIGHTINGSPECULAR
#define ACKLIGHTINGSPECULAR

#ifdef ANISOTROPIC_SPECULAR
	#define USE_TANGENTS
#endif

#define HASSPECULAR
#include "Core.cginc"
#include "Reflections.cginc"

float _Glossiness;

#if defined(_METALLICGLOSSMAP) && defined(HASMETALLIC)
	#define GET_GLOSSINESS _GlossMapScale * (_SmoothnessTextureChannel == 0 ? _MetallicGlossMap.Sample(sampler_MainTex, s.uv.xy).a : _MainTex.Sample(sampler_MainTex, s.uv.xy).a)
#else
	#define GET_GLOSSINESS _Glossiness;
#endif

#ifndef LIGHTSPECOVERRIDE
void calcSpecular(inout shadingData s) {
	s.glossiness = GET_GLOSSINESS;

	float3 halfVector = normalize(s.lightDir + s.viewDir);
	float specular = pow(saturate(dot(s.normal, halfVector)), s.glossiness * 100);
	
	fixed3 probe = calcProbe(s.viewDir, s.normal, s.posWorld, s.lightCol, 1 - s.glossiness, s.light.g);
	
	s.specular += specular * s.lightCol + probe;
}
#endif // LIGHTSPECOVERRIDE

/*
float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax) {
	#if UNITY_SPECCUBE_BOX_PROJECTION
		[branch] if (cubemapPosition.w > 0) {
			float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - cubemapPosition);
		}
	#endif
	return direction;
}

float3 calcSpecular(float3 lightDir, float3 viewDir, float3 normalDir, float3 lightColor, VertexOutput i, float atten, float env) {
	float3 specularIntensity = _SpecularMap.Sample(sampler_MainTex, i.uv.xy).rgb * _SpecularColor.rgb;
	float3 halfVector = normalize(lightDir + viewDir);
	float3 specular = pow( saturate( dot( normalDir, halfVector)), _SpecularPower);
	float3 probe = float3(0, 0, 0);
	
	// http://wiki.unity3d.com/index.php/Anisotropic_Highlight_Shader
	[branch] if (_Anisotropic > 0) {
		float3 anisodir = normalDir;
		[branch] switch (_Anisotropic) {
			case 1: // Texture
				float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
				float3 anisotexdir = UnpackNormal(_AnisoTex.Sample(sampler_MainTex, i.uv.xy));
				anisodir = normalize(mul(anisotexdir.rgb, tangentTransform));
				break;
			case 2: // Horizontal
				anisodir = i.tangentDir;
				break;
			case 3: // Vertical
				anisodir = i.bitangentDir;
				break;
		}
		float NdotL = saturate(dot(normalDir, lightDir));
		fixed HdotA = dot(normalize(normalDir + anisodir.rgb), halfVector);
		float aniso = max(0, sin(radians((HdotA + _AnisoOffset) * 180)));
		specular = saturate(pow(aniso, _SpecularPower));
	}
	
	if (env > 0.00001) {
		float3 reflectionDir = reflect(-viewDir, normalDir);
		Unity_GlossyEnvironmentData envData;
		envData.roughness = 1 - _ProbeClarity;
		envData.reflUVW = BoxProjection(reflectionDir, i.posWorld, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
		float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
		#if UNITY_SPECCUBE_BLENDING
			float interpolator = unity_SpecCube0_BoxMin.w;
			[branch] if (interpolator < 0.99999) {
				envData.reflUVW = BoxProjection(reflectionDir, i.posWorld, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
				float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube0_HDR, envData);
				probe = lerp(probe1, probe0, interpolator);
			} else {
				probe = probe0;
			}
		#else
			probe = probe0;
		#endif
	}
	
	specular = specular * specularIntensity * lightColor * atten + probe * env;
	return specular;
}
*/

#endif // ACKLIGHTINGSPECULAR
