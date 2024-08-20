using System.Collections.Generic;
using UnityEngine;
using TMPro;

[ExecuteInEditMode, RequireComponent(typeof(TMP_Text))]
public class TMP_UltraHandler : MonoBehaviour {
  public struct TMP_UltraCharInfo {
    public float Depth;
    public Vector2 DepthMapping;
  }

  private readonly List<TMP_UltraCharInfo> _ultraCharInfos = new();
  private readonly List<Vector4> _cachedVertUVs = new();

  [SerializeField] private TMP_Text _tmp;
  [SerializeField] private float _defaultDepth = 1;

  private void OnValidate() {
    _tmp = GetComponent<TMP_Text>();
    _ultraCharInfos.Clear();
    OnTextChanged(_tmp);
  }

  private void OnEnable() {
    _tmp = GetComponent<TMP_Text>();

    // Enables the UV2 channel to be set by this script.
    if (_tmp is TextMeshProUGUI tmpUGUI) {
      var canvas = GetComponentInParent<Canvas>();
      if (canvas) {
        canvas.additionalShaderChannels |= AdditionalCanvasShaderChannels.TexCoord2;
      }
    }

    TMPro_EventManager.TEXT_CHANGED_EVENT.Add(OnTextChanged);
    _tmp.OnPreRenderText += info => UpdateWorldToObjectMatrix();
  }

  private void OnDisable() {
    TMPro_EventManager.TEXT_CHANGED_EVENT.Remove(OnTextChanged);
    _tmp.OnPreRenderText -= info => UpdateWorldToObjectMatrix();
  }


  private void Update() {
    if (transform.hasChanged) {
      UpdateWorldToObjectMatrix();
      transform.hasChanged = false;
    }
  }

  private void OnTextChanged(UnityEngine.Object tmp) {
    if (tmp != _tmp || _tmp == null) {
      return;
    }

    if (_tmp.textInfo == null) {
      return;
    }

    // Removes old chars from 3D data;
    for (int i = _ultraCharInfos.Count - 1; i >= _tmp.textInfo.characterCount; i--) {
      _ultraCharInfos.RemoveAt(i);
    }

    // Adds new chars to 3D data;
    for (int i = _ultraCharInfos.Count; i < _tmp.textInfo.characterCount; i++) {
      var ultraCharInfo = new TMP_UltraCharInfo {
        Depth = _defaultDepth,
        DepthMapping = new Vector2(0, 1)
      };
      _ultraCharInfos.Add(ultraCharInfo);
    }

    UpdateVertUVs();
  }

  private void UpdateVertUVs() {
    var count = Mathf.Min(_ultraCharInfos.Count, _tmp.textInfo.characterCount);

    for (int i = 0; i < _tmp.textInfo.meshInfo.Length; i++) {
      var meshInfo = _tmp.textInfo.meshInfo[i];
      var mesh = meshInfo.mesh;

      if (mesh == null) {
        continue;
      }

      // ==========================================================================================
      // TODO: It is likely that UV2 is used internally by TMP.
      // ==========================================================================================
      _cachedVertUVs.Clear();
      mesh.SetUVs(2, _cachedVertUVs);

      // Fetches the UVs from the original mesh.
      mesh.GetUVs(0, _cachedVertUVs);

      int iLastCharVert = -1;
      for (int iChar = 0; iChar < count; iChar++) {
        var charInfo = _tmp.textInfo.characterInfo[iChar];
        int iMat = charInfo.materialReferenceIndex;
        if (iMat != i) {
          // Debug.Log($"---------material index not match: {iMat} to {i}, Char[{iChar}]: {charInfo.character}, meshIdx: {iMat}");
          continue;
        }

        // The first vertex index of the character. 4 vertices per character.
        int iCharVert = charInfo.vertexIndex;

        if (iLastCharVert > iCharVert) {
          // Debug.Log($"---------vertex index not match: last({iLastCharVert}) to current({iCharVert}), Char[{iChar}]: {charInfo.character}");
          continue;
        }

        iLastCharVert = iCharVert;
        var iUnderlineVert = charInfo.underlineVertexIndex;
        var iStrikethroughVert = charInfo.strikethroughVertexIndex;

        var ultraCharInfo = _ultraCharInfos[iChar];
        var ultraVertData = new Vector4(ultraCharInfo.Depth,
                                        ultraCharInfo.DepthMapping.x,
                                        ultraCharInfo.DepthMapping.y,
                                        0);

        _cachedVertUVs[iCharVert + 0] = ultraVertData;
        _cachedVertUVs[iCharVert + 1] = ultraVertData;
        _cachedVertUVs[iCharVert + 2] = ultraVertData;
        _cachedVertUVs[iCharVert + 3] = ultraVertData;

        if (iUnderlineVert != iCharVert) {
          // Debug.Log($"Set different underline vertex index: {iUnderlineVert}");

          _cachedVertUVs[iUnderlineVert + 0] = ultraVertData;
          _cachedVertUVs[iUnderlineVert + 1] = ultraVertData;
          _cachedVertUVs[iUnderlineVert + 2] = ultraVertData;
          _cachedVertUVs[iUnderlineVert + 3] = ultraVertData;

          _cachedVertUVs[iUnderlineVert + 4] = ultraVertData;
          _cachedVertUVs[iUnderlineVert + 5] = ultraVertData;
          _cachedVertUVs[iUnderlineVert + 6] = ultraVertData;
          _cachedVertUVs[iUnderlineVert + 7] = ultraVertData;

          _cachedVertUVs[iUnderlineVert + 8] = ultraVertData;
          _cachedVertUVs[iUnderlineVert + 9] = ultraVertData;
          _cachedVertUVs[iUnderlineVert + 10] = ultraVertData;
          _cachedVertUVs[iUnderlineVert + 11] = ultraVertData;
        }

        if (iStrikethroughVert != iCharVert) {
          // Debug.Log($"Set different strikethrough vertex index: {iStrikethroughVert}");

          _cachedVertUVs[iStrikethroughVert + 0] = ultraVertData;
          _cachedVertUVs[iStrikethroughVert + 1] = ultraVertData;
          _cachedVertUVs[iStrikethroughVert + 2] = ultraVertData;
          _cachedVertUVs[iStrikethroughVert + 3] = ultraVertData;

          _cachedVertUVs[iStrikethroughVert + 4] = ultraVertData;
          _cachedVertUVs[iStrikethroughVert + 5] = ultraVertData;
          _cachedVertUVs[iStrikethroughVert + 6] = ultraVertData;
          _cachedVertUVs[iStrikethroughVert + 7] = ultraVertData;

          _cachedVertUVs[iStrikethroughVert + 8] = ultraVertData;
          _cachedVertUVs[iStrikethroughVert + 9] = ultraVertData;
          _cachedVertUVs[iStrikethroughVert + 10] = ultraVertData;
          _cachedVertUVs[iStrikethroughVert + 11] = ultraVertData;
        }
      }

      mesh.SetUVs(2, _cachedVertUVs);
    }
    _tmp.UpdateVertexData(TMP_VertexDataUpdateFlags.Uv2);
  }

  private void UpdateWorldToObjectMatrix() {
    Debug.Log("UpdateWorldToObjectMatrix");
    Matrix4x4 m = transform.worldToLocalMatrix;
    _tmp.fontMaterial.SetMatrix("_WorldToObject", m);
  }
}
