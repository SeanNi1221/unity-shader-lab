Shader "TextMeshPro/Ultra/3D" {
  Properties {

    // General
    _FaceTex        ("Face Texture", 2D) = "white" {}
    _Color          ("Color", Color) = (1,1,1,1)
    _WeightBold			("Weight Bold", Range(0, 1)) = 0.6
    _WeightNormal		("Weight Normal", Range(0, 1)) = 0.5

    // 3D
    _MinStep        ("Raymarch Min Step", Range(0.001, 0.1)) = 0.01
    _DepthTex       ("Depth Texture", 2D) = "white" {}

		// Outline
		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth("Outline Thickness", Range(0,1)) = 0

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
      CGPROGRAM
      #pragma target 3.0
      #pragma vertex VertShader
      #pragma geometry GeomShader
      #pragma fragment PixShader

      #pragma require geometry

      #include "UnityCG.cginc"
      #include "Common.hlsl"
      #include "Raymarch.hlsl"

      #define MAX_STEPS 32


      tmp_plus_v2g VertShader(tmp_plus_a2v input) {

        tmp_plus_v2g o;
        o.worldPos = mul(unity_ObjectToWorld, input.objPos);
        o.normal = mul(unity_ObjectToWorld, input.normal);
        o.color = input.color;
        o.atlas = input.texcoord0;
        o.texcoord1 = input.texcoord1;
        o.param3d = input.param3d;

        return o;
      }

      // Extrudes the TMP quads
      [maxvertexcount(24)]
      void GeomShader(triangle tmp_plus_v2g input[3],
                      inout TriangleStream<tmp_plus_g2f> triStream) {

        tmp_plus_g2f o;

        float3 baseOffset = float3(0, 0, 0);

        // TODO: Consider removing this from param3d and use a property instead. The canvas
        // additional_currSampleAlpha shader channels are needed for this, and we don't know if this
        // conflicts with the internal TMP behaviours.
        float depth = input[0].param3d.x;

        // World space, assumes that all input normals are the same
        float3 worldExtrusion = input[0].normal * depth;

        float widthUV = abs(input[2].atlas.x - input[1].atlas.x);
        float heightUV = abs(input[1].atlas.y - input[0].atlas.y);
        float xUV = min(input[0].atlas.x, input[2].atlas.x);
        float yUV = min(input[0].atlas.y, input[1].atlas.y);
        float4 boundsUV = float4(xUV, yUV, widthUV, heightUV);

        float3 v0Local = mul(unity_WorldToObject, float4(input[0].worldPos.xyz, 1)).xyz;
        float3 v1Local = mul(unity_WorldToObject, float4(input[1].worldPos.xyz, 1)).xyz;
        float3 v2Local = mul(unity_WorldToObject, float4(input[2].worldPos.xyz, 1)).xyz;

        float widthLocal = abs(v2Local.x - v1Local.x);
        float heightLocal = abs(v1Local.y - v0Local.y);
        float xLocal = min(v0Local.x, v2Local.x);
        float yLocal = min(v0Local.y, v1Local.y);
        float4 boundsLocal = float4(xLocal, yLocal, widthLocal, heightLocal);

        // TODO: For For TextMeshProUGUI, as an UI object, the object space is relative to the
        // canvas instead of the object. To ensure the compatibility, we added the zLocal here.
        // Verify if this is correct.
        float zLocal = min(v0Local.z, v1Local.z);

        float skewLocal = abs(v1Local.x - v0Local.x);
        float skewUV = abs(input[1].atlas.x - input[0].atlas.x);
        // float4 boundsLocalZ = float4(zLocal - depth, zLocal, skewLocal, skewUV);
        float4 boundsLocalZ = float4(-depth, 0, skewLocal, skewUV);

        FillGeometry(input, triStream, baseOffset, worldExtrusion,
                     boundsUV, boundsLocal, boundsLocalZ);
      }

      pixel_t PixShader(tmp_plus_g2f input) {
        UNITY_SETUP_INSTANCE_ID(input);

        pixel_t o;
        o.color = 0;
        o.depth = 0;

        float3 nmPos = normalize(input.worldPos.xyz);

        // o.color = float4(nmPos, 1);
        // o.depth = ComputeDepth(input.clipPos);
        // return o;

        float bold = step(input.texcoord1.y, 0); // original texcoord1.y
        float edge = lerp(_WeightNormal, _WeightBold, bold); // choose between normal and bold
        float outlineEdge = edge + _OutlineWidth;

        float charDepth = input.param3d.x;
        float2 depthMapped = input.param3d.yz;

        InitializeRaymarcher(input);

        for (int i = 0; i <= MAX_STEPS; i++) {
          NextRaymarch(edge);
          clip(_currIsInBound);

          if (_currSampleAlpha <= outlineEdge) {
            // TODO: Convert between world and object space for _currPos
            float tDepth = saturate(InverseLerp(0, charDepth, -_currPos.z));
            tDepth = saturate(lerp(depthMapped.x, depthMapped.y, tDepth));

            float3 depthColor = tex2D(_DepthTex, float2(tDepth, 0.5));

            if (_currSampleAlpha > edge ) {
              o.color = float4(depthColor * _OutlineColor.rgb, 1);
            } else {
              float3 faceColor = tex2D(_FaceTex, _currPos.xy * _FaceTex_ST.xy - _FaceTex_ST.zw) *
                  _Color;
              o.color = float4(depthColor * faceColor.rgb, 1);
            }

            o.depth = ComputeDepth(UnityObjectToClipPos(_currPos));

            return o;
          }
        }

        clip(-1);
        return o;
      }
      ENDCG
    }
  }
}