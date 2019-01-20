// Synergiance Toon Shader (TransparentFix2)

Shader "Synergiance/Toon/TransparentFix2"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
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
        _ShadowAmbient("Ambient Light", Range(0,1)) = 0.8
        _ShadowAmbAdd("Ambient", Range(0,1)) = 0
        _shadow_coverage("Shadow Coverage", Range(0,1)) = 0.6
        _shadow_feather("Shadow Feather", Range(0,1)) = 0.2
        _shadowcast_intensity("Shadow cast intensity", Range(0,1)) = 0.75
        _ShadowIntensity("Shadow Intensity", Range(0,1)) = 0.1
		_outline_width("outline_width", Range(0,1)) = 0.2
		_outline_color("outline_color", Color) = (0.5,0.5,0.5,1)
		_outline_feather("outline_width", Range(0,1)) = 0.5
		_outline_tint("outline_tint", Range(0, 1)) = 0.5
		_EmissionMap("Emission Map", 2D) = "white" {}
		[HDR]_EmissionColor("Emission Color", Color) = (0,0,0,1)
		_EmissionSpeed("Emission Speed", Range(0,10)) = 3
		_EmissionPulseMap("Emission Pulse Map", 2D) = "white" {}
		[HDR]_EmissionPulseColor("Emission Pulse Color", Color) = (0,0,0,1)
        _Brightness("Brightness", Range(0,10)) = 1
        _CorrectionLevel("Gamma Correct", Range(0,1)) = 1
		[Normal]_BumpMap("BumpMap", 2D) = "bump" {}
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
		_AlphaOverride("Alpha override", Range(0,10)) = 1
		_SphereAddTex("Sphere (Add)", 2D) = "black" {}
		_SphereMulTex("Sphere (Multiply)", 2D) = "white" {}
		_SphereMultiTex("Sphere (Multiple)", 2D) = "white" {}
		[Enum(1x2,2,2x2,4,2x4,8,3x3,9,4x4,16,3x6,18,5x5,25)] _SphereNum("Number of Spheres", Int) = 4
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

		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _OutlineMode("__outline_mode", Float) = 0.0
		[HideInInspector] _OutlineColorMode("__outline_color_mode", Float) = 0.0
		[HideInInspector] _LightingHack("__lighting_hack", Float) = 0.0
		[HideInInspector] _TransFix("__transparent_fix", Float) = 0.0
		[HideInInspector] _ShadowMode("__shadow_mode", Float) = 0.0
		[HideInInspector] _SphereMode("__sphere_mode", Float) = 0.0
        [HideInInspector] _OverlayMode ("Overlay Mode", Float) = 0.0
        [HideInInspector] _OverlayBlendMode ("Blend Mode", Float) = 0.0
		
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blending Operation", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0
		//[HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _CullMode ("__zw", Float) = 0.0
        
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
			"Queue" = "Transparent+100"
			"PreviewType" = "Sphere"
            //"RenderType" = "Opaque"
		}
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

        UsePass "Synergiance/Toon/Transparent/FORWARD"
        
        UsePass "Synergiance/Toon/Transparent/FORWARD_DELTA"
	}
	FallBack "Diffuse"
	CustomEditor "SynToonInspector"
}