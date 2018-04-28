// Alpha Rainbow by Synergiance

#ifndef ALPHA_RAINBOW_CORE_INCLUDED

#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#if defined(RAINBOW)
#include "HSB.cginc"
#endif

sampler2D _MainTex;
sampler2D _ToonLut;
sampler2D _BumpMap;
sampler2D _ColorMask;
sampler2D _EmissionMap;
float4 _EmissionColor;
#if defined(PULSE)
float _EmissionSpeed;
sampler2D _EmissionPulseMap;
float4 _EmissionPulseColor;
#endif
float _Brightness;
float4 _Color;
float _Shadow;
float _Cutoff;
float _AlphaOverride;
#if defined(RAINBOW)
sampler2D _RainbowMask;
float _Speed;
#endif
uniform float _outline_width;
uniform float _outline_feather;
uniform float4 _outline_color;

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
	SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)
};

struct VertexOutput
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
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
	SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)
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
    o.uv = v.texcoord;
    o.uv1 = v.texcoord1;
	TRANSFER_SHADOW(o);
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

float4 frag(VertexOutput i) : SV_Target
{
    float4 color = tex2D(_MainTex, i.uv);
    //fixed dotv = dot(i.normal, _WorldSpaceLightPos0);
    #if defined(RAINBOW)
    float4 maskcolor = tex2D(_RainbowMask, i.uv);
    #endif
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);

    float4 _EmissionMap_var = tex2D(_EmissionMap, i.uv);
    float3 emissive = (_EmissionMap_var.rgb*_EmissionColor.rgb);
    #if defined(PULSE)
    emissive = lerp(emissive, _EmissionPulseColor.rgb*_EmissionPulseMap.rgb, sin(_Time[1] * _EmissionSpeed * _EmissionSpeed * _EmissionSpeed))
    #endif
    float4 _ColorMask_var = tex2D(_ColorMask, i.uv);
    color = lerp((color.rgba*_Color.rgba),color.rgba,_ColorMask_var.r);
    
    // Lighting
    i.normalDir = normalize(i.normalDir);
    float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
    float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,i.uv));
    float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform));
    float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
    float3 viewDirection = normalize(_WorldSpaceCameraPos - i.posWorld.xyz);
    float grayscaleDirectLighting = dot(lightDirection, normalDirection)*i.lightData.r*attenuation + grayscaleSH9(normalDirection);
    float remappedLight = (grayscaleDirectLighting - i.lightData.g) / i.lightData.a;
    //float3 directContribution = saturate((1.0 - _Shadow) + floor(saturate(remappedLight) * 2.0));
    float3 directContribution = saturate((1.0 - _Shadow) + tex2D(_ToonLut, float2(remappedLight, 0)));
    //float3 lightmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1 * unity_LightmapST.xy + unity_LightmapST.zw));
    //color *= float4(i.col.rgb, 1);

    #if COLORED_OUTLINE
    //if(i.is_outline) 
    //{
        //color.rgb = i.col.rgb; 
    //}
    #endif
    
    #if defined(RAINBOW)
    // Rainbow
    color = float4(hueShift(color.rgb, maskcolor.rgb),color.a);
    emissive = hueShift(emissive, 1);
    #endif

    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
    clip (color.a - _Cutoff);
    #endif
    
    // Outline
    #if !NO_OUTLINE
    //lerp(outlineColor,color.rgb,smoothstep(_outline_width - 0.05, outline_width, dot(viewDirection, normalDirection)));
    float3 outlineColor = color.rgb;
    float3 outlineEmissive = emissive;
    #if TINTED_OUTLINE
    outlineColor *= _outline_color.rgb;
    outlineEmissive *= _outline_color.rgb;
    #elif COLORED_OUTLINE
    outlineColor = float3((_outline_color.rgb * _outline_color.a) + (color.rgb * (1 - _outline_color.a)));
    outlineEmissive = float3((_outline_color.rgb * _outline_color.a) + (emissive * (1 - _outline_color.a)));
    #endif
    color.rgb = lerp(outlineColor,color.rgb,smoothstep(_outline_width - _outline_feather / 10, _outline_width, dot(viewDirection, normalDirection)));
    emissive = lerp(outlineEmissive,emissive,smoothstep(_outline_width - _outline_feather / 10, _outline_width, dot(viewDirection, normalDirection)));
    //lerp(outlineColor,color.rgb,dot(viewDirection, normalDirection));
    //lerp(outlineEmissive,emissive,dot(viewDirection, normalDirection));
    #endif
    
    // Combining
    
    float3 indirectLighting = saturate((i.indirect + i.reflectionMap));
    float3 directLighting = saturate((i.direct + i.reflectionMap + i.amb.rgb));
    float3 finalColor = emissive + (color * ((i.lightModifier + 1) / 2) * lerp(indirectLighting, directLighting, directContribution));
    fixed4 finalRGBA = fixed4(finalColor, color.a);
    float3 lighting = lerp(saturate(i.indirect + i.reflectionMap), saturate(i.direct + i.amb.rgb + i.reflectionMap), directContribution);
    color = float4(color.rgb * _Brightness * lighting * ((i.lightModifier + 1) / 2), color.a * _AlphaOverride) + float4(emissive, 0);
    UNITY_APPLY_FOG(i.fogCoord, color);
    return color;
    //return lightModifier;
    //return float4(directContribution, color.a);
    //return i.col;
}

float4 frag1(VertexOutput i) : COLOR
{
    i.normalDir = normalize(i.normalDir);
    float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
    float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,i.uv));
    float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform)); // Perturbed normals
    float4 _MainTex_var = tex2D(_MainTex,i.uv);
    
    float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
    float3 lightColor = i.amb.rgb;
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);

    float4 _EmissionMap_var = tex2D(_EmissionMap,i.uv);
    float3 emissive = (_EmissionMap_var.rgb*_EmissionColor.rgb);
    float4 _ColorMask_var = tex2D(_ColorMask,i.uv);
    float4 baseColor = lerp((_MainTex_var.rgba*_Color.rgba),_MainTex_var.rgba,_ColorMask_var.r);
    //baseColor *= float4(i.col.rgb, 1);

    #if COLORED_OUTLINE
    //if(i.is_outline) 
    //{
        //baseColor.rgb = i.col.rgb; 
    //}
    #endif

    #if defined(_ALPHATEST_ON)
    clip (baseColor.a - _Cutoff);
    #endif
    
    baseColor.rgb = float3((_outline_color.rgb * _outline_color.a) + (baseColor.rgb * (1 - _outline_color.a)));
    emissive = float3((_outline_color.rgb * _outline_color.a) + (emissive * (1 - _outline_color.a)));

    float grayscaleDirectLighting = dot(lightDirection, normalDirection)*i.lightData.r*attenuation + grayscaleSH9(normalDirection);
    float remappedLight = (grayscaleDirectLighting - i.lightData.g) / i.lightData.a;

    float3 indirectLighting = saturate((i.indirect + i.reflectionMap));
    float3 directLighting = saturate((i.direct + i.reflectionMap + i.amb.rgb));
    float3 directContribution = saturate((1.0 - _Shadow) + tex2D(_ToonLut, float2(remappedLight, 0)));
    float3 finalColor = emissive + (baseColor * ((i.lightModifier + 1) / 2) * lerp(indirectLighting, directLighting, directContribution));
    fixed4 finalRGBA = fixed4(finalColor, baseColor.a);
    UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
    return finalRGBA;
    //return fixed4(i.col.rgb,0);
}

float4 frag2(VertexOutput i) : COLOR
{
    i.normalDir = normalize(i.normalDir);
    float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
    float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap, i.uv));
    float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform)); // Perturbed normals
    float4 _MainTex_var = tex2D(_MainTex, i.uv);

    float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);

    float4 _ColorMask_var = tex2D(_ColorMask, i.uv);
    float4 baseColor = lerp((_MainTex_var.rgba*_Color.rgba),_MainTex_var.rgba,_ColorMask_var.r);
    //float4 baseColor = _MainTex_var.rgba;
    //baseColor *= float4(i.col.rgb, 1);

    #if COLORED_OUTLINE
    //if(i.is_outline) {
        //baseColor.rgb = i.col.rgb;
    //}
    #endif

    #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON)
    clip (baseColor.a - _Cutoff);
    #endif
    
    #if defined(RAINBOW)
    float4 maskcolor = tex2D(_RainbowMask, i.uv);
    baseColor = float4(hueShift(baseColor.rgb, maskcolor.rgb), baseColor.a);
    #endif
    
    float lightContribution = dot(normalize(_WorldSpaceLightPos0.xyz - i.posWorld.xyz),normalDirection)*attenuation;
    //float3 directContribution = floor(saturate(lightContribution) * 2.0);
    float3 directContribution = tex2D(_ToonLut, float2(lightContribution, 0));
    //float3 finalColor = baseColor * lerp(0, i.amb.rgb, saturate(directContribution + ((1 - _Shadow) * attenuation)));
    float3 finalColor = baseColor * lerp(0, i.amb.rgb, saturate(directContribution + ((1 - _Shadow) * tex2D(_ToonLut, float2(attenuation, 0)))));
    //float3 finalColor = baseColor * lerp(0, i.amb.rgb, saturate(directContribution * (1 - _Shadow) + _Shadow / 2));
    finalColor = finalColor * _Brightness * i.lightModifier * saturate(i.lightModifier);
    //fixed4 finalRGBA = fixed4(finalColor,1) * i.col;
    fixed4 finalRGBA = fixed4(finalColor, baseColor.a);
    UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
    return finalRGBA;
    //return fixed4(0,0,0,0);
}

[maxvertexcount(6)]
void geom(triangle v2g IN[3], inout TriangleStream<VertexOutput> tristream)
{
	VertexOutput o;
	//#if !NO_OUTLINE
	//for (int i = 2; i >= 0; i--)
	//{
		//o.pos = UnityObjectToClipPos(IN[i].vertex + normalize(IN[i].normal) * (_outline_width * .01));
		//o.uv = IN[i].uv;
		//o.uv1 = IN[i].uv1;
		//o.col = fixed4( _outline_color.r, _outline_color.g, _outline_color.b, 1);
		//o.posWorld = mul(unity_ObjectToWorld, IN[i].vertex);
		//o.normalDir = UnityObjectToWorldNormal(IN[i].normal);
		//o.tangentDir = IN[i].tangentDir;
		//o.bitangentDir = IN[i].bitangentDir;
		//o.is_outline = true;
        
        //o.amb = IN[i].amb;
        //o.direct = IN[i].direct;
        //o.indirect = IN[i].indirect;
        //o.lightData = IN[i].lightData;
        //o.reflectionMap = IN[i].reflectionMap;
        //o.lightModifier = IN[i].lightModifier;

		// Pass-through the shadow coordinates if this pass has shadows.
		//#if defined (SHADOWS_SCREEN) || ( defined (SHADOWS_DEPTH) && defined (SPOT) ) || defined (SHADOWS_CUBE)
		//o._ShadowCoord = IN[i]._ShadowCoord;
		//#endif

		// Pass-through the fog coordinates if this pass has shadows.
		//#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
		//o.fogCoord = IN[i].fogCoord;
		//#endif

		//tristream.Append(o);
	//}

	//tristream.RestartStrip();
	//#endif

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

		// Pass-through the fog coordinates if this pass has shadows.
		#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
		o.fogCoord = IN[ii].fogCoord;
		#endif

		tristream.Append(o);
	}

	tristream.RestartStrip();
}

#endif