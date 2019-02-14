// SynToon by Synergiance
// v0.4.1.2

#define VERSION="v0.4.1.2"

#ifndef ALPHA_RAINBOW_CORE_INCLUDED

#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "HSB.cginc"
#include "Rotate.cginc"

sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _OcclusionMap;
sampler2D _ColorMask;
sampler2D _EmissionMap;
float4 _MainTex_ST;
float4 _EmissionColor;
#if defined(PULSE)
float _EmissionSpeed;
sampler2D _EmissionPulseMap;
float4 _EmissionPulseColor;
#endif
float _Brightness;
float _CorrectionLevel;
float4 _Color;
float4 _LightColor;
float _LightOverride;
float _ShadowAmbient;
sampler2D _ShadowRamp;
sampler2D _ShadowTexture;
int _ShadowRampDirection;
int _ShadowTextureMode;
float4 _ShadowTint;
float _shadow_coverage;
float _shadow_feather;
float _shadowcast_intensity;
float _ShadowIntensity;
float _Cutoff;
float _AlphaOverride;
float _SaturationBoost;
#if defined(RAINBOW)
sampler2D _RainbowMask;
float _Speed;
#endif
uniform float _outline_width;
uniform float _outline_feather;
uniform float4 _outline_color;
//sampler2D _ToonTex;
Texture2D _SphereAddTex;
Texture2D _SphereMulTex;
Texture2D _SphereMultiTex;
Texture2D _SphereAtlas;
SamplerState sampler_SphereAtlas;
int _SphereNum;
uniform float4 _StaticToonLight;
float _OverlayMode;
float _OverlayBlendMode;
samplerCUBE _PanoSphereTex;
sampler2D _PanoFlatTex;
sampler2D _PanoOverlayTex;
float _PanoRotationSpeedX;
float _PanoRotationSpeedY;
float _PanoBlend;
sampler2D _SpecularMap;
float _SpecularPower;
float3 _SpecularColor;
float _UVScrollX;
float _UVScrollY;
float _SphereMode;
float _ShadowMode;
int _SphereUV;
int _ShadowUV;

static const float3 grayscale_vector = float3(0, 0.3823529, 0.01845836);

struct v2g
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float3 normal : NORMAL;
    fixed4 amb : COLOR0;
    fixed3 direct : COLOR1;
    fixed3 indirect : COLOR2;
    float4 posWorld : TEXCOORD2;
    float3 normalDir : TEXCOORD3;
    float3 tangentDir : TEXCOORD4;
    float3 bitangentDir : TEXCOORD5;
    float4 lightData : TEXCOORD8;
    float3 reflectionMap : TEXCOORD9;
    float lightModifier : TEXCOORD10;
	float4 pos : CLIP_POS;
	LIGHTING_COORDS(6,7)
	UNITY_FOG_COORDS(11)
	float2 uv2 : TEXCOORD12;
	float2 uv3 : TEXCOORD13;
};

struct VertexOutput
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
    float3 normal : NORMAL;
    fixed4 amb : COLOR0; //
    fixed3 direct : COLOR1; //
    fixed3 indirect : COLOR2; //
	float4 posWorld : TEXCOORD2;
	float3 normalDir : TEXCOORD3;
	float3 tangentDir : TEXCOORD4;
	float3 bitangentDir : TEXCOORD5;
    float4 lightData : TEXCOORD8; //
    float3 reflectionMap : TEXCOORD9; //
    float lightModifier : TEXCOORD10; //
	float4 col : COLOR3;
	bool is_outline : IS_OUTLINE;
	LIGHTING_COORDS(6,7)
	UNITY_FOG_COORDS(11)
	float2 uv2 : TEXCOORD12;
	float2 uv3 : TEXCOORD13;
};

float grayscaleSH9(float3 normalDirection)
{
    return dot(ShadeSH9(half4(normalDirection, 1.0)), grayscale_vector);
}

#if defined(RAINBOW)
float3 hueShift(float3 col, float3 mask)
{
    float3 newc = col;
    newc = float3(applyHue(newc, _Time[1] * _Speed * _Speed * _Speed));
    newc = float3((newc * mask) + (col * (1 - mask)));
    return newc;
}
#endif

