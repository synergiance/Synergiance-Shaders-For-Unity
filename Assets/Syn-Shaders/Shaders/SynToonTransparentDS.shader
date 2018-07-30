// Synergiance Toon Shader (Transparent)

Shader "Synergiance/Toon/TransparentDS"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_ColorMask("ColorMask", 2D) = "black" {}
        _RainbowMask ("Rainbow Mask", 2D) = "white" {}
        _Speed("Speed", Range(0,10)) = 3
        _ShadowTint("Shadow Tint", Color) = (0.75,0.75,0.75,1)
        _ShadowRamp("Toon Texture", 2D) = "white" {}
        _ShadowAmbient("Ambient Light", Range(0,1)) = 0
        _shadow_coverage("Shadow Coverage", Range(0,1)) = 0.6
        _shadow_feather("Shadow Feather", Range(0,1)) = 0.2
        _shadowcast_intensity("Shadow cast intensity", Range(0,1)) = 0.75
		_outline_width("outline_width", Range(0,1)) = 0.2
		_outline_color("outline_color", Color) = (0.5,0.5,0.5,1)
		_outline_feather("outline_width", Range(0,1)) = 0.5
		_outline_tint("outline_tint", Range(0, 1)) = 0.5
		_EmissionMap("Emission Map", 2D) = "white" {}
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		_EmissionSpeed("Emission Speed", Range(0,10)) = 3
		_EmissionPulseMap("Emission Pulse Map", 2D) = "white" {}
		[HDR]_EmissionPulseColor("Emission Pulse Color", Color) = (0,0,0,1)
        _Brightness("Brightness", Range(0,1)) = 1
		_BumpMap("BumpMap", 2D) = "bump" {}
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
		_AlphaOverride("Alpha override", Range(0,10)) = 1
		_SphereAddTex("Sphere (Add)", 2D) = "black" {}
		_SphereMulTex("Sphere (Multiply)", 2D) = "white" {}
        _StaticToonLight ("Static Light", Vector) = (1,1.5,1.5,0)

		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _OutlineMode("__outline_mode", Float) = 0.0
		[HideInInspector] _OutlineColorMode("__outline_color_mode", Float) = 0.0
		[HideInInspector] _LightingHack("__lighting_hack", Float) = 0.0
		[HideInInspector] _ShadowMode("__shadow_mode", Float) = 0.0
		[HideInInspector] _SphereMode("__sphere_mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _CullMode ("__zw", Float) = 0.0
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"PreviewType" = "Sphere"
            //"RenderType" = "Opaque"
		}

		Pass
		{
			Name "BACKSIDE"
            
            //Blend SrcAlpha OneMinusSrcAlpha
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull Front
            
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
			#pragma shader_feature TINTED_OUTLINE COLORED_OUTLINE
            #pragma shader_feature _ ARTSY_OUTLINE
            #pragma shader_feature _ RAINBOW ALPHA LIGHTING
            #pragma shader_feature PULSE
            #pragma shader_feature NO_SHADOW TINTED_SHADOW RAMP_SHADOW
            #pragma shader_feature NO_SPHERE ADD_SPHERE MUL_SPHERE
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature NORMAL_LIGHTING WORLD_STATIC_LIGHT LOCAL_STATIC_LIGHT
            #pragma shader_feature _ OVERRIDE_REALTIME
            #include "SynToonCore.cginc"
            
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
            
			#pragma only_renderers d3d11 glcore gles
			#pragma target 4.0

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
            
			ENDCG
		}
        
        Pass
        {
			Name "BACKSIDE_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
            //Blend SrcAlpha One
			Blend [_SrcBlend] One
            Cull Front

			CGPROGRAM
			#pragma shader_feature TINTED_OUTLINE COLORED_OUTLINE
            #pragma shader_feature _ ARTSY_OUTLINE
            #pragma shader_feature _ RAINBOW ALPHA LIGHTING PULSE
            #pragma shader_feature NO_SHADOW TINTED_SHADOW RAMP_SHADOW
            #pragma shader_feature NO_SPHERE ADD_SPHERE MUL_SPHERE
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature NORMAL_LIGHTING WORLD_STATIC_LIGHT LOCAL_STATIC_LIGHT
            #pragma shader_feature _ OVERRIDE_REALTIME
			#include "SynToonCore.cginc"
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag4

			#pragma only_renderers d3d11 glcore gles
			#pragma target 4.0

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
            
            ENDCG
        }

        UsePass "Synergiance/Toon/Transparent/FORWARD"
        
        UsePass "Synergiance/Toon/Transparent/FORWARD_DELTA"
	}
	FallBack "Diffuse"
	CustomEditor "SynToonInspector"
}