#ifndef  RAYMARCH
#define  RAYMARCH

// Strange fact: for TextMeshProUGUI, Object space is relative to the canvas, not the object
// https://stackoverflow.com/questions/55641879/how-to-get-object-space-in-a-shader-from-an-ui-image-disablebatching-does-not-s

float _MinStep;

tmp_plus_g2f _input;
float3 _viewDir;
float3 _startPos;

float _currProgress;
float3 _currPos;
float3 _currMask;
float _currIsInBound;
float _currSampleAlpha;

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

float3 PositionToMask(float3 localPos, tmp_plus_g2f input) {
  // tx, ty, tz are the normalized coordinates of the _currPos in the 3d bounds of the triangle.
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

  float ty = InverseLerp(input.bounds.y, input.bounds.y + input.bounds.w, localPos.y);
  float dx = saturate(ty) * input.boundsZ.z;
  float tx = InverseLerp(input.bounds.x, input.bounds.x + input.bounds.z,
      localPos.x - dx);
  float tz = InverseLerp(input.boundsZ.x, input.boundsZ.y, localPos.z);
  return float3(tx, ty, tz);
}

float SampleSDFAlpha(float3 mask, tmp_plus_g2f input) {
  float u = saturate(lerp(input.boundsUV.x, input.boundsUV.x + input.boundsUV.z, mask.x));
  float v = saturate(lerp(input.boundsUV.y, input.boundsUV.y + input.boundsUV.w, mask.y));
  return tex2D(_MainTex, float2(u, v)).a;
}

  // TODO: What is this?
float GradientToLocalLength(tmp_plus_g2f input, float sampleAlpha, float offset) {
  float pixels = _TextureHeight * input.boundsUV.w;
  float gradientPixelScale = _GradientScale / pixels;
  float localM = input.bounds.w * gradientPixelScale;

  float min = -(localM * offset);
  float max = localM * (1 - offset);
  return lerp(min, max, sampleAlpha);
}

float IsInBounds(float3 mask) {
  // clipX, clipY, clipZ are normalized distances of the _currPos to the nearest bound.
  float clipX = 0.5 - abs(mask.x - 0.5) + 0.01;
  float clipY = 0.5 - abs(mask.y - 0.5) + 0.01;
  float clipZ = 0.5 - abs(mask.z - 0.5) + 0.01;
  return min(0, min(clipX, min(clipY, clipZ)));
}

void NextRaymarch(float edge) {
	_currPos = _startPos + _viewDir * _currProgress;
  _currMask = PositionToMask(_currPos, _input);
  _currIsInBound = IsInBounds(_currMask);
  float alpha = SampleSDFAlpha(saturate(_currMask), _input);
  _currSampleAlpha = 1 - alpha;

  // TODO: What is this?
  float sdfDistance = GradientToLocalLength(_input, _currSampleAlpha, edge);
  float ratio = sdfDistance / length(_viewDir.xy);

  // TODO: Why?
  float step = length(_viewDir) * ratio;

  _currProgress += max(step, _MinStep);
}
#endif