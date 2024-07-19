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
    }

    CGPROGRAM
		#pragma target 3.0
    #pragma vertex TmpUltra_VertShader
    #pragma geometry TmpUltra_GeoShader
    #pragma fragment TmpUltra_PixShader
  }
}