// AckToon Shader

Shader "Synergiance/AckToon/Medium" {
	Properties {
		// Main Maps
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0

        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        _GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
        [Enum(Metallic Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0

        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap("Metallic", 2D) = "white" {}

        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}

        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion", 2D) = "white" {}

        _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}

		// Color Options
		_Vivid("Vivid", Range(0, 1)) = 0
		_Speed("Rainbow Speed", Range(0, 10)) = 0
		
		// Options
		[Toggle(_ALPHAPREMULTIPLY_ON)] _Premultiply ("Premultiply", Int) = 0
		_Exposure ("Exposure", Float) = 1
		_AmbDirection ("Directional Ambient", Range(0,1)) = 0.25
		_ToonAmb ("Toonstyle Ambient", Range(0,1)) = 0.5
		_FallbackLightDir ("Fallback Light Direction", Vector) = (0.5, 1, 0.25)
		_PointLightLitShade ("Point Light Lit Shade", Range(0, 1)) = 0.2
		_FakeLight ("Fake Light", Range(0, 1)) = 0
		[HDR]_FakeLightCol ("Fake Light Color", Color) = (1, 1, 1)
		
		_ToonFeather ("Feather", Range(0, 1)) = 0.1
		_ToonCoverage ("Coverage", Range(0, 1)) = 0.5
		_ToonColor ("Color", Color) = (0,0,0,0)
		_ToonIntensity ("Surface Intensity", Range(0, 1)) = 0
		
		_SpecFeather ("Specular Feather", Range(0, 1)) = 0.1
		_SpecPower ("Specular Intensity", Range(0, 1)) = 0.5
		_ReflPower ("Reflections Intensity", Range(0, 1)) = 0

		// Rendering
		[Enum(Opaque,0,Cutout,1,Fade,2,Transparent,3)] _Mode ("Render Mode", Int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blending Operation", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0
        [Enum(Off,0,Front,1,Back,2)] _CullMode ("Cull Mode", Float) = 0
		[Enum(Off,0,On,1)] _ZWrite("Z Write", Int) = 1

		// Advanced Rendering
		[IntRange] _Stencil ("Stencil ID (0-255)", Range(0,255)) = 0
		_ReadMask ("ReadMask (0-255)", Int) = 255
		_WriteMask ("WriteMask (0-255)", Int) = 255
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", Int) = 4
		[Enum(None,0,Alpha,1,Red,8,Green,4,Blue,2,RGB,14,RGBA,15)] _stencilcolormask("Color Mask", Int) = 15
        [Enum(UnityEngine.Rendering.BlendMode)] _ASrcBlend ("Alpha Source Blend", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _ADstBlend ("Alpha Destination Blend", Int) = 0
	}

	SubShader {
		Tags {
			"Queue" = "Geometry"
			"PreviewType" = "Sphere"
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

		Pass {
			Name "FORWARD"
            
            Blend [_SrcBlend] [_DstBlend], [_ASrcBlend] [_ADstBlend]
            ZWrite [_ZWrite]
            
			Tags {
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ALPHATEST_ON
			#pragma shader_feature _ALPHABLEND_ON
			#pragma shader_feature _ALPHAPREMULTIPLY_ON
			
            #define BASE_PASS
			#define COLOR_EFFECTS
			#define FAKE_LIGHT
            #include "../cginc/Effects.cginc"
            
			#pragma vertex vert
			#pragma fragment frag
            
			#pragma only_renderers d3d11 glcore gles
			#pragma target 4.0

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
            
			ENDCG
		}
        
        Pass {
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One, Zero One
			Fog { Color (0,0,0,0) } // in additive pass fog should be black
			ZWrite Off

			CGPROGRAM
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _ALPHATEST_ON
			#pragma shader_feature _ALPHABLEND_ON
			#pragma shader_feature _ALPHAPREMULTIPLY_ON
			
			#define ADD_PASS
			#define COLOR_EFFECTS
			#include "../cginc/Effects.cginc"
			
			#pragma vertex vert
			#pragma fragment frag

			#pragma only_renderers d3d11 glcore gles
			#pragma target 4.0

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
            
            ENDCG
        }
		
		Pass {
			Name "SHADOWCASTER"
			Tags {
				"LightMode" = "ShadowCaster"
			}
			
			CGPROGRAM
			
			#pragma target 3.0
			
			#pragma multi_compile_shadowcaster
			
            #pragma shader_feature _ALPHATEST_ON
			#pragma shader_feature _ALPHABLEND_ON
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "../cginc/ShadowCore.cginc"
			
			ENDCG
		}
	}
    
	FallBack "Diffuse"
	CustomEditor "Synergiance.Shaders.AckToon.BaseInspector"
}