// HSB

inline float3 applyHue(float3 aColor, float aHue)
{
    float angle = radians(aHue);
    float3 k = float3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(angle);
    //Rodrigues' rotation formula
    return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1 - cosAngle);
}
 
 
inline float4 applyHSBEffect(float4 startColor, fixed4 hsbc)
{
    float _Hue = 360 * hsbc.r;
    float _Brightness = hsbc.g * 2 - 1;
    float _Contrast = hsbc.b * 2;
    float _Saturation = hsbc.a * 2;
 
    float4 outputColor = startColor;
    outputColor.rgb = applyHue(outputColor.rgb, _Hue);
    outputColor.rgb = (outputColor.rgb - 0.5f) * (_Contrast) + 0.5f;
    outputColor.rgb = outputColor.rgb + _Brightness;      
    float3 intensity = dot(outputColor.rgb, float3(0.299,0.587,0.114));
    outputColor.rgb = lerp(intensity, outputColor.rgb, _Saturation);
 
    return outputColor;
}

float Epsilon = 1e-10;

float3 RGBtoHCV(in float3 RGB)
{
    // Based on work by Sam Hocevar and Emil Persson
    float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
    float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
    return float3(H, C, Q.x);
}

float3 HUEtoRGB(in float H)
{
    float R = abs(H * 6 - 3) - 1;
    float G = 2 - abs(H * 6 - 2);
    float B = 2 - abs(H * 6 - 4);
    return saturate(float3(R,G,B));
}

float3 HSVtoRGB(in float3 HSV)
{
    float3 RGB = HUEtoRGB(HSV.x);
    return ((RGB - 1) * HSV.y + 1) * HSV.z;
}

float3 RGBtoHSV(in float3 RGB)
{
    float3 HCV = RGBtoHCV(RGB);
    float S = HCV.y / (HCV.z + Epsilon);
    return float3(HCV.x, S, HCV.z);
}
