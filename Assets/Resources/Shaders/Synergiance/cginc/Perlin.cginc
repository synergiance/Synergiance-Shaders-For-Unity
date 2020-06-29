#ifndef PERLIN_NOISE
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
#define PERLIN_NOISE

// Hash lookup table as defined by Ken Perlin.  This is a randomly
// arranged array of all numbers from 0-255 inclusive.
static uint p[256] = {
    151,160,137, 91, 90, 15,131, 13,201, 95, 96, 53,194,233,  7,225,
    140, 36,103, 30, 69,142,  8, 99, 37,240, 21, 10, 23,190,  6,148,
    247,120,234, 75,  0, 26,197, 62, 94,252,219,203,117, 35, 11, 32,
     57,177, 33, 88,237,149, 56, 87,174, 20,125,136,171,168, 68,175,
     74,165, 71,134,139, 48, 27,166, 77,146,158,231, 83,111,229,122,
     60,211,133,230,220,105, 92, 41, 55, 46,245, 40,244,102,143, 54,
     65, 25, 63,161,  1,216, 80, 73,209, 76,132,187,208, 89, 18,169,
    200,196,135,130,116,188,159, 86,164,100,109,198,173,186,  3, 64,
     52,217,226,250,124,123,  5,202, 38,147,118,126,255, 82, 85,212,
    207,206, 59,227, 47, 16, 58, 17,182,189, 28, 42,223,183,170,213,
    119,248,152,  2, 44,154,163, 70,221,153,101,155,167, 43,172,  9,
    129, 22, 39,253, 19, 98,108,110, 79,113,224,232,178,185,112,104,
    218,246, 97,228,251, 34,242,193,238,210,144, 12,191,179,162,241,
     81, 51,145,235,249, 14,239,107, 49,192,214, 31,181,199,106,157,
    184, 84,204,176,115,121, 50, 45,127,  4,150,254,138,236,205, 93,
    222,114, 67, 29, 24, 72,243,141,128,195, 78, 66,215, 61,156,180
};

float3 fade3(float3 t) { // Fade function as defined by Ken Perlin
    return t * t * t * (t * (t * 6 - 15) + 10); // 6t^5 - 15t^4 + 10t^3
}

float2 fade2(float2 t) { // Fade function as defined by Ken Perlin
    return t * t * t * (t * (t * 6 - 15) + 10); // 6t^5 - 15t^4 + 10t^3
}

float fade(float t) { // Fade function as defined by Ken Perlin
    return t * t * t * (t * (t * 6 - 15) + 10); // 6t^5 - 15t^4 + 10t^3
}

float perlRand(int2 coords, float offset) {
    return frac(sin(coords.x * 13.6827 + coords.y + 76.3433 + offset) * 44257.8944);
}

float2 randVec(int2 coords, float offset) {
	float2 ret;
    sincos(radians(perlRand(coords, offset) * 360), ret.x, ret.y);
    return ret;
}

float dotVecFunc(int ix, int iy, float2 coords, float offset) {
    float2 dist = coords - float2(ix, iy);
    return dot(dist, perlRand(int2(ix, iy), offset));
}

// http://adrianb.io/2014/08/09/perlinnoise.html
// https://catlikecoding.com/unity/tutorials/noise/
float grad3(uint hash, float x, float y, float z) {
    uint h = hash % 16;
    float u = h < 8 ? x : y;
    float v = h < 4 ? y : (h == 12 || h == 14 ? x : z);
    return u * ((h % 2) == 0 ? 1 : -1) + v * ((h % 4) < 2 ? 1 : -1);
} // This should be bitwise & operators but those don't seem to be working

float grad2(uint hash, float x, float y) {
    uint h = hash % 8;
    float u, v;
    if (h & 4 == 0) v = y;
    else v = -y;
    if (h & 2 == 0) u = x;
    else u = y;
    if (h & 1 != 0) u *= -1;
    return u;
}

float grad(uint hash, float coord) {
    return (hash & 1) == 0 ? coord : -coord;
}

