// AckToon GUI

using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace Synergiance.Shaders.AckToon {
	public class BaseInspector : SynInspectorBase {
		
		protected override string version => "0.10b9";

		protected const string DEPRECATED_STR = "Deprecated, but let me know if this still helps some models";

		protected virtual bool hasEffects { get { return false; }}

		static string[] BlendPropNames = {"_SrcBlend", "_DstBlend", "_ASrcBlend", "_ADstBlend"};

		struct RenderingSettings {
			public int queue;
			public string renderType;
			public BlendMode srcBlend, dstBlend, srcAlphaBlend, dstAlphaBlend;
			public bool zWrite, premultiply;
			public float cutoff;

			public static RenderingSettings[] modes = {
				new RenderingSettings() {
					queue = (int)RenderQueue.Geometry,
					renderType = "",
					srcBlend = BlendMode.One,
					dstBlend = BlendMode.Zero,
					srcAlphaBlend = BlendMode.One,
					dstAlphaBlend = BlendMode.Zero,
					zWrite = true,
					premultiply = false,
					cutoff = 0.0f
				},
				new RenderingSettings() {
					queue = (int)RenderQueue.AlphaTest,
					renderType = "TransparentCutout",
					srcBlend = BlendMode.One,
					dstBlend = BlendMode.Zero,
					srcAlphaBlend = BlendMode.One,
					dstAlphaBlend = BlendMode.Zero,
					zWrite = true,
					premultiply = false,
					cutoff = 0.5f
				},
				new RenderingSettings() {
					queue = (int)RenderQueue.Transparent,
					renderType = "Transparent",
					srcBlend = BlendMode.SrcAlpha,
					dstBlend = BlendMode.One,
					srcAlphaBlend = BlendMode.Zero,
					dstAlphaBlend = BlendMode.One,
					zWrite = false,
					premultiply = false,
					cutoff = 0.01f
				},
				new RenderingSettings() {
					queue = (int)RenderQueue.Transparent - 400,
					renderType = "Transparent",
					srcBlend = BlendMode.One,
					dstBlend = BlendMode.OneMinusSrcAlpha,
					srcAlphaBlend = BlendMode.One,
					dstAlphaBlend = BlendMode.OneMinusSrcAlpha,
					zWrite = true,
					premultiply = true,
					cutoff = 0.01f
				}
			};
		}
		
		protected bool fMain = true, fToon = true, fOutline = true, fOpts = false, fRend = false, fAdvRend = false, fCols = false, fUtil = false, fEffects = false;

		protected bool hasCutoff = false;
		
		protected override void DoMain() {
			DoRenderMode();
			EditorGUILayout.Space();

			BoldFoldout(ref fMain, "Main Maps", DoMainMaps);
			BoldFoldout(ref fToon, "Toon Settings", DoToon);

			if (PropertyExists("_OutlineWidth")) BoldFoldout(ref fOutline, "Outline Settings", DoOutline);

			if (PropertyExists("_Speed") || PropertyExists("_Vivid")) BoldFoldout(ref fCols, "Color Options", () => {
				ShowPropertyIfExists("_Vivid");
				if (PropertyExists("_RainbowMask")) {
					MaterialProperty speedProp = FindProperty("_Speed");
					editor.TexturePropertySingleLine(MakeLabel(speedProp), FindProperty("_RainbowMask"), speedProp);
				} else {
					ShowPropertyIfExists("_Speed");
				}
			});

			if (hasEffects) BoldFoldout(ref fEffects, "Effects", DoEffects);

			AdditionalSettings();
			
			BoldFoldout(ref fOpts, "Options", DoOptions);
			BoldFoldout(ref fRend, "Blending Options", DoBlending);
			BoldFoldout(ref fAdvRend, "Advanced Options", DoAdvanced);
			BoldFoldout(ref fUtil, "Utilities", DoUtilities);
		}

		protected virtual void DoRenderMode() {
			EditorGUI.BeginChangeCheck();
			ShowPropertyIfExists("_Mode");
			if (EditorGUI.EndChangeCheck()) OnRenderModeChange();
		}

		protected virtual void DoMainMaps() {
			MaterialProperty mainTex = FindProperty("_MainTex");
			editor.TexturePropertySingleLine(MakeLabel("Main Texture", "Albedo (RGB), Alpha (A)"), mainTex, FindProperty("_Color"));
			ShaderProperty("_Cutoff");
			ShowPropertyIfExists("_VertexColors");
			DoSpecularMetallicArea();
			DoNormalArea();
			DoEmissionArea();
			editor.TextureScaleOffsetProperty(mainTex);
		}

		protected virtual void DoToon() {
			ShaderProperty("_ToonFeather", "Feather", "How soft the line between light and dark will be");
			ShaderProperty("_ToonCoverage", "Coverage", "How much of the model light should affect at one time");
			if (PropertyExists("_ShadeTex")) {
				editor.TexturePropertySingleLine(MakeLabel("Shade"), FindProperty("_ShadeTex"), FindProperty("_ToonColor"), FindProperty("_ShadeMode"));
			} else {
				ShaderProperty("_ToonColor", "Color", "Tint color for the shadowed areas");
			}
			ShaderProperty("_ToonIntensity", "Surface Intensity", "This will make the surface color more prominant in shadowed areas");
			ShaderProperty("_SpecFeather");
			ShaderProperty("_SpecPower");
		}

		protected virtual void DoOutline() {
			GUIContent colorText = MakeLabel("Outline Color", "Outline Color Tint (RGB)");
			GUIContent widthText = MakeLabel("Outline Width", "Outline Width (mm)");
			MaterialProperty widthProp = FindProperty("_OutlineWidth");
			MaterialProperty colorProp = FindProperty("_OutlineColor");
			MaterialProperty blendProp = FindProperty("_OutlineColorMode");
			if (PropertyExists("_OutlineMap")) {
				MaterialProperty colorMap = FindProperty("_OutlineMap");
				editor.TexturePropertySingleLine(colorText, colorMap, colorProp, blendProp);
				ShowPropertyIfExists("_OutlineMapCol");
			} else {
				ShaderProperty(colorProp, colorText);
				ShaderProperty(blendProp);
			}
			ShowPropertyIfExists("_OutlineAlpha");
			ShaderProperty(widthProp, widthText);
			ShaderProperty("_OutlineSpace");
			ShaderProperty("_OutlineScreen");
		}

		protected virtual void DoOptions() {
			ShaderProperty("_Exposure");
			ShaderProperty("_AmbDirection");
			ShaderProperty("_PointLightLitShade");
			ShaderProperty("_ToonAmb");
			ShowPropertyIfExists("_FakeLight", "Fake Light", "Promenance of the fake light.  Direction is based on fallback light direction.");
			ShowPropertyIfExists("_FakeLightCol", "Fake Light Color", "This is the color of the fake light when the promenance is at its highest");
			Vec3Prop(MakeLabel("Fallback Light Direction", "This is the direction the light will appear to come from when there is no directional light in the world."), FindProperty("_FallbackLightDir"));
			if (PropertyExists("_ReflPowerTex")) editor.TexturePropertySingleLine(MakeLabel("Reflections Intensity", "Reflections Intensity Texture (B)"), FindProperty("_ReflPowerTex"), FindProperty("_ReflPower"));
			else ShaderProperty("_ReflPower");
			if (PropertyExists("_ReflBackupCube")) editor.TexturePropertySingleLine(MakeLabel("Reflections Backup Map", "Use a bright cubemap for best appearance"), FindProperty("_ReflBackupCube"));
		}

		protected virtual void DoBlending() {
			editor.RenderQueueField();
			ShowPropertyIfExists("_BlendOp");
			ShowPropertyIfExists("_SrcBlend");
			ShowPropertyIfExists("_DstBlend");
			ShowPropertyIfExists("_CullMode");
			ShowPropertyIfExists("_ZWrite");
			ShowPropertyIfExists("_Premultiply", "Premultiply", "Causes reflections in low opacity areas to be much more prominant");
			EditorGUILayout.Space();
		}

		protected virtual void DoAdvanced() {
			ShowPropertyIfExists("_Stencil");
			ShowPropertyIfExists("_ReadMask");
			ShowPropertyIfExists("_WriteMask");
			ShowPropertyIfExists("_StencilComp");
			ShowPropertyIfExists("_StencilOp");
			ShowPropertyIfExists("_StencilFail");
			ShowPropertyIfExists("_StencilZFail");
			ShowPropertyIfExists("_ZTest");
			ShowPropertyIfExists("_stencilcolormask");
			ShowPropertyIfExists("_ASrcBlend");
			ShowPropertyIfExists("_ADstBlend");
			ShowPropertyIfExists("_AlphaToMask");
		}

		protected virtual void DoEffects() {}

		protected virtual void DoUtilities() {
			if (GUILayout.Button("Wipe Keywords")) foreach (var obj in editor.targets) {
				WipeKeywords((Material)obj);
				SetMaterialKeywords((Material)obj);
			}
		}
		
		protected void DoEmissionArea() {
			MaterialProperty emissionCol = FindProperty("_EmissionColor");
			MaterialProperty emissionTex = FindProperty("_EmissionMap");
			Color matCol = emissionCol.colorValue;
			HDRColorTextureProperty(MakeLabel("Emission", "Emission Texture (RGB)"), emissionTex, emissionCol, false);
			if (matCol.r > 0 || matCol.g > 0 || matCol.b > 0) {
				EditorGUI.indentLevel += 2;
				ShowPropertyIfExists("_EmissionFalloff");
				EditorGUI.indentLevel -= 2;
			}
		}

		protected void DoNormalArea() {
			MaterialProperty bumpMap = FindProperty("_BumpMap");
			editor.TexturePropertySingleLine(MakeLabel(bumpMap), bumpMap, bumpMap.textureValue != null ? FindProperty("_BumpScale") : null);
		}

		protected void DoSpecularMetallicArea() {
			bool hasGlossMap = false;
			MaterialProperty metallicMap = FindProperty("_MetallicGlossMap");
			hasGlossMap = metallicMap.textureValue != null;
			editor.TexturePropertySingleLine(MakeLabel("Metallic", "Metallic (R) and Smoothness (A)"), metallicMap, hasGlossMap ? null : FindProperty("_Metallic"));

			bool showSmoothnessScale = hasGlossMap;
			MaterialProperty smoothnessMapChannel = FindProperty("_SmoothnessTextureChannel");
			int smoothnessChannel = (int)smoothnessMapChannel.floatValue;
			if (smoothnessChannel == 1) // Alpha Channel
				showSmoothnessScale = true;
			
			
			int indentation = 2; // align with labels of texture properties
			editor.ShaderProperty(showSmoothnessScale ? FindProperty("_GlossMapScale") : FindProperty("_Glossiness"), showSmoothnessScale ? MakeLabel("Smoothness", "Smoothness scale factor") : MakeLabel("Smoothness", "Smoothness value"), indentation);

			++indentation;
			editor.ShaderProperty(smoothnessMapChannel, MakeLabel("Source", "Smoothness texture and channel"), indentation);
		}

		protected virtual void OnRenderModeChange() {
			RecordAction("Rendering Mode");
			RenderingSettings settings = RenderingSettings.modes[(int)FindProperty("_Mode").floatValue];
			foreach (Material m in editor.targets) {
				m.renderQueue = settings.queue;
				m.SetOverrideTag("RenderType", settings.renderType);
				SetIntIfExists("_SrcBlend", m, (int)settings.srcBlend);
				SetIntIfExists("_DstBlend", m, (int)settings.dstBlend);
				SetIntIfExists("_ASrcBlend", m, (int)settings.srcAlphaBlend);
				SetIntIfExists("_ADstBlend", m, (int)settings.dstAlphaBlend);
				m.SetInt("_ZWrite", settings.zWrite ? 1 : 0);
				m.SetInt("_Premultiply", settings.premultiply ? 1 : 0);
				m.SetFloat("_Cutoff", settings.cutoff);
				MaterialChanged(m);
			}
		}

		static bool CheckAlphaBlend(Material material) {
			bool blendsAlpha = false;
			foreach (string propName in BlendPropNames) {
				if (!material.HasProperty(propName)) continue;
				int i = material.GetInt(propName);
				if (i == 5 || i > 6) {
					blendsAlpha = true;
					break;
				}
			}
			return blendsAlpha;
		}
		
		static void SetMaterialKeywords(Material material) {
			Color matCol = material.GetColor("_EmissionColor");
			bool shouldEmissionBeEnabled = matCol.r > 0 || matCol.g > 0 || matCol.b > 0;
			SetKeyword(material, "_EMISSION", shouldEmissionBeEnabled);
			SetKeyword(material, "_NORMALMAP", material.GetTexture("_BumpMap") != null);

			// Render Mode Keywords
			SetKeyword(material, "_ALPHATEST_ON", material.GetFloat("_Cutoff") > 0);
			SetKeyword(material, "_ALPHABLEND_ON", CheckAlphaBlend(material));
			SetKeyword(material, "_ALPHAPREMULTIPLY_ON", material.GetInt("_Premultiply") == 1);
		}
		
		protected override void MaterialChanged(Material material) {
			SetMaterialKeywords(material);
		}

		protected virtual void AdditionalSettings() {}

		protected virtual void AdditionalOptions() {}
	}
}
