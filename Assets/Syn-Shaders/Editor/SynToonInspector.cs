// Written by Synergiance
// Significant portions taken and modified from FlatLitToon

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
        Ramp
    }
    
    public enum SphereMode
    {
        None,
        Add,
        Mul
    }

    MaterialProperty blendMode;
    MaterialProperty mainTexture;
    MaterialProperty color;
    MaterialProperty colorMask;
    MaterialProperty shadowMode;
    MaterialProperty shadowWidth;
    MaterialProperty shadowFeather;
    MaterialProperty shadowAmbient;
    MaterialProperty shadowTint;
    MaterialProperty shadowRamp;
    MaterialProperty outlineMode;
    MaterialProperty outlineWidth;
    MaterialProperty outlineFeather;
    MaterialProperty outlineColor;
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
    MaterialProperty sphereAddTex;
    MaterialProperty sphereMulTex;
    MaterialProperty sphereMode;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        { //Find Properties
            blendMode = FindProperty("_Mode", props);
            mainTexture = FindProperty("_MainTex", props);
            color = FindProperty("_Color", props);
            colorMask = FindProperty("_ColorMask", props);
            shadowMode = FindProperty("_ShadowMode", props);
            shadowWidth = FindProperty("_shadow_coverage", props);
            shadowFeather = FindProperty("_shadow_feather", props);
            shadowAmbient = FindProperty("_ShadowAmbient", props);
            shadowTint = FindProperty("_ShadowTint", props);
            shadowRamp = FindProperty("_ShadowRamp", props);
            outlineMode = FindProperty("_OutlineMode", props);
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
            alphaOverride = FindProperty("_AlphaOverride", props);
            sphereAddTex = FindProperty("_SphereAddTex", props);
            sphereMulTex = FindProperty("_SphereMulTex", props);
            sphereMode = FindProperty("_SphereMode", props);
        }
        
        Material material = materialEditor.target as Material;
        
        bool backfacecull = Array.IndexOf(material.shaderKeywords, "BCKFCECULL") != -1;
        bool rainbowEnable = Array.IndexOf(material.shaderKeywords, "RAINBOW") != -1;
        bool pulseEnable = Array.IndexOf(material.shaderKeywords, "PULSE") != -1;
        
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
                    }
                }

                EditorGUI.showMixedValue = false;
                
                EditorGUI.BeginChangeCheck();
                backfacecull = EditorGUILayout.Toggle("Backface Culling", backfacecull);
                if (EditorGUI.EndChangeCheck())
                {
                    if (backfacecull)
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.EnableKeyword("BCKFCECULL");
                            mat.SetInt("_CullMode", (int)UnityEngine.Rendering.CullMode.Back);
                        }
                    else
                        foreach (Material mat in materialEditor.targets)
                        {
                            mat.DisableKeyword("BCKFCECULL");
                            mat.SetInt("_CullMode", (int)UnityEngine.Rendering.CullMode.Off);
                        }
                }
                EditorGUILayout.Space();

                materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture", "Main Color Texture (RGB)"), mainTexture, color);
                EditorGUI.indentLevel += 2;
                if (((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout) || ((BlendMode)material.GetFloat("_Mode") == BlendMode.Alphablend))
                    materialEditor.ShaderProperty(alphaCutoff, "Alpha Cutoff", 2);
                if ((BlendMode)material.GetFloat("_Mode") == BlendMode.Alphablend)
                    materialEditor.ShaderProperty(alphaOverride, "Alpha Override", 2);
                materialEditor.TexturePropertySingleLine(new GUIContent("Color Mask", "Masks Color Tinting (G)"), colorMask);
                EditorGUI.indentLevel -= 2;
                materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map", "Normal Map (RGB)"), normalMap);
                materialEditor.TexturePropertySingleLine(new GUIContent("Emission", "Emission (RGB)"), emissionMap, emissionColor);
                
                EditorGUILayout.Space();
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
                materialEditor.ShaderProperty(brightness, "Brightness");

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
                        materialEditor.ShaderProperty(shadowWidth, "Coverage");
                        materialEditor.ShaderProperty(shadowFeather, "Feather");
                        materialEditor.ShaderProperty(shadowAmbient, "Ambient Light");
                        materialEditor.ShaderProperty(shadowTint, "Tint Color");
                        EditorGUI.indentLevel -= 2;
                        break;
                    case ShadowMode.Ramp:
                        EditorGUI.indentLevel += 2;
                        materialEditor.ShaderProperty(shadowAmbient, "Ambient Light");
                        materialEditor.TexturePropertySingleLine(new GUIContent("Shadow Ramp", "Shadow Ramp (RGBA)"), shadowRamp);
                        EditorGUILayout.LabelField("Set your texture's wrapping mode to clamp!");
                        EditorGUI.indentLevel -= 2;
                        break;
                    case ShadowMode.None:
                    default:
                        break;
                }
                EditorGUILayout.Space();

                var oMode = (OutlineMode)outlineMode.floatValue;

                EditorGUI.BeginChangeCheck();
                oMode = (OutlineMode)EditorGUILayout.Popup("Outline Mode", (int)oMode, Enum.GetNames(typeof(OutlineMode)));
                
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Outline Mode");
                    outlineMode.floatValue = (float)oMode;

                    foreach (var obj in outlineMode.targets)
                    {
                        SetupMaterialWithOutlineMode((Material)obj, (OutlineMode)material.GetFloat("_OutlineMode"));
                    }

                }
                switch (oMode)
                {
                    case OutlineMode.Tinted:
                    case OutlineMode.Colored:
                        materialEditor.ShaderProperty(outlineColor, "Color", 2);
                        materialEditor.ShaderProperty(outlineWidth, new GUIContent("Width", "Outline Width in percent"), 2);
                        materialEditor.ShaderProperty(outlineFeather, new GUIContent("Feather", "Outline Smoothness"), 2);
                        break;
                    case OutlineMode.None:
                    default:
                        break;
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
                material.EnableKeyword("NO_OUTLINE");
                material.DisableKeyword("TINTED_OUTLINE");
                material.DisableKeyword("COLORED_OUTLINE");
                break;
            case OutlineMode.Tinted:
                material.DisableKeyword("NO_OUTLINE");
                material.EnableKeyword("TINTED_OUTLINE");
                material.DisableKeyword("COLORED_OUTLINE");
                break;
            case OutlineMode.Colored:
                material.DisableKeyword("NO_OUTLINE");
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
            case ShadowMode.Ramp:
                material.DisableKeyword("NO_SHADOW");
                material.DisableKeyword("TINTED_SHADOW");
                material.EnableKeyword("RAMP_SHADOW");
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
}