v2g vert(appdata_full v)
{
    v2g o;
	o.pos = UnityObjectToClipPos(v.vertex);
    o.normal = v.normal;
    o.normalDir = normalize(UnityObjectToWorldNormal(v.normal));
    float3 lcHSV = RGBtoHSV(_LightColor.rgb);
    o.amb = lerp(_LightColor0, float4(HSVtoRGB(float3(lcHSV.xy, RGBtoHSV(_LightColor0.rgb).z)), _LightColor0.z), _LightOverride);
    o.direct = ShadeSH9(half4(0.0, 1.0, 0.0, 1.0));
    o.indirect = ShadeSH9(half4(0.0, -1.0, 0.0, 1.0));
    o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
    o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
    o.posWorld = mul(unity_ObjectToWorld, v.vertex);
    o.vertex = v.vertex;
    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	#ifdef LIGHTMAP_ON
		o.uv1 = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	#else
		o.uv1 = v.texcoord1.xy;
	#endif
	TRANSFER_VERTEX_TO_FRAGMENT(o);
	UNITY_TRANSFER_FOG(o, o.pos);
	o.uv2 = v.texcoord2.xy;
	o.uv3 = v.texcoord3.xy;
    
    // Calc
    o.lightData.r = dot(_LightColor0.rgb, grayscale_vector);       // grayscalelightcolor
    o.lightData.g = grayscaleSH9(float3(0.0, -1.0, 0.0));          // bottomIndirectLighting
    o.lightData.b = grayscaleSH9(float3(0.0, 1.0, 0.0));           // topIndirectLighting
    o.lightData.a = o.lightData.b + o.lightData.r - o.lightData.g; // lightDifference
    
    float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
    o.reflectionMap = DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, normalize((_WorldSpaceCameraPos - objPos.rgb)), 7), unity_SpecCube0_HDR)* 0.02;
    float3 lightColor = o.direct + o.amb.rgb * 2 + o.reflectionMap;
    float brightness = lightColor.r * 0.3 + lightColor.g * 0.59 + lightColor.b * 0.11;
    float correctedBrightness = -1 / (brightness * 2 + 1) + 1 + brightness * 0.1;
    o.lightModifier = correctedBrightness / brightness;
    
    return o;
}

float3 calcSpecular(float3 lightDir, float3 viewDir, float3 normalDir, float3 lightColor, float2 uv, float atten)
{
	float3 specularIntensity = tex2D(_SpecularMap, uv).rgb * _SpecularColor.rgb;
	float3 halfVector = normalize(lightDir + viewDir);
	float3 specular = pow( saturate( dot( normalDir, halfVector)), _SpecularPower);
	specular = specular * specularIntensity * lightColor * atten;
	return specular;
}

float4 calcShadow(float3 position, float3 normal, float atten, float4 uvs, float3 color)
{// Generate the shadow based on the light direction
	float2 uv  = uvs.xy;
	float2 uv1 = uvs.zw;
    float4 bright = float4(1.0, 1.0, 1.0, 1);
	[branch] if (_ShadowMode > 0) {
		float lightScale = 1;
		float3 lightDirection = float3(0, 0, 0);
		#if LOCAL_STATIC_LIGHT // Places light at a specific vector relative to the model.
			lightDirection = normalize(_StaticToonLight.rgb);
		#elif WORLD_STATIC_LIGHT // Places light at a specific vector relative to the world.
			lightDirection = normalize(_StaticToonLight.rgb - position);
		#else // Normal lighting
			[flatten] if (!(abs(_WorldSpaceLightPos0.x + _WorldSpaceLightPos0.y + _WorldSpaceLightPos0.z) <= 0.01))
			{
				lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - position, _WorldSpaceLightPos0.w));
				lightScale = dot(normal, lightDirection) * 0.5 + 0.5;
			}
			else
			{
				atten = 1;
			}
		#endif
		#if !NORMAL_LIGHTING
			#if !OVERRIDE_REALTIME
				[flatten] if (!(abs(_WorldSpaceLightPos0.x + _WorldSpaceLightPos0.y + _WorldSpaceLightPos0.z) <= 0.01))
				{
					lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - position, _WorldSpaceLightPos0.w));
				}
				else
				{
					atten = 1;
				}
			#else
				atten = 1;
			#endif
			[flatten] if (abs(_WorldSpaceLightPos0.x + _WorldSpaceLightPos0.y + _WorldSpaceLightPos0.z) <= 0.01)
			{
				atten = 1;
			}
			lightScale = dot(normal, lightDirection) * 0.5 + 0.5;
		#endif
		#if defined(IS_OPAQUE) && !DISABLE_SHADOW
			//lightScale *= atten * _shadowcast_intensity + (1 - _shadowcast_intensity);  * tex2D(_OcclusionMap, uv)
			lightScale *= atten;
		#endif
		bright.a = lightScale;
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
				[branch] if (_ShadowRampDirection) { // Horizontal
					bright.rgb = tex2D(_ShadowRamp, float2(lightScale * tex2D(_OcclusionMap, uv).r, tex2D(_ShadowTexture, uv1).r)).rgb;
				} else { // Vertical
					bright.rgb = tex2D(_ShadowRamp, float2(tex2D(_ShadowTexture, uv1).r, lightScale * tex2D(_OcclusionMap, uv).r)).rgb;
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
	}
    return bright;
}

