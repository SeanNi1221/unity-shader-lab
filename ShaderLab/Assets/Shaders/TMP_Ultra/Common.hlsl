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
  float4  uv2           : TEXCOORD2; // x=depth, y=mappingx=0, z=mappingy=1, w=0
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
  float4  boundsUV      : TEXCOORD2;
  float4  boundsLocal   : TEXCOORD3;
  float4  boundsLocalZ  : TEXCOORD4;
  float4  tmpUltra          : TEXCOORD5;
  float2  tmp               : TEXCOORD6;
};

struct pixel_t {
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

tmp_plus_g2f CreateVertex(tmp_plus_v2g worldInput, float3 worldOffset,
                          float4 boundsUV, float4 boundsLocal, float4 boundsLocalZ) {
  tmp_plus_g2f o;

  // Normal is converted to object space
  worldInput.normal = mul(unity_WorldToObject, worldInput.normal);

  UNITY_INITIALIZE_OUTPUT(tmp_plus_g2f, o);
  UNITY_SETUP_INSTANCE_ID(worldInput);
  UNITY_TRANSFER_INSTANCE_ID(worldInput, o);
  UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

  // Position is unchanged in world space
  worldInput.position /= worldInput.position.w;

  o.worldPos = worldInput.position;
  o.worldPos.xyz += worldOffset;

  // Position is converted to clip space
  // TODO: Investigate simpler alternatives for converting world to clip
  float4 vert = mul(unity_WorldToObject, o.worldPos);
  float4 vPosition = UnityObjectToClipPos(vert);

  o.position = vPosition; // clip space
  o.color = worldInput.color;
  o.atlas = worldInput.uv0;
  o.boundsUV = boundsUV;
  o.boundsLocal = boundsLocal;
  o.boundsLocalZ = boundsLocalZ;
  o.tmpUltra = worldInput.uv2;
  o.tmp = worldInput.uv1;

  return o;
}

void FillGeometry(triangle tmp_plus_v2g worldInput[3], inout TriangleStream<tmp_plus_g2f> triStream,
    float3 baseOffset, float3 worldExtrusion, float4 boundsUV, float4 boundsLocal,
    float4 boundsLocalZ) {

  // Top
    triStream.RestartStrip();
    triStream.Append(
        CreateVertex(worldInput[0], worldExtrusion, boundsUV, boundsLocal, boundsLocalZ));
    triStream.Append(
        CreateVertex(worldInput[1], worldExtrusion, boundsUV, boundsLocal, boundsLocalZ));
    triStream.Append(
        CreateVertex(worldInput[2], worldExtrusion, boundsUV, boundsLocal, boundsLocalZ));


    // Bottom
    triStream.RestartStrip();
    triStream.Append(
        CreateVertex(worldInput[2], baseOffset, boundsUV, boundsLocal, boundsLocalZ));
    triStream.Append(
        CreateVertex(worldInput[1], baseOffset, boundsUV, boundsLocal, boundsLocalZ));
    triStream.Append(
        CreateVertex(worldInput[0], baseOffset, boundsUV, boundsLocal, boundsLocalZ));

    // Side A1
    // triStream.RestartStrip();
    // triStream.Append(
    //     CreateVertex(worldInput[0], worldExtrusion, boundsUV, boundsLocal, boundsLocalZ));
    // triStream.Append(
    //     CreateVertex(worldInput[0], baseOffset, boundsUV, boundsLocal, boundsLocalZ));
    // triStream.Append(
    //     CreateVertex(worldInput[1], worldExtrusion, boundsUV, boundsLocal, boundsLocalZ));

    // // Side A2
    // triStream.RestartStrip();
    // triStream.Append(
    //     CreateVertex(worldInput[0], baseOffset, boundsUV, boundsLocal, boundsLocalZ));
    // triStream.Append(
    //     CreateVertex(worldInput[1], baseOffset, boundsUV, boundsLocal, boundsLocalZ));
    // triStream.Append(
    //     CreateVertex(worldInput[1], worldExtrusion, boundsUV, boundsLocal, boundsLocalZ));

    // // Side B1
    // triStream.RestartStrip();
    // triStream.Append(
    //     CreateVertex(worldInput[1], worldExtrusion, boundsUV, boundsLocal, boundsLocalZ));
    // triStream.Append(
    //     CreateVertex(worldInput[1], baseOffset, boundsUV, boundsLocal, boundsLocalZ));
    // triStream.Append(
    //     CreateVertex(worldInput[2], worldExtrusion, boundsUV, boundsLocal, boundsLocalZ));

    // // Side B2
    // triStream.RestartStrip();
    // triStream.Append(
    //     CreateVertex(worldInput[1], baseOffset, boundsUV, boundsLocal, boundsLocalZ));
    // triStream.Append(
    //     CreateVertex(worldInput[2], baseOffset, boundsUV, boundsLocal, boundsLocalZ));
    // triStream.Append(
    //     CreateVertex(worldInput[2], worldExtrusion, boundsUV, boundsLocal, boundsLocalZ));

    // Side C is in between of the quad's triangles and not needed.
}

pixel_t ValidatePixel(pixel_t output, int step) {
  // TODO: Add debug modes (steps, mask, etc)
  return output;
}
#endif