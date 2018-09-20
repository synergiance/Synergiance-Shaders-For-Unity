// SynToon by Synergiance
// v0.3.0

#define VERSION="v0.3.0"

#ifndef ALPHA_RAINBOW_CORE_INCLUDED

#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "HSB.cginc"
#include "Rotate.cginc"

sampler2D _MainTex;
sampler2D _BumpMap;
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
float4 _Color;
#if !NO_SHADOW
float _ShadowAmbient;
sampler2D _ShadowRamp;
float4 _ShadowTint;
float _shadow_coverage;
float _shadow_feather;
#if defined(IS_OPAQUE) && !DISABLE_SHADOW
float _shadowcast_intensity;
#endif
#endif
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
sampler2D _SphereAddTex;
sampler2D _SphereMulTex;
uniform float4 _StaticToonLight;
samplerCUBE _PanoSphereTex;
sampler2D _PanoFlatTex;
sampler2D _PanoOverlayTex;
float _PanoRotationSpeedX;
float _PanoRotationSpeedY;
float _PanoBlend;

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
    o.amb = _LightColor0;
    o.direct = ShadeSH9(half4(0.0, 1.0, 0.0, 1.0));
    o.indirect = ShadeSH9(half4(0.0, -1.0, 0.0, 1.0));
    o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
    o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
    o.posWorld = mul(unity_ObjectToWorld, v.vertex);
    o.vertex = v.vertex;
    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
    o.uv1 = v.texcoord1;
	TRANSFER_VERTEX_TO_FRAGMENT(o);
	UNITY_TRANSFER_FOG(o, o.pos);
    
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

//float4 calcSpecular(float4 lightDirection);
//{
//	float dirDotNormalHalf = max(0, dot(s.Normal, normalize(lightDir + viewDir)));
//	float dirSpecularWeight = pow( dirDotNormalHalf, _Shininess );
//	float4 dirSpecular = _SpecularColor * lightColor * dirSpecularWeight;
//}

float3 calcShadow(float3 position, float3 normal, float atten)
{// Generate the shadow based on the light direction
    float3 bright = float3(1.0, 1.0, 1.0);
    #if !NO_SHADOW
    float lightScale = 1;
    #if LOCAL_STATIC_LIGHT // Places light at a specific vector relative to the model.
    float3 lightDirection = normalize(_StaticToonLight.rgb);
    #elif WORLD_STATIC_LIGHT // Places light at a specific vector relative to the world.
    float3 lightDirection = normalize(_StaticToonLight.rgb - position);
    #else // Normal lighting
    float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - position, _WorldSpaceLightPos0.w));
    lightScale = dot(normal, lightDirection) * 0.5 + 0.5;
    #endif
    #if !NORMAL_LIGHTING
    #if !OVERRIDE_REALTIME
    if (!(abs(_WorldSpaceLightPos0.x + _WorldSpaceLightPos0.y + _WorldSpaceLightPos0.z) <= 0.01))
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
    if (abs(_WorldSpaceLightPos0.x + _WorldSpaceLightPos0.y + _WorldSpaceLightPos0.z) <= 0.01)
    {
        atten = 1;
    }
    lightScale = dot(normal, lightDirection) * 0.5 + 0.5;
    #endif
    #if defined(IS_OPAQUE) && !DISABLE_SHADOW
    lightScale *= atten * _shadowcast_intensity + (1 - _shadowcast_intensity);
    #endif
    #if TINTED_SHADOW
    float lightContrib = saturate(smoothstep((1 - _shadow_feather) * _shadow_coverage, _shadow_coverage, lightScale));
    bright = lerp(_ShadowTint.rgb, float3(1.0, 1.0, 1.0), lightContrib);
    #elif RAMP_SHADOW
    bright = tex2D(_ShadowRamp, float2(lightScale, lightScale)).rgb;
    #else
    #endif
    #endif
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

float3 applySphere(float3 color, float3 view, float3 normal)
{// Applies add and multiply spheres
    #if !NO_SPHERE
    float3 tangent = normalize(cross(view, float3(0.0, 1.0, 0.0)));
    float3 bitangent = normalize(cross(tangent, view));
	float3 viewNormal = normalize(mul(float3x3(tangent, bitangent, view), normal));
	float2 sphereUv = viewNormal.xy * 0.5 + 0.5;
    //float2 sphereUv = capCoord * 0.5 + 0.5;
    #if ADD_SPHERE
	float4 sphereAdd = tex2D( _SphereAddTex, sphereUv );
    color += sphereAdd.rgb;
    #elif MUL_SPHERE
	float4 sphereMul = tex2D( _SphereMulTex, sphereUv );
    color *= sphereMul.rgb;
    #endif
    #endif
    return color;
}

float3 applyPano(float3 color, float3 view, float2 coord, float2 uv)
{
    #if !NO_PANO
    float3 col;
    float2 transform = float2(_Time[1] * _PanoRotationSpeedX, _Time[1] * _PanoRotationSpeedY);
    #if SPHERE_PANO
    float3 newview = RotatePointAroundOrigin(view, transform);
    col = texCUBE(_PanoSphereTex, newview);
    #elif SCREEN_PANO
    float2 newcoord = coord + transform;
    col = tex2D(_PanoFlatTex, coord);
    #endif
    #if PANOOVERLAY
    float4 ocol = tex2D(_PanoOverlayTex, uv);
    #if PANOALPHA
    col = lerp(col, ocol.rgb, ocol.a);
    #else
    col += ocol.rgb;
    #endif
    #endif
    color = lerp(color, col, _PanoBlend);
    #endif
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
    float attenuation = LIGHT_ATTENUATION(i);
    float _AmbientLight = 0.8;
    i.normalDir = normalize(i.normalDir);
    float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
    float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,i.uv));
    float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform));
    float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
    float3 directLighting = (saturate(i.direct + i.reflectionMap + i.amb.rgb) + i.amb.rgb) / 2;
    float3 bright = calcShadow(i.posWorld.xyz, normalDirection, attenuation);
    #if defined(ALLOWOVERBRIGHT)
    float3 lightColor = saturate((lerp(0.0, i.direct, _AmbientLight ) + _LightColor0.rgb + i.reflectionMap) * _Brightness);
    #else
    float3 lightColor = saturate((lerp(0.0, i.direct, _AmbientLight ) + _LightColor0.rgb + i.reflectionMap) * _Brightness * ((i.lightModifier + 1) / 2));
    #endif
    
    // Pulse
    #if defined(PULSE)
    float4 pulsemask = tex2D(_EmissionPulseMap, i.uv);
    emissive = lerp(emissive, _EmissionPulseColor.rgb*pulsemask.rgb, (sin(_Time[1] * _EmissionSpeed * _EmissionSpeed * _EmissionSpeed) + 1) / 2);
    #endif
    
    // Secondary Effects
    color.rgb = applyPano(color.rgb, viewDirection, i.pos.xy / i.pos.w * 0.5 + 0.5, i.uv);
    
    // Primary effects
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    #if defined(RAINBOW)
    float4 maskcolor = tex2D(_RainbowMask, i.uv);
    color = float4(hueShift(color.rgb, maskcolor.rgb),color.a);
    bright = hueShift(bright, maskcolor.rgb);
    emissive = hueShift(emissive, 1);
    #endif

    // Outline
    color.rgb = artsyOutline(color.rgb, viewDirection, normalDirection);
    emissive = artsyOutline(emissive, viewDirection, normalDirection);
    
    #if !NO_SPHERE
    color.rgb = applySphere(color.rgb, viewDirection, normalDirection);
    #endif
    
    // Combining
    UNITY_APPLY_FOG(i.fogCoord, color);
    return float4(bright * lightColor, _AlphaOverride) * color + float4(emissive, 0);
}

float4 frag4(VertexOutput i) : COLOR
{
    // Variables
    float4 color = tex2D(_MainTex, i.uv);
    float4 _ColorMask_var = tex2D(_ColorMask, i.uv);
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
    clip (color.a - _Cutoff);
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
    float attenuation = LIGHT_ATTENUATION(i);
    #if defined (POINT) || defined (SPOT)
    attenuation = tex2D(_LightTexture0, dot(i._LightCoord,i._LightCoord).rr).UNITY_ATTEN_CHANNEL;
    #if defined(IS_OPAQUE) && !DISABLE_SHADOW && !NO_SHADOW
    attenuation *= SHADOW_ATTENUATION(i) * _shadowcast_intensity + (1 - _shadowcast_intensity);
    #endif
    #endif
    i.normalDir = normalize(i.normalDir);
    float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
    float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,i.uv));
    float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform));
    float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
    float3 bright = calcShadow(i.posWorld.xyz, normalDirection, 1);
    #if defined(IS_OPAQUE) && !DISABLE_SHADOW && !NO_SHADOW
    bright *= attenuation * _shadowcast_intensity + (1 - _shadowcast_intensity);
    #elif defined (POINT) || defined (SPOT)
    bright *= tex2D(_LightTexture0, dot(i._LightCoord,i._LightCoord).rr).UNITY_ATTEN_CHANNEL;
    #endif
    #if defined(ALLOWOVERBRIGHT)
    float3 lightColor = saturate(i.amb.rgb * _Brightness);
    #else
    float3 lightColor = saturate(i.amb.rgb * _Brightness * i.lightModifier * saturate(i.lightModifier) * 0.5);
    #endif
    
    color.rgb = applyPano(color.rgb, viewDirection, i.pos.xy / i.pos.w * 0.5 + 0.5, i.uv);
    
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    #if defined(RAINBOW)
    float4 maskcolor = tex2D(_RainbowMask, i.uv);
    color = float4(hueShift(color.rgb, maskcolor.rgb),color.a);
    bright = hueShift(bright, maskcolor.rgb);
    #endif

    // Outline
    color.rgb = artsyOutline(color.rgb, viewDirection, normalDirection);
    
    #if !NO_SPHERE
    color.rgb = applySphere(color.rgb, viewDirection, normalDirection);
    #endif
    
    // Combining
    UNITY_APPLY_FOG(i.fogCoord, color);
    return float4(bright * lightColor, _AlphaOverride) * color;
}

float4 frag3(VertexOutput i) : COLOR
{
    // Variables
    float4 color = tex2D(_MainTex, i.uv);
    float4 _ColorMask_var = tex2D(_ColorMask, i.uv);
    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
    clip (color.a - _Cutoff);
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
    float3 lightColor = saturate((lerp(0.0, i.direct, _AmbientLight ) + _LightColor0.rgb + i.reflectionMap) * _Brightness);
    #else
    float3 lightColor = saturate((lerp(0.0, i.direct, _AmbientLight ) + _LightColor0.rgb + i.reflectionMap) * _Brightness * ((i.lightModifier + 1) / 2));
    #endif
    
    // Primary Effects
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    #if defined(RAINBOW)
    float4 maskcolor = tex2D(_RainbowMask, i.uv);
    color = float4(hueShift(color.rgb, maskcolor.rgb),color.a);
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
    return float4(lightColor, _AlphaOverride) * color;
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
    float3 lightColor = saturate(i.amb.rgb * _Brightness);
    #else
    float3 lightColor = saturate(i.amb.rgb * _Brightness * i.lightModifier * saturate(i.lightModifier) * 0.5);
    #endif
    
    // Primary Effects
    // Saturation boost
    float3 hsvcol = RGBtoHSV(color.rgb);
    hsvcol.y *= 1 + _SaturationBoost;
    color.rgb = HSVtoRGB(hsvcol);
    // Rainbow
    #if defined(RAINBOW)
    float4 maskcolor = tex2D(_RainbowMask, i.uv);
    color = float4(hueShift(color.rgb, maskcolor.rgb),color.a);
    #endif
    
    // Secondary Effects

    // Outline
    #if TINTED_OUTLINE
    color.rgb *= _outline_color.rgb;
    #elif COLORED_OUTLINE
    color.rgb = float3((_outline_color.rgb * _outline_color.a) + (color.rgb * (1 - _outline_color.a)));
    #endif
    // Outline Effects
    
    #ifdef POINT
    //lightColor *= tex2D(_LightTexture0, dot(i._LightCoord,i._LightCoord).rr).UNITY_ATTEN_CHANNEL;
    #endif
    
    // Combining
    UNITY_APPLY_FOG(i.fogCoord, color);
    return float4(lightColor, _AlphaOverride) * color;
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