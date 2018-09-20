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