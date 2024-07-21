#ifndef TMP_ULTRA_COMMON
#define TMP_ULTRA_COMMON

// =================================================================================================
// Properties
// =================================================================================================

// General
uniform sampler2D _FaceTex;
fixed4            _Color;
uniform float     _WeightBold;
uniform float     _WeightNormal;

// 3D
sampler2D         _DepthColor;

// Outline
uniform fixed4    _OutlineColor;
uniform float     _OutlineWidth;

// Font Atlas properties
uniform sampler2D _MainTex;
uniform float     _textureWidth;
uniform float     _textureHeight;
uniform float     _GradientScale;

// TMP Internal
uniform float     _ScaleRatioA;
uniform float     _ScaleRatioB;
uniform float     _ScaleRatioC;

// Used by Unity internally to handle Texture Tiling and Offset.
float4            _FaceTex_ST;
float4            _OutlineTex_ST;

// =================================================================================================
// Structs
// =================================================================================================
struct tmp_plus_a2v {
  UNITY_VERTEX_INPUT_INSTANCE_ID
  float4  position			: POSITION;
  float3  normal        : NORMAL;
  fixed4  color         : COLOR;
  float2  uv0           : TEXCOORD0;
  float2  uv1           : TEXCOORD1;
  float4  uv2           : TEXCOORD2;
};

struct tmp_plus_v2g {
  UNITY_VERTEX_INPUT_INSTANCE_ID
  float4  position			: POSITION;
  float3  normal        : NORMAL;
  fixed4  color         : COLOR;
  float2  uv0           : TEXCOORD0;
  float2  uv1           : TEXCOORD1;
  float4  uv2           : TEXCOORD2;
};

struct tmp_plus_g2f {
  UNITY_VERTEX_INPUT_INSTANCE_ID
  float4  position			    : SV_POSITION;
  fixed4  color             : COLOR;
  float2  atlas             : TEXCOORD0;
  float4  worldPos          : TEXCOORD1;
  float4  boundariesUV      : TEXCOORD2;
  float4  boundariesLocal   : TEXCOORD3;
  float4  boundariesLocalZ  : TEXCOORD4;
  float4  tmpUltra          : TEXCOORD5;
  float2  tmp               : TEXCOORD6;
};

struct PixelOutput {
  fixed4 color : SV_Target;
  float  depth : SV_Depth;
};

// =================================================================================================
// Functions
// =================================================================================================
float ComputeDepth(float4 clipPos) {
  #if defined(SHADER_TARGET_GLSL)
    return (clipPos.z / clipPos.w) * 0.5 + 0.5;
  #else
    return clipPos.z / clipPos.w;
  #endif
}
#endif