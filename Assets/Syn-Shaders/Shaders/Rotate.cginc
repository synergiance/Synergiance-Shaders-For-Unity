float3 RotatePointAroundOrigin(float3 input, float2 angles) {
    // float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
    float2 a = float2(cos(angles.y), sin(angles.y));
    float2 b = float2(a.y * -1, a.x);
    float2 c = float2(cos(angles.x), sin(angles.x));
    float3 d = float3(c.x * a.x, a.y, c.y * a.x);
    float3 e = float3(c.x * b.x, b.y, c.y * b.x);
    float3 f = normalize(cross(d, e));
    float3x3 g = float3x3(d, e, f);
    float3 h = normalize(mul(input, g));
    return float3(h);
}

float3 RotatePointAroundAxis(float3 input, float3 axis, float angle) {
	float3 n = normalize(axis);
	// 3D matrix formula from axis and angle
	float3 a = float3(cos(angle) + n.x * n.x * (1 - cos(angle)), n.x * n.y * (1 - cos(angle)) - n.z * sin(angle), n.x * n.z * (1 - cos(angle)) + n.y * sin(angle));
	float3 b = float3(n.x * n.y * (1 - cos(angle)) + n.z * sin(angle), cos(angle) + n.y * n.y * (1 - cos(angle)), n.y * n.z * (1 - cos(angle)) - n.x * sin(angle));
	float3 c = float3(n.x * n.z * (1 - cos(angle)) - n.y * sin(angle), n.y * n.z * (1 - cos(angle)) + n.x * sin(angle), cos(angle) + n.z * n.z * (1 - cos(angle)));
	float3x3 r = float3x3(a, b, c);
	return mul(input, r);
}