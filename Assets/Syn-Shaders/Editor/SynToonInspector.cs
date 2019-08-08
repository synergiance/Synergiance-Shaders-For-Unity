// Syn's MMD Toon Shader

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class SynToonInspector : ShaderGUI {
	
	static string version = "0.5.0b8";
    
	public enum OutlineMode {
        None, Artsy, Normal, Screenspace
    }
    
    public enum OutlineColorMode {
        Tinted, Colored
    }
    
    public enum ShadowMode {
        None, Tint, Toon, Texture, Multiple, Auto
    }
    
    public enum LightingHack {
        None, WorldPosition, WorldDirection, LocalDirection
    }
    
    public enum SphereMode {
        None, Add, Multiply, Multiple
    }
    
    public enum OverlayMode {
        None, PanoSphere, PanoScreen, UVScroll
    }
    
    public enum TransFix {
        None, Level1, Level2
    }
	
	/*
	enum sphereNumsSimple {
		"2x1", "2x2", "4x2", "4x4", "8x4", "8x8", "3x3", "6x3", "6x6", "5x5"
	}
	
	enum sphereNumsAdditional {
		2x1, 2x2, 4x2, 4x4, 8x4, 8x8, 3x3, 6x3, 6x6, 5x5, 3x2, 4x3, 5x4, 6x4, 6x5, 8x5, 8x6
	}
	
	static int[] sphereNums = {
		2, 4, 8, 16, 32, 64, 9, 18, 36, 25, 6, 12, 20, 24, 30, 40, 48
	}
	*/
	
	enum RenderingMode {
		Opaque, Cutout, Fade, Multiply, Alphablend, Custom, Refract
	}
	
	struct RenderingSettings {
		public BlendMode srcBlend, dstBlend;
		public BlendOp operation;
		public bool zWrite, showShadows, showCutoff, showOverride, showRefract, showTransFix, showCustom, showDither;
		
		public static RenderingSettings[] modes = {
			new RenderingSettings() {
				srcBlend = BlendMode.One,
				dstBlend = BlendMode.Zero,
				operation = BlendOp.Add,
				zWrite = true,
				showShadows = true,
				showCutoff = false,
				showOverride = false,
				showRefract = false,
				showTransFix = false,
				showCustom = false,
				showDither = false
			},
			new RenderingSettings() {
				srcBlend = BlendMode.One,
				dstBlend = BlendMode.Zero,
				operation = BlendOp.Add,
				zWrite = true,
				showShadows = true,
				showCutoff = true,
				showOverride = false,
				showRefract = false,
				showTransFix = false,
				showCustom = false,
				showDither = true
			},
			new RenderingSettings() {
				srcBlend = BlendMode.SrcAlpha,
				dstBlend = BlendMode.OneMinusSrcAlpha,
				operation = BlendOp.Add,
				zWrite = false,
				showShadows = false,
				showCutoff = true,
				showOverride = true,
				showRefract = false,
				showTransFix = true,
				showCustom = false,
				showDither = false
			},
			new RenderingSettings() {
				srcBlend = BlendMode.One,
				dstBlend = BlendMode.OneMinusSrcAlpha,
				operation = BlendOp.Add,
				zWrite = false,
				showShadows = false,
				showCutoff = true,
				showOverride = true,
				showRefract = false,
				showTransFix = true,
				showCustom = false,
				showDither = false
			},
			new RenderingSettings() {
				srcBlend = BlendMode.SrcAlpha,
				dstBlend = BlendMode.OneMinusSrcAlpha,
				operation = BlendOp.Add,
				zWrite = true,
				showShadows = false,
				showCutoff = true,
				showOverride = true,
				showRefract = false,
				showTransFix = true,
				showCustom = false,
				showDither = false
			},
			new RenderingSettings() {
				srcBlend = BlendMode.SrcAlpha,
				dstBlend = BlendMode.OneMinusSrcAlpha,
				operation = BlendOp.Add,
				zWrite = false,
				showShadows = false,
				showCutoff = true,
				showOverride = true,
				showRefract = false,
				showTransFix = true,
				showCustom = true,
				showDither = false
			},
			new RenderingSettings() {
				srcBlend = BlendMode.One,
				dstBlend = BlendMode.Zero,
				operation = BlendOp.Add,
				zWrite = true,
				showShadows = false,
				showCutoff = false,
				showOverride = true,
				showRefract = true,
				showTransFix = false,
				showCustom = false,
				showDither = false
			}
		};
	}
	
	Material target;
	MaterialEditor editor;
	MaterialProperty[] properties;
	RenderingSettings renderSettings;
	
	bool fMain = true, fOptions = false, fEffects = false, fAdvanced = false, fStencil = false, fCustom = false;
	
	static GUIContent staticLabel = new GUIContent();
	static ColorPickerHDRConfig emissionConfig = new ColorPickerHDRConfig(0f, 99f, 1f / 99f, 3f);
	
	static GUIContent MakeLabel(string text, string tooltip = null) {
		staticLabel.text = text;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}
	
	static GUIContent MakeLabel(MaterialProperty property, string tooltip = null) {
		staticLabel.text = property.displayName;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}
	
	bool BoldFoldout(bool foldout, GUIContent content) {
		GUIStyle BFstyle = EditorStyles.foldout;
		BFstyle.fontStyle = FontStyle.Bold;
		return EditorGUILayout.Foldout(foldout, content, BFstyle);
	}
	
	bool BoldFoldout(bool foldout, string content) {
		return BoldFoldout(foldout, MakeLabel(content));
	}
	
	MaterialProperty FindProperty(string name) {
		return FindProperty(name, properties);
	}
	
	void RecordAction(string label) {
		editor.RegisterPropertyChangeUndo(label);
	}
	
	bool IsKeywordEnabled(string keyword) {
		return target.IsKeywordEnabled(keyword);
	}
	
	void SetKeyword(string keyword, bool state) {
		if (state) {
			foreach (Material m in editor.targets) {
				m.EnableKeyword(keyword);
			}
		} else {
			foreach (Material m in editor.targets) {
				m.DisableKeyword(keyword);
			}
		}
	}
	
	bool KeywordToggle(string keyword, GUIContent display) {
		EditorGUI.BeginChangeCheck();
		bool state = EditorGUILayout.Toggle(display, IsKeywordEnabled(keyword));
		if (EditorGUI.EndChangeCheck()) SetKeyword(keyword, state);
		return state;
	}
	
	bool KeywordToggle(string keyword, string display) {
		return KeywordToggle(keyword, MakeLabel(display));
	}
	
	bool ReverseKeywordToggle(string keyword, GUIContent display) {
		EditorGUI.BeginChangeCheck();
		bool state = !EditorGUILayout.Toggle(display, !IsKeywordEnabled(keyword));
		if (EditorGUI.EndChangeCheck()) SetKeyword(keyword, state);
		return !state;
	}
	
	bool ReverseKeywordToggle(string keyword, string display) {
		return ReverseKeywordToggle(keyword, MakeLabel(display));
	}
	
	void ConvertKeyword(Material m, string keyword, string property, float setTo) {
		if (m.IsKeywordEnabled(keyword)) {
			m.DisableKeyword(keyword);
			m.SetFloat(property, setTo);
			editor.PropertiesChanged();
		}
	}
	
	void MakeGradientEditor(MaterialProperty property, GUIContent display) {
		//
	}
	
	void ShaderProperty(string enumName) {
		MaterialProperty enumProp = FindProperty(enumName);
		editor.ShaderProperty(enumProp, MakeLabel(enumProp));
	}
	
	void ShaderProperty(string enumName, string display) {
		editor.ShaderProperty(FindProperty(enumName), MakeLabel(display));
	}
	
	void ShaderProperty(string enumName, string display, string display2) {
		editor.ShaderProperty(FindProperty(enumName), MakeLabel(display, display2));
	}
	
	void Vec2Prop(string label, MaterialProperty prop1, MaterialProperty prop2) {
		Vec2Prop(MakeLabel(label), prop1, prop2);
	}
	
	void Vec2Prop(GUIContent label, MaterialProperty prop1, MaterialProperty prop2) {
		EditorGUI.BeginChangeCheck();
		EditorGUI.showMixedValue = prop1.hasMixedValue || prop2.hasMixedValue;
		Rect controlRect = EditorGUILayout.GetControlRect(true, MaterialEditor.GetDefaultPropertyHeight(prop1), EditorStyles.layerMaskField, new GUILayoutOption[0]);
		Vector2 vec2 = EditorGUI.Vector2Field(controlRect, label, new Vector2(prop1.floatValue, prop2.floatValue));
		EditorGUI.showMixedValue = false;
		if (EditorGUI.EndChangeCheck()) {
			prop1.floatValue = vec2.x;
			prop2.floatValue = vec2.y;
		}
	}
	
	void Vec3Prop(string label, MaterialProperty prop) {
		Vec3Prop(MakeLabel(label), prop);
	}
	
	void Vec3Prop(GUIContent label, MaterialProperty prop) {
		EditorGUI.BeginChangeCheck();
		EditorGUI.showMixedValue = prop.hasMixedValue;
		Rect controlRect = EditorGUILayout.GetControlRect(true, MaterialEditor.GetDefaultPropertyHeight(prop), EditorStyles.layerMaskField, new GUILayoutOption[0]);
		Vector3 vec3 = EditorGUI.Vector3Field(controlRect, label, new Vector3(prop.vectorValue.x, prop.vectorValue.y, prop.vectorValue.z));
		EditorGUI.showMixedValue = false;
		if (EditorGUI.EndChangeCheck()) prop.vectorValue = new Vector4(vec3.x, vec3.y, vec3.z, prop.vectorValue.w);
	}
	
	static bool ToonRampTextureNeedsFixing(MaterialProperty prop) {
		if (prop.type != MaterialProperty.PropType.Texture) return false;
		
		foreach (Material m in prop.targets) {
			Texture tex = m.GetTexture(prop.name);
			if (tex != null && (tex.wrapModeU != TextureWrapMode.Clamp || tex.wrapModeV != TextureWrapMode.Clamp)) return true;
		}

		return false;
	}
	
	/*
	static void FixToonRampTexture(MaterialProperty prop) {
		foreach (Material m in prop.targets)
			m.GetTexture(prop.name).wrapMode = TextureWrapMode.Clamp;
	}
	*/
	
	public void ToonRampClampWarning(MaterialProperty prop) {
		if (ToonRampTextureNeedsFixing(prop)) {
			EditorGUILayout.HelpBox("Set your texture's wrapping mode to clamp to get rid of glitches", MessageType.Warning);
			/*
			if (editor.HelpBoxWithButton(MakeLabel("This texture's wrap mode is not set to Clamp"), MakeLabel("Fix Now"))) {
				FixToonRampTexture(prop);
			}
			*/
		}
	}
	
	void SanitizeKeywords() {
		foreach (Material m in editor.targets) {
			RemoveKeywords(m);
			ConvertKeywords(m);
		}
	}
	
	void RemoveKeywords(Material m) {
		m.DisableKeyword("NO_SHADOW");
		m.DisableKeyword("TINTED_SHADOW");
		m.DisableKeyword("RAMP_SHADOW");
		m.DisableKeyword("NO_SPHERE");
		m.DisableKeyword("ADD_SPHERE");
		m.DisableKeyword("MUL_SPHERE");
		m.DisableKeyword("NORMAL_LIGHTING");
		m.DisableKeyword("WORLD_STATIC_LIGHT");
		m.DisableKeyword("LOCAL_STATIC_LIGHT");
		m.DisableKeyword("ALLOWOVERBRIGHT");
		m.DisableKeyword("GAMMACORRECT");
		m.DisableKeyword("TINTED_OUTLINE");
		m.DisableKeyword("COLORED_OUTLINE");
		m.DisableKeyword("ARTSY_OUTLINE");
		m.DisableKeyword("OUTSIDE_OUTLINE");
		m.DisableKeyword("SCREENSPACE_OUTLINE");
		m.DisableKeyword("BCKFCECULL");
		m.DisableKeyword("DISABLE_SHADOW");
	}
	
	void ConvertKeywords(Material m) {
		ConvertKeyword(m, "RAINBOW", "_Rainbowing", 1);
		ConvertKeyword(m, "PULSE", "_PulseEmission", 1);
		ConvertKeyword(m, "SHADEEMISSION", "_ShadeEmission", 1);
		ConvertKeyword(m, "SLEEPEMISSION", "_SleepEmission", 1);
		ConvertKeyword(m, "HUESHIFTMODE", "_HueShiftMode", 1);
		ConvertKeyword(m, "OVERRIDE_REALTIME", "_OverrideRealtime", 1);
		ConvertKeyword(m, "PANOOVERLAY", "_PanoUseOverlay", 1);
		ConvertKeyword(m, "PANOALPHA", "_PanoUseAlpha", 1);
	}
	
	public override void OnGUI(MaterialEditor editor, MaterialProperty[] properties) {
		this.target = editor.target as Material;
		this.editor = editor;
		this.properties = properties;
		SanitizeKeywords();
		DoRenderingMode();
		DoMain();
		//DoSecondary();
		DoOptions();
		DoEffects();
		DoAdvanced();
		DoStencil();
		if (renderSettings.showCustom) DoCustom();
		EditorGUILayout.Space();
		GUILayout.Label("Version: " + version);
	}
	
	void DoRenderingMode() {
		MaterialProperty blendMode = FindProperty("_Mode");
		EditorGUI.showMixedValue = blendMode.hasMixedValue;
		RenderingMode mode = (RenderingMode)blendMode.floatValue;
		
		EditorGUI.BeginChangeCheck();
		mode = (RenderingMode)EditorGUILayout.EnumPopup(MakeLabel("Rendering Mode"), mode);
		renderSettings = RenderingSettings.modes[(int)mode];
		if (EditorGUI.EndChangeCheck()) {
			RecordAction("Rendering Mode");
			SetKeyword("_ALPHATEST_ON", mode == RenderingMode.Cutout);
			blendMode.floatValue = (float)mode;
			
			foreach (Material m in editor.targets) {
				m.SetInt("_SrcBlend", (int)renderSettings.srcBlend);
				m.SetInt("_DstBlend", (int)renderSettings.dstBlend);
				m.SetInt("_BlendOp", (int)renderSettings.operation);
				m.SetInt("_ZWrite", renderSettings.zWrite ? 1 : 0);
				SetupMaterialShaderSelect(m);
			}
		}
		
		EditorGUI.showMixedValue = false;
	}
	
	void DoMain() {
		fMain = BoldFoldout(fMain, "Main Maps");
		
		if (fMain) {
			MaterialProperty mainTex = FindProperty("_MainTex");
			editor.TexturePropertySingleLine(MakeLabel(mainTex, "Main Color Texture (RGB)"), mainTex, FindProperty("_Color"));
			EditorGUI.indentLevel += 2;
			if (renderSettings.showCutoff) DoAlphaCutoff();
			if (renderSettings.showOverride) DoAlphaOverride();
			if (renderSettings.showDither) DoDithering();
			if (renderSettings.showRefract) DoRefract();
			DoColorMask();
			EditorGUI.indentLevel -= 2;
			//DoMetallic();
			//DoSmoothness();
			DoNormals();
			DoOcclusion();
			DoSpecular();
			DoEmission();
			//DoDetailMask();
			editor.TextureScaleOffsetProperty(mainTex);
			DoBrightnessSaturation();
		}
	}
	
	void DoSecondary() {
		GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);
	}
	
	void DoOptions() {
		EditorGUILayout.Space();
		fOptions = BoldFoldout(fOptions, "Options");
		
		if (fOptions) {
			DoShadows();
			EditorGUILayout.Space();
			DoOutline();
			EditorGUILayout.Space();
			DoSpheres();
		}
	}
	
	void DoEffects() {
		EditorGUILayout.Space();
		fEffects = BoldFoldout(fEffects, "Effects");
		
		if (fEffects) {
			DoPano();
			EditorGUILayout.Space();
			DoRainbow();
			EditorGUILayout.Space();
			DoSubsurface();
		}
	}
	
	void DoAdvanced() {
		EditorGUILayout.Space();
		fAdvanced = BoldFoldout(fAdvanced, "Advanced Options");
		
		if (fAdvanced) {
			editor.RenderQueueField();
			DoDoubleSided();
			DoTransFix();
			DoLightingHack();
			DoReflectionProbes();
			DoCastShadows();
			
			ShaderProperty("_HueShiftMode", "HSB mode", "This will make it so you can change the color of your material completely, but any color variation will be lost");
			ShaderProperty("_OverbrightProtection", "Overbright Protection", "Protects against overbright worlds");
			ShaderProperty("_CorrectionLevel", "Gamma Correction", "Use if your colors seem washed out, or your blacks appear gray.");
			
			DoBatchDisable();
		}
	}
	
	void DoAlphaCutoff() {
		ShaderProperty("_Cutoff", "Alpha Cutoff", "Material will clip here.  Drag to the left if you're losing detail.  Recommended value for alphablend: 0.1");
	}
	
	void DoAlphaOverride() {
		ShaderProperty("_AlphaOverride", "Alpha Override", "Overrides a texture's alpha (useful for very faint textures)");
	}
	
	void DoDithering() {
		ShaderProperty("_Dither", "Dithering", "Use dithering transparency.  Use Cutoff slider to set cutoff point as usual");
	}
	
	void DoRefract() {
		ShaderProperty("_IndexofRefraction", "Index of Refraction", "How much to refract everything behind");
		ShaderProperty("_ChromaticAberration", "Chromatic Abberation", "Strength of chromatic abberation effect");
	}
	
	void DoColorMask() {
		editor.TexturePropertySingleLine(MakeLabel("Color Mask", "Masks Color Tinting (B)"), FindProperty("_ColorMask"));
	}
	
	void DoNormals() {
		MaterialProperty map = FindProperty("_BumpMap");
		Texture tex = map.textureValue;
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertySingleLine(MakeLabel("Normal Map"), map, /*tex ? FindProperty("_BumpScale") :*/ null);
		/*
		if (EditorGUI.EndChangeCheck() && tex != map.textureValue) {
			SetKeyword("_NORMAL_MAP", map.textureValue);
		}
		*/
	}
	
	void DoRainbow() {
		MaterialProperty rainbowing = FindProperty("_Rainbowing");
		editor.ShaderProperty(rainbowing, MakeLabel("Color Change", "Color changing"));
		if (rainbowing.floatValue >= 1) {
			//MaterialProperty colChangeMode = FindProperty("_ColChangeMode");
			MaterialProperty colChangeEffect = FindProperty("_ColChangeEffect");
			MaterialProperty colChangeGeomEffect = FindProperty("_ColChangeGeomEffect");
			MaterialProperty colChangeSteps = FindProperty("_ColChangeSteps");
			MaterialProperty rainbowMask = FindProperty("_RainbowMask");
			if (colChangeGeomEffect.floatValue == 0) {
				editor.TexturePropertySingleLine(MakeLabel("Color Change Speed", "Color Change Mask (RGB) with Speed Setting"), rainbowMask, FindProperty("_Speed"));
				EditorGUI.indentLevel += 2;
			} else {
				EditorGUI.indentLevel += 2;
				ShaderProperty("_Speed", "Color Change Speed");
			}
			editor.ShaderProperty(colChangeSteps, MakeLabel("Steps", "Number of steps, 0 is smooth"));
			editor.ShaderProperty(colChangeMode, MakeLabel("Color Mode"));
			if (colChangeSteps.floatValue > 0) {
				editor.ShaderProperty(colChangeEffect, MakeLabel("Color Effect"));
				if (!rainbowMask.textureValue) editor.ShaderProperty(colChangeGeomEffect, MakeLabel("Geometry Effect"));
				if (colChangeEffect.floatValue > 0 || colChangeGeomEffect.floatValue > 0) {
					EditorGUILayout.HelpBox("Color change effects are currently incomplete.  They will function, but will be improved in a later version.", MessageType.Info);
					ShaderProperty("_ColChangePercent", "Change Time", "Time it takes to change color in percent, whether its a color effect or geometry effect");
				}
				if (colChangeEffect.floatValue == 2) ShaderProperty("_ColChangeColor", "Color");
			}
			ShaderProperty("_ColChangeDirection", "Direction", "The direction that the wave will occur");
			colChangeMode.floatValue = 0;
			if (colChangeMode.floatValue == 1) {
				MaterialProperty colChangeCustomRamp = FindProperty("_ColChangeCustomRamp");
				editor.ShaderProperty(colChangeCustomRamp, MakeLabel("Custom Ramp Texture", "Use a texture instead of the gradient editor"));
				if (colChangeCustomRamp.floatValue == 1) editor.TexturePropertySingleLine(MakeLabel("Ramp Texture"), FindProperty("_ColChangeRamp"));
				else MakeGradientEditor(FindProperty("_ColChangeRamp"), MakeLabel("Ramp Gradient"));
			}
			EditorGUI.indentLevel -= 2;
		}
	}
	
	void DoEmission() {
		MaterialProperty map = FindProperty("_EmissionMap");
		Texture tex = map.textureValue;
		//EditorGUI.BeginChangeCheck();
		editor.TexturePropertyWithHDRColor(MakeLabel("Emission", "Emission (RGB)"), map, FindProperty("_EmissionColor"), emissionConfig, false);
		MaterialProperty pulse = FindProperty("_PulseEmission");
		if (pulse.floatValue == 1) editor.TexturePropertySingleLine(MakeLabel("Emission Pulse", "Emission Pulse (RGB) and Pulse Speed"), FindProperty("_EmissionPulseMap"), FindProperty("_EmissionPulseColor"), FindProperty("_EmissionSpeed"));
		EditorGUI.indentLevel += 2;
		ShaderProperty("_PulseEmission", "Pulse Emission");
		ShaderProperty("_ShadeEmission", "Shaded Emission");
		ShaderProperty("_SleepEmission", "Sleep Emission");
		EditorGUI.indentLevel -= 2;
		/*
		if (EditorGUI.EndChangeCheck() && tex != map.textureValue) {
			SetKeyword("_EMISSION_MAP", map.textureValue);
		}
		*/
	}
	
	void DoOcclusion() {
		MaterialProperty map = FindProperty("_OcclusionMap");
		Texture tex = map.textureValue;
		//EditorGUI.BeginChangeCheck();
		editor.TexturePropertySingleLine(MakeLabel(map, "Occlusion (G)"), map, /*tex ? FindProperty("_OcclusionStrength") :*/ null);
		/*
		if (EditorGUI.EndChangeCheck() && tex != map.textureValue) {
			SetKeyword("_OCCLUSION_MAP", map.textureValue);
		}
		*/
	}
	
	void DoSpecular() {
		editor.TexturePropertySingleLine(MakeLabel("Specular", "Specular Map (RGB) with Specular Power"), FindProperty("_SpecularMap"), FindProperty("_SpecularColor"), FindProperty("_SpecularPower"));
	}
	
	void DoBrightnessSaturation() {
		ShaderProperty("_Brightness", "Brightness", "How much light gets to your model.  This can have a better effect than darkening the color");
		ShaderProperty("_SaturationBoost", "Saturation Boost", "This will boost the saturation, don't turn it up too high unless you know what you're doing");
	}
	
	void DoShadows() {
		MaterialProperty shadowMode = FindProperty("_ShadowMode");
		ShadowMode sMode = (ShadowMode)shadowMode.floatValue;

		EditorGUI.BeginChangeCheck();
		sMode = (ShadowMode)EditorGUILayout.EnumPopup(MakeLabel("Shadow Mode"), sMode);
		
		if (EditorGUI.EndChangeCheck())
		{
			RecordAction("Shadow Mode");
			shadowMode.floatValue = (float)sMode;

		}
		EditorGUI.indentLevel += 2;
		switch (sMode)
		{
			case ShadowMode.Tint:
				DoShadowTint();
				break;
			case ShadowMode.Toon:
				DoShadowToon();
				break;
			case ShadowMode.Texture:
				DoShadowTexture();
				break;
			case ShadowMode.Multiple:
				DoShadowMultiple();
				break;
			case ShadowMode.Auto:
				DoShadowAuto();
				break;
			case ShadowMode.None:
			default:
				break;
		}
		EditorGUI.indentLevel -= 2;
	}
	
	void DoShadowTint() {
		ShaderProperty("_shadow_coverage", "Coverage", "How much of your character is shadowed? I'd recommend somewhere between 0.5 for crisp toons and 0.65 for smooth shading");
		ShaderProperty("_shadow_feather", "Blur", "Slide to the left for crisp toons, to the right for smooth shading");
		ShaderProperty("_ShadowTint", "Tint Color", "This will tint your shadows, try pinkish colors for skin");
	}
	
	void DoShadowToon() {
		MaterialProperty ramp = FindProperty("_ShadowRamp");
		EditorGUI.indentLevel -= 2;
		editor.TexturePropertySingleLine(MakeLabel("Toon Texture", "(RGBA) Vertical or horizontal. Bottom and left are dark"), ramp);
		ToonRampClampWarning(ramp);
		EditorGUI.indentLevel += 2;
	}
	
	void DoShadowTexture() {
		ShaderProperty("_shadow_coverage", "Coverage", "How much of your character is shadowed? I'd recommend somewhere between 0.5 for crisp toons and 0.65 for smooth shading");
		ShaderProperty("_shadow_feather", "Blur", "Slide to the left for crisp toons, to the right for smooth shading");
		EditorGUI.indentLevel -= 2;
		editor.TexturePropertySingleLine(MakeLabel("Shadow Texture", "(RGB) This is what your model will look like with only ambient light"), FindProperty("_ShadowTexture"), FindProperty("_ShadowUV"));
		EditorGUI.indentLevel += 2;
		ShaderProperty("_ShadowTextureMode");
	}
	
	void DoShadowMultiple() {
		MaterialProperty ramp = FindProperty("_ShadowRamp");
		EditorGUI.indentLevel -= 2;
		editor.TexturePropertySingleLine(MakeLabel("Toon Texture", "(RGBA) Vertical or horizontal, specify below. Bottom or left are dark"), ramp);
		ToonRampClampWarning(ramp);
		EditorGUI.indentLevel += 2;
		ShaderProperty("_ShadowRampDirection");
		EditorGUI.indentLevel -= 2;
		editor.TexturePropertySingleLine(MakeLabel("Shadow Texture", "(RGB) This is an atlas for what toon ramp to use"), FindProperty("_ShadowTexture"), FindProperty("_ShadowUV"));
		EditorGUI.indentLevel += 2;
	}
	
	void DoShadowAuto() {
		ShaderProperty("_shadow_coverage", "Coverage", "How much of your character is shadowed? I'd recommend somewhere between 0.5 for crisp toons and 0.65 for smooth shading");
		ShaderProperty("_shadow_feather", "Blur", "Slide to the left for crisp toons, to the right for smooth shading");
		ShaderProperty("_ShadowIntensity", "Intensity", "Slide to the right to make shadows more noticeable");
		ShaderProperty("_ShadowAmbient", "Ambient Light", "Slide to the left for shadow light, to the right for direct light");
		ShaderProperty("_ShadowTint", "Ambiant Color", "This is the ambient light tint, use it lightly");
	}
	
	void DoOutline() {
		MaterialProperty outlineMode = FindProperty("_OutlineMode");
		OutlineMode oMode = (OutlineMode)outlineMode.floatValue;

		EditorGUI.BeginChangeCheck();
		oMode = (OutlineMode)EditorGUILayout.EnumPopup(MakeLabel("Outline Mode"), oMode);
		
		if (EditorGUI.EndChangeCheck())
		{
			RecordAction("Outline Mode");
			outlineMode.floatValue = (float)oMode;
			
			foreach (var obj in outlineMode.targets)
			{
				SetupMaterialShaderSelect((Material)obj);
			}
		}
		EditorGUI.indentLevel += 2;
		switch (oMode)
		{
			case OutlineMode.Artsy:
				DoOutlineArtsy();
				break;
			case OutlineMode.Normal:
			case OutlineMode.Screenspace:
				DoOutlineNormal();
				break;
			case OutlineMode.None:
			default:
				break;
		}
		EditorGUI.indentLevel -= 2;
	}
	
	void DoOutlineArtsy() {
		DoOutlineNormal();
		ShaderProperty("_outline_feather", "Blur", "Smoothness of the outline. You can go from very crisp to very blurry");
		EditorGUILayout.HelpBox("This mode may or may not look good on your model.  Try \"Normal\" or \"Screenspace\" if this doesn't look the way you want it to.", MessageType.Info);
	}
	
	void DoOutlineNormal() {
		MaterialProperty outlineColorMode = FindProperty("_OutlineColorMode");
		OutlineColorMode ocMode = (OutlineColorMode)outlineColorMode.floatValue;
		EditorGUI.BeginChangeCheck();
		ocMode = (OutlineColorMode)EditorGUILayout.EnumPopup(MakeLabel("Color Mode"), ocMode);
		if (EditorGUI.EndChangeCheck()) {
			RecordAction("Color Mode");
			outlineColorMode.floatValue = (float)ocMode;
		}
		EditorGUI.indentLevel -= 2;
		editor.TexturePropertySingleLine(MakeLabel("Color", "This is the color of the outline"), FindProperty("_outline_tex"), FindProperty("_outline_color"));
		EditorGUI.indentLevel += 2;
		ShaderProperty("_outline_width", "Width", "This is the width of the outline");
	}
	
	void DoSpheres() {
		MaterialProperty sphereMode = FindProperty("_SphereMode");
		SphereMode sphMode = (SphereMode)sphereMode.floatValue;

		EditorGUI.BeginChangeCheck();
		sphMode = (SphereMode)EditorGUILayout.EnumPopup(MakeLabel("Sphere Mode"), sphMode);
		
		if (EditorGUI.EndChangeCheck())
		{
			RecordAction("Sphere Mode");
			sphereMode.floatValue = (float)sphMode;

		}
		switch (sphMode)
		{
			case SphereMode.Add:
				DoSphereAdd();
				break;
			case SphereMode.Multiply:
				DoSphereMultiply();
				break;
			case SphereMode.Multiple:
				DoSphereMultiple();
				break;
			case SphereMode.None:
			default:
				break;
		}
	}
	
	void DoSphereAdd() {
		editor.TexturePropertySingleLine(MakeLabel("Sphere Texture", "Sphere Texture (RGB Additive Shine)"), FindProperty("_SphereAddTex"));
	}
	
	void DoSphereMultiply() {
		editor.TexturePropertySingleLine(MakeLabel("Sphere Texture", "Sphere Texture (RGB Multiplied Metallic)"), FindProperty("_SphereMulTex"));
	}
	
	void DoSphereMultiple() {
		editor.TexturePropertySingleLine(MakeLabel("Sphere Textures", "Sphere Texture (RGB Map) with Layout"), FindProperty("_SphereMultiTex"), FindProperty("_SphereNum"));
		editor.TexturePropertySingleLine(MakeLabel("Sphere Atlas", "Sphere Atlas (RG Sphere Select XY, B Metallic)"), FindProperty("_SphereAtlas"), FindProperty("_SphereUV"));
	}
	
	void DoPano() {
		MaterialProperty panoSphereMode = FindProperty("_OverlayMode");
		OverlayMode panoMode = (OverlayMode)panoSphereMode.floatValue;

		EditorGUI.BeginChangeCheck();
		panoMode = (OverlayMode)EditorGUILayout.EnumPopup(MakeLabel("Overlay Mode"), panoMode);
		
		if (EditorGUI.EndChangeCheck())
		{
			RecordAction("Overlay Mode");
			panoSphereMode.floatValue = (float)panoMode;
		}
		switch (panoMode)
		{
			case OverlayMode.PanoSphere:
				DoPanoSphere();
				break;
			case OverlayMode.PanoScreen:
				DoPanoScreen();
				break;
			case OverlayMode.UVScroll:
				DoUVScroll();
				break;
			case OverlayMode.None:
			default:
				break;
		}
	}
	
	void DoPanoSphere() {
		DoPanoTransform("Rotation", "Rotate", "Overlay Texture (Directional Panosphere Mode)", "_PanoSphereTex");
		DoOverlayMode("Overlay", "Use an overlay for the panosphere");
	}
	
	void DoPanoScreen() {
		DoPanoTransform("Scroll", "Scroll", "Overlay Texture (Screen Positional Panosphere Mode)", "_PanoFlatTex");
		DoOverlayMode("Static Overlay", "Use an additional static overlay");
		EditorGUILayout.HelpBox("This section will work now, but isn't fully tested.  Please report any bugs to me (Synergiance) in the discord for this shader (https://discord.gg/rvpGU5E) under #bug-reports.", MessageType.Info);
	}
	
	void DoUVScroll() {
		DoPanoTransform("Scroll", "Scroll", "Overlay Texture (UV Scrolling Mode)", "_PanoFlatTex");
		DoOverlayMode("Static Overlay", "Use an additional static overlay");
	}
	
	void DoPanoTransform(string op1, string op2, string flavor, string prop) {
		editor.TexturePropertySingleLine(MakeLabel("Overlay Texture", flavor), FindProperty(prop), FindProperty("_OverlayBlendMode"));
		EditorGUI.indentLevel += 2;
		ShaderProperty("_PanoBlend", "Blend", "Mix between normal albedo and Overlay");
		/*if (FindProperty("_EmissionMap").textureValue)*/ ShaderProperty("_PanoEmission", "Apply to Emission", "Apply this pano effect to the emission");
		Vec2Prop(MakeLabel(op1 + " Speed", op2 + " the overlay texture (Set to 0 to turn off)"), FindProperty("_PanoRotationSpeedX"), FindProperty("_PanoRotationSpeedY"));
		EditorGUI.indentLevel -= 2;
	}
	
	void DoOverlayMode(string display, string tip) {
		EditorGUI.indentLevel += 2;
		MaterialProperty panoOverlay = FindProperty("_PanoUseOverlay");
		editor.ShaderProperty(panoOverlay, MakeLabel(display, tip));
		EditorGUI.indentLevel -= 2;
		if (panoOverlay.floatValue == 1) {
			editor.TexturePropertySingleLine(MakeLabel("Texture", "Static Overlay"), FindProperty("_PanoOverlayTex"));
			EditorGUI.indentLevel += 2;
			ShaderProperty("_PanoUseAlpha", "Use Alpha Channel", "Blending for the panosphere overlay, unchecked is add, checked is alpha");
			EditorGUI.indentLevel -= 2;
		}
	}
	
	void DoDoubleSided() {
		MaterialProperty cullMode = FindProperty("_CullMode");
		UnityEngine.Rendering.CullMode cMode = (UnityEngine.Rendering.CullMode)cullMode.floatValue;
		EditorGUI.BeginChangeCheck();
		cMode = (UnityEngine.Rendering.CullMode)EditorGUILayout.EnumPopup(MakeLabel(cullMode, "Set this to Back if you don't want this material to be double sided"), cMode);
		if (EditorGUI.EndChangeCheck()) {
			RecordAction("Cull Mode");
			cullMode.floatValue = (float)cMode;
			
			foreach (Material mat in editor.targets) {
				SetupMaterialShaderSelect((Material)mat);
			}
		}
		if (cullMode.floatValue == 0) {
			ShaderProperty("_FlipBackfaceNorms");
			ShaderProperty("_BackFaceTint", "Backface Shade", "Set amount of shade the back face of this material receives.");
		} else if (cullMode.floatValue == 2) {
			GUI.enabled = false;
			EditorGUILayout.Toggle(MakeLabel(FindProperty("_FlipBackfaceNorms")), false);
			ShaderProperty("_BackFaceTint", "Backface Shade", "Set amount of shade the back face of this material receives.");
		} else {
			GUI.enabled = false;
			EditorGUILayout.Toggle(MakeLabel(FindProperty("_FlipBackfaceNorms")), true);
			ShaderProperty("_BackFaceTint", "Backface Shade", "Set amount of shade the back face of this material receives.");
		}
		GUI.enabled = true;
	}
	
	void DoTransFix() {
		MaterialProperty transFix = FindProperty("_TransFix");
		TransFix tFix = (TransFix)transFix.floatValue;
		if (renderSettings.showTransFix) {
			EditorGUI.BeginChangeCheck();
			tFix = (TransFix)EditorGUILayout.EnumPopup(MakeLabel("Transparent Fix"), tFix);
			if (EditorGUI.EndChangeCheck())
			{
				editor.RegisterPropertyChangeUndo("Transparent Fix");
				transFix.floatValue = (float)tFix;
				
				foreach (var obj in transFix.targets)
				{
					SetupMaterialShaderSelect((Material)obj);
				}
			}
		} else {
			GUI.enabled = false;
			EditorGUILayout.EnumPopup(MakeLabel("Transparent Fix"), tFix);
			GUI.enabled = true;
		}
	}
	
	void DoLightingHack() {
		MaterialProperty lightingHack = FindProperty("_LightingHack");
		LightingHack lHack = (LightingHack)lightingHack.floatValue;

		EditorGUI.BeginChangeCheck();
		lHack = (LightingHack)EditorGUILayout.EnumPopup(MakeLabel("Static Light"), lHack);
		
		if (EditorGUI.EndChangeCheck())
		{
			RecordAction("Static Light");
			lightingHack.floatValue = (float)lHack;
		}
		switch (lHack)
		{
			case LightingHack.WorldPosition:
			case LightingHack.WorldDirection:
			case LightingHack.LocalDirection:
				EditorGUI.indentLevel += 2;
				ShaderProperty("_OverrideRealtime", "Override All", "Override All lights not just directionless lights");
				Vec3Prop(MakeLabel("Light Coordinate", "Static World Light Position"), FindProperty("_StaticToonLight"));
				EditorGUI.indentLevel -= 2;
				break;
			case LightingHack.None:
			default:
				break;
		}
		MaterialProperty unlit = FindProperty("_Unlit");
		editor.ShaderProperty(unlit, MakeLabel("Light Mode", "Choose whether light affects this material"));
		GUI.enabled = (unlit.floatValue != 1);
		ShaderProperty("_LightColor", "Light Color", "Light will become this color depending on the slider below");
		ShaderProperty("_LightOverride", "Light Override", "Turn this slider to the right to use the color above");
		GUI.enabled = true;
	}
	
	void DoReflectionProbes() {
		ShaderProperty("_ProbeStrength", "Probe Strength", "Strength of reflection probes on this material");
		if (target.GetFloat("_ProbeStrength") > 0) {
			EditorGUI.indentLevel += 1;
			ShaderProperty("_ProbeClarity", "Probe Clarity", "Clarity of reflection probes on this material");
			EditorGUI.indentLevel -= 1;
		}
	}
	
	void DoCastShadows() {
		if (renderSettings.showShadows) {
			ShaderProperty("_shadowcast_intensity", "Shadow Intensity", "This is how much other objects affect your shadow");
		} else {
			GUI.enabled = false;
			ShaderProperty("_shadowcast_intensity", "Shadow Intensity", "This is how much other objects affect your shadow");
			GUI.enabled = true;
		}
	}
	
	void DoSubsurface() {
		MaterialProperty intensity = FindProperty("_SSIntensity");
		if (intensity.floatValue > 0) {
			editor.TexturePropertySingleLine(MakeLabel("Subsurface Scattering", "Subsurface scattering intensity.  Use thickness map to the left to control local scattering intensity."), FindProperty("_SSThickness"), intensity);
			EditorGUI.indentLevel += 2;
			ShaderProperty("_SSDistortion", "Distortion", "Light distortion for subsurface scattering effect.");
			ShaderProperty("_SSPower", "Power", "How wide is the effect");
			EditorGUI.indentLevel -= 2;
			editor.TexturePropertySingleLine(MakeLabel("Subsurface Tint", "Tints the light in the subsurface."), FindProperty("_SSTintMap"), FindProperty("_SSTint"));
		} else {
			editor.ShaderProperty(intensity, MakeLabel("Subsurface Scattering", "Subsurface scattering intensity.  Drag right to reveal more options"));
		}
	}
	
	void DoBatchDisable() {
		bool batchDisable = target.GetFloat("_DisableBatching") > 0;
		EditorGUI.BeginChangeCheck();
		batchDisable = EditorGUILayout.Toggle(MakeLabel("Disable Batching", "Enable this if you have batching problems"), batchDisable);
		if (EditorGUI.EndChangeCheck())
		{
			if (batchDisable)
			{
				target.SetInt("_DisableBatching", 1);
				target.SetOverrideTag("DisableBatching", "True");
			}
			else
			{
				target.SetInt("_DisableBatching", 0);
				target.SetOverrideTag("DisableBatching", "False");
			}
		}
	}
	
	void DoStencil() {
		EditorGUILayout.Space();
		fStencil = BoldFoldout(fStencil, "Stencil Options");
		
		if (fStencil) {
			ShaderProperty("_stencilcolormask");
			ShaderProperty("_Stencil");
			ShaderProperty("_StencilComp");
			ShaderProperty("_StencilOp");
			ShaderProperty("_StencilFail");
			ShaderProperty("_StencilZFail");
			ShaderProperty("_ZTest");
			ShaderProperty("_ZWrite");
		}
	}
	
	void DoCustom() {
		EditorGUILayout.Space();
		fCustom = BoldFoldout(fCustom, "Blending Options");
		
		if (fCustom) {
			ShaderProperty("_SrcBlend");
			ShaderProperty("_DstBlend");
			ShaderProperty("_BlendOp");
		}
	}

    void SetupMaterialShaderSelect(Material material)
    {
        bool doubleSided = material.GetFloat("_CullMode") == 0;
		string shaderName = "Synergiance/Toon";
        float transFix = (float)material.GetFloat("_TransFix");
        switch ((OutlineMode)material.GetFloat("_OutlineMode"))
        {
            case OutlineMode.Normal:
            case OutlineMode.Screenspace:
                shaderName += "-Outline";
                break;
            default:
                break;
        }
        switch ((RenderingMode)material.GetFloat("_Mode"))
        {
            case RenderingMode.Cutout:
                shaderName += "/Cutout";
                break;
            case RenderingMode.Fade:
            case RenderingMode.Multiply:
            case RenderingMode.Alphablend:
            case RenderingMode.Custom:
                shaderName += "/Transparent";
                if (transFix > 0) shaderName += "Fix";
                if (transFix > 1) shaderName += "2";
                if (doubleSided) shaderName += "DS";
                break;
            case RenderingMode.Refract:
                shaderName += "/Refraction";
                break;
            default:
                break;
        }
        material.shader = Shader.Find(shaderName);
    }
}