float3 artsyOutline(float3 color, float3 view, float3 normal)
{// Outline
    #if ARTSY_OUTLINE
		float3 outlineColor = color;
		#if TINTED_OUTLINE
			outlineColor *= _outline_color.rgb;
		#elif COLORED_OUTLINE
			outlineColor = float3((_outline_color.rgb * _outline_color.a) + (color * (1 - _outline_color.a)));
		#endif
		color = lerp(outlineColor,color.rgb,smoothstep(_outline_width - _outline_feather / 10, _outline_width, dot(view, normal)));
		// Outline Effects
		
    #endif
    return color;
}

float3 applySphere(float3 color, float3 view, float3 normal, float2 uv)
{// Applies add and multiply spheres
	[branch] if (_SphereMode > 0) { // Don't execute without sphere mode set
		float3 tangent = normalize(cross(view, float3(0.0, 1.0, 0.0)));
		float3 bitangent = normalize(cross(tangent, view));
		float3 viewNormal = normalize(mul(float3x3(tangent, bitangent, view), normal));
		float2 sphereUv = viewNormal.xy * 0.5 + 0.5;
		//float2 sphereUv = capCoord * 0.5 + 0.5;
		[branch] if (_SphereMode == 1) { // Add
			float4 sphereAdd = _SphereAddTex.Sample(sampler_SphereAtlas, sphereUv);
			color += sphereAdd.rgb;
		} else if (_SphereMode == 2) { // Multiply
			float4 sphereMul = _SphereMulTex.Sample(sampler_SphereAtlas, sphereUv);
			color *= sphereMul.rgb;
		} else { // Multiple
			uint w, h;
			[branch] switch(_SphereNum) {
				case 2:  { w = 2; h = 1; } break;
				case 4:  { w = 2; h = 2; } break;
				case 8:  { w = 4; h = 2; } break;
				case 9:  { w = 3; h = 3; } break;
				case 16: { w = 4; h = 4; } break;
				case 18: { w = 6; h = 3; } break;
				case 25: { w = 5; h = 5; } break;
				default: { w = 1; h = 1; } break;
			}
			float2 dim = float2(w, h);
			float4 atlCol = sqrt(_SphereAtlas.Sample(sampler_SphereAtlas, uv));
			float2 sel = atlCol.rg;
			sel.g = 1 - sel.g;
			sel *= dim;
			sel = clamp(floor(sel), float2(0, 0), dim - 1) / dim;
			sphereUv /= float2(w, h);
			sphereUv += sel;
			float4 sphCol = _SphereMultiTex.Sample(sampler_SphereAtlas, sphereUv);
			float3 dbgCol = lerp(atlCol.rgb, float3(sel, 0), 0.75);
			color = lerp(lerp(color + sphCol.rgb, color * sphCol.rgb, atlCol.b), dbgCol, 0);
		}
	}
    return color;
}

