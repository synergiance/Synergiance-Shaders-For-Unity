float3 RotatePointAroundOrigin(float3 input, float2 angles) {
    // float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
	float2 sn, cs;
	sincos(angles, sn, cs);
    float2 a = float2(cs.y, sn.y);
    float2 b = float2(a.y * -1, a.x);
    float2 c = float2(cs.x, sn.x);
    float3 d = float3(c.x * a.x, a.y, c.y * a.x);
    float3 e = float3(c.x * b.x, b.y, c.y * b.x);
    float3 f = normalize(cross(d, e));
    float3x3 g = float3x3(d, e, f);
    float3 h = normalize(mul(input, g));
    return float3(h);
}

float3x3 GetRotationMatrixAxis(float3 axis, float angle) {
	float3 n = normalize(axis);
	// Rodrigues formula converting axis-angle to an euler rotation matrix
	float cs, sn;
	sincos(angle, sn, cs);
	float om = 1 - cs;
	float xx = n.x * n.x;
	float yy = n.y * n.y;
	float zz = n.z * n.z;
	float xy = n.x * n.y;
	float xz = n.x * n.z;
	float yz = n.y * n.z;
	float3 a = float3(cs + xx * om, xy * om - n.z * sn, xz * om + n.y * sn);
	float3 b = float3(xy * om + n.z * sn, cs + yy * om, yz * om - n.x * sn);
	float3 c = float3(xz * om - n.y * sn, yz * om + n.x * sn, cs + zz * om);
	return float3x3(a, b, c);
}

float3 RotatePointAroundAxis(float3 input, float3 axis, float angle) {
	return mul(input, GetRotationMatrixAxis(axis, angle));
}