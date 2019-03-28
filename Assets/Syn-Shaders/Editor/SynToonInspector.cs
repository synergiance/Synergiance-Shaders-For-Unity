// Syn's MMD Toon Shader

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class SynToonInspector : ShaderGUI {
	
	static string version = "0.4.4.2";
    
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
        None, World, Local
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
	
	enum RenderingMode {
		Opaque, Cutout, Fade, Multiply, Alphablend, Custom, Refract
	}
	
	struct RenderingSettings {
		public BlendMode srcBlend, dstBlend;
		public BlendOp operation;
		public bool zWrite, showShadows, showCutoff, showOverride, showRefract, showTransFix, showCustom;
		
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
				showCustom = false
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
				showCustom = false
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
				showCustom = false
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
				showCustom = false
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
				showCustom = false
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
				showCustom = true
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
				showCustom = false
			}
		};
	}
	
	Material target;
	MaterialEditor editor;
	MaterialProperty[] properties;
	RenderingSettings renderSettings;
	
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
	
	void SanitizeKeywords() {
		foreach (Material m in editor.targets) {
			m.DisableKeyword("NO_SHADOW");
			m.DisableKeyword("TINTED_SHADOW");
			m.DisableKeyword("RAMP_SHADOW");
			m.DisableKeyword("NO_SPHERE");
			m.DisableKeyword("ADD_SPHERE");
			m.DisableKeyword("MUL_SPHERE");
			m.DisableKeyword("NORMAL_LIGHTING");
			m.DisableKeyword("WORLD_STATIC_LIGHT");
			m.DisableKeyword("LOCAL_STATIC_LIGHT");
		}
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
		renderSettings = RenderingSettings.modes[(int)mode];
		
		EditorGUI.showMixedValue = false;
	}
	
	void DoMain() {
		GUILayout.Label("Main Maps", EditorStyles.boldLabel);
		
		MaterialProperty mainTex = FindProperty("_MainTex");
		editor.TexturePropertySingleLine(MakeLabel(mainTex, "Main Color Texture (RGB)"), mainTex, FindProperty("_Color"));
		EditorGUI.indentLevel += 2;
		if (renderSettings.showCutoff) DoAlphaCutoff();
		if (renderSettings.showOverride) DoAlphaOverride();
		if (renderSettings.showRefract) DoRefract();
		DoColorMask();
		EditorGUI.indentLevel -= 2;
		//DoMetallic();
		//DoSmoothness();
		DoNormals();
		DoOcclusion();
		DoSpecular();
		DoEmission();
		DoRainbow();
		//DoDetailMask();
		editor.TextureScaleOffsetProperty(mainTex);
		DoBrightnessSaturation();
	}
	
	void DoSecondary() {
		GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);
	}
	
	void DoOptions() {
		EditorGUILayout.Space();
		GUILayout.Label("Options", EditorStyles.boldLabel);
		
		DoShadows();
		EditorGUILayout.Space();
		DoOutline();
		EditorGUILayout.Space();
		DoSpheres();
	}
	
	void DoEffects() {
		EditorGUILayout.Space();
		GUILayout.Label("Effects", EditorStyles.boldLabel);
		
		DoPano();
	}
	
	void DoAdvanced() {
		EditorGUILayout.Space();
		GUILayout.Label("Advanced Options", EditorStyles.boldLabel);
		
		editor.RenderQueueField();
		DoDoubleSided();
		DoTransFix();
		DoLightingHack();
		DoReflectionProbes();
		DoCastShadows();
		
		KeywordToggle("HUESHIFTMODE", MakeLabel("HSB mode", "This will make it so you can change the color of your material completely, but any color variation will be lost"));
		ReverseKeywordToggle("ALLOWOVERBRIGHT", MakeLabel("Overbright Protection", "Protects against overbright worlds"));
		if (KeywordToggle("GAMMACORRECT", MakeLabel("Gamma Correction", "Use if your colors seem washed out, or your blacks appear gray."))) {
			EditorGUI.indentLevel += 2;
			ShaderProperty("_CorrectionLevel", "Intensity", "Effectiveness of gamma correction.");
			EditorGUI.indentLevel -= 2;
		}
		
		DoBatchDisable();
	}
	
	void DoAlphaCutoff() {
		ShaderProperty("_Cutoff", "Alpha Cutoff", "Material will clip here.  Drag to the left if you're losing detail.  Recommended value for alphablend: 0.1");
	}
	
	void DoAlphaOverride() {
		ShaderProperty("_AlphaOverride", "Alpha Override", "Overrides a texture's alpha (useful for very faint textures)");
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
		EditorGUI.BeginChangeCheck();
		EditorGUI.indentLevel += 2;
		bool rainbow = EditorGUILayout.Toggle("Rainbow", IsKeywordEnabled("RAINBOW"));
		EditorGUI.indentLevel -= 2;
		if (EditorGUI.EndChangeCheck()) SetKeyword("RAINBOW", rainbow);
		if (rainbow) editor.TexturePropertySingleLine(MakeLabel("Rainbow Mask", "Rainbow Mask (RGB) with Rainbow Speed"), FindProperty("_RainbowMask"), FindProperty("_Speed"));
	}
	
	void DoEmission() {
		MaterialProperty map = FindProperty("_EmissionMap");
		Texture tex = map.textureValue;
		bool shadeEmission = false;
		bool sleepEmission = false;
		bool pulseEnable   = false;
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertyWithHDRColor(MakeLabel("Emission", "Emission (RGB)"), map, FindProperty("_EmissionColor"), emissionConfig, false);
		if (IsKeywordEnabled("PULSE")) editor.TexturePropertySingleLine(MakeLabel("Emission Pulse", "Emission Pulse (RGB) and Pulse Speed"), FindProperty("_EmissionPulseMap"), FindProperty("_EmissionPulseColor"), FindProperty("_EmissionSpeed"));
		EditorGUI.indentLevel += 2;
		pulseEnable   = EditorGUILayout.Toggle("Pulse Emission",  IsKeywordEnabled("PULSE"));
		shadeEmission = EditorGUILayout.Toggle("Shaded Emission", IsKeywordEnabled("SHADEEMISSION"));
		sleepEmission = EditorGUILayout.Toggle("Sleep Emission",  IsKeywordEnabled("SLEEPEMISSION"));
		EditorGUI.indentLevel -= 2;
		if (EditorGUI.EndChangeCheck()) {
			SetKeyword("PULSE",         pulseEnable);
			SetKeyword("SHADEEMISSION", shadeEmission);
			SetKeyword("SLEEPEMISSION", sleepEmission);
			/*
			if (tex != map.textureValue) {
				SetKeyword("_EMISSION_MAP", map.textureValue);
			}
			*/
		}
	}
	
	void DoOcclusion() {
		MaterialProperty map = FindProperty("_OcclusionMap");
		Texture tex = map.textureValue;
		EditorGUI.BeginChangeCheck();
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
		EditorGUI.indentLevel -= 2;
		editor.TexturePropertySingleLine(MakeLabel("Toon Texture", "(RGBA) Vertical or horizontal. Bottom and left are dark"), FindProperty("_ShadowRamp"));
		EditorGUI.indentLevel += 2;
		EditorGUILayout.HelpBox("Set your texture's wrapping mode to clamp to get rid of glitches", MessageType.Info);
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
		EditorGUI.indentLevel -= 2;
		editor.TexturePropertySingleLine(MakeLabel("Toon Texture", "(RGBA) Vertical or horizontal, specify below. Bottom or left are dark"), FindProperty("_ShadowRamp"));
		EditorGUI.indentLevel += 2;
		ShaderProperty("_ShadowRampDirection");
		EditorGUI.indentLevel -= 2;
		editor.TexturePropertySingleLine(MakeLabel("Shadow Texture", "(RGB) This is what your model will look like with only ambient light"), FindProperty("_ShadowTexture"), FindProperty("_ShadowUV"));
		EditorGUI.indentLevel += 2;
		EditorGUILayout.HelpBox("Set your texture's wrapping mode to clamp to get rid of glitches", MessageType.Info);
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
				SetupMaterialWithOutlineMode((Material)obj);
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
			
			foreach (var obj in outlineColorMode.targets)
			{
				SetupMaterialWithOutlineColorMode((Material)obj);
			}
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
		Vec2Prop(MakeLabel(op1 + " Speed", op2 + " the overlay texture (Set to 0 to turn off)"), FindProperty("_PanoRotationSpeedX"), FindProperty("_PanoRotationSpeedY"));
		EditorGUI.indentLevel -= 2;
	}
	
	void DoOverlayMode(string display, string tip) {
		bool panoOverlay = IsKeywordEnabled("PANOOVERLAY");
		EditorGUI.indentLevel += 2;
		EditorGUI.BeginChangeCheck();
		panoOverlay = EditorGUILayout.Toggle(MakeLabel(display, tip), panoOverlay);
		EditorGUI.indentLevel -= 2;
		if (EditorGUI.EndChangeCheck()) SetKeyword("PANOOVERLAY", panoOverlay);
		if (panoOverlay) {
			editor.TexturePropertySingleLine(MakeLabel("Texture", "Static Overlay"), FindProperty("_PanoOverlayTex"));
			EditorGUI.indentLevel += 2;
			KeywordToggle("PANOALPHA", MakeLabel("Use Alpha Channel", "Blending for the panosphere overlay, unchecked is add, checked is alpha"));
			EditorGUI.indentLevel -= 2;
		}
	}
	
	void DoDoubleSided() {
		EditorGUI.BeginChangeCheck();
		bool backfacecull = !EditorGUILayout.Toggle(MakeLabel("Double Sided", "Render this material on both sides"), !IsKeywordEnabled("BCKFCECULL"));
		if (EditorGUI.EndChangeCheck())
		{
			if (backfacecull)
				foreach (Material mat in editor.targets)
				{
					mat.EnableKeyword("BCKFCECULL");
					mat.SetInt("_CullMode", (int)UnityEngine.Rendering.CullMode.Back);
					SetupMaterialShaderSelect((Material)mat);
				}
			else
				foreach (Material mat in editor.targets)
				{
					mat.DisableKeyword("BCKFCECULL");
					mat.SetInt("_CullMode", (int)UnityEngine.Rendering.CullMode.Off);
					SetupMaterialShaderSelect((Material)mat);
				}
		}
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
			case LightingHack.World:
			case LightingHack.Local:
				EditorGUI.indentLevel += 2;
				KeywordToggle("OVERRIDE_REALTIME", MakeLabel("Override All", "Override All lights not just directionless lights"));
				Vec3Prop(MakeLabel("Light Coordinate", "Static World Light Position"), FindProperty("_StaticToonLight"));
				EditorGUI.indentLevel -= 2;
				break;
			case LightingHack.None:
			default:
				break;
		}
		ShaderProperty("_LightColor", "Light Color", "Light will become this color depending on the slider below");
		ShaderProperty("_LightOverride", "Light Override", "Turn this slider to the right to use the color above");
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
			if (ReverseKeywordToggle("DISABLE_SHADOW", MakeLabel("Enable Shadow Casts", "This makes shadows appear on the material from other objects"))) {
				EditorGUI.indentLevel += 2;
				ShaderProperty("_shadowcast_intensity", "Intensity", "This is how much other objects affect your shadow");
				ShaderProperty("_ShadowAmbAdd", "Ambient", "Controls casted ambient light, values above zero will cause visible squares around point lights");
				EditorGUI.indentLevel -= 2;
			}
		} else {
			GUI.enabled = false;
			EditorGUILayout.Toggle(MakeLabel("Enable Shadow Casts", "This makes shadows appear on the material from other objects"), false);
			GUI.enabled = true;
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
		GUILayout.Label("Stencil Options", EditorStyles.boldLabel);
		
		ShaderProperty("_stencilcolormask");
		ShaderProperty("_Stencil");
		ShaderProperty("_StencilComp");
		ShaderProperty("_StencilOp");
		ShaderProperty("_StencilFail");
		ShaderProperty("_StencilZFail");
		ShaderProperty("_ZTest");
		ShaderProperty("_ZWrite");
	}
	
	void DoCustom() {
		EditorGUILayout.Space();
		GUILayout.Label("Blending Options", EditorStyles.boldLabel);
		
		ShaderProperty("_SrcBlend");
		ShaderProperty("_DstBlend");
		ShaderProperty("_BlendOp");
	}

    public static void SetupMaterialWithOutlineMode(Material material)
    {
        switch ((OutlineMode)material.GetFloat("_OutlineMode"))
        {
            case OutlineMode.None:
                material.DisableKeyword("ARTSY_OUTLINE");
                material.DisableKeyword("OUTSIDE_OUTLINE");
                material.DisableKeyword("SCREENSPACE_OUTLINE");
                //material.shader = Shader.Find("Synergiance/Toon");
                break;
            case OutlineMode.Artsy:
                material.EnableKeyword("ARTSY_OUTLINE");
                material.DisableKeyword("OUTSIDE_OUTLINE");
                material.DisableKeyword("SCREENSPACE_OUTLINE");
                //material.shader = Shader.Find("Synergiance/Toon");
                break;
            case OutlineMode.Normal:
                material.DisableKeyword("ARTSY_OUTLINE");
                material.EnableKeyword("OUTSIDE_OUTLINE");
                material.DisableKeyword("SCREENSPACE_OUTLINE");
                //material.shader = Shader.Find("Synergiance/Toon-Outline");
                break;
            case OutlineMode.Screenspace:
                material.DisableKeyword("ARTSY_OUTLINE");
                material.DisableKeyword("OUTSIDE_OUTLINE");
                material.EnableKeyword("SCREENSPACE_OUTLINE");
                //material.shader = Shader.Find("Synergiance/Toon-Outline");
                break;
            default:
                break;
        }
    }

    void SetupMaterialWithOutlineColorMode(Material material)
    {
        switch ((OutlineColorMode)material.GetFloat("_OutlineColorMode"))
        {
            case OutlineColorMode.Tinted:
                material.EnableKeyword("TINTED_OUTLINE");
                material.DisableKeyword("COLORED_OUTLINE");
                break;
            case OutlineColorMode.Colored:
                material.DisableKeyword("TINTED_OUTLINE");
                material.EnableKeyword("COLORED_OUTLINE");
                break;
            default:
                break;
        }
    }

    void SetupMaterialShaderSelect(Material material)
    {
        bool doubleSided = !IsKeywordEnabled("BCKFCECULL");
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