float3 applyPano(float3 color, float3 view, float4 coord, float2 uv)
{
	[branch] if (_OverlayMode > 0) // has overlay
	{
		float4 col = float4(1,1,1,1);
		float2 transform = float2(_Time[1] * _PanoRotationSpeedX, _Time[1] * _PanoRotationSpeedY);
		[branch] if (_OverlayMode == 1) { // Panosphere (Rotation)
			float3 newview = RotatePointAroundOrigin(view, transform);
			col = texCUBE(_PanoSphereTex, newview);
		} else if   (_OverlayMode == 2) { // Panosphere (Screen)
			float4 newcoord = UNITY_PROJ_COORD(ComputeScreenPos(coord));
			col = tex2Dproj(_PanoFlatTex, newcoord);
		} else if   (_OverlayMode == 3) { // UV Scroll
			float2 newcoord = uv + transform / 2;
			col = tex2D(_PanoFlatTex, newcoord);
		}
		#if PANOOVERLAY
			float4 ocol = tex2D(_PanoOverlayTex, uv);
			#if PANOALPHA
				col.rgb = lerp(col.rgb, ocol.rgb, ocol.a);
			#else
				col.rgb += ocol.rgb;
			#endif
		#endif
		[branch] if (_OverlayBlendMode == 1) { // Add
			col.rgb += color;
		} else if   (_OverlayBlendMode == 2) { // Multiply
			col.rgb *= color;
		} else if   (_OverlayBlendMode == 3) { // Alphablend
			col.rgb = lerp(color, col.rgb, col.a);
		} else if   (_OverlayBlendMode == 4) { // Set Hue
			float3 hue1 = RGBtoHSV(col.rgb);
			float3 hue2 = RGBtoHSV(color);
			hue2.r = hue1.r;
			col.rgb = HSVtoRGB(hue2);
		}
		color = lerp(color, col, _PanoBlend);
	}
    return color;
}

