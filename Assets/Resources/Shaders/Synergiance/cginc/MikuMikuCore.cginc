#ifndef SYN_MMD_CORE
#define SYN_MMD_CORE

#define CALC_POSTLIGHT calcMatcap(s);

#define HAS_MATCAP
#define SHADOWRAMP
#define CUSTOM_VERT
#define USE_TOON_VERT
#include "Lighting/ToonSpecular.cginc"

Texture2D _SphereAddTex;
Texture2D _SphereMulTex;
Texture2D _SphereMask;
SamplerState sampler_SphereAddTex;

void calcMatcap(shadingData s) {
    float4 mcp = _SphereMulTex.Sample(sampler_SphereAddTex, s.uvCap);
    float4 mcm = _SphereMask.Sample(sampler_MainTex, s.uv.xy);
    #ifdef USEALPHA
        s.alpha *= lerp(1, mcp.a, mcm.a);
    #endif
    s.color *= lerp(1, mcp.rgb, mcm.rgb);
    #ifdef BASE_PASS
        mcp = _SphereAddTex.Sample(sampler_SphereAddTex, s.uvCap);
        s.specular.rgb += mcp.rgb * mcp.a * s.light * mcm.rgb * mcm.a;
    #endif
}

#include "ToonCore.cginc"

#endif