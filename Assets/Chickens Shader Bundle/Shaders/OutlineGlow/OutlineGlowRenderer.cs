using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[AddComponentMenu("Chickenlord/Outline Glow Renderer")]
public class OutlineGlowRenderer : MonoBehaviour {


    public bool DrawOutline = true;
    public bool IncludeChildMeshes = false;
    public Color OutlineColor = Color.cyan;
    public int ObjectBlurSteps = 2;
    public float ObjectBlurSpread = 0.6f;
    public float ObjectOutlineStrength = 3f;
    private bool ICMT = false;
    private int myID = -1;
    private int previousLayer;
    public int childCounter = 0;

    private List<int> childLayers;
	// Update is called once per frame
	void Update () 
    {
        //Grabbing id here, as it doesn't work in Start without modifying the script execution order. Shouldn't cost too much performance.
        if (myID == -1)
        {
            OutlineGlowEffectScript es = OutlineGlowEffectScript.Instance;
            if (es != null)
                myID = es.AddRenderer(this);
        }
	}

    void OnEnable()
    {
        if (this.myID == -1)
        {
            try
            {
                myID = OutlineGlowEffectScript.Instance.AddRenderer(this);
            }
            catch
            {
            }
        }
        else
        {
            Debug.LogWarning("OutlineGlowRenderer enabled, although id is already/still assigned. Shouldn't happen.");
        }
    }

    void OnDisable()
    {
        if (this.myID != -1)
        {
            OutlineGlowEffectScript.Instance.RemoveRenderer(this.myID);
            this.myID = -1;
            this.childLayers = null;
        }
    }

    public void SetLayer(int layer)
    {
        previousLayer = this.gameObject.layer;
        ICMT = this.IncludeChildMeshes;
        if (DrawOutline && this.enabled)
        {
            if (ICMT)
            {
                if (this.childLayers == null)
                {
                    childLayers = new List<int>();
                }
                else
                {
                    this.childLayers.Clear();
                }
                SetLayerRecursive(this.transform, layer);
            }
            else
            {
                this.gameObject.layer = layer;
            }
        }
    }

    public void ResetLayer()
    {
        childCounter = 0;
        this.gameObject.layer = previousLayer;
        if (ICMT)
        {
            ResetLayerRecursive(this.transform);
        }
    }

    private void SetLayerRecursive(Transform trans,int layer)
    {
        this.childLayers.Add(trans.gameObject.layer);
        trans.gameObject.layer = layer;
        for (int i = 0; i < trans.childCount; i++)
        {
            SetLayerRecursive(trans.GetChild(i), layer);
        }
    }

    private void ResetLayerRecursive(Transform trans)
    {
        trans.gameObject.layer = this.childLayers[childCounter];
        childCounter++;
        for (int i = 0; i < trans.childCount; i++)
        {
            ResetLayerRecursive(trans.GetChild(i));
        }
    }

}
