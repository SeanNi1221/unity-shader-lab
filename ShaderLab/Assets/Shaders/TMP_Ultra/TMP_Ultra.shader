Shader "TextMeshPro/Ultra/Simple" {
  Properties {

    // General
    _FaceTex        ("Face Texture", 2D) = "white" {}
    _Color          ("Color", Color) = (1,1,1,1)

    _WeightNormal		("Weight Normal", float) = 0
    _WeightBold			("Weight Bold", float) = 0.5

    // 3D
    _MinStep        ("Raymarch Min Step", Range(0.001, 0.1)) = 0.01
    _DepthColor     ("Depth Color", Color) = (.25, .5, .5, 1)
    _DepthTex       ("Depth Texture", 2D) = "white" {}

    // Outline
    _OutlineColor   ("Outline Color", Color) = (0,0,0,1)
    _OutlineWidth		("Outline Thickness", Range(0, 1)) = 0
    _OutlineSoftness	("Outline Softness", Range(0,1)) = 0

    // Font Atlas Properties
    _MainTex			("Font Atlas", 2D) = "white" {}
    _TextureWidth		("Texture Width", float) = 512
    _TextureHeight		("Texture Height", float) = 512
    _GradientScale		("Gradient Scale", float) = 5.0
		_ScaleX("Scale X", float) = 1.0
    _ScaleY				("Scale Y", float) = 1.0
    _PerspectiveFilter	("Perspective Correction", Range(0, 1)) = 0.875
    _Sharpness			("Sharpness", Range(-1,1)) = 0

    // TMP Internal
    _ScaleRatioA		("Scale RatioA", float) = 1
    _ScaleRatioB		("Scale RatioB", float) = 1
    _ScaleRatioC		("Scale RatioC", float) = 1
  }

  SubShader {
    Tags {
      "Queue" = "Geometry"
      "IgnoreProjector" = "True"
			"RenderType" = "Geometry"
    }

    Lighting Off
    Fog { Mode Off }

    Blend SrcAlpha OneMinusSrcAlpha

    Pass {
      Stencil {
        Ref 2
        Comp Always
        Pass replace
      }

      CGPROGRAM
      #pragma target 3.0
      #pragma vertex VertShader
      #pragma geometry GeomShader
      #pragma fragment PixShader

      #pragma shader_feature __ OUTLINE_ON
      #pragma shader_feature __ MAXSTEPS_96
      #pragma shader_feature __ DEBUG_MASK

      #pragma require geometry

      #include "UnityCG.cginc"
      #include "Common.hlsl"

      #define MAX_STEPS 128

      tmp_plus_v2g VertShader(tmp_plus_a2v input) {

        tmp_plus_v2g o;

        o.position = mul(unity_ObjectToWorld, input.position);
        o.normal = mul(unity_ObjectToWorld, input.normal);
        o.color = input.color;
        o.uv0 = input.uv0;
        o.uv1 = input.uv1;
        o.uv2 = input.uv2;

        return o;
      }

      // Extrudes the TMP quads
      //
      // TODO: Clarify - No shared vertices?
      [maxvertexcount(24)]
      void GeomShader(triangle tmp_plus_v2g input[3],
                      inout TriangleStream<tmp_plus_g2f> triStream) {

        tmp_plus_g2f o;

        float3 def = float3(0, 0, 0);
        float depth = input[0].uv2.r;
        float3 extrusion = input[0].normal * depth;

        float skewUV = abs(input[1].uv0.x - input[0].uv0.x);
        float widthUV = abs(input[2].uv0.x - input[1].uv0.x);
        float heightUV = abs(input[1].uv0.y - input[0].uv0.y);
        float xUV = min(input[0].uv0.x, input[2].uv0.x);
        float yUV = min(input[0].uv0.y, input[1].uv0.y);
        float4 boundariesUV = float4(xUV, yUV, widthUV, heightUV);

        // World to local positions
        float3 v0Local = mul(unity_WorldToObject, float4(input[0].position.xyz, 1)).xyz;
        float3 v1Local = mul(unity_WorldToObject, float4(input[1].position.xyz, 1)).xyz;
        float3 v2Local = mul(unity_WorldToObject, float4(input[2].position.xyz, 1)).xyz;

        float skewLocal = abs(v1Local.x - v0Local.x);
        float widthLocal = abs(v2Local.x - v1Local.x);
        float heightLocal = abs(v1Local.y - v0Local.y);
        float xLocal = min(v0Local.x, v2Local.x);
        float yLocal = min(v0Local.y, v1Local.y);
        float4 boundariesLocal = float4(xLocal, yLocal, widthLocal, heightLocal);

        // TODO: What is this?
        float4 boundariesLocalZ = float4(-depth, 0, skewLocal, skewUV);

        FillGeometry(input, triStream, def, extrusion,
                     boundariesUV, boundariesLocal, boundariesLocalZ);
      }

      pixel_t PixShader(tmp_plus_g2f input) {
        UNITY_SETUP_INSTANCE_ID(input);

        pixel_t o;
        o.color = _Color;
        o.depth = 0;

        // float bold = step(input.tmp.y, 0);
        // float edge = lerp(_WeightNormal, _WeightBold, bold);
        // edge += _OutlineWidth;

        // float charDepth = input.tmpUltra.x;
        // float2 depthMapped = input.tmpUltra.yz;

        return ValidatePixel(o, 0);
      }
      ENDCG
    }
  }
}