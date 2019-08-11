#if !defined(SYN_TOON_LIGHTING)
#define SYN_TOON_LIGHTING

#define GET_LIGHTDIR(p,l) normalize(lerp(l.xyz, l.xyz - p.xyz, l.w))
#define DIR_IS_ZERO(i, t) (abs(i.x) + abs(i.y) + abs(i.z) < t)

// Modified versions of Unity macros, designed to allow shadows to be moved within geometry functions unaltered
#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
	#define SYN_TRANSFER_SHADOW(src, dest) dest._ShadowCoord = src._ShadowCoord;
#elif defined(SHADOWS_SCREEN) && !defined(LIGHTMAP_ON) && !defined(UNITY_NO_SCREENSPACE_SHADOWS)
	#define SYN_TRANSFER_SHADOW(src, dest) dest._ShadowCoord = src._ShadowCoord;
#else
	#if defined(SHADOWS_SHADOWMASK)
		#define SYN_TRANSFER_SHADOW(src, dest) dest._ShadowCoord = src._ShadowCoord;
	#else
		#define SYN_TRANSFER_SHADOW(src, dest)
	#endif
#endif

// Modified versions of Unity macros, designed to separate shadow attenuation and light attenuation
#ifdef POINT
#define SYN_LIGHT_ATTENUATION(destName, worldPos) \
    unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
    fixed destName = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
#endif

#ifdef SPOT
#define SYN_LIGHT_ATTENUATION(destName, worldPos) \
    unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)); \
    fixed destName = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
#endif

#ifdef DIRECTIONAL
    #define SYN_LIGHT_ATTENUATION(destName, worldPos) fixed destName = 1.0;
#endif

#ifdef POINT_COOKIE
#define SYN_LIGHT_ATTENUATION(destName, worldPos) \
    unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
    fixed destName = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, lightCoord).w;
#endif

#ifdef DIRECTIONAL_COOKIE
#define SYN_LIGHT_ATTENUATION(destName, worldPos) \
    unityShadowCoord2 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xy; \
    fixed destName = tex2D(_LightTexture0, lightCoord).w;
#endif

float _LightingHack;
float _OverrideRealtime;
float _shadowcast_intensity;
float _ShadowAmbient;
sampler2D _ShadowRamp;
sampler2D _ShadowTexture;
int _ShadowRampDirection;
int _ShadowTextureMode;
float4 _ShadowTint;
float _shadow_coverage;
float _shadow_feather;
float _ShadowIntensity;
float _SSIntensity;
float _SSDistortion;
float _SSPower;

struct SynLighting {
	half3 lightDir;
	float noScale;
	float attenOverride;
};

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