float perlin3D(float3 coords) {
    int3 iLo = floor(coords);
    int3 iHi = iLo + 1;
    float3 t0 = coords - iLo;
    float3 t1 = t0 - 1;
    float3 itpl = fade3(t0);

    uint a = p[iLo.x & 255];
    uint b = p[iHi.x & 255];
    uint aa = p[(a + iLo.y) & 255];
    uint ba = p[(b + iLo.y) & 255];
    uint ab = p[(a + iHi.y) & 255];
    uint bb = p[(b + iHi.y) & 255];
    uint aaa = p[(aa + iLo.z) & 255];
    uint baa = p[(ba + iLo.z) & 255];
    uint aba = p[(ab + iLo.z) & 255];
    uint bba = p[(bb + iLo.z) & 255];
    uint aab = p[(aa + iHi.z) & 255];
    uint bab = p[(ba + iHi.z) & 255];
    uint abb = p[(ab + iHi.z) & 255];
    uint bbb = p[(bb + iHi.z) & 255];

    float4 g0, g1;
    g0.x = grad3(aaa, t0.x, t0.y, t0.z);
    g0.y = grad3(aab, t0.x, t0.y, t1.z);
    g0.z = grad3(aba, t0.x, t1.y, t0.z);
    g0.w = grad3(abb, t0.x, t1.y, t1.z);
    g1.x = grad3(baa, t1.x, t0.y, t0.z);
    g1.y = grad3(bab, t1.x, t0.y, t1.z);
    g1.z = grad3(bba, t1.x, t1.y, t0.z);
    g1.w = grad3(bbb, t1.x, t1.y, t1.z);
    g0 = lerp(g0, g1, itpl.x);
    g0.xy = lerp(g0.xy, g0.zw, itpl.y);
    return lerp(g0.x, g0.y, itpl.z);
}

float perlin3DOffset(float3 coords, float offset) {
    int3 iLo = floor(coords);
    int3 iHi = iLo + 1;
    int oLo = floor(offset);
    int oHi = oLo + 1;
    float3 t0 = coords - iLo;
    float3 t1 = t0 - 1;
    float3 itpl = fade3(t0);
    float itplOffset = offset - oLo;

    uint a = p[iLo.x & 255];
    uint b = p[iHi.x & 255];
    uint aa = p[(a + iLo.y) & 255];
    uint ba = p[(b + iLo.y) & 255];
    uint ab = p[(a + iHi.y) & 255];
    uint bb = p[(b + iHi.y) & 255];
    uint aaa = p[(aa + iLo.z) & 255];
    uint baa = p[(ba + iLo.z) & 255];
    uint aba = p[(ab + iLo.z) & 255];
    uint bba = p[(bb + iLo.z) & 255];
    uint aab = p[(aa + iHi.z) & 255];
    uint bab = p[(ba + iHi.z) & 255];
    uint abb = p[(ab + iHi.z) & 255];
    uint bbb = p[(bb + iHi.z) & 255];
    uint aaaa = p[(aaa + oLo) & 255];
    uint baaa = p[(baa + oLo) & 255];
    uint abaa = p[(aba + oLo) & 255];
    uint bbaa = p[(bba + oLo) & 255];
    uint aaba = p[(aab + oLo) & 255];
    uint baba = p[(bab + oLo) & 255];
    uint abba = p[(abb + oLo) & 255];
    uint bbba = p[(bbb + oLo) & 255];
    uint aaab = p[(aaa + oHi) & 255];
    uint baab = p[(baa + oHi) & 255];
    uint abab = p[(aba + oHi) & 255];
    uint bbab = p[(bba + oHi) & 255];
    uint aabb = p[(aab + oHi) & 255];
    uint babb = p[(bab + oHi) & 255];
    uint abbb = p[(abb + oHi) & 255];
    uint bbbb = p[(bbb + oHi) & 255];

    float4 g0, g1, g2, g3;
    g0.x = grad3(aaaa, t0.x, t0.y, t0.z);
    g0.y = grad3(aaba, t0.x, t0.y, t1.z);
    g0.z = grad3(abaa, t0.x, t1.y, t0.z);
    g0.w = grad3(abba, t0.x, t1.y, t1.z);
    g1.x = grad3(baaa, t1.x, t0.y, t0.z);
    g1.y = grad3(baba, t1.x, t0.y, t1.z);
    g1.z = grad3(bbaa, t1.x, t1.y, t0.z);
    g1.w = grad3(bbba, t1.x, t1.y, t1.z);
    g2.x = grad3(aaab, t0.x, t0.y, t0.z);
    g2.y = grad3(aabb, t0.x, t0.y, t1.z);
    g2.z = grad3(abab, t0.x, t1.y, t0.z);
    g2.w = grad3(abbb, t0.x, t1.y, t1.z);
    g3.x = grad3(baab, t1.x, t0.y, t0.z);
    g3.y = grad3(babb, t1.x, t0.y, t1.z);
    g3.z = grad3(bbab, t1.x, t1.y, t0.z);
    g3.w = grad3(bbbb, t1.x, t1.y, t1.z);
    g0 = lerp(g0, g2, itplOffset);
    g1 = lerp(g1, g3, itplOffset);
    g0 = lerp(g0, g1, itpl.x);
    g0.xy = lerp(g0.xy, g0.zw, itpl.y);
    return lerp(g0.x, g0.y, itpl.z);
}

#endif