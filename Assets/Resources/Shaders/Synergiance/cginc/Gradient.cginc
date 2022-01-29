#ifndef SYNGRADIENT
#define SYNGRADIENT

#define LERPGRADIENTALPHA(prefix, numa, numb, val) lerp(_##prefix##Alpha##numa##.x, _##prefix##Alpha##numb##.x, FlatStep(_##prefix##Alpha##numa##.y, _##prefix##Alpha##numb##.y, val))
#define LERPGRADIENTCOLOR(prefix, numa, numb, val) lerp(_##prefix##Color##numa##,   _##prefix##Color##numb##,   FlatStep(_##prefix##Alpha##numa##.z, _##prefix##Alpha##numb##.z, val))

#define DEFINEGRADIENT(prefix) \
float3 _##prefix##Alpha1; \
float3 _##prefix##Alpha2; \
float3 _##prefix##Alpha3; \
float3 _##prefix##Alpha4; \
float3 _##prefix##Alpha5; \
float3 _##prefix##Alpha6; \
float3 _##prefix##Alpha7; \
float3 _##prefix##Alpha8; \
float3 _##prefix##Color1; \
float3 _##prefix##Color2; \
float3 _##prefix##Color3; \
float3 _##prefix##Color4; \
float3 _##prefix##Color5; \
float3 _##prefix##Color6; \
float3 _##prefix##Color7; \
float3 _##prefix##Color8; \
float4 SampleGradient##prefix##(float val) { \
    float4 col = 0; \
    [branch] if (val < _##prefix##Alpha1.y) { \
        col.a = _##prefix##Alpha1.x; \
    } else if (val < _##prefix##Alpha2.y) { \
        col.a = LERPGRADIENTALPHA(prefix, 1, 2, val); \
    } else if (_##prefix##Alpha3.y == -1) { \
        col.a = _##prefix##Alpha2.x; \
    } else if (val < _##prefix##Alpha3.y) { \
        col.a = LERPGRADIENTALPHA(prefix, 2, 3, val); \
    } else if (_##prefix##Alpha4.y == -1) { \
        col.a = _##prefix##Alpha3.x; \
    } else if (val < _##prefix##Alpha4.y) { \
        col.a = LERPGRADIENTALPHA(prefix, 3, 4, val); \
    } else if (_##prefix##Alpha5.y == -1) { \
        col.a = _##prefix##Alpha4.x; \
    } else if (val < _##prefix##Alpha5.y) { \
        col.a = LERPGRADIENTALPHA(prefix, 4, 5, val); \
    } else if (_##prefix##Alpha6.y == -1) { \
        col.a = _##prefix##Alpha5.x; \
    } else if (val < _##prefix##Alpha6.y) { \
        col.a = LERPGRADIENTALPHA(prefix, 5, 6, val); \
    } else if (_##prefix##Alpha7.y == -1) { \
        col.a = _##prefix##Alpha6.x; \
    } else if (val < _##prefix##Alpha7.y) { \
        col.a = LERPGRADIENTALPHA(prefix, 6, 7, val); \
    } else if (_##prefix##Alpha8.y == -1) { \
        col.a = _##prefix##Alpha7.x; \
    } else if (val < _##prefix##Alpha8.y) { \
        col.a = LERPGRADIENTALPHA(prefix, 7, 8, val); \
    } else { \
        col.a = _##prefix##Alpha8.x; \
    } \
    [branch] if (val < _##prefix##Alpha1.z) { \
        col.rgb = _##prefix##Color1; \
    } else if (val < _##prefix##Alpha2.z) { \
        col.rgb = LERPGRADIENTCOLOR(prefix, 1, 2, val); \
    } else if (_##prefix##Alpha3.z == -1) { \
        col.rgb = _##prefix##Color2; \
    } else if (val < _##prefix##Alpha3.z) { \
        col.rgb = LERPGRADIENTCOLOR(prefix, 2, 3, val); \
    } else if (_##prefix##Alpha4.z == -1) { \
        col.rgb = _##prefix##Color3; \
    } else if (val < _##prefix##Alpha4.z) { \
        col.rgb = LERPGRADIENTCOLOR(prefix, 3, 4, val); \
    } else if (_##prefix##Alpha5.z == -1) { \
        col.rgb = _##prefix##Color4; \
    } else if (val < _##prefix##Alpha5.z) { \
        col.rgb = LERPGRADIENTCOLOR(prefix, 4, 5, val); \
    } else if (_##prefix##Alpha6.z == -1) { \
        col.rgb = _##prefix##Color5; \
    } else if (val < _##prefix##Alpha6.z) { \
        col.rgb = LERPGRADIENTCOLOR(prefix, 5, 6, val); \
    } else if (_##prefix##Alpha7.z == -1) { \
        col.rgb = _##prefix##Color6; \
    } else if (val < _##prefix##Alpha7.z) { \
        col.rgb = LERPGRADIENTCOLOR(prefix, 6, 7, val); \
    } else if (_##prefix##Alpha8.z == -1) { \
        col.rgb = _##prefix##Color7; \
    } else if (val < _##prefix##Alpha8.z) { \
        col.rgb = LERPGRADIENTCOLOR(prefix, 7, 8, val); \
    } else { \
        col.rgb = _##prefix##Color8; \
    } \
    return col; \
}

float FlatStep(float low, float high, float val) {
    return saturate((val - low) / (high - low));
}

#endif // SYNGRADIENT