float3 calcSpecular(float3 lightDir, float3 viewDir, float3 normalDir, float3 lightColor, float2 uv, float atten, float env, float3 pos)
{
	float3 specularIntensity = tex2D(_SpecularMap, uv).rgb * _SpecularColor.rgb;
	float3 halfVector = normalize(lightDir + viewDir);
	float3 specular = pow( saturate( dot( normalDir, halfVector)), _SpecularPower);
	float3 probe = float3(0, 0, 0);
	
	if (env > 0.00001) {
		float3 reflectionDir = reflect(-viewDir, normalDir);
		Unity_GlossyEnvironmentData envData;
		envData.roughness = 1 - _ProbeClarity;
		envData.reflUVW = BoxProjection(reflectionDir, pos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
		float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
		#if UNITY_SPECCUBE_BLENDING
			float interpolator = unity_SpecCube0_BoxMin.w;
			[branch] if (interpolator < 0.99999) {
				envData.reflUVW = BoxProjection(reflectionDir, pos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
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

SynLighting GetLightDirection(float3 position) {
	bool isZero = DIR_IS_ZERO(_WorldSpaceLightPos0, 0.01);
	SynLighting lightVar;
	lightVar.lightDir = half3(0, 0, 0);
	lightVar.noScale = 0;
	lightVar.attenOverride = isZero ? 1 : 0;
	[branch] switch (_LightingHack) {
		case 1:  //  World Static Light: Places light at a specific vector relative to the world.
			lightVar.lightDir = normalize(_StaticToonLight.rgb - position);
			break;
		case 2:  //  Local Static Light: Places light at a specific vector relative to the model.
			lightVar.lightDir = normalize(_StaticToonLight.rgb);
			break;
		case 3:  //  Object Static Light: Places light at a specific vector relative to the model in object space.
			lightVar.lightDir = normalize(mul(unity_ObjectToWorld, float4(_StaticToonLight.rgb, 0.0)).xyz);
			break;
		default: //  Normal lighting
			[branch] if (!isZero) {
				lightVar.lightDir = GET_LIGHTDIR(position, _WorldSpaceLightPos0);
			} else {
				lightVar.noScale = 1;
			}
			break;
	}
	[branch] if (_LightingHack > 0) {
		[branch] if (_OverrideRealtime) {
			lightVar.attenOverride = 1;
		} else {
			[branch] if (!isZero) {
				lightVar.lightDir = GET_LIGHTDIR(position, _WorldSpaceLightPos0);
			}/* else {
				// Xiexe's light probe dominant direction calculation
				half3 probeLightDir = normalize(unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz);
				[flatten] if(!DIR_IS_ZERO(probeLightDir, 0.1)) {
					lightVar.lightDir = probeLightDir;
				}
				lightVar.noScale = 1;
			}*/
		}
	}
	return lightVar;
}

float GetLightScale(SynLighting lightVar, float3 normal, float atten) {
	float lightScale = 1;
	[branch] if (!lightVar.noScale) {
		lightScale = dot(normal, lightVar.lightDir) * 0.5 + 0.5;
	}
	#if defined(IS_OPAQUE)
		[branch] if (_shadowcast_intensity > 0 && !lightVar.attenOverride) {
			lightScale *= atten;
		}
	#endif
	return lightScale;
}

float4 GetStyledShadow(float lightScale, float4 uvs, float3 color) {
	float4 uv  = float4(uvs.xy, 0, 0);
	float4 uv1 = float4(uvs.zw, 0, 0);
    float4 bright = float4(1.0, 1.0, 1.0, lightScale);
	[branch] switch (_ShadowMode) {
		case 1: // Tinted Shadow
			{
				float lightContrib = saturate(smoothstep((1 - _shadow_feather) * _shadow_coverage, _shadow_coverage, lightScale)) * tex2Dlod(_OcclusionMap, uv).r;
				bright.rgb = lerp(_ShadowTint.rgb, float3(1.0, 1.0, 1.0), lightContrib);
			}
			break;
		case 2: // Ramp Shadow
			{
				lightScale *= tex2Dlod(_OcclusionMap, uv).r;
				bright.rgb = tex2Dlod(_ShadowRamp, float4(lightScale, lightScale, 0, 0)).rgb;
			}
			break;
		case 3: // Texture Shadow
			{
				bright.rgb = tex2Dlod(_ShadowTexture, uv1);
				[branch] if (_ShadowTextureMode) { // Tint
					float lightContrib = saturate(smoothstep((1 - _shadow_feather) * _shadow_coverage, _shadow_coverage, lightScale)) * tex2Dlod(_OcclusionMap, uv);
					bright.rgb = lerp(bright.rgb, float3(1.0, 1.0, 1.0), lightContrib);
				} else { // Texture
					bright.a = lightScale * tex2Dlod(_OcclusionMap, uv).r;
				}
			}
			break;
		case 4: // Multiple Shadows
			{
				lightScale *= tex2Dlod(_OcclusionMap, uv).r;
				[branch] if (_ShadowRampDirection) { // Horizontal
					bright.rgb = tex2Dlod(_ShadowRamp, float4(lightScale * tex2Dlod(_OcclusionMap, uv).r, clamp(LinearToGammaSpace(tex2Dlod(_ShadowTexture, uv1)).r, 0.01, 0.99), 0, 0)).rgb;
				} else { // Vertical
					bright.rgb = tex2Dlod(_ShadowRamp, float4(clamp(LinearToGammaSpace(tex2Dlod(_ShadowTexture, uv1)).r, 0.01, 0.99), lightScale * tex2Dlod(_OcclusionMap, uv).r, 0, 0)).rgb;
				}
			}
			break;
		case 5: // Auto Shadow
			{
				float lightContrib = saturate(smoothstep((1 - _shadow_feather) * _shadow_coverage, _shadow_coverage, lightScale)) * tex2Dlod(_OcclusionMap, uv).r;
				float3 tintColor = lerp(bright.rgb, pow(color, 2), _ShadowIntensity) * lerp(float3(0,0,0), _ShadowTint, _ShadowAmbient);
				bright.rgb = lerp(tintColor, float3(1.0, 1.0, 1.0), lightContrib);
			}
			break;
		default:
			break;
	}
	return bright;
}

float CalcScattering(float3 lightDir, float3 normalDir, float3 viewDir) {
	float3 halfDir = normalize(lightDir + normalDir * _SSDistortion);
	return pow(saturate(dot(viewDir, -halfDir)), _SSPower);
}

float4 calcShadow(float3 position, float3 normal, float atten, float4 uvs, float3 color)
{// Generate the shadow based on the light direction
	float4 bright = float4(1.0, 1.0, 1.0, 1.0);
	[branch] if (_ShadowMode > 0) {
		float lightScale = GetLightScale(GetLightDirection(position), normal, atten);
		bright = GetStyledShadow(lightScale, uvs, color);
	}
	return bright;
}

float3 Shade4PointLightsStyled (
    float4 lightPosX, float4 lightPosY, float4 lightPosZ,
    float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
    float4 lightAttenSq, float3 pos, float3 normal, float4 uvs, float3 color)
{
    // to light vectors
    float4 toLightX = lightPosX - pos.x;
    float4 toLightY = lightPosY - pos.y;
    float4 toLightZ = lightPosZ - pos.z;
    // squared lengths
    float4 lengthSq = 0;
    lengthSq += toLightX * toLightX;
    lengthSq += toLightY * toLightY;
    lengthSq += toLightZ * toLightZ;
    // don't produce NaNs if some vertex position overlaps with the light
    lengthSq = max(lengthSq, 0.000001);

    // NdotL
    float4 ndotl = 0;
    ndotl += toLightX * normal.x;
    ndotl += toLightY * normal.y;
    ndotl += toLightZ * normal.z;
    // correct NdotL
    float4 corr = rsqrt(lengthSq);
    ndotl = max (float4(0,0,0,0), ndotl * corr);
    // attenuation
    float4 atten = 1.0 / (1.0 + lengthSq * lightAttenSq);
    float4 diff = ndotl * atten;
    // final color
    float3 col = 0;
    col += lightColor0 * diff.x * GetStyledShadow(diff.x, uvs, color);
    col += lightColor1 * diff.y * GetStyledShadow(diff.y, uvs, color);
    col += lightColor2 * diff.z * GetStyledShadow(diff.z, uvs, color);
    col += lightColor3 * diff.w * GetStyledShadow(diff.w, uvs, color);
    return col;
}

#endif
