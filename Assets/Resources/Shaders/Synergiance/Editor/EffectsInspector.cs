using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace Synergiance.Shaders.AckToon {
    public class EffectsInspector : BaseInspector {
        protected override bool hasEffects => true;

        protected override void DoEffects() {
            MaterialProperty emissionNoise = FindProperty("_EmissionNoise");
            ShaderProperty(emissionNoise, "Emission Noise");
            if (emissionNoise.floatValue > 0) {
                EditorGUI.indentLevel += 2;
                ShaderProperty("_EmissionNoiseSpeed", "Speed");
                ShaderProperty("_EmissionIterations", "Iterations");
                ShaderProperty("_EmissionNoiseDensity", "Density");
                MaterialProperty emissionNoiseUVChannel = FindProperty("_EmissionNoiseCoords");
                ShaderProperty(emissionNoiseUVChannel, "Coordinate Space");
                if (emissionNoiseUVChannel.floatValue >= 2) {
                    EditorGUI.indentLevel += 2;
                    ShaderProperty("_EmissionNoise3DUV", "Channel is 3D");
                    EditorGUI.indentLevel -= 2;
                }
                EditorGUI.indentLevel -= 2;
            }
        }
    }
}