float4 frag(VertexOutput i) : SV_Target
{
    // Variables
    float4 color = tex2D(_MainTex, i.uv);
    float4 _EmissionMap_var = tex2D(_EmissionMap, i.uv);
    float3 emissive = (_EmissionMap_var.rgb*_EmissionColor.rgb);
    float4 _ColorMask_var = tex2D(_ColorMask, i.uv);
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
		clip (color.a - _Cutoff);
    #endif
    #if defined(GAMMACORRECT)
		color.rgb *= lerp(1, color.rgb * (color.rgb * 0.305306011 + 0.682171111) + 0.012522878, _CorrectionLevel);
    #endif
    #if defined(HUESHIFTMODE)
		float3 colhsv = RGBtoHSV(_Color.rgb);
		float3 inphsv = RGBtoHSV(color.rgb);
		inphsv.x = colhsv.x;
		inphsv.y *= colhsv.y;
		inphsv.z *= colhsv.z;
		float4 shiftcolor = float4(HSVtoRGB(inphsv), color.a * _Color.a);
    #else
		float4 shiftcolor = color.rgba * _Color.rgba;
    #endif
    color = lerp(shiftcolor.rgba, color.rgba, _ColorMask_var.r);
	
	float4 uvShadow;
	uvShadow.xy = i.uv;
	[branch] switch(_ShadowUV) {
		case 0: { uvShadow.zw = i.uv;  } break;
		case 1: { uvShadow.zw = i.uv1; } break;
		case 2: { uvShadow.zw = i.uv2; } break;
		case 3: { uvShadow.zw = i.uv3; } break;
	}
	float2 uvSphere;
	[branch] switch(_SphereUV) {
		case 0: { uvSphere = i.uv;  } break;
		case 1: { uvSphere = i.uv1; } break;
		case 2: { uvSphere = i.uv2; } break;
		case 3: { uvSphere = i.uv3; } break;
	}
    
    // Lighting
    float attenuation = LIGHT_ATTENUATION(i);
    float _AmbientLight = 0.8;
    i.normalDir = normalize(i.normalDir);
    float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
    float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,i.uv));
    float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform));
    float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
    float3 directLighting = (saturate(i.direct + i.reflectionMap + i.amb.rgb) + i.amb.rgb) / 2;
    float4 bright = calcShadow(i.posWorld.xyz, normalDirection, attenuation, uvShadow, color.rgb);
    #if defined(ALLOWOVERBRIGHT)
		float3 lightColor = saturate(lerp(0.0, i.direct, _AmbientLight ) + i.amb.rgb + i.reflectionMap) * _Brightness;
    #else
		float3 lightColor = saturate(lerp(0.0, i.direct, _AmbientLight ) + i.amb.rgb + i.reflectionMap * ((i.lightModifier + 1) / 2)) * _Brightness;
    #endif
	#ifdef LIGHTMAP_ON
		lightColor += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1));
	#endif
    
    // Pulse
    #if defined(PULSE)
		float4 pulsemask = tex2D(_EmissionPulseMap, i.uv);
		emissive = lerp(emissive, _EmissionPulseColor.rgb*pulsemask.rgb, (sin(_Time[1] * _EmissionSpeed * _EmissionSpeed * _EmissionSpeed) + 1) / 2);
    #endif
    
    // Shaded Emission
    #if defined(SHADEEMISSION)
		[branch] if (_ShadowMode == 3 && _ShadowTextureMode == 0) {
			float4 emshade = calcShadow(i.posWorld.xyz, normalDirection, 1, uvShadow, emissive.rgb);
			emissive *= lerp(emshade.rgb, float3(1.0, 1.0, 1.0), emshade.a);
		} else {
			emissive *= calcShadow(i.posWorld.xyz, normalDirection, 1, uvShadow, emissive.rgb).rgb;
		}
		emissive = applySphere(emissive, viewDirection, normalDirection, uvSphere);
    #endif
    
    // Hidden Emission
    #if defined(SLEEPEMISSION)
		emissive *= smoothstep(0.7, 1.0, 1 - (i.amb.r * 0.3 + i.amb.g * 0.59 + i.amb.b * 0.11));
    #endif
    
    // Secondary Effects
    color.rgb = applyPano(color.rgb, viewDirection, i.pos, i.uv);
    
    // Primary effects
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    #if defined(RAINBOW)
		float4 maskcolor = tex2D(_RainbowMask, i.uv);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
		bright.rgb = hueShift(bright.rgb, maskcolor.rgb);
		emissive = hueShift(emissive, maskcolor.rgb);
    #endif

    // Outline
    color.rgb = artsyOutline(color.rgb, viewDirection, normalDirection);
    emissive = artsyOutline(emissive, viewDirection, normalDirection);
    
    // Sphere
	color.rgb = applySphere(color.rgb, viewDirection, normalDirection, uvSphere);
	
	float3 specular = calcSpecular(normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w)), viewDirection, normalDirection, bright.rgb * lightColor, i.uv, attenuation * bright.a) * tex2D(_OcclusionMap, i.uv).r;
    
    // Combining
    UNITY_APPLY_FOG(i.fogCoord, color);
	[branch] if (_ShadowMode == 3 && _ShadowTextureMode == 0) {
		return float4(lightColor, _AlphaOverride) * float4(lerp(bright.rgb, color.rgb, bright.a), color.a) + float4(emissive + specular, 0);
	} else {
		return float4(bright.rgb * lightColor, _AlphaOverride) * color + float4(emissive + specular, 0);
	}
}

