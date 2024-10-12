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
sampler2D         _DepthTex;

// Outline
uniform fixed4		_OutlineColor;
uniform float		_OutlineWidth;

// Font Atlas properties
uniform sampler2D _MainTex;
uniform float     _TextureWidth;
uniform float     _TextureHeight;
uniform float     _GradientScale;

// TMP Internal
uniform float     _ScaleRatioA;
uniform float     _ScaleRatioB;
uniform float     _ScaleRatioC;

// Used by Unity internally to handle Texture Tiling and Offset.
float4 _MainTex_TexelSize;
float4            _FaceTex_ST;
float4            _OutlineTex_ST;

// =================================================================================================
// Structs
// =================================================================================================
struct tmp_plus_a2v {
  UNITY_VERTEX_INPUT_INSTANCE_ID
  float4  objPos        : POSITION;
  float3  normal        : NORMAL;
  fixed4  color         : COLOR;
  float2  texcoord0     : TEXCOORD0;
  float2  texcoord1     : TEXCOORD1;
  float4  param3d       : TEXCOORD2;
  float4  tangent       : TANGENT;
};

struct tmp_plus_v2g {
  UNITY_VERTEX_INPUT_INSTANCE_ID
  float4  worldPos   	: POSITION;
  float3  normal        : NORMAL;
  fixed4  color         : COLOR;
  float2  atlas         : TEXCOORD0;
  float2  texcoord1     : TEXCOORD1;
  float4  param3d       : TEXCOORD2;
  half3x3 worldToTangent: TEXCOORD3;
};

struct tmp_plus_g2f {
  UNITY_VERTEX_INPUT_INSTANCE_ID
  float4  clipPos			: SV_POSITION;
  fixed4  color             : COLOR;
  float2  atlas             : TEXCOORD0;
  float2  texcoord1         : TEXCOORD1; // tilling, bold
  float4  boundsUV          : TEXCOORD2;
  float4  bounds            : TEXCOORD3; // x, y, width, height
  float4  boundsZ           : TEXCOORD4; // tangentPosZ-depth, tangentPosZ, skew, skewUV
  float4  param3d           : TEXCOORD5; // depth, mappingx, mappingy=1, _
  float4  worldPos          : TEXCOORD6;
  half3x3 worldToTangent    : TEXCOORD7;
};

struct pixel_t {
  fixed4 color : SV_Target;
  float  depth : SV_Depth;
};

// =================================================================================================
// Functions
// =================================================================================================
float ComputeDepth(float4 clipPos) {

  // TODO: Verify if this is enough without SHADER_API_GLES and SHADER_API_GLES3
  #if defined(SHADER_TARGET_GLSL)

  return (clipPos.z / clipPos.w) * 0.5 + 0.5;
  #else
    return clipPos.z / clipPos.w;
  #endif
}

float InverseLerp(float a, float b, float value) {
  return (value - a) / (b - a);
}

tmp_plus_g2f CreateVertex(tmp_plus_v2g input, float3 worldOffset,
                          float4 boundsUV, float4 bounds, float4 boundsZ) {
  tmp_plus_g2f o;

  input.normal = mul(unity_WorldToObject, input.normal);

  UNITY_INITIALIZE_OUTPUT(tmp_plus_g2f, o);
  UNITY_SETUP_INSTANCE_ID(input);
  UNITY_TRANSFER_INSTANCE_ID(input, o);
  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

  input.worldPos /= input.worldPos.w;

  o.worldPos = input.worldPos;
  o.worldPos.xyz += worldOffset;

  // worldPos is converted to clip space
  // TODO: Investigate simpler alternatives for converting world to clip
  float4 vert = mul(unity_WorldToObject, o.worldPos);
  float4 clipPos = UnityObjectToClipPos(vert);

  o.clipPos = clipPos; // clip space
  o.color = input.color;
  o.atlas = input.atlas;
  o.boundsUV = boundsUV;
  o.bounds = bounds;
  o.boundsZ = boundsZ;
  o.param3d = input.param3d;
  o.texcoord1 = input.texcoord1;
  o.worldToTangent = input.worldToTangent;

  return o;
}

void FillGeometry(triangle tmp_plus_v2g input[3], inout TriangleStream<tmp_plus_g2f> triStream,
    float3 baseOffset, float3 worldExtrusion, float4 boundsUV, float4 bounds,
    float4 boundsZ) {

// Top
  triStream.RestartStrip();
  triStream.Append(
      CreateVertex(input[0], worldExtrusion, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[1], worldExtrusion, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[2], worldExtrusion, boundsUV, bounds, boundsZ));


  // Bottom
  triStream.RestartStrip();
  triStream.Append(
      CreateVertex(input[2], baseOffset, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[1], baseOffset, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[0], baseOffset, boundsUV, bounds, boundsZ));

  // Side A1
  triStream.RestartStrip();
  triStream.Append(
      CreateVertex(input[0], worldExtrusion, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[0], baseOffset, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[1], worldExtrusion, boundsUV, bounds, boundsZ));

  // Side A2
  triStream.RestartStrip();
  triStream.Append(
      CreateVertex(input[0], baseOffset, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[1], baseOffset, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[1], worldExtrusion, boundsUV, bounds, boundsZ));

  // Side B1
  triStream.RestartStrip();
  triStream.Append(
      CreateVertex(input[1], worldExtrusion, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[1], baseOffset, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[2], worldExtrusion, boundsUV, bounds, boundsZ));

  // Side B2
  triStream.RestartStrip();
  triStream.Append(
      CreateVertex(input[1], baseOffset, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[2], baseOffset, boundsUV, bounds, boundsZ));
  triStream.Append(
      CreateVertex(input[2], worldExtrusion, boundsUV, bounds, boundsZ));

  // Side C is in between of the quad's triangles and not needed.
}
#endif