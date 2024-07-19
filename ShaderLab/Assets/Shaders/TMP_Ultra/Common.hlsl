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
struct vertex_t {
  UNITY_VERTEX_INPUT_INSTANCE_ID
  float4  position			: POSITION;
  float3  normal        : NORMAL;
  fixed4  color         : COLOR;
  float2  uv0           : TEXCOORD0;
  float2  uv1           : TEXCOORD1;
  float2  uv2           : TEXCOORD2;
}

struct geometry_t {
  UNITY_VERTEX_INPUT_INSTANCE_ID
  float4  position			: POSITION;
  float3  normal        : NORMAL;
  fixed4  color         : COLOR;
  float2  uv0           : TEXCOORD0;
  float2  uv1           : TEXCOORD1;
  float2  uv2           : TEXCOORD2;
}

struct pixel_t {
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
}

// =================================================================================================
// Functions
// =================================================================================================

#endif