float4 frag4(VertexOutput i) : COLOR
{
    // Variables
    float4 color = tex2D(_MainTex, i.uv);
    float4 _ColorMask_var = tex2D(_ColorMask, i.uv);
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
		clip (color.a - _Cutoff);
    #endif
    #if defined(GAMMACORRECT)
		color.rgb *= lerp(1, color.rgb * (color.rgb * 0.305306011 + 0.682171111) + 0.012522878, _CorrectionLevel);
    #endif
    #if defined(HUESHIFTMODE)
		float3 colhsv = RGBtoHSV(_Color.rgb);
		float3 inphsv = RGBtoHSV(color.rgb);
		inphsv.x = colhsv.x;
		inphsv.y *= colhsv.y;
		inphsv.z *= colhsv.z;
		float4 shiftcolor = float4(HSVtoRGB(inphsv), color.a * _Color.a);
    #else
		float4 shiftcolor = color.rgba * _Color.rgba;
    #endif
    color = lerp(shiftcolor.rgba, color.rgba, _ColorMask_var.r);
	
	float4 uvShadow;
	uvShadow.xy = i.uv;
	[branch] switch(_ShadowUV) {
		case 0: { uvShadow.zw = i.uv;  } break;
		case 1: { uvShadow.zw = i.uv1; } break;
		case 2: { uvShadow.zw = i.uv2; } break;
		case 3: { uvShadow.zw = i.uv3; } break;
	}
	float2 uvSphere;
	[branch] switch(_SphereUV) {
		case 0: { uvSphere = i.uv;  } break;
		case 1: { uvSphere = i.uv1; } break;
		case 2: { uvSphere = i.uv2; } break;
		case 3: { uvSphere = i.uv3; } break;
	}
    
    // Lighting
    float attenuation = LIGHT_ATTENUATION(i);
    //#if defined (POINT) || defined (SPOT)
    //attenuation = tex2D(_LightTexture0, dot(i._LightCoord,i._LightCoord).rr).UNITY_ATTEN_CHANNEL;
    //#if defined(IS_OPAQUE) && !DISABLE_SHADOW && !NO_SHADOW
    //attenuation *= SHADOW_ATTENUATION(i) * _shadowcast_intensity + (1 - _shadowcast_intensity);
    //#endif
    //#endif
    i.normalDir = normalize(i.normalDir);
    float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
    float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,i.uv));
    float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform));
    float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
    float4 bright = calcShadow(i.posWorld.xyz, normalDirection, 1, uvShadow, color.rgb);
    bright.rgb *= attenuation * tex2D(_OcclusionMap, i.uv).r;
    //#if defined(IS_OPAQUE) && !DISABLE_SHADOW && !NO_SHADOW
    //bright *= attenuation * _shadowcast_intensity + (1 - _shadowcast_intensity);
    //#elif defined (POINT) || defined (SPOT)
    //bright *= tex2D(_LightTexture0, dot(i._LightCoord,i._LightCoord).rr).UNITY_ATTEN_CHANNEL;
    //bright = 1;
    //#endif
    #if defined(ALLOWOVERBRIGHT)
		float3 lightColor = saturate(i.amb.rgb) * _Brightness;
    #else
		float3 lightColor = saturate(i.amb.rgb * i.lightModifier * saturate(i.lightModifier) * 0.5) * _Brightness;
    #endif
    
    color.rgb = applyPano(color.rgb, viewDirection, i.pos, i.uv);
    
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    #if defined(RAINBOW)
		float4 maskcolor = tex2D(_RainbowMask, i.uv);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
		bright.rgb = hueShift(bright.rgb, maskcolor.rgb);
    #endif

    // Outline
    color.rgb = artsyOutline(color.rgb, viewDirection, normalDirection);
    
	// Sphere
    color.rgb = applySphere(color.rgb, viewDirection, normalDirection, uvSphere);
	
	float3 specular = calcSpecular(normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w)), viewDirection, normalDirection, bright.rgb * lightColor, i.uv, attenuation * bright.a) * tex2D(_OcclusionMap, i.uv).r;
    
    // Combining
    UNITY_APPLY_FOG(i.fogCoord, color);
	[branch] if (_ShadowMode == 3 && _ShadowTextureMode == 0) {
		return float4(lightColor, _AlphaOverride) * float4(lerp(bright.rgb, color.rgb, bright.a), color.a) + float4(specular, 0);
	} else {
		return float4(bright.rgb * lightColor, _AlphaOverride) * color + float4(specular, 0);
	}
}

