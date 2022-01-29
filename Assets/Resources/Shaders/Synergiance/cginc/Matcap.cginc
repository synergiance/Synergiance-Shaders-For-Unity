#ifndef SYNMATCAP
#define SYNMATCAP

#include "Structs.cginc"

float2 calcMatcapCoords(float3 viewDir, float3 normal) {
    float3 tangent = normalize(cross(viewDir, float3(0.0, 1.0, 0.0)));
    float3 bitangent = normalize(cross(tangent, viewDir));
    float3 viewNormal = normalize(mul(float3x3(tangent, bitangent, viewDir), normal));
    return viewNormal.xy * 0.5 + 0.5;
}

#endif // SYNMATCAP
