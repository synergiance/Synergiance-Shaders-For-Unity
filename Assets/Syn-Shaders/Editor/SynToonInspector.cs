// Written by Synergiance
// Major edit from Cubed's FlatLitToon

using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using System;

public class SynToonInspector : ShaderGUI
{
    public enum OutlineMode
    {
        None,
        Artsy,
        Outside,
        Screenspace
    }
    
    public enum OutlineColorMode
    {
        Tinted,
        Colored
    }

    public enum BlendMode
    {
        Opaque,
        Cutout,
        Fade,   // Old school alpha-blending mode, fresnel does not affect amount of transparency
        Multiply, // Physically plausible transparency mode, implemented as alpha pre-multiply
        Alphablend // Full alpha blending
    }
    
    public enum ShadowMode
    {
        None,
        Tint,
        Toon
    }
    
    public enum LightingHack
    {
        None,
        World,
        Local
    }
    
    public enum SphereMode
    {
        None,
        Add,
        Mul
    }
    
    public enum PanoMode
    {
        None,
        Sphere,
        Screen
    }
    
    public enum TransFix
    {
        None,
        Level1,
        Level2
    }

    MaterialProperty blendMode;
    MaterialProperty mainTexture;
    MaterialProperty color;
    MaterialProperty colorMask;
    MaterialProperty lightingHack;
    MaterialProperty transFix;
    MaterialProperty staticLight;
    MaterialProperty shadowMode;
    MaterialProperty shadowWidth;
    MaterialProperty shadowFeather;
    MaterialProperty shadowAmbient;
    MaterialProperty shadowAmbAdd;
    MaterialProperty shadowCastIntensity;
    MaterialProperty shadowTint;
    MaterialProperty shadowRamp;
    MaterialProperty outlineMode;
    MaterialProperty outlineWidth;
    MaterialProperty outlineFeather;
    MaterialProperty outlineColor;
    MaterialProperty outlineColorMode;
    MaterialProperty emissionMap;
    MaterialProperty emissionColor;
    MaterialProperty emissionSpeed;
    MaterialProperty emissionPulseMap;
    MaterialProperty emissionPulseColor;
    MaterialProperty normalMap;
    MaterialProperty alphaCutoff;
    MaterialProperty alphaOverride;
    //MaterialProperty rainbowMode;
    MaterialProperty rainbowMask;
    MaterialProperty rainbowSpeed;
    MaterialProperty brightness;
    MaterialProperty gammaLevel;
    MaterialProperty sphereAddTex;
    MaterialProperty sphereMulTex;
    MaterialProperty sphereMode;
    MaterialProperty saturationBoost;
    MaterialProperty panoSphereMode;
    MaterialProperty panoSphereTex;
    MaterialProperty panoFlatTex;
    MaterialProperty panoRotationSpeedX;
    MaterialProperty panoRotationSpeedY;
    MaterialProperty panoOverlayTex;
    MaterialProperty panoBlend;
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        { //Find Properties
            blendMode = FindProperty("_Mode", props);
            mainTexture = FindProperty("_MainTex", props);
            color = FindProperty("_Color", props);
            colorMask = FindProperty("_ColorMask", props);
            lightingHack = FindProperty("_LightingHack", props);
            transFix = FindProperty("_TransFix", props);
            staticLight = FindProperty("_StaticToonLight", props);
            shadowMode = FindProperty("_ShadowMode", props);
            shadowWidth = FindProperty("_shadow_coverage", props);
            shadowFeather = FindProperty("_shadow_feather", props);
            shadowAmbient = FindProperty("_ShadowAmbient", props);
            shadowAmbAdd = FindProperty("_ShadowAmbAdd", props);
            shadowCastIntensity = FindProperty("_shadowcast_intensity", props);
            shadowTint = FindProperty("_ShadowTint", props);
            shadowRamp = FindProperty("_ShadowRamp", props);
            outlineMode = FindProperty("_OutlineMode", props);
            outlineColorMode = FindProperty("_OutlineColorMode", props);
            outlineWidth = FindProperty("_outline_width", props);
            outlineFeather = FindProperty("_outline_feather", props);
            outlineColor = FindProperty("_outline_color", props);
            emissionMap = FindProperty("_EmissionMap", props);
            emissionColor = FindProperty("_EmissionColor", props);
            emissionSpeed = FindProperty("_EmissionSpeed", props);
            emissionPulseMap = FindProperty("_EmissionPulseMap", props);
            emissionPulseColor = FindProperty("_EmissionPulseColor", props);
            normalMap = FindProperty("_BumpMap", props);
            alphaCutoff = FindProperty("_Cutoff", props);
            //rainbowMode = FindProperty("_RainbowMode", props);
            rainbowMask = FindProperty("_RainbowMask", props);
            rainbowSpeed = FindProperty("_Speed", props);
            brightness = FindProperty("_Brightness", props);
            gammaLevel = FindProperty("_CorrectionLevel", props);
            alphaOverride = FindProperty("_AlphaOverride", props);
            sphereAddTex = FindProperty("_SphereAddTex", props);
            sphereMulTex = FindProperty("_SphereMulTex", props);
            sphereMode = FindProperty("_SphereMode", props);
            saturationBoost = FindProperty("_SaturationBoost", props);
            panoSphereMode = FindProperty("_PanoMode", props);
            panoSphereTex = FindProperty("_PanoSphereTex", props);
            panoFlatTex = FindProperty("_PanoFlatTex", props);
            panoRotationSpeedX = FindProperty("_PanoRotationSpeedX", props);
            panoRotationSpeedY = FindProperty("_PanoRotationSpeedY", props);
            panoOverlayTex = FindProperty("_PanoOverlayTex", props);
            panoBlend = FindProperty("_PanoBlend", props);
        }
        
        Material material = materialEditor.target as Material;
        
        bool allowOverbright = Array.IndexOf(material.shaderKeywords, "ALLOWOVERBRIGHT") != -1;
        bool realOverride = Array.IndexOf(material.shaderKeywords, "OVERRIDE_REALTIME") != -1;
        bool shadowDisable = Array.IndexOf(material.shaderKeywords, "DISABLE_SHADOW") != -1;
        bool shadeEmission = Array.IndexOf(material.shaderKeywords, "SHADEEMISSION") != -1;
        bool sleepEmission = Array.IndexOf(material.shaderKeywords, "SLEEPEMISSION") != -1;
        bool backfacecull = Array.IndexOf(material.shaderKeywords, "BCKFCECULL") != -1;
        bool rainbowEnable = Array.IndexOf(material.shaderKeywords, "RAINBOW") != -1;
        bool hueMode = Array.IndexOf(material.shaderKeywords, "HUESHIFTMODE") != -1;
        bool pulseEnable = Array.IndexOf(material.shaderKeywords, "PULSE") != -1;
        bool panoAlpha = Array.IndexOf(material.shaderKeywords, "PANOALPHA") != -1;
        bool panoOverlay = Array.IndexOf(material.shaderKeywords, "PANOOVERLAY") != -1;
        bool gammaCorrect = Array.IndexOf(material.shaderKeywords, "GAMMACORRECT") != -1;
        
        { //Shader Properties GUI
            EditorGUIUtility.labelWidth = 0f;
            
            EditorGUI.BeginChangeCheck();
            {
                EditorGUI.showMixedValue = blendMode.hasMixedValue;
                var bMode = (BlendMode)blendMode.floatValue;

                EditorGUI.BeginChangeCheck();
                bMode = (BlendMode)EditorGUILayout.Popup("Rendering Mode", (int)bMode, Enum.GetNames(typeof(BlendMode)));
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Rendering Mode");
                    blendMode.floatValue = (float)bMode;

                    foreach (var obj in blendMode.targets)
                    {
                        SetupMaterialWithBlendMode((Material)obj, (BlendMode)material.GetFloat("_Mode"));
                        SetupMaterialShaderSelect((Material)obj, (OutlineMode)material.GetFloat("_OutlineMode"), (BlendMode)material.GetFloat("_Mode"), (TransFix)material.GetFloat("_TransFix"), !backfacecull);
                    }
                }

                EditorGUI.showMixedValue = false;
                EditorGUILayout.Space();

                materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture", "Main Color Texture (RGB)"), mainTexture, color);
                EditorGUI.indentLevel += 2;
                if (((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout) || ((BlendMode)material.GetFloat("_Mode") == BlendMode.Alphablend))
                    materialEditor.ShaderProperty(alphaCutoff, new GUIContent("Alpha Cutoff", "Material will clip here.  Drag to the left if you're losing detail.  Recommended value for alphablend: 0.1"), 2);
                if ((BlendMode)material.GetFloat("_Mode") == BlendMode.Alphablend)
                    materialEditor.ShaderProperty(alphaOverride, new GUIContent("Alpha Override", "Overrides a texture's alpha (useful for very faint textures)"), 2);
                materialEditor.TexturePropertySingleLine(new GUIContent("Color Mask", "Masks Color Tinting (G)"), colorMask);
                EditorGUI.indentLevel -= 2;
                materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map", "Normal Map (RGB)"), normalMap);
                materialEditor.TexturePropertySingleLine(new GUIContent("Emission", "Emission (RGB)"), emissionMap, emissionColor);
                
                EditorGUILayout.Space();
                EditorGUI.BeginChangeCheck();
                shadeEmission = EditorGUILayout.Toggle("Shaded Emission", shadeEmission);
                if (EditorGUI.EndChangeCheck())
                {
                    if (shadeEmission)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("SHADEEMISSION");
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("SHADEEMISSION");
                        }
                }
                
                EditorGUI.BeginChangeCheck();
                sleepEmission = EditorGUILayout.Toggle("Hide Emission", sleepEmission);
                if (EditorGUI.EndChangeCheck())
                {
                    if (sleepEmission)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("SLEEPEMISSION");
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("SLEEPEMISSION");
                        }
                }
                
                EditorGUI.BeginChangeCheck();
                pulseEnable = EditorGUILayout.Toggle("Pulse Emission", pulseEnable);
                if (EditorGUI.EndChangeCheck())
                {
                    if (pulseEnable)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("PULSE");
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("PULSE");
                        }
                }
                if (pulseEnable)
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Emission Pulse", "Emission Pulse (RGB)"), emissionPulseMap, emissionPulseColor);
                    EditorGUI.indentLevel += 2;
                    materialEditor.ShaderProperty(emissionSpeed, "Pulse Speed");
                    EditorGUI.indentLevel -= 2;
                }
                
                EditorGUI.BeginChangeCheck();
                materialEditor.TextureScaleOffsetProperty(mainTexture);
                if (EditorGUI.EndChangeCheck())
                    emissionMap.textureScaleAndOffset = mainTexture.textureScaleAndOffset;
                
                EditorGUILayout.Space();
                EditorGUI.BeginChangeCheck();
                rainbowEnable = EditorGUILayout.Toggle("Rainbow", rainbowEnable);
                if (EditorGUI.EndChangeCheck())
                {
                    if (rainbowEnable)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("RAINBOW");
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("RAINBOW");
                        }
                }
                if (rainbowEnable)
                {
                    EditorGUI.indentLevel += 2;
                    materialEditor.TexturePropertySingleLine(new GUIContent("Rainbow Mask", "Rainbow Mask (G)"), rainbowMask);
                    materialEditor.ShaderProperty(rainbowSpeed, "Rainbow Speed");
                    EditorGUI.indentLevel -= 2;
                }
                
                EditorGUILayout.Space();
                materialEditor.ShaderProperty(brightness, new GUIContent("Brightness", "How much light gets to your model.  This can have a better effect than darkening the color"));
                materialEditor.ShaderProperty(saturationBoost, new GUIContent("Saturation Boost", "This will boost the saturation, don't turn it up too high unless you know what you're doing"));

                var sMode = (ShadowMode)shadowMode.floatValue;

                EditorGUI.BeginChangeCheck();
                sMode = (ShadowMode)EditorGUILayout.Popup("Shadow Mode", (int)sMode, Enum.GetNames(typeof(ShadowMode)));
                
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Shadow Mode");
                    shadowMode.floatValue = (float)sMode;

                    foreach (var obj in shadowMode.targets)
                    {
                        SetupMaterialWithShadowMode((Material)obj, (ShadowMode)material.GetFloat("_ShadowMode"));
                    }

                }
                switch (sMode)
                {
                    case ShadowMode.Tint:
                        EditorGUI.indentLevel += 2;
                        materialEditor.ShaderProperty(shadowWidth, new GUIContent("Coverage", "How much of your character is shadowed? I'd recommend somewhere between 0.5 for crisp toons and 0.65 for smooth shading"));
                        materialEditor.ShaderProperty(shadowFeather, new GUIContent("Feather", "Slide to the left for crisp toons, to the right for smooth shading"));
                        materialEditor.ShaderProperty(shadowAmbient, new GUIContent("Ambient Light", "Slide to the left for shadow light, to the right for direct light"));
                        materialEditor.ShaderProperty(shadowTint, new GUIContent("Tint Color", "This will tint your shadows, try pinkish colors for skin"));
                        EditorGUI.indentLevel -= 2;
                        break;
                    case ShadowMode.Toon:
                        EditorGUI.indentLevel += 2;
                        //materialEditor.ShaderProperty(shadowAmbient, "Ambient Light");
                        materialEditor.TexturePropertySingleLine(new GUIContent("Toon Texture", "(RGBA) Vertical or horizontal. Bottom and left are dark"), shadowRamp);
                        EditorGUILayout.HelpBox("Set your texture's wrapping mode to clamp to get rid of glitches", MessageType.Info);
                        EditorGUI.indentLevel -= 2;
                        break;
                    case ShadowMode.None:
                    default:
                        break;
                }
                EditorGUILayout.Space();

                var oMode = (OutlineMode)outlineMode.floatValue;
                var ocMode = (OutlineColorMode)outlineColorMode.floatValue;

                EditorGUI.BeginChangeCheck();
                oMode = (OutlineMode)EditorGUILayout.Popup("Outline Mode", (int)oMode, Enum.GetNames(typeof(OutlineMode)));
                
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Outline Mode");
                    outlineMode.floatValue = (float)oMode;

                    foreach (var obj in outlineMode.targets)
                    {
                        SetupMaterialWithOutlineMode((Material)obj, (OutlineMode)material.GetFloat("_OutlineMode"));
                        SetupMaterialShaderSelect((Material)obj, (OutlineMode)material.GetFloat("_OutlineMode"), (BlendMode)material.GetFloat("_Mode"), (TransFix)material.GetFloat("_TransFix"), !backfacecull);
                    }

                }
                EditorGUI.BeginChangeCheck();
                switch (oMode) // solidOutline
                {
                    case OutlineMode.Artsy:
                        EditorGUI.indentLevel += 2;
                        ocMode = (OutlineColorMode)EditorGUILayout.Popup("Color Mode", (int)ocMode, Enum.GetNames(typeof(OutlineColorMode)));
                        materialEditor.ShaderProperty(outlineColor, new GUIContent("Color", "This is the color of the outline"));
                        materialEditor.ShaderProperty(outlineWidth, new GUIContent("Width", "This is the width of the outline.  This mode may or may not look good on your model.  Try \"Outline\""));
                        materialEditor.ShaderProperty(outlineFeather, new GUIContent("Feather", "Smoothness of the outline. You can go from very crisp to very blurry"));
                        EditorGUI.indentLevel -= 2;
                        break;
                    case OutlineMode.Outside:
                    case OutlineMode.Screenspace:
                        EditorGUI.indentLevel += 2;
                        ocMode = (OutlineColorMode)EditorGUILayout.Popup("Color Mode", (int)ocMode, Enum.GetNames(typeof(OutlineColorMode)));
                        materialEditor.ShaderProperty(outlineColor, new GUIContent("Color", "This is the color of the outline"));
                        materialEditor.ShaderProperty(outlineWidth, new GUIContent("Width", "This is the width of the outline"));
                        EditorGUI.indentLevel -= 2;
                        break;
                    case OutlineMode.None:
                    default:
                        break;
                }
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Color Mode");
                    outlineColorMode.floatValue = (float)ocMode;

                    foreach (var obj in outlineColorMode.targets)
                    {
                        SetupMaterialWithOutlineColorMode((Material)obj, (OutlineColorMode)material.GetFloat("_OutlineColorMode"));
                    }

                }
                EditorGUILayout.Space();

                var sphMode = (SphereMode)sphereMode.floatValue;

                EditorGUI.BeginChangeCheck();
                sphMode = (SphereMode)EditorGUILayout.Popup("Sphere Mode", (int)sphMode, Enum.GetNames(typeof(SphereMode)));
                
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Sphere Mode");
                    sphereMode.floatValue = (float)sphMode;

                    foreach (var obj in sphereMode.targets)
                    {
                        SetupMaterialWithSphereMode((Material)obj, (SphereMode)material.GetFloat("_SphereMode"));
                    }

                }
                switch (sphMode)
                {
                    case SphereMode.Add:
                        EditorGUI.indentLevel += 2;
                        materialEditor.TexturePropertySingleLine(new GUIContent("Sphere Texture", "Sphere Texture (Add)"), sphereAddTex);
                        EditorGUI.indentLevel -= 2;
                        break;
                    case SphereMode.Mul:
                        EditorGUI.indentLevel += 2;
                        materialEditor.TexturePropertySingleLine(new GUIContent("Sphere Texture", "Sphere Texture (Multiply)"), sphereMulTex);
                        EditorGUI.indentLevel -= 2;
                        break;
                    case SphereMode.None:
                    default:
                        break;
                }
                EditorGUILayout.Space();
                
                GUILayout.Label("Effects", EditorStyles.boldLabel);

                var panoMode = (PanoMode)panoSphereMode.floatValue;

                EditorGUI.BeginChangeCheck();
                panoMode = (PanoMode)EditorGUILayout.Popup("Panosphere Mode", (int)panoMode, Enum.GetNames(typeof(PanoMode)));
                
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Panosphere Mode");
                    panoSphereMode.floatValue = (float)panoMode;

                    foreach (var obj in panoSphereMode.targets)
                        SetupMaterialWithPanoMode((Material)obj, (PanoMode)material.GetFloat("_PanoMode"));

                }
                switch (panoMode)
                {
                    case PanoMode.Sphere:
                        EditorGUI.indentLevel += 2;
                        materialEditor.TexturePropertySingleLine(new GUIContent("Panosphere Texture", "Panosphere Texture (Sphere Directional Mode)"), panoSphereTex);
                        materialEditor.ShaderProperty(panoBlend, new GUIContent("Blend", "Mix between normal albedo and panosphere"));
                        materialEditor.ShaderProperty(panoRotationSpeedX, new GUIContent("Rotation Speed (X)", "Rotate the panosphere texture (Set to 0 to turn off)"));
                        materialEditor.ShaderProperty(panoRotationSpeedY, new GUIContent("Rotation Speed (Y)", "Rotate the panosphere texture (Set to 0 to turn off)"));
                        EditorGUI.BeginChangeCheck();
                        panoOverlay = EditorGUILayout.Toggle(new GUIContent("Overlay", "Use an overlay for the panosphere"), panoOverlay);
                        if (EditorGUI.EndChangeCheck())
                        {
                            if (panoOverlay)
                                foreach (Material mat in materialEditor.targets)
                                    mat.EnableKeyword("PANOOVERLAY");
                            else
                                foreach (Material mat in materialEditor.targets)
                                    mat.DisableKeyword("PANOOVERLAY");
                        }
                        if (panoOverlay)
                        {
                            EditorGUI.indentLevel += 2;
                            materialEditor.TexturePropertySingleLine(new GUIContent("Texture", "Overlay for panosphere"), panoOverlayTex);
                            EditorGUI.BeginChangeCheck();
                            panoAlpha = EditorGUILayout.Toggle(new GUIContent("Use Alpha Channel", "Blending for the panosphere overlay, unchecked is add, checked is alpha"), panoAlpha);
                            EditorGUI.indentLevel -= 2;
                        }
                        EditorGUI.indentLevel -= 2;
                        break;
                    case PanoMode.Screen:
                        EditorGUI.indentLevel += 2;
                        materialEditor.TexturePropertySingleLine(new GUIContent("Panosphere Texture", "Panosphere Texture (Screen Positional Mode)"), panoFlatTex);
                        materialEditor.ShaderProperty(panoBlend, new GUIContent("Blend", "Mix between normal albedo and panosphere"));
                        materialEditor.ShaderProperty(panoRotationSpeedX, new GUIContent("Rotation Speed (X)", "Rotate the panosphere texture (Set to 0 to turn off)"));
                        materialEditor.ShaderProperty(panoRotationSpeedY, new GUIContent("Rotation Speed (Y)", "Rotate the panosphere texture (Set to 0 to turn off)"));
                        EditorGUI.BeginChangeCheck();
                        panoOverlay = EditorGUILayout.Toggle(new GUIContent("Overlay", "Use an overlay for the panosphere"), panoOverlay);
                        if (EditorGUI.EndChangeCheck())
                        {
                            if (panoOverlay)
                                foreach (Material mat in materialEditor.targets)
                                    mat.EnableKeyword("PANOOVERLAY");
                            else
                                foreach (Material mat in materialEditor.targets)
                                    mat.DisableKeyword("PANOOVERLAY");
                        }
                        if (panoOverlay)
                        {
                            EditorGUI.indentLevel += 2;
                            materialEditor.TexturePropertySingleLine(new GUIContent("Texture", "Overlay for panosphere"), panoOverlayTex);
                            EditorGUI.BeginChangeCheck();
                            panoAlpha = EditorGUILayout.Toggle(new GUIContent("Use Alpha Channel", "Blending for the panosphere overlay, unchecked is add, checked is alpha"), panoAlpha);
                            EditorGUI.indentLevel -= 2;
                        }
                        EditorGUILayout.HelpBox("This section does not work, in fact it's super broken, use a cube map instead with the sphere mode", MessageType.Info);
                        EditorGUI.indentLevel -= 2;
                        break;
                    case PanoMode.None:
                    default:
                        break;
                }
                if (EditorGUI.EndChangeCheck())
                {
                    if (panoAlpha)
                        foreach (Material mat in materialEditor.targets)
                            mat.EnableKeyword("PANOALPHA");
                    else
                        foreach (Material mat in materialEditor.targets)
                            mat.DisableKeyword("PANOALPHA");
                }
                EditorGUILayout.Space();

                GUILayout.Label("Advanced Options", EditorStyles.boldLabel);
                materialEditor.RenderQueueField();
                
                EditorGUI.BeginChangeCheck();
                backfacecull = !EditorGUILayout.Toggle(new GUIContent("Double Sided", "Render this material on both sides"), !backfacecull);
                if (EditorGUI.EndChangeCheck())
                {
                    if (backfacecull)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("BCKFCECULL");
                            mat.SetInt("_CullMode", (int)UnityEngine.Rendering.CullMode.Back);
                            SetupMaterialShaderSelect((Material)mat, (OutlineMode)material.GetFloat("_OutlineMode"), (BlendMode)material.GetFloat("_Mode"), (TransFix)material.GetFloat("_TransFix"), !backfacecull);
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("BCKFCECULL");
                            mat.SetInt("_CullMode", (int)UnityEngine.Rendering.CullMode.Off);
                            SetupMaterialShaderSelect((Material)mat, (OutlineMode)material.GetFloat("_OutlineMode"), (BlendMode)material.GetFloat("_Mode"), (TransFix)material.GetFloat("_TransFix"), !backfacecull);
                        }
                }
                
                var tFix = (TransFix)transFix.floatValue;
                EditorGUI.BeginChangeCheck();
                if ((BlendMode)material.GetFloat("_Mode") == BlendMode.Alphablend) {
                    tFix = (TransFix)EditorGUILayout.Popup("Transparent Fix", (int)tFix, Enum.GetNames(typeof(TransFix)));
                } else {
                    GUI.enabled = false;
                    tFix = (TransFix)EditorGUILayout.Popup("Transparent Fix", (int)tFix, Enum.GetNames(typeof(TransFix)));
                    GUI.enabled = true;
                }
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Transparent Fix");
                    transFix.floatValue = (float)tFix;

                    foreach (var obj in transFix.targets)
                    {
                        SetupMaterialShaderSelect((Material)obj, (OutlineMode)material.GetFloat("_OutlineMode"), (BlendMode)material.GetFloat("_Mode"), (TransFix)material.GetFloat("_TransFix"), !backfacecull);
                    }
                }

                var lHack = (LightingHack)lightingHack.floatValue;

                EditorGUI.BeginChangeCheck();
                lHack = (LightingHack)EditorGUILayout.Popup("Static Light", (int)lHack, Enum.GetNames(typeof(LightingHack)));
                
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Static Light");
                    lightingHack.floatValue = (float)lHack;

                    foreach (var obj in lightingHack.targets)
                    {
                        SetupMaterialWithLightingHack((Material)obj, (LightingHack)material.GetFloat("_LightingHack"));
                    }

                }
                EditorGUI.BeginChangeCheck();
                switch (lHack)
                {
                    case LightingHack.World:
                        EditorGUI.indentLevel += 2;
                        realOverride = EditorGUILayout.Toggle(new GUIContent("Override All", "Override All lights not just directionless lights"), realOverride);
                        materialEditor.ShaderProperty(staticLight, new GUIContent("Light Coordinate", "Static World Light Position"));
                        EditorGUI.indentLevel -= 2;
                        break;
                    case LightingHack.Local:
                        EditorGUI.indentLevel += 2;
                        realOverride = EditorGUILayout.Toggle(new GUIContent("Override All", "Override All lights not just directionless lights"), realOverride);
                        materialEditor.ShaderProperty(staticLight, new GUIContent("Light Coordinate", "Static Local Light Position"));
                        EditorGUI.indentLevel -= 2;
                        break;
                    case LightingHack.None:
                    default:
                        break;
                }
                if (EditorGUI.EndChangeCheck())
                {
                    if (realOverride)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("OVERRIDE_REALTIME");
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("OVERRIDE_REALTIME");
                        }
                }
                
                EditorGUI.BeginChangeCheck();
                if ((BlendMode)material.GetFloat("_Mode") <= BlendMode.Cutout) {
                    shadowDisable = !EditorGUILayout.Toggle(new GUIContent("Enable Shadow Casts", "This makes shadows appear on the material from other objects"), !shadowDisable);
                } else {
                    GUI.enabled = false;
                    shadowDisable = EditorGUILayout.Toggle(new GUIContent("Enable Shadow Casts", "This makes shadows appear on the material from other objects"), false);
                    GUI.enabled = true;
                }
                if (EditorGUI.EndChangeCheck())
                {
                    if (shadowDisable)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("DISABLE_SHADOW");
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("DISABLE_SHADOW");
                        }
                }
                if (!shadowDisable && (BlendMode)material.GetFloat("_Mode") <= BlendMode.Cutout) {
                    EditorGUI.indentLevel += 2;
                    materialEditor.ShaderProperty(shadowCastIntensity, new GUIContent("Intensity", "This is how much other objects affect your shadow"));
                    materialEditor.ShaderProperty(shadowAmbAdd, new GUIContent("Ambient", "Controls casted ambient light, values above zero will cause visible squares around point lights"));
                    EditorGUI.indentLevel -= 2;
                }
                
                EditorGUI.BeginChangeCheck();
                hueMode = EditorGUILayout.Toggle(new GUIContent("HSB mode", "This will make it so you can change the color of your material completely, but any color variation will be lost"), hueMode);
                if (EditorGUI.EndChangeCheck())
                {
                    if (hueMode)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("HUESHIFTMODE");
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("HUESHIFTMODE");
                        }
                }
                
                EditorGUI.BeginChangeCheck();
                allowOverbright = !EditorGUILayout.Toggle(new GUIContent("Overbright Protection", "Protects against overbright worlds"), !allowOverbright);
                if (EditorGUI.EndChangeCheck())
                {
                    if (allowOverbright)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("ALLOWOVERBRIGHT");
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("ALLOWOVERBRIGHT");
                        }
                }
                EditorGUI.BeginChangeCheck();
                gammaCorrect = EditorGUILayout.Toggle(new GUIContent("Gamma Correction", "Use if your colors seem washed out, or your blacks appear gray."), gammaCorrect);
                if (EditorGUI.EndChangeCheck())
                {
                    if (gammaCorrect)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("GAMMACORRECT");
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("GAMMACORRECT");
                        }
                }
                if (gammaCorrect)
                {
                    EditorGUI.indentLevel += 2;
                    materialEditor.ShaderProperty(gammaLevel, new GUIContent("Intensity", "Effectiveness of gamma correction."));
                    EditorGUI.indentLevel -= 2;
                }
            }
            EditorGUI.EndChangeCheck();
        }
    }
    
    public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
    {
        switch ((BlendMode)material.GetFloat("_Mode"))
        {
            case BlendMode.Opaque:
                material.SetOverrideTag("RenderType", "Opaque");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                material.DisableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHABLEND_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Geometry;
                break;
            case BlendMode.Cutout:
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                material.EnableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHABLEND_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                break;
            case BlendMode.Fade:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 0);
                material.DisableKeyword("_ALPHATEST_ON");
                material.EnableKeyword("_ALPHABLEND_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.Multiply:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 0);
                material.DisableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHABLEND_ON");
                material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.Alphablend:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 1);
                material.DisableKeyword("_ALPHATEST_ON");
                material.EnableKeyword("_ALPHABLEND_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                break;
        }
    }

    public static void SetupMaterialWithOutlineMode(Material material, OutlineMode outlineMode)
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
            case OutlineMode.Outside:
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

    public static void SetupMaterialWithOutlineColorMode(Material material, OutlineColorMode outlineColorMode)
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
    
    public static void SetupMaterialWithShadowMode(Material material, ShadowMode shadowMode)
    {
        switch ((ShadowMode)material.GetFloat("_ShadowMode"))
        {
            case ShadowMode.None:
                material.EnableKeyword("NO_SHADOW");
                material.DisableKeyword("TINTED_SHADOW");
                material.DisableKeyword("RAMP_SHADOW");
                break;
            case ShadowMode.Tint:
                material.DisableKeyword("NO_SHADOW");
                material.EnableKeyword("TINTED_SHADOW");
                material.DisableKeyword("RAMP_SHADOW");
                break;
            case ShadowMode.Toon:
                material.DisableKeyword("NO_SHADOW");
                material.DisableKeyword("TINTED_SHADOW");
                material.EnableKeyword("RAMP_SHADOW");
                break;
            default:
                break;
        }
    }
    
    public static void SetupMaterialWithLightingHack(Material material, LightingHack lightingHack)
    {
        switch ((LightingHack)material.GetFloat("_LightingHack"))
        {
            case LightingHack.None:
                material.EnableKeyword("NORMAL_LIGHTING");
                material.DisableKeyword("WORLD_STATIC_LIGHT");
                material.DisableKeyword("LOCAL_STATIC_LIGHT");
                break;
            case LightingHack.World:
                material.DisableKeyword("NORMAL_LIGHTING");
                material.EnableKeyword("WORLD_STATIC_LIGHT");
                material.DisableKeyword("LOCAL_STATIC_LIGHT");
                break;
            case LightingHack.Local:
                material.DisableKeyword("NORMAL_LIGHTING");
                material.DisableKeyword("WORLD_STATIC_LIGHT");
                material.EnableKeyword("LOCAL_STATIC_LIGHT");
                break;
            default:
                break;
        }
    }

    public static void SetupMaterialWithSphereMode(Material material, SphereMode sphereMode)
    {
        switch ((SphereMode)material.GetFloat("_SphereMode"))
        {
            case SphereMode.None:
                material.EnableKeyword("NO_SPHERE");
                material.DisableKeyword("ADD_SPHERE");
                material.DisableKeyword("MUL_SPHERE");
                break;
            case SphereMode.Add:
                material.DisableKeyword("NO_SPHERE");
                material.EnableKeyword("ADD_SPHERE");
                material.DisableKeyword("MUL_SPHERE");
                break;
            case SphereMode.Mul:
                material.DisableKeyword("NO_SPHERE");
                material.DisableKeyword("ADD_SPHERE");
                material.EnableKeyword("MUL_SPHERE");
                break;
            default:
                break;
        }
    }

    public static void SetupMaterialWithPanoMode(Material material, PanoMode panoMode)
    {
        switch ((PanoMode)material.GetFloat("_PanoMode"))
        {
            case PanoMode.None:
                material.EnableKeyword("NO_PANO");
                material.DisableKeyword("SPHERE_PANO");
                material.DisableKeyword("SCREEN_PANO");
                break;
            case PanoMode.Sphere:
                material.DisableKeyword("NO_PANO");
                material.EnableKeyword("SPHERE_PANO");
                material.DisableKeyword("SCREEN_PANO");
                break;
            case PanoMode.Screen:
                material.DisableKeyword("NO_PANO");
                material.DisableKeyword("SPHERE_PANO");
                material.EnableKeyword("SCREEN_PANO");
                break;
            default:
                break;
        }
    }
    
    public static void SetupMaterialShaderSelect(Material material, OutlineMode outlineMode, BlendMode blendMode, TransFix transparentFix, bool doubleSided)
    {
        string shaderName = "Synergiance/Toon";
        float transFix = (float)material.GetFloat("_TransFix");
        switch ((OutlineMode)material.GetFloat("_OutlineMode"))
        {
            case OutlineMode.Outside:
                shaderName += "-Outline";
                break;
            case OutlineMode.Screenspace:
                shaderName += "-Outline";
                break;
            default:
                break;
        }
        switch ((BlendMode)material.GetFloat("_Mode"))
        {
            case BlendMode.Cutout:
                shaderName += "/Cutout";
                break;
            case BlendMode.Fade:
                shaderName += "/Transparent";
                if (doubleSided) shaderName += "DS";
                break;
            case BlendMode.Multiply:
                shaderName += "/Transparent";
                if (doubleSided) shaderName += "DS";
                break;
            case BlendMode.Alphablend:
                shaderName += "/Transparent";
                if (transFix > 0) shaderName += "Fix";
                if (transFix > 1) shaderName += "2";
                if (doubleSided) shaderName += "DS";
                break;
            default:
                break;
        }
        material.shader = Shader.Find(shaderName);
    }
}