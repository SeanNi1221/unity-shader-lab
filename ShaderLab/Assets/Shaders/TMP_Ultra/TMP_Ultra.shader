Shader "TextMeshPro/Ultra/Simple" {
  Properties {

    // General
    _FaceTex        ("Face Texture", 2D) = "white" {}
    _Color          ("Color", Color) = (1,1,1,1)

    _WeightNormal		("Weight Normal", float) = 0.5
    _WeightBold			("Weight Bold", float) = 0.75

    // 3D
    _MinStep        ("Raymarch Min Step", Range(0.001, 0.1)) = 0.01
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
      #pragma fragment PixShader_Debug

      #pragma shader_feature __ OUTLINE_ON
      #pragma shader_feature __ MAXSTEPS_128
      #pragma multi_compile __ DEBUG_MASK

      #pragma require geometry

      #include "UnityCG.cginc"

      // TODO: Remove the dependency on Common.hlsl
      #include "Common.hlsl"

      #include "Raymarch.hlsl"

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
      [maxvertexcount(24)]
      void GeomShader(triangle tmp_plus_v2g worldInput[3],
                      inout TriangleStream<tmp_plus_g2f> triStream) {

        tmp_plus_g2f o;

        float3 baseOffset = float3(0, 0, 0);

        // ========================================================
        // TODO: The problem for UGUI is in the depth passing

        float depth = worldInput[0].uv2.x;

        // ========================================================

        // float depth = 20;

        // World space, assumes that all worldInput normals are the same
        float3 worldExtrusion = worldInput[0].normal * depth;

        float3 v0Local = mul(unity_WorldToObject, float4(worldInput[0].position.xyz, 1)).xyz;
        float3 v1Local = mul(unity_WorldToObject, float4(worldInput[1].position.xyz, 1)).xyz;
        float3 v2Local = mul(unity_WorldToObject, float4(worldInput[2].position.xyz, 1)).xyz;
        float widthLocal = abs(v2Local.x - v1Local.x);
        float heightLocal = abs(v1Local.y - v0Local.y);
        float xLocal = min(v0Local.x, v2Local.x);
        float yLocal = min(v0Local.y, v1Local.y);
        float4 boundsLocal = float4(xLocal, yLocal, widthLocal, heightLocal);

        float widthUV = abs(worldInput[2].uv0.x - worldInput[1].uv0.x);
        float heightUV = abs(worldInput[1].uv0.y - worldInput[0].uv0.y);
        float xUV = min(worldInput[0].uv0.x, worldInput[2].uv0.x);
        float yUV = min(worldInput[0].uv0.y, worldInput[1].uv0.y);
        float4 boundsUV = float4(xUV, yUV, widthUV, heightUV);

        // TODO: What is this?
        float skewLocal = abs(v1Local.x - v0Local.x);
        float skewUV = abs(worldInput[1].uv0.x - worldInput[0].uv0.x);
        float4 boundsLocalZ = float4(-depth, 0, skewLocal, skewUV);

        FillGeometry(worldInput, triStream, baseOffset, worldExtrusion,
                     boundsUV, boundsLocal, boundsLocalZ);
      }

      pixel_t PixShader_Debug(tmp_plus_g2f input) {
        UNITY_SETUP_INSTANCE_ID(input);

        pixel_t o;
        o.color = 0;
        o.depth = 0;

        float bold = step(input.tmp.y, 0); // original uv1.y
        float edge = lerp(_WeightNormal, _WeightBold, bold); // choose between normal and bold

        float charDepth = input.tmpUltra.x;
        float2 depthMapped = input.tmpUltra.yz;

        InitializeRaymarcher(input);

        for (int i = 0; i <= 40; i++) {
          NextRaymarch_Debug(edge);
        }

        o.color = float4(normalize(_currPos), 1);
        return o;
      }

      pixel_t PixShader(tmp_plus_g2f input) {
        UNITY_SETUP_INSTANCE_ID(input);

        pixel_t o;
        o.color = 0;
        o.depth = 0;

        float bold = step(input.tmp.y, 0); // original uv1.y
        float edge = lerp(_WeightNormal, _WeightBold, bold); // choose between normal and bold

        float charDepth = input.tmpUltra.x;
        float2 depthMapped = input.tmpUltra.yz;

        InitializeRaymarcher(input);

        for (int i = 0; i <= MAX_STEPS; i++) {
          NextRaymarch(edge);
          float3 localPos = _currPos;
          float3 mask = _currMask;
          float bound = _currBound;
          float sample = _currSample;

          clip(bound);

          if (sample <= edge) {
            float depth = -localPos.z;
            float tProgress = saturate(InverseLerp(0, charDepth, depth));
            float progress = saturate(lerp(depthMapped.x, depthMapped.y, tProgress));
            float3 depthColor = tex2D(_DepthTex, float2(progress, 0.5)) * _Color.rgb;
            float3 faceColor = tex2D(_FaceTex, localPos.xy * _FaceTex_ST.xy - _FaceTex_ST.zw);
            depthColor *= faceColor;

            o.depth = ComputeDepth(UnityObjectToClipPos(localPos));
            o.color = float4(depthColor * input.color, 1);
            return ValidatePixel(o, i);
          }
        }

        clip(-1);
        return ValidatePixel(o, MAX_STEPS);
      }
      ENDCG
    }
  }
}