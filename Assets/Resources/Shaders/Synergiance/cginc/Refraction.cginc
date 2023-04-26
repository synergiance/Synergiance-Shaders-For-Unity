// Function taken and modified from a refraction shader example

uniform float _ChromaticAberration;
uniform float _IndexofRefraction;
uniform sampler2D _RefractGrab;

float3 refractGrab(float3 normalDir, float4 screenPos, float3 viewDir) {
	//normalDir = normalDir + 0.00001 * screenPos * worldPos;
	float2 tempCoords = float2(2, -2) * UNITY_PROJ_COORD(ComputeGrabScreenPos(screenPos)).xy/ _ScreenParams.xy;
	float3 refractionOffset = ((((_IndexofRefraction - 1.0) * mul(UNITY_MATRIX_V, float4(normalDir, 0.0))) * (1.0 / (screenPos.z + 1.0))) * (1.0 - dot(normalDir, viewDir)));
	float2 cameraRefraction = float2(refractionOffset.x, -(refractionOffset.y * _ProjectionParams.x));
	float red = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_RefractGrab, tempCoords + cameraRefraction * (1.0 - _ChromaticAberration)).r;
	float green = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_RefractGrab, tempCoords + cameraRefraction).g;
	float blue = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_RefractGrab, tempCoords + cameraRefraction * (1.0 + _ChromaticAberration)).b;
	return float3(red, green, blue);
}
