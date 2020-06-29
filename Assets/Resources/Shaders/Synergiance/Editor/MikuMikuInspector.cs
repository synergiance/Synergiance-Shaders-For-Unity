// AckToon GUI

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace Synergiance.Shaders.AckToon {
	public class MikuMikuInspector : BaseInspector {

		protected override bool hasGradient { get { return true; }}

		protected override void DoToon() {
			ShaderProperty("_ToonIntensity");
			editor.TexturePropertySingleLine(MakeLabel("Toon Ramp", "Toon Ramp (RGBA) Use alpha channel as control ramp"), FindProperty("_ShadowRamp"));
			editor.TexturePropertySingleLine(MakeLabel("Additive MatCap", "Additive MatCap (Sphere Texture .spa files)"), FindProperty("_SphereAddTex"));
			editor.TexturePropertySingleLine(MakeLabel("Multiplicative MatCap", "Multiplicative MatCap (Sphere Texture .sph files)"), FindProperty("_SphereMulTex"));
			editor.TexturePropertySingleLine(MakeLabel("MatCap Mask Texture", "Masks each RGBA channel separately"), FindProperty("_SphereMask"));
		}
	}
}