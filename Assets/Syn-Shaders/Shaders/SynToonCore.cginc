// SynToon by Synergiance
// v0.4.4.3

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
#if defined(PULSE)
float _EmissionSpeed;
Texture2D _EmissionPulseMap;
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

float _Rainbowing;

#include "SynToonLighting.cginc"
#if defined(REFRACTION)
#include "Refraction.cginc"
#endif

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
    float3 reflectionMap : TEXCOORD9;
    float lightModifier : TEXCOORD10;
	float4 pos : CLIP_POS;
	LIGHTING_COORDS(6,7)
	UNITY_FOG_COORDS(11)
	float2 uv2 : TEXCOORD12;
	float2 uv3 : TEXCOORD13;
	#if defined(VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD8;
	#endif
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
    float3 reflectionMap : TEXCOORD9; //
    float lightModifier : TEXCOORD10; //
	float4 col : COLOR3;
	bool is_outline : IS_OUTLINE;
	LIGHTING_COORDS(6,7)
	UNITY_FOG_COORDS(11)
	float2 uv2 : TEXCOORD12;
	float2 uv3 : TEXCOORD13;
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
    
    float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
    o.reflectionMap = DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, normalize((_WorldSpaceCameraPos - objPos.rgb)), 7), unity_SpecCube0_HDR)* 0.02;
    float3 lightColor = o.direct + o.amb.rgb * 2 + o.reflectionMap;
    float brightness = lightColor.r * 0.3 + lightColor.g * 0.59 + lightColor.b * 0.11;
    float correctedBrightness = -1 / (brightness * 2 + 1) + 1 + brightness * 0.1;
    o.lightModifier = correctedBrightness / brightness;
	
	float4 uvShadow = float4(0, 0, 0, 0);
	uvShadow.xy = o.uv;
	[branch] switch(_ShadowUV) {
		case 0: { uvShadow.zw = o.uv;  } break;
		case 1: { uvShadow.zw = o.uv1; } break;
		case 2: { uvShadow.zw = o.uv2; } break;
		case 3: { uvShadow.zw = o.uv3; } break;
	}
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

float3 artsyOutline(float3 color, float3 view, float3 normal, float2 uv)
{// Outline
    #if ARTSY_OUTLINE
		float4 outline = _outline_color * tex2D(_outline_tex, uv);
		float3 outlineColor = color;
		#if TINTED_OUTLINE
			outlineColor *= outline.rgb;
		#elif COLORED_OUTLINE
			outlineColor = float3((outline.rgb * outline.a) + (color * (1 - outline.a)));
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

FragmentOutput frag(VertexOutput i)
{
    // Variables
    float4 color = _MainTex.Sample(sampler_MainTex, i.uv);
    float4 _EmissionMap_var = _EmissionMap.Sample(sampler_MainTex, i.uv);
    float3 emissive = (_EmissionMap_var.rgb*_EmissionColor.rgb);
    float4 _ColorMask_var = _ColorMask.Sample(sampler_MainTex, i.uv);
	#if defined(DEFERRED_PASS) && !defined(IS_OPAQUE)
		clip (color.a - 0.8);
    #elif defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
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
    color = lerp(shiftcolor.rgba, color.rgba, _ColorMask_var.b);
	
	float4 uvShadow = float4(0, 0, 0, 0);
	uvShadow.xy = i.uv;
	[branch] switch(_ShadowUV) {
		case 0: { uvShadow.zw = i.uv;  } break;
		case 1: { uvShadow.zw = i.uv1; } break;
		case 2: { uvShadow.zw = i.uv2; } break;
		case 3: { uvShadow.zw = i.uv3; } break;
	}
	float2 uvSphere = float2(0, 0);
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
    float3 _BumpMap_var = UnpackNormal(_BumpMap.Sample(sampler_MainTex, i.uv));
    float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform));
    float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
    float3 directLighting = (saturate(i.direct + i.reflectionMap + i.amb.rgb) + i.amb.rgb) / 2;
    float4 bright = calcShadow(i.posWorld.xyz, normalDirection, attenuation, uvShadow, color.rgb);
    #if defined(ALLOWOVERBRIGHT)
		float3 lightColor = saturate(lerp(0.0, i.direct, _AmbientLight ) + i.amb.rgb + i.reflectionMap) * _Brightness;
    #else
		float3 lightColor = saturate(lerp(0.0, i.direct, _AmbientLight ) + i.amb.rgb + i.reflectionMap * ((i.lightModifier + 1) / 2)) * _Brightness;
    #endif
	float3 ambient = float3(0, 0, 0);
	#ifdef LIGHTMAP_ON
		ambient += DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1));
	#endif
	#if defined(VERTEXLIGHT_ON)
		ambient += i.vertexLightColor;
	#endif
	//ambient += max(0, ShadeSH9(float4(normalDirection, 1)));
    
    // Pulse
    #if defined(PULSE)
		float4 pulsemask = _EmissionPulseMap.Sample(sampler_MainTex, i.uv);
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
    if (_Rainbowing == 1) {
		float4 maskcolor = _RainbowMask.Sample(sampler_MainTex, i.uv);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
		bright.rgb = hueShift(bright.rgb, maskcolor.rgb);
		emissive = hueShift(emissive, maskcolor.rgb);
    }

    // Outline
    color.rgb = artsyOutline(color.rgb, viewDirection, normalDirection, i.uv);
    emissive = artsyOutline(emissive, viewDirection, normalDirection, i.uv);
    
    // Sphere
	color.rgb = applySphere(color.rgb, viewDirection, normalDirection, uvSphere);
	
	float3 specular = calcSpecular(normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w)), viewDirection, normalDirection, bright.rgb * lightColor, i.uv, attenuation * bright.a, _ProbeStrength, i.posWorld) * tex2D(_OcclusionMap, i.uv).r;
    
    // Combining
	UNITY_APPLY_FOG(i.fogCoord, color);
	FragmentOutput output;
	#if defined(DEFERRED_PASS)
		output.gBuffer0.rgb = color.rgb;
		output.gBuffer0.a = tex2D(_OcclusionMap, i.uv).r;
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
	#endif
	return output;
}

float4 frag4(VertexOutput i) : COLOR
{
    // Variables
    float4 color = _MainTex.Sample(sampler_MainTex, i.uv);
    float4 _ColorMask_var = _ColorMask.Sample(sampler_MainTex, i.uv);
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
	
	float4 uvShadow = float4(0, 0, 0, 0);
	uvShadow.xy = i.uv;
	[branch] switch(_ShadowUV) {
		case 0: { uvShadow.zw = i.uv;  } break;
		case 1: { uvShadow.zw = i.uv1; } break;
		case 2: { uvShadow.zw = i.uv2; } break;
		case 3: { uvShadow.zw = i.uv3; } break;
	}
	float2 uvSphere = float2(0, 0);
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
    float3 _BumpMap_var = UnpackNormal(_BumpMap.Sample(sampler_MainTex, i.uv));
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
    if (_Rainbowing == 1) {
		float4 maskcolor = _RainbowMask.Sample(sampler_MainTex, i.uv);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
		bright.rgb = hueShift(bright.rgb, maskcolor.rgb);
    }

    // Outline
    color.rgb = artsyOutline(color.rgb, viewDirection, normalDirection, i.uv);
    
	// Sphere
    color.rgb = applySphere(color.rgb, viewDirection, normalDirection, uvSphere);
	
	float3 specular = calcSpecular(normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz, _WorldSpaceLightPos0.w)), viewDirection, normalDirection, bright.rgb * lightColor, i.uv, attenuation * bright.a, 0, float3(0, 0, 0)) * tex2D(_OcclusionMap, i.uv).r;
    
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
    float4 color = _MainTex.Sample(sampler_MainTex, i.uv);
    float4 _ColorMask_var = _ColorMask.Sample(sampler_MainTex, i.uv);
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
    if (_Rainbowing == 1) {
		float4 maskcolor = _RainbowMask.Sample(sampler_MainTex, i.uv);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
    }
    
    // Secondary Effects

    // Outline
    #if TINTED_OUTLINE
		color.rgb *= _outline_color.rgb * tex2D(_outline_tex, i.uv).rgb;
    #elif COLORED_OUTLINE
		float4 outlineColor = _outline_color * tex2D(_outline_tex, i.uv);
		color.rgb = float3((outlineColor.rgb * outlineColor.a) + (color.rgb * (1 - outlineColor.a)));
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
    float4 color = _MainTex.Sample(sampler_MainTex, i.uv);
    float4 _ColorMask_var = _ColorMask.Sample(sampler_MainTex, i.uv);
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
    if (_Rainbowing == 1) {
		float4 maskcolor = _RainbowMask.Sample(sampler_MainTex, i.uv);
		color.rgb = hueShift(color.rgb, maskcolor.rgb);
    }
    
    // Secondary Effects

    // Outline
    #if TINTED_OUTLINE
		color.rgb *= _outline_color.rgb * tex2D(_outline_tex, i.uv).rgb;
    #elif COLORED_OUTLINE
		float4 outlineColor = _outline_color * tex2D(_outline_tex, i.uv);
		color.rgb = float3((outlineColor.rgb * outlineColor.a) + (color.rgb * (1 - outlineColor.a)));
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
		
		#if defined(VERTEXLIGHT_ON)
			o.vertexLightColor = IN[ii].vertexLightColor;
		#endif

		tristream.Append(o);
	}

	tristream.RestartStrip();
}

#endif