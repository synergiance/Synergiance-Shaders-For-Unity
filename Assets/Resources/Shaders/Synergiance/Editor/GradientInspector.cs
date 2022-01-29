// AckToon GUI

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace Synergiance.Shaders.AckToon {
	public class GradientInspector : BaseInspector {

		protected override bool hasGradient { get { return true; }}

		protected override void DoToon() {
			ShaderProperty("_ToonIntensity");
			GradientProperty(MakeLabel("Toon Gradient"), "_Toon", false);
		}
	}
}