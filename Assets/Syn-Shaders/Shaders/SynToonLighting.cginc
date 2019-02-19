#if !defined(SYN_TOON_LIGHTING)
#define SYN_TOON_LIGHTING

#define GET_LIGHTDIR(p,l) normalize(lerp(l.xyz, l.xyz - p.xyz, l.w))
#define DIR_IS_ZERO(i, t) (abs(i.x + i.y + i.z) < t)

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

float GetLightScale(float3 position, float3 normal, float atten) {
	float lightScale = 1;
	float3 lightDirection = float3(0, 0, 0);
	#if LOCAL_STATIC_LIGHT // Places light at a specific vector relative to the model.
		lightDirection = normalize(_StaticToonLight.rgb);
	#elif WORLD_STATIC_LIGHT // Places light at a specific vector relative to the world.
		lightDirection = normalize(_StaticToonLight.rgb - position);
	#else // Normal lighting
		[branch] if (!DIR_IS_ZERO(_WorldSpaceLightPos0, 0.01)) {
			lightDirection = GET_LIGHTDIR(position, _WorldSpaceLightPos0);
			lightScale = dot(normal, lightDirection) * 0.5 + 0.5;
		} else {
			atten = 1;
		}
	#endif
	#if !NORMAL_LIGHTING
		#if !OVERRIDE_REALTIME
			[branch] if (!DIR_IS_ZERO(_WorldSpaceLightPos0, 0.01)) {
				lightDirection = GET_LIGHTDIR(position, _WorldSpaceLightPos0);
			} else {
				atten = 1;
			}
		#else
			atten = 1;
		#endif
		[branch] if (DIR_IS_ZERO(_WorldSpaceLightPos0, 0.01)) {
			atten = 1;
		}
		lightScale = dot(normal, lightDirection) * 0.5 + 0.5;
	#endif
	#if defined(IS_OPAQUE) && !DISABLE_SHADOW
		lightScale *= atten;
	#endif
	return lightScale;
}

float4 GetStyledShadow(float lightScale, float4 uvs, float3 color) {
	float2 uv  = uvs.xy;
	float2 uv1 = uvs.zw;
    float4 bright = float4(1.0, 1.0, 1.0, lightScale);
	[branch] switch (_ShadowMode) {
		case 1: // Tinted Shadow
			{
				float lightContrib = saturate(smoothstep((1 - _shadow_feather) * _shadow_coverage, _shadow_coverage, lightScale)) * tex2D(_OcclusionMap, uv).r;
				bright.rgb = lerp(_ShadowTint.rgb, float3(1.0, 1.0, 1.0), lightContrib);
			}
			break;
		case 2: // Ramp Shadow
			{
				lightScale *= tex2D(_OcclusionMap, uv).r;
				bright.rgb = tex2D(_ShadowRamp, float2(lightScale, lightScale)).rgb;
			}
			break;
		case 3: // Texture Shadow
			{
				bright.rgb = tex2D(_ShadowTexture, uv1);
				[branch] if (_ShadowTextureMode) { // Tint
					float lightContrib = saturate(smoothstep((1 - _shadow_feather) * _shadow_coverage, _shadow_coverage, lightScale)) * tex2D(_OcclusionMap, uv);
					bright.rgb = lerp(bright.rgb, float3(1.0, 1.0, 1.0), lightContrib);
				} else { // Texture
					bright.a = lightScale * tex2D(_OcclusionMap, uv).r;
				}
			}
			break;
		case 4: // Multiple Shadows
			{
				lightScale *= tex2D(_OcclusionMap, uv).r;
				[branch] if (_ShadowRampDirection) { // Horizontal
					bright.rgb = tex2D(_ShadowRamp, float2(lightScale * tex2D(_OcclusionMap, uv).r, LinearToGammaSpace(tex2D(_ShadowTexture, uv1)).r)).rgb;
				} else { // Vertical
					bright.rgb = tex2D(_ShadowRamp, float2(LinearToGammaSpace(tex2D(_ShadowTexture, uv1)).r, lightScale * tex2D(_OcclusionMap, uv).r)).rgb;
				}
			}
			break;
		case 5: // Auto Shadow
			{
				float lightContrib = saturate(smoothstep((1 - _shadow_feather) * _shadow_coverage, _shadow_coverage, lightScale)) * tex2D(_OcclusionMap, uv).r;
				float3 tintColor = lerp(bright.rgb, pow(color, 2), _ShadowIntensity) * lerp(float3(0,0,0), _ShadowTint, _ShadowAmbient);
				bright.rgb = lerp(tintColor, float3(1.0, 1.0, 1.0), lightContrib);
			}
			break;
		default:
			break;
	}
	return bright;
}

float4 calcShadow(float3 position, float3 normal, float atten, float4 uvs, float3 color)
{// Generate the shadow based on the light direction
	float4 bright = float4(1.0, 1.0, 1.0, 1.0);
	[branch] if (_ShadowMode > 0) {
		float lightScale = GetLightScale(position, normal, atten);
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