float4 frag3(VertexOutput i) : COLOR
{
    // Variables
    float4 color = tex2D(_MainTex, i.uv);
    float4 _ColorMask_var = tex2D(_ColorMask, i.uv);
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
		clip (color.a - _Cutoff);
    #endif
    #if defined(GAMMACORRECT)
		color.rgb *= lerp(1, color.rgb * (color.rgb * 0.305306011 + 0.682171111) + 0.012522878, _CorrectionLevel);
    #endif
    #if defined(HUESHIFTMODE)
		float3 colhsv = RGBtoHSV(_Color.rgb);
		float3 inphsv = RGBtoHSV(color.rgb);
		inphsv.x = colhsv.x;
		inphsv.y *= colhsv.y;
		inphsv.z *= colhsv.z;
		float4 shiftcolor = float4(HSVtoRGB(inphsv), color.a * _Color.a);
    #else
		float4 shiftcolor = color.rgba * _Color.rgba;
    #endif
    color = lerp(shiftcolor.rgba, color.rgba, _ColorMask_var.r);
    
    // Lighting
    float _AmbientLight = 0.8;
    #if defined(ALLOWOVERBRIGHT)
		float3 lightColor = saturate(lerp(0.0, i.direct, _AmbientLight ) + i.amb.rgb + i.reflectionMap) * _Brightness;
    #else
		float3 lightColor = saturate((lerp(0.0, i.direct, _AmbientLight ) + i.amb.rgb + i.reflectionMap) * ((i.lightModifier + 1) / 2)) * _Brightness;
    #endif
	#ifdef LIGHTMAP_ON
		lightColor += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1));
	#endif
    
    // Primary Effects
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    #if defined(RAINBOW)
		float4 maskcolor = tex2D(_RainbowMask, i.uv);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
    #endif
    
    // Secondary Effects

    // Outline
    #if TINTED_OUTLINE
		color.rgb *= _outline_color.rgb;
    #elif COLORED_OUTLINE
		color.rgb = float3((_outline_color.rgb * _outline_color.a) + (color.rgb * (1 - _outline_color.a)));
    #endif
    // Outline Effects
    
    // Combining
    UNITY_APPLY_FOG(i.fogCoord, color);
    return float4(lightColor, _AlphaOverride) * color * LIGHT_ATTENUATION(i);
    //return float4(_LightColor0.rgb, _AlphaOverride) * color;
}

float4 frag5(VertexOutput i) : COLOR
{
    // Variables
    float4 color = tex2D(_MainTex, i.uv);
    float4 _ColorMask_var = tex2D(_ColorMask, i.uv);
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
		clip (color.a - _Cutoff);
    #endif
    #if defined(GAMMACORRECT)
		color.rgb *= lerp(1, color.rgb * (color.rgb * 0.305306011 + 0.682171111) + 0.012522878, _CorrectionLevel);
    #endif
    #if defined(HUESHIFTMODE)
		float3 colhsv = RGBtoHSV(_Color.rgb);
		float3 inphsv = RGBtoHSV(color.rgb);
		inphsv.x = colhsv.x;
		inphsv.y *= colhsv.y;
		inphsv.z *= colhsv.z;
		float4 shiftcolor = float4(HSVtoRGB(inphsv), color.a * _Color.a);
    #else
		float4 shiftcolor = color.rgba * _Color.rgba;
    #endif
    color = lerp(shiftcolor.rgba, color.rgba, _ColorMask_var.r);
    
    // Lighting
    #if defined(ALLOWOVERBRIGHT)
		float3 lightColor = saturate(i.amb.rgb) * _Brightness;
    #else
		float3 lightColor = saturate(i.amb.rgb * i.lightModifier * saturate(i.lightModifier) * 0.5) * _Brightness;
    #endif
    
    // Primary Effects
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    #if defined(RAINBOW)
		float4 maskcolor = tex2D(_RainbowMask, i.uv);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
    #endif
    
    // Secondary Effects

    // Outline
    #if TINTED_OUTLINE
		color.rgb *= _outline_color.rgb;
    #elif COLORED_OUTLINE
		color.rgb = float3((_outline_color.rgb * _outline_color.a) + (color.rgb * (1 - _outline_color.a)));
    #endif
    // Outline Effects
    
    //#ifdef POINT
		//lightColor *= tex2D(_LightTexture0, dot(i._LightCoord,i._LightCoord).rr).UNITY_ATTEN_CHANNEL;
    //#endif
    
    // Combining
    UNITY_APPLY_FOG(i.fogCoord, color);
    return float4(lightColor, _AlphaOverride) * color * LIGHT_ATTENUATION(i);
    //return float4(_LightColor0.rgb, _AlphaOverride) * color;
}

[maxvertexcount(6)]
void geom(triangle v2g IN[3], inout TriangleStream<VertexOutput> tristream)
{
	VertexOutput o;
	for (int ii = 0; ii < 3; ii++)
	{
		o.pos = UnityObjectToClipPos(IN[ii].vertex);
		o.uv = IN[ii].uv;
		o.uv1 = IN[ii].uv1;
		o.uv2 = IN[ii].uv2;
		o.uv3 = IN[ii].uv3;
		o.col = fixed4(1., 1., 1., 0.);
		o.posWorld = mul(unity_ObjectToWorld, IN[ii].vertex);
		o.normalDir = UnityObjectToWorldNormal(IN[ii].normal);
		o.tangentDir = IN[ii].tangentDir;
		o.bitangentDir = IN[ii].bitangentDir;
		o.is_outline = false;
        o.normal = IN[ii].normal;
        
        o.amb = IN[ii].amb;
        o.direct = IN[ii].direct;
        o.indirect = IN[ii].indirect;
        o.lightData = IN[ii].lightData;
        o.reflectionMap = IN[ii].reflectionMap;
        o.lightModifier = IN[ii].lightModifier;

		// Pass-through the shadow coordinates if this pass has shadows.
		#if defined (SHADOWS_SCREEN) || ( defined (SHADOWS_DEPTH) && defined (SPOT) ) || defined (SHADOWS_CUBE)
			o._ShadowCoord = IN[ii]._ShadowCoord;
		#endif

		// Pass-through the light coordinates if this pass has shadows.
		#if defined (POINT) || defined (SPOT) || defined (POINT_COOKIE) || defined (DIRECTIONAL_COOKIE)
			o._LightCoord = IN[ii]._LightCoord;
		#endif

		// Pass-through the fog coordinates if this pass has shadows.
		#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
			o.fogCoord = IN[ii].fogCoord;
		#endif

		tristream.Append(o);
	}

	tristream.RestartStrip();
}

[maxvertexcount(6)]
void geom2(triangle v2g IN[3], inout TriangleStream<VertexOutput> tristream)
{
	VertexOutput o;
	for (int ii = 0; ii < 3; ii++)
	{
		#if OUTSIDE_OUTLINE
			o.pos = UnityObjectToClipPos(IN[ii].vertex + normalize(IN[ii].normal) * (_outline_width * .01));
        #elif SCREENSPACE_OUTLINE
			o.pos = UnityObjectToClipPos(IN[ii].vertex + normalize(IN[ii].normal) * (_outline_width * .05) * distance(_WorldSpaceCameraPos,mul(unity_ObjectToWorld, IN[ii].vertex).rgb));
        #else
			o.pos = UnityObjectToClipPos(IN[ii].vertex);
        #endif
		o.uv = IN[ii].uv;
		o.uv1 = IN[ii].uv1;
		o.uv2 = IN[ii].uv2;
		o.uv3 = IN[ii].uv3;
		o.col = fixed4( _outline_color.r, _outline_color.g, _outline_color.b, 1);
		o.posWorld = mul(unity_ObjectToWorld, IN[ii].vertex);
		o.normalDir = UnityObjectToWorldNormal(IN[ii].normal);
		o.tangentDir = IN[ii].tangentDir;
		o.bitangentDir = IN[ii].bitangentDir;
		o.is_outline = false;
        o.normal = IN[ii].normal;
        
        o.amb = IN[ii].amb;
        o.direct = IN[ii].direct;
        o.indirect = IN[ii].indirect;
        o.lightData = IN[ii].lightData;
        o.reflectionMap = IN[ii].reflectionMap;
        o.lightModifier = IN[ii].lightModifier;

		// Pass-through the shadow coordinates if this pass has shadows.
		#if defined (SHADOWS_SCREEN) || ( defined (SHADOWS_DEPTH) && defined (SPOT) ) || defined (SHADOWS_CUBE)
			o._ShadowCoord = IN[ii]._ShadowCoord;
		#endif

		// Pass-through the light coordinates if this pass has shadows.
		#if defined (POINT) || defined (SPOT) || defined (POINT_COOKIE) || defined (DIRECTIONAL_COOKIE)
			o._LightCoord = IN[ii]._LightCoord;
		#endif

		// Pass-through the fog coordinates if this pass has shadows.
		#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
			o.fogCoord = IN[ii].fogCoord;
		#endif

		tristream.Append(o);
	}

	tristream.RestartStrip();
}

#endif