#ifndef  RAYMARCH
#define  RAYMARCH

#include "Common.hlsl"

// Strange fact: for TextMeshProUGUI, Object space is relative to the canvas, not the object
// https://stackoverflow.com/questions/55641879/how-to-get-object-space-in-a-shader-from-an-ui-image-disablebatching-does-not-s

float _MinStep;

tmp_plus_g2f _input;
float3 _viewDir;
float3 _startPos;

float _currProgress;
float3 _currPos;
float3 _currMask;
float _currBound;
float _currSample;

// TODO: Consider using out parameters instead of returning private fields

void InitializeRaymarcher(tmp_plus_g2f input) {

  float3 viewDir = normalize(input.worldPos.xyz - _WorldSpaceCameraPos.xyz);
  float3 cameraFwd = normalize(mul((float3x3)unity_CameraToWorld, float3(0, 0, 1)));

  // Equals to `viewDir = camera.isOrtho? cameraFwd : viewDir;`
  viewDir = lerp(viewDir, cameraFwd, unity_OrthoParams.w);

  // The 4th col/row cannot be ignored because they contains the translation values
  //
  // https://blog.lidia-martinez.com/transformation-matrices-spaces-linear-algebra-unity
  _startPos = mul(unity_WorldToObject, float4(input.worldPos.xyz, 1));

  _viewDir = mul((float3x3)unity_WorldToObject, viewDir);
  _currProgress = 0;
  _input = input;
}

void NextRaymarch(float edge) {
  // Pos
  _currPos = _startPos + _viewDir * _currProgress;

  // Mask
  //
  // tx, ty, tz are the normalized coordinates of the _currPos in the 3d bounds of the triangle.
  float ty = InverseLerp(_input.boundsLocal.y, _input.boundsLocal.y + _input.boundsLocal.w,
    _currPos.y);

  /*
            v1 _____________
           / \           |
          /   \          |
         /     \ ______  h
        /     /|\     |  |
       /     / | \    y  |
      /     /  |  \   |  |
    v0-------------v2-----
     | px  | dx|   |
     |--- x ---|   |
     |----- w -----|

  skew = v1.x - v0.x
  dx = y * skew/h = y/h * skew = ty * skew
  px = x - dx
  */
  float dx = saturate(ty) * _input.boundsLocalZ.z;
  float px = _currPos.x - dx;
  float tx = InverseLerp(_input.boundsLocal.x, _input.boundsLocal.x + _input.boundsLocal.z, px);

  float tz = InverseLerp(_input.boundsLocalZ.x, _input.boundsLocalZ.y, _currPos.z);
  _currMask = float3(tx, ty, tz);

  // Bound
  //
  // TODO: Isn't this always 0?
  //
  // clipX, clipY, clipZ are normalized distances of the _currPos to the nearest bound.
  float clipX = -(abs(tx - 0.5) - 0.5) + 0.01;
  float clipY = -(abs(ty - 0.5) - 0.5) + 0.01;
  float clipZ = -(abs(tz - 0.5) - 0.5) + 0.01;
  _currBound = min(0, min(clipX, min(clipY, clipZ)));

  // Sample
  float maskU = saturate(lerp(_input.boundsUV.x, _input.boundsUV.x + _input.boundsUV.z,
      saturate(tx)));
  float maskV = saturate(lerp(_input.boundsUV.y, _input.boundsUV.y + _input.boundsUV.w,
      saturate(ty)));
  _currSample = 1 - tex2D(_MainTex, float2(maskU, maskV)).a;

  // Distance
  //
  // TODO: What is this?
  float distance = 0;
  float gradientUV = _GradientScale / _TextureHeight;
  float gradientRelative = gradientUV / _input.boundsUV.w;
  float localM = _input.boundsLocal.w * gradientRelative;
  float minM = -(localM * edge);
  float maxM = localM * (1 - edge);
  distance = lerp(minM, maxM, _currSample);

  float ratio = distance / length(_viewDir.xy);

  _currProgress += max(length(_viewDir) * ratio, _MinStep);
}

void NextRaymarch_Debug(float edge) {
  // Pos
  _currPos = _startPos + _viewDir * _currProgress;

  // Mask - Normalized position of the _currPos in the 3d bounds of the triangle.
  //
  //
  float ty = InverseLerp(_input.boundsLocal.y, _input.boundsLocal.y + _input.boundsLocal.w,
    _currPos.y);

  /*
            v1 _____________
           / \           |
          /   \          |
         /     \ ______  h
        /     /|\     |  |
       /     / | \    y  |
      /     /  |  \   |  |
    v0-------------v2-----
     | px  | dx|   |
     |--- x ---|   |
     |----- w -----|

  skew = v1.x - v0.x
  dx = y * skew/h = y/h * skew = ty * skew
  px = x - dx
  */
  float dx = saturate(ty) * _input.boundsLocalZ.z;
  float px = _currPos.x - dx;
  float tx = InverseLerp(_input.boundsLocal.x, _input.boundsLocal.x + _input.boundsLocal.z, px);

  // TODO: For TextMeshPro, the tz is as exprected. But for TextMeshProUGUI, the tz is affected by
  // the `local position z` of the object (because for an UI object, the object space is relative to
  // the canvas instead of the object). To ensure the compatibility, we added the _startPos.z here.
  // Verify if this is correct.
  float tz = InverseLerp(_input.boundsLocalZ.x, _input.boundsLocalZ.y, _currPos.z);
  _currMask = float3(tx, ty, tz);

  // Bound - Minimum normalized distance of the _currPos to the nearest bound.
  //
  // TODO: Isn't this always 0?
  //
  float clipX = -(abs(tx - 0.5) - 0.5) + 0.01;
  float clipY = -(abs(ty - 0.5) - 0.5) + 0.01;
  float clipZ = -(abs(tz - 0.5) - 0.5) + 0.01;
  _currBound = min(0, min(clipX, min(clipY, clipZ)));

  _currProgress += _MinStep;
}
#endif