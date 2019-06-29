// SynToon by Synergiance
// v0.4.5.4

#ifndef ALPHA_RAINBOW_CORE_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "HSB.cginc"
#include "Rotate.cginc"

SamplerState sampler_MainTex;
Texture2D _MainTex;
Texture2D _BumpMap;
Texture2D _ColorMask;
Texture2D _EmissionMap;
float4 _MainTex_ST;
sampler2D _OcclusionMap;
float4 _EmissionColor;
float _EmissionSpeed;
Texture2D _EmissionPulseMap;
float4 _EmissionPulseColor;
float _Brightness;
float _CorrectionLevel;
float4 _Color;
float4 _LightColor;
float _LightOverride;
float _Cutoff;
float _AlphaOverride;
float _SaturationBoost;
Texture2D _RainbowMask;
float _Speed;
uniform float _outline_width;
uniform float _outline_feather;
uniform float4 _outline_color;
sampler2D _outline_tex;
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
float _ProbeStrength;
float _ProbeClarity;
float3 _BackFaceTint;
float _BackFaceShadowed;

float _OutlineMode;
float _OutlineColorMode;

float _Unlit;
float _Rainbowing;
float _OverbrightProtection;
float _PulseEmission;
float _ShadeEmission;
float _SleepEmission;
float _FlipBackfaceNorms;
float _CullMode;
float _HueShiftMode;
float _PanoUseOverlay;
float _PanoUseAlpha;
float _PanoEmission;
float _Dither;

sampler3D _DitherMaskLOD;

#include "SynToonLighting.cginc"
#if defined(REFRACTION)
#include "Refraction.cginc"
#endif

static const float3 grayscale_vector = float3(0, 0.3823529, 0.01845836);

struct v2g
{
    float4 vertex : POSITION;
    float4 uv : TEXCOORD0;
    float4 uv1 : TEXCOORD1;
    float3 normal : NORMAL;
    fixed4 amb : COLOR0;
    fixed3 direct : COLOR1;
    fixed3 indirect : COLOR2;
    float4 posWorld : TEXCOORD2;
    float3 normalDir : TEXCOORD3;
    float3 tangentDir : TEXCOORD4;
    float3 bitangentDir : TEXCOORD5;
    float3 reflectionMap : TEXCOORD9;
    float lightModifier : TEXCOORD10;
	float4 pos : CLIP_POS;
	UNITY_SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)
	#if defined(VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD8;
	#endif
};

struct VertexOutput
{
	float4 pos : SV_POSITION;
	float4 uv : TEXCOORD0;
	float4 uv1 : TEXCOORD1;
    float3 normal : NORMAL;
    fixed4 amb : COLOR0; //
    fixed3 direct : COLOR1; //
    fixed3 indirect : COLOR2; //
	float4 posWorld : TEXCOORD2;
	float3 normalDir : TEXCOORD3;
	float3 tangentDir : TEXCOORD4;
	float3 bitangentDir : TEXCOORD5;
    float3 reflectionMap : TEXCOORD9; //
    float lightModifier : TEXCOORD10; //
	float4 col : COLOR3;
	bool is_outline : IS_OUTLINE;
	UNITY_SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)
	#if defined(VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD8;
	#endif
};

struct FragmentOutput {
	#if defined(DEFERRED_PASS)
		float4 gBuffer0 : SV_Target0;
		float4 gBuffer1 : SV_Target1;
		float4 gBuffer2 : SV_Target2;
		float4 gBuffer3 : SV_Target3;
	#else
		float4 color : SV_Target;
	#endif
};

float grayscaleSH9(float3 normalDirection)
{
    return dot(ShadeSH9(half4(normalDirection, 1.0)), grayscale_vector);
}

// Rainbowing Effect
float3 hueShift(float3 col, float3 mask)
{
    float3 newc = col;
    newc = float3(applyHue(newc, _Time[1] * _Speed * _Speed * _Speed));
    newc = float3((newc * mask) + (col * (1 - mask)));
    return newc;
}

float4 selectUVs(float4 uvs1, float4 uvs2) {
	float4 uvs = float4(0, 0, 0, 0);
	[branch] switch(_ShadowUV) {
		case 0: { uvs.xy = uvs1.xy; } break;
		case 1: { uvs.xy = uvs2.xy; } break;
		case 2: { uvs.xy = uvs1.zw; } break;
		case 3: { uvs.xy = uvs2.zw; } break;
	}
	[branch] switch(_SphereUV) {
		case 0: { uvs.zw = uvs1.xy; } break;
		case 1: { uvs.zw = uvs2.xy; } break;
		case 2: { uvs.zw = uvs1.zw; } break;
		case 3: { uvs.zw = uvs2.zw; } break;
	}
	return uvs;
}

v2g vert(appdata_full v)
{
    v2g o;
	UNITY_INITIALIZE_OUTPUT(v2g, o);
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
    o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	#ifdef LIGHTMAP_ON
		o.uv1.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	#else
		o.uv1.xy = v.texcoord1.xy;
	#endif
	UNITY_TRANSFER_SHADOW(o, 1);
	UNITY_TRANSFER_FOG(o, o.pos);
	o.uv.zw = v.texcoord2.xy;
	o.uv1.zw = v.texcoord3.xy;
    
    float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
    o.reflectionMap = DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, normalize((_WorldSpaceCameraPos - objPos.rgb)), 7), unity_SpecCube0_HDR)* 0.02;
    [branch] if (_OverbrightProtection > 0) {
		float3 lightColor = o.direct + o.amb.rgb * 2 + o.reflectionMap;
		float brightness = lightColor.r * 0.3 + lightColor.g * 0.59 + lightColor.b * 0.11;
		float correctedBrightness = -1 / (brightness * 2 + 1) + 1 + brightness * 0.1;
		o.lightModifier = correctedBrightness / brightness;
	} else {
		o.lightModifier = 1;
	}
	
	float4 uvShadow = float4(o.uv.xy, selectUVs(o.uv, o.uv1).xy);
	#if defined(VERTEXLIGHT_ON)
		o.vertexLightColor = Shade4PointLightsStyled(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, o.posWorld, o.normalDir,
			uvShadow, float3(0, 0, 0)
		);
	#endif
    
    return o;
}

float dither(float alpha, float4 clipPos) {
	float clipVal = 1;
	[branch] if (_Dither) {
		float4 screenPos = UNITY_PROJ_COORD(ComputeScreenPos(clipPos));
		clipVal = tex3D(_DitherMaskLOD, float3((screenPos.xy + 1) * 0.25, alpha * 0.9375)).a - 0.01;
	}
	return clipVal;
}

float getAttenuation(VertexOutput i) {
	SYN_LIGHT_ATTENUATION(attenuation, i.posWorld.xyz);
	return attenuation;
}

fixed getShadowAttenuation(VertexOutput i) {
	fixed attenuation = 1.0;
	#if defined(IS_OPAQUE)
		[branch] if (_shadowcast_intensity > 0) {
			attenuation = lerp(1, UNITY_SHADOW_ATTENUATION(i, i.posWorld.xyz), _shadowcast_intensity);
		}
	#endif
	return attenuation;
}

bool calcBackFace(inout VertexOutput i, float3 viewDirection) {
	bool backFace = false;
	[branch] switch (_CullMode) {
		case 0:
			backFace = dot(viewDirection, i.normalDir) < 0;
			break;
		case 1:
			backFace = true;
			break;
		case 2:
			backFace = false;
			break;
	}
	return backFace;
}

float3 calcNormal(inout VertexOutput i, float3 viewDirection) {
    i.normalDir = normalize(i.normalDir);
    float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
    float3 _BumpMap_var = UnpackNormal(_BumpMap.Sample(sampler_MainTex, i.uv.xy));
    float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform));
	[branch] if (_FlipBackfaceNorms && _CullMode == 0) {
		[flatten] if (dot(viewDirection, i.normalDir) < 0) {
			normalDirection *= -1;
		}
	}
	[branch] if (_CullMode == 1) {
		normalDirection *= -1;
	}
	return normalDirection;
}

float3 calcOutline(float3 color, float2 uv)
{// Computes the color of an outline
	float4 outline = _outline_color * tex2D(_outline_tex, uv);
	[branch] if (_OutlineColorMode == 0) {
		color *= outline.rgb;
	} else if (_OutlineColorMode == 1) {
		color = float3((outline.rgb * outline.a) + (color * (1 - outline.a)));
	}
	// Outline Effects
	
	return color;
}

float3 artsyOutline(float3 color, float3 view, float3 normal, float2 uv, inout float lightingVal)
{// Outline
    [branch] if (_OutlineMode == 1) {
		lightingVal = (lightingVal == -1) ? smoothstep(_outline_width - _outline_feather / 10, _outline_width, dot(view, normal)) : lightingVal;
		color = lerp(calcOutline(color, uv), color.rgb, lightingVal);
    }
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
			[flatten] switch(_SphereNum) {
				case 2:  { w = 2; h = 1; } break;
				case 4:  { w = 2; h = 2; } break;
				case 6:  { w = 3; h = 2; } break;
				case 8:  { w = 4; h = 2; } break;
				case 9:  { w = 3; h = 3; } break;
				case 12: { w = 4; h = 3; } break;
				case 15: { w = 5; h = 3; } break;
				case 16: { w = 4; h = 4; } break;
				case 18: { w = 6; h = 3; } break;
				case 20: { w = 5; h = 4; } break;
				case 24: { w = 6; h = 4; } break;
				case 25: { w = 5; h = 5; } break;
				case 30: { w = 6; h = 5; } break;
				case 32: { w = 8; h = 4; } break;
				case 36: { w = 6; h = 6; } break;
				case 40: { w = 8; h = 5; } break;
				case 48: { w = 8; h = 6; } break;
				case 64: { w = 8; h = 8; } break;
				default: { w = 1; h = 1; } break;
			}
			float2 dim = float2(w, h);
			float3 atlCol = LinearToGammaSpace(_SphereAtlas.Sample(sampler_SphereAtlas, uv));
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
			col = tex2D(_PanoFlatTex, float2(2, -2) * newcoord.xy / _ScreenParams.xy);
		} else if   (_OverlayMode == 3) { // UV Scroll
			float2 newcoord = uv + transform / 2;
			col = tex2D(_PanoFlatTex, newcoord);
		}
		[branch] if (_PanoUseOverlay) {
			float4 ocol = tex2D(_PanoOverlayTex, uv);
			if (_PanoUseAlpha) {
				col.rgb = lerp(col.rgb, ocol.rgb, ocol.a);
			} else {
				col.rgb += ocol.rgb;
			}
		}
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

float3 gammaCorrect(float3 color) {
    [branch] if (_CorrectionLevel > 0) {
		color *= lerp(1, color * (color * 0.305306011 + 0.682171111) + 0.012522878, _CorrectionLevel);
    }
	return color;
}

float4 blendColor(float4 color, float mask) {
    float4 shiftcolor;
	[branch] if (_HueShiftMode) {
		float3 colhsv = RGBtoHSV(_Color.rgb);
		float3 inphsv = RGBtoHSV(color.rgb);
		inphsv.x = colhsv.x;
		inphsv.y *= colhsv.y;
		inphsv.z *= colhsv.z;
		shiftcolor = float4(HSVtoRGB(inphsv), color.a * _Color.a);
    } else {
		shiftcolor = color.rgba * _Color.rgba;
    }
    return lerp(shiftcolor.rgba, color.rgba, mask);
}

FragmentOutput frag(VertexOutput i)
{
    // Variables
    float4 color = _MainTex.Sample(sampler_MainTex, i.uv.xy);
    float4 _EmissionMap_var = _EmissionMap.Sample(sampler_MainTex, i.uv.xy);
    float3 emissive = (_EmissionMap_var.rgb*_EmissionColor.rgb);
    float4 _ColorMask_var = _ColorMask.Sample(sampler_MainTex, i.uv.xy);
	float2 occlusionM = tex2D(_OcclusionMap, i.uv.xy).rg;
	//#if defined(DEFERRED_PASS) && !defined(IS_OPAQUE)
	//	clip (color.a - 0.8);
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
		clip (color.a - _Cutoff);
    #endif
	color.rgb = gammaCorrect(color.rgb);
	color = blendColor(color, _ColorMask_var.b);
	
	#if defined(_ALPHATEST_ON) && !defined(_ALPHABLEND_ON)
		clip (dither(color.a, i.pos));
	#endif
	
	float4 uvs = selectUVs(i.uv, i.uv1);
	float4 uvShadow = float4(i.uv.xy, uvs.xy);
	float2 uvSphere = float2(uvs.zw);
    
    // Lighting
    float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
    float3 normalDirection = calcNormal(i, viewDirection);
	int isBackFace = calcBackFace(i, viewDirection) ? 1 : 0;
	//fixed shadowAtten = lerp(getShadowAttenuation(i), 1.0 - _BackFaceShadowed, isBackFace);
	float occlusion = (isBackFace) ? occlusionM.g : occlusionM.r;
	fixed shadowAtten = getShadowAttenuation(i) * occlusion;
    float _AmbientLight = 0.8;
    //float3 directLighting = (saturate(i.direct + i.reflectionMap + i.amb.rgb) + i.amb.rgb) / 2;
    float4 bright = calcShadow(i.posWorld.xyz, normalDirection, shadowAtten, uvShadow, color.rgb);
	float lightModifier = 1;
	[branch] if (_OverbrightProtection > 0) {
		lightModifier = lerp(1, (i.lightModifier + 1) * 0.5, _OverbrightProtection);
	}
	float3 lightColor = saturate((lerp(0.0, i.direct, _AmbientLight ) + i.amb.rgb + i.reflectionMap) * lightModifier) * _Brightness;
	float3 ambient = float3(0, 0, 0);
	#ifdef LIGHTMAP_ON
		ambient += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1.xy));
	#endif
	#if defined(VERTEXLIGHT_ON)
		ambient += i.vertexLightColor;
	#endif
	//ambient += max(0, ShadeSH9(float4(normalDirection, 1)));
	[branch] if (_Unlit == 1) {
		lightColor = float3(1, 1, 1);
		ambient = float3(0, 0, 0);
	}
	[flatten] if (isBackFace == 1/* && _BackFaceShadowed == 0*/) {
		color.rgb *= _BackFaceTint;
	}
    
    // Pulse
    [branch] if (_PulseEmission == 1) {
		float4 pulsemask = _EmissionPulseMap.Sample(sampler_MainTex, i.uv.xy);
		emissive = lerp(emissive, _EmissionPulseColor.rgb*pulsemask.rgb, (sin(_Time[1] * _EmissionSpeed * _EmissionSpeed * _EmissionSpeed) + 1) / 2);
    }
    
    // Shaded Emission
    [branch] if (_ShadeEmission == 1) {
		[branch] if (_ShadowMode == 3 && _ShadowTextureMode == 0) {
			float4 emshade = calcShadow(i.posWorld.xyz, normalDirection, 1, uvShadow, emissive.rgb);
			emissive *= lerp(emshade.rgb, float3(1.0, 1.0, 1.0), emshade.a);
		} else {
			emissive *= calcShadow(i.posWorld.xyz, normalDirection, 1, uvShadow, emissive.rgb).rgb;
		}
		emissive = applySphere(emissive, viewDirection, normalDirection, uvSphere);
    }
    
    // Hidden Emission
    [branch] if (_SleepEmission == 1) {
		emissive *= smoothstep(0.7, 1.0, 1 - (i.amb.r * 0.3 + i.amb.g * 0.59 + i.amb.b * 0.11));
    }
    
    // Secondary Effects
    color.rgb = applyPano(color.rgb, viewDirection, i.pos, i.uv.xy);
	[branch] if (_PanoEmission == 1) {
		emissive = applyPano(emissive, viewDirection, i.pos, i.uv.xy);
	}
    
    // Primary effects
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    [branch] if (_Rainbowing == 1) {
		float4 maskcolor = _RainbowMask.Sample(sampler_MainTex, i.uv.xy);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
		bright.rgb = hueShift(bright.rgb, maskcolor.rgb);
		emissive = hueShift(emissive, maskcolor.rgb);
    }

    // Outline
	float lightingVal = -1;
    color.rgb = artsyOutline(color.rgb, viewDirection, normalDirection, i.uv.xy, lightingVal);
    emissive = artsyOutline(emissive, viewDirection, normalDirection, i.uv.xy, lightingVal);
	[branch] if (_Unlit == 2) {
		lightColor = lerp(float3(1, 1, 1), lightColor, lightingVal);
	}
    
    // Sphere
	color.rgb = applySphere(color.rgb, viewDirection, normalDirection, uvSphere);
	
	float3 specular = calcSpecular(normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w)), viewDirection, normalDirection, bright.rgb * lightColor, i.uv, shadowAtten * bright.a, _ProbeStrength, i.posWorld) * tex2D(_OcclusionMap, i.uv).r;
    
    // Combining
	UNITY_APPLY_FOG(i.fogCoord, color);
	bright.rgb = max(bright.rgb, 0);
	FragmentOutput output;
	#if defined(DEFERRED_PASS)
		output.gBuffer0.rgb = color.rgb;
		output.gBuffer0.a = tex2D(_OcclusionMap, i.uv.xy).r;
		output.gBuffer1.rgb = _SpecularColor.rgb;
		output.gBuffer1.a = _SpecularPower * 0.01;
		output.gBuffer2 = float4(normalDirection.xyz * 0.5 + 0.5, 1);
		output.gBuffer3 = float4(emissive, 1);
	#else
		[branch] if (_ShadowMode == 3 && _ShadowTextureMode == 0) {
			output.color = float4(lightColor + ambient, _AlphaOverride) * float4(lerp(bright.rgb, color.rgb, bright.a), color.a) + float4(emissive + specular, 0);
		} else {
			output.color = float4(bright.rgb * lightColor + ambient, _AlphaOverride) * color + float4(emissive + specular, 0);
		}
		#if defined(REFRACTION)
			output.color = float4(lerp(refractGrab(normalDirection, i.pos, viewDirection) + specular + emissive, output.color.rgb, output.color.a), 1);
		#endif
		output.color.a = clamp(output.color.a, 0, 1);
	#endif
	return output;
}

float4 frag4(VertexOutput i) : COLOR
{
    // Variables
    float4 color = _MainTex.Sample(sampler_MainTex, i.uv.xy);
    float4 _ColorMask_var = _ColorMask.Sample(sampler_MainTex, i.uv.xy);
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
		clip (color.a - _Cutoff);
    #endif
	color.rgb = gammaCorrect(color.rgb);
	color = blendColor(color, _ColorMask_var.b);
	
	#if defined(_ALPHATEST_ON) && !defined(_ALPHABLEND_ON)
		clip (dither(color.a, i.pos));
	#endif
	
	float4 uvs = selectUVs(i.uv, i.uv1);
	float4 uvShadow = float4(i.uv.xy, uvs.xy);
	float2 uvSphere = float2(uvs.zw);
    
    // Lighting
    float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
    float3 normalDirection = calcNormal(i, viewDirection);
	int isBackFace = calcBackFace(i, viewDirection) ? 1 : 0;
	
	fixed attenuation = getAttenuation(i);
	//fixed shadowAtten = lerp(getShadowAttenuation(i), 1.0 - _BackFaceShadowed, isBackFace);
	fixed shadowAtten = getShadowAttenuation(i);
    float4 bright = calcShadow(i.posWorld.xyz, normalDirection, shadowAtten, uvShadow, color.rgb);
    bright.rgb *= tex2D(_OcclusionMap, i.uv.xy).r;
	float lightModifier = 1;
	[branch] if (_OverbrightProtection > 0) {
		lightModifier = lerp(1, i.lightModifier * saturate(i.lightModifier) * 0.5, _OverbrightProtection);
	}
	float3 lightColor = saturate(i.amb.rgb * lightModifier) * _Brightness * attenuation;
	[branch] if (_Unlit == 1) {
		lightColor = float3(0, 0, 0);
	}
	[flatten] if (isBackFace == 1/* && _BackFaceShadowed == 0*/) {
		color.rgb *= _BackFaceTint;
	}
    
    color.rgb = applyPano(color.rgb, viewDirection, i.pos, i.uv.xy);
    
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    [branch] if (_Rainbowing == 1) {
		float4 maskcolor = _RainbowMask.Sample(sampler_MainTex, i.uv.xy);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
		bright.rgb = hueShift(bright.rgb, maskcolor.rgb);
    }

    // Outline
	float lightingVal = -1;
    color.rgb = artsyOutline(color.rgb, viewDirection, normalDirection, i.uv.xy, lightingVal);
	[branch] if (_Unlit == 2) {
		lightColor = lerp(float3(0, 0, 0), lightColor, lightingVal);
	}
    
	// Sphere
    color.rgb = applySphere(color.rgb, viewDirection, normalDirection, uvSphere);
	
	float3 specular = calcSpecular(normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w)), viewDirection, normalDirection, bright.rgb * lightColor, i.uv, attenuation * bright.a, 0, float3(0, 0, 0)) * tex2D(_OcclusionMap, i.uv).r;
    
    // Combining
    UNITY_APPLY_FOG(i.fogCoord, color);
	bright.rgb = max(bright.rgb, 0);
	float4 retCol = 0;
	[branch] if (_ShadowMode == 3 && _ShadowTextureMode == 0) {
		retCol = float4(lightColor, _AlphaOverride) * float4(lerp(bright.rgb, color.rgb, bright.a), color.a) + float4(specular, 0);
	} else {
		retCol = float4(bright.rgb * lightColor, _AlphaOverride) * color + float4(specular, 0);
	}
	retCol.a = clamp(retCol.a, 0, 1);
	return retCol;
}

float4 frag3(VertexOutput i) : COLOR
{
    // Variables
    float4 color = _MainTex.Sample(sampler_MainTex, i.uv.xy);
    float4 _ColorMask_var = _ColorMask.Sample(sampler_MainTex, i.uv.xy);
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
		clip (color.a - _Cutoff);
    #endif
	color.rgb = gammaCorrect(color.rgb);
	color = blendColor(color, _ColorMask_var.b);
	
	#if defined(_ALPHATEST_ON) && !defined(_ALPHABLEND_ON)
		clip (dither(color.a, i.pos));
	#endif
    
    // Lighting
    float _AmbientLight = 0.8;
	float lightModifier = 1;
	[branch] if (_OverbrightProtection > 0) {
		lightModifier = lerp(1, (i.lightModifier + 1) * 0.5, _OverbrightProtection);
	}
	float3 lightColor = saturate((lerp(0.0, i.direct, _AmbientLight ) + i.amb.rgb + i.reflectionMap) * lightModifier) * _Brightness;
	#ifdef LIGHTMAP_ON
		lightColor += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1.xy));
	#endif
	[branch] if ((_Unlit == 1) || (_Unlit == 2)) {
		lightColor = float3(1, 1, 1);
	}
    
    // Primary Effects
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    [branch] if (_Rainbowing == 1) {
		float4 maskcolor = _RainbowMask.Sample(sampler_MainTex, i.uv.xy);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
    }
    
    // Secondary Effects

    // Outline
    color.rgb = calcOutline(color.rgb, i.uv.xy);
    
    // Combining
    UNITY_APPLY_FOG(i.fogCoord, color);
    return float4(lightColor, _AlphaOverride) * color * getAttenuation(i) * getShadowAttenuation(i);
    //return float4(_LightColor0.rgb, _AlphaOverride) * color;
}

float4 frag5(VertexOutput i) : COLOR
{
    // Variables
    float4 color = _MainTex.Sample(sampler_MainTex, i.uv.xy);
    float4 _ColorMask_var = _ColorMask.Sample(sampler_MainTex, i.uv.xy);
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
		clip (color.a - _Cutoff);
    #endif
	color.rgb = gammaCorrect(color.rgb);
	color = blendColor(color, _ColorMask_var.b);
	
	#if defined(_ALPHATEST_ON) && !defined(_ALPHABLEND_ON)
		clip (dither(color.a, i.pos));
	#endif
    
    // Lighting
	float lightModifier = 1;
	[branch] if (_OverbrightProtection > 0) {
		lightModifier = lerp(1, i.lightModifier * saturate(i.lightModifier) * 0.5, _OverbrightProtection);
	}
	float3 lightColor = saturate(i.amb.rgb * lightModifier) * _Brightness;
	[branch] if ((_Unlit == 1) || (_Unlit == 2)) {
		lightColor = float3(0, 0, 0);
	}
    
    // Primary Effects
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    [branch] if (_Rainbowing == 1) {
		float4 maskcolor = _RainbowMask.Sample(sampler_MainTex, i.uv.xy);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
    }
    
    // Secondary Effects

    // Outline
    color.rgb = calcOutline(color.rgb, i.uv.xy);
    
    //#ifdef POINT
		//lightColor *= tex2D(_LightTexture0, dot(i._LightCoord,i._LightCoord).rr).UNITY_ATTEN_CHANNEL;
    //#endif
    
    // Combining
    UNITY_APPLY_FOG(i.fogCoord, color);
    return float4(lightColor, _AlphaOverride) * color * getAttenuation(i) * getShadowAttenuation(i);
    //return float4(_LightColor0.rgb, _AlphaOverride) * color;
}

[maxvertexcount(6)]
void geom(triangle v2g IN[3], inout TriangleStream<VertexOutput> tristream)
{
	VertexOutput o;
	UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
	for (int ii = 0; ii < 3; ii++)
	{
		o.pos = UnityObjectToClipPos(IN[ii].vertex);
		o.uv = IN[ii].uv;
		o.uv1 = IN[ii].uv1;
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
        o.reflectionMap = IN[ii].reflectionMap;
        o.lightModifier = IN[ii].lightModifier;

		// Pass-through the shadow coordinates if this pass has shadows.
		SYN_TRANSFER_SHADOW(IN[ii], o)

		// Pass-through the fog coordinates if this pass has shadows.
		#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
			o.fogCoord = IN[ii].fogCoord;
		#endif
		
		#if defined(VERTEXLIGHT_ON)
			o.vertexLightColor = IN[ii].vertexLightColor;
		#endif

		tristream.Append(o);
	}

	tristream.RestartStrip();
}

[maxvertexcount(6)]
void geom2(triangle v2g IN[3], inout TriangleStream<VertexOutput> tristream)
{
	VertexOutput o;
	UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
	for (int ii = 0; ii < 3; ii++)
	{
		[branch] if (_OutlineMode == 2) {
			o.pos = UnityObjectToClipPos(IN[ii].vertex + normalize(IN[ii].normal) * (_outline_width * .01));
        } else if (_OutlineMode == 3) {
			o.pos = UnityObjectToClipPos(IN[ii].vertex + normalize(IN[ii].normal) * (_outline_width * .05) * distance(_WorldSpaceCameraPos,mul(unity_ObjectToWorld, IN[ii].vertex).rgb));
        } else {
			o.pos = UnityObjectToClipPos(IN[ii].vertex);
        }
		o.uv = IN[ii].uv;
		o.uv1 = IN[ii].uv1;
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
        o.reflectionMap = IN[ii].reflectionMap;
        o.lightModifier = IN[ii].lightModifier;

		// Pass-through the shadow coordinates if this pass has shadows.
		SYN_TRANSFER_SHADOW(IN[ii], o)

		// Pass-through the fog coordinates if this pass has shadows.
		#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
			o.fogCoord = IN[ii].fogCoord;
		#endif
		
		#if defined(VERTEXLIGHT_ON)
			o.vertexLightColor = IN[ii].vertexLightColor;
		#endif

		tristream.Append(o);
	}

	tristream.RestartStrip();
}

#endif