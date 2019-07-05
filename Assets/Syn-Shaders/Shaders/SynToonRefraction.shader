// Synergiance Toon Shader (Refraction)

Shader "Synergiance/Toon/Refraction"
{
	Properties
	{
		[HDR]_MainTex("Main Texture", 2D) = "white" {}
		[HDR]_Color("Color", Color) = (1,1,1,1)
		_ColorMask("ColorMask", 2D) = "black" {}
        _RainbowMask ("Rainbow Mask", 2D) = "white" {}
        _Speed("Speed", Range(0,10)) = 3
		_LightColor("Light Color", Color) = (1,1,1,1)
		_LightOverride("Light Override", Range(0,1)) = 0
        _ShadowTint("Shadow Tint", Color) = (0.75,0.75,0.75,1)
        _ShadowRamp("Toon Texture", 2D) = "white" {}
        _ShadowTexture("Shadow Texture", 2D) = "black" {}
        [Enum(Vertical,0,Horizontal,1)] _ShadowRampDirection("Ramp Direction", Int) = 1
        [Enum(Texture,0,Tint,1)] _ShadowTextureMode("Texture Tint", Int) = 1
		[Enum(UV1,0,UV2,1,UV3,2,UV4,3)] _ShadowUV("Shadow Atlas UV Map", Int) = 0
        _ShadowAmbient("Ambient Light", Range(0,1)) = 0.8
        _ShadowAmbAdd("Ambient", Range(0,1)) = 0
        _shadow_coverage("Shadow Coverage", Range(0,1)) = 0.6
        _shadow_feather("Shadow Feather", Range(0,1)) = 0.2
        _shadowcast_intensity("Shadow cast intensity", Range(0,1)) = 0.75
        _ShadowIntensity("Shadow Intensity", Range(0,1)) = 0.1
		_outline_width("outline_width", Range(0,1)) = 0.2
		_outline_color("outline_color", Color) = (0.5,0.5,0.5,1)
		_outline_tex("Outline Map", 2D) = "white" {}
		_outline_feather("outline_width", Range(0,1)) = 0.5
		_outline_tint("outline_tint", Range(0, 1)) = 0.5
		_EmissionMap("Emission Map", 2D) = "white" {}
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		_EmissionSpeed("Emission Speed", Range(0,10)) = 3
		_EmissionPulseMap("Emission Pulse Map", 2D) = "white" {}
		[HDR]_EmissionPulseColor("Emission Pulse Color", Color) = (0,0,0,1)
        _Brightness("Brightness", Range(0,10)) = 1
        _CorrectionLevel("Gamma Correct", Range(0,1)) = 0
		[Normal]_BumpMap("BumpMap", 2D) = "bump" {}
		_OcclusionMap("Occlusion Map", 2D) = "white" {}
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
		_AlphaOverride("Alpha override", Range(0,10)) = 1
		_SphereAddTex("Sphere (Add)", 2D) = "black" {}
		_SphereMulTex("Sphere (Multiply)", 2D) = "white" {}
		_SphereMultiTex("Sphere (Multiple)", 2D) = "white" {}
		[Gamma]_SphereAtlas("Sphere Atlas Texture", 2D) = "black" {}
		[Enum(2x1,2,2x2,4,4x2,8,3x3,9,4x4,16,6x3,18,5x5,25)] _SphereNum("Number of Spheres", Int) = 4
		[Enum(UV1,0,UV2,1,UV3,2,UV4,3)] _SphereUV("Sphere Atlas UV Map", Int) = 0
        _StaticToonLight ("Static Light", Vector) = (1,1.5,1.5,0)
        _SaturationBoost ("Saturation Boost", Range(0,5)) = 0
        _PanoSphereTex ("Panosphere Texture", Cube) = "" {}
        _PanoFlatTex ("Panosphere Texture", 2D) = "" {}
        _PanoRotationSpeedX ("Rotation (X)", Float) = 0
        _PanoRotationSpeedY ("Rotation (Y)", Float) = 0
        _PanoOverlayTex ("Panosphere Overlay", 2D) = "black" {}
        _PanoBlend ("Blend", Range(0,1)) = 1
		_SpecularMap ("Specular Map", 2D) = "white" {}
		_SpecularPower ("Specular Power", Float) = 1
		[HDR]_SpecularColor ("Specular Color", Color) = (0,0,0,1)
		_UVScrollX ("UV Scroll (x)", Float) = 0
		_UVScrollY ("UV Scroll (Y)", Float) = 0
		_ProbeStrength ("Probe Strength", Range(0,1)) = 0
		_ProbeClarity ("Probe Clarity", Range(0,1)) = 0
		_ChromaticAberration("Chromatic Aberration", Range( 0 , 0.3)) = 0.1
		_IndexofRefraction("Index of Refraction", Range( -3 , 4)) = 1
		_OverbrightProtection("Overbright Protection", Range(0, 1)) = 0
		_BackFaceTint("Backface Tint", Color) = (1, 1, 1, 1)
		
		_ColChangePercent("Color Change Time", Range(0, 1)) = 0.25
		[Enum(Rainbow,0,Gradient,1)]_ColChangeMode("Color Change Mode", Float) = 0
		[Toggle(_)]_ColChangeCustomRamp("Custom Color Texture", Float) = 0
		[HDR]_ColChangeRamp("Custom Color Ramp Texture", 2D) = "red" {}
		[IntRange]_ColChangeSteps("Color Change Steps", Range(0, 1000)) = 0
		[Enum(None,0,UV,1,Height,2,View Distance,3)]_ColChangeDirection("Color Change Direction", Float) = 0
		[Enum(None,0,Fade,1,FadeThrough,2,Oversaturate,3)]_ColChangeEffect("Color Change Effect", Float) = 1
		[Enum(None,0,Flip,1,Shrink,2,Twist,3,Flyout,4,Flyin,5)]_ColChangeGeomEffect("Color Change Geometry Effect", Float) = 0
		[Enum(None,0,Full,1,Emission Only,2)] _Rainbowing("Rainbow", Float) = 0
		[Enum(Regular Lighting,0,Unlit,1,Unlit Outline,2)] _Unlit("Light Mode", Float) = 0
		[Toggle(_)] _PulseEmission("Pulse Emission", Float) = 0
		[Toggle(_)] _ShadeEmission("Shade Emission", Float) = 0
		[Toggle(_)] _SleepEmission("Sleep Emission", Float) = 0
		[Toggle(_)] _FlipBackfaceNorms("Flip Backface Normals", Float) = 1
        [Enum(Off,0,Front,1,Back,2)] _CullMode ("Cull Mode", Float) = 0
		[Toggle(_)] _HueShiftMode("HSB Mode", Float) = 0
		[Toggle(_)] _OverrideRealtime("Override Realtime Lights", Float) = 0
		[Toggle(_)] _PanoUseOverlay("Overlay", Float) = 0
		[Toggle(_)] _PanoUseAlpha("Use Alpha Channel", Float) = 0
		[Toggle(_)] _PanoEmission("Panosphere On Emission", Float) = 0
		[Toggle(_)] _Dither("Dithered Transparency", Float) = 0

		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _OutlineMode("__outline_mode", Float) = 0.0
		[HideInInspector] _OutlineColorMode("__outline_color_mode", Float) = 0.0
		[HideInInspector] _LightingHack("__lighting_hack", Float) = 0.0
		[Enum(None,0,Level1,1,Level2,2)] _TransFix("__transparent_fix", Float) = 0.0
		[HideInInspector] _ShadowMode("__shadow_mode", Float) = 0.0
		[HideInInspector] _SphereMode("__sphere_mode", Float) = 0.0
        [HideInInspector] _OverlayMode ("Overlay Mode", Float) = 0.0
        [Enum(None,0,Add,1,Multiply,2,Alphablend,3,Hue,4)] _OverlayBlendMode ("Blend Mode", Int) = 0
		
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blending Operation", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0
		//[HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _DisableBatching ("__db", Int) = 0
        
        // Stencil
		[IntRange] _Stencil ("Stencil ID (0-255)", Range(0,255)) = 0
		_ReadMask ("ReadMask (0-255)", Int) = 255
		_WriteMask ("WriteMask (0-255)", Int) = 255
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Int) = 0
		[Enum(Off,0,On,1)] _ZWrite("ZWrite", Int) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
		[Enum(None,0,Alpha,1,Red,8,Green,4,Blue,2,RGB,14,RGBA,15)] _stencilcolormask("Color Mask", Int) = 15 
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent+3000"
			"PreviewType" = "Sphere"
            //"RenderType" = "Opaque"
		}
        Cull [_CullMode]
		ColorMask [_stencilcolormask]
        ZTest [_ZTest]
        BlendOp [_BlendOp]
        
		Stencil
		{
			Ref [_Stencil]
			ReadMask [_ReadMask]
			WriteMask [_WriteMask]
			Comp [_StencilComp]
			Pass [_StencilOp]
			Fail [_StencilFail]
			ZFail [_StencilZFail]
		}
		
		GrabPass { "_RefractGrab" }
		
		UsePass "Synergiance/Toon/META"

		Pass
		{
			Name "FORWARD"
            
            Blend One Zero
            ZWrite [_ZWrite]
            
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
            #define IS_OPAQUE
			#define BASE_PASS
			#define REFRACTION
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
        
        UsePass "Synergiance/Toon/Transparent/FORWARD_DELTA"
		
		UsePass "Synergiance/Toon/Transparent/DEFERRED"
		
		UsePass "Synergiance/Toon/Transparent/SHADOWCASTER"
	}
    
	FallBack "Diffuse"
	CustomEditor "SynToonInspector"
}