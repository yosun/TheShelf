using UnityEngine;
using System.Collections;

[AddComponentMenu("Chickenlord/Mobile ToonPack Lookup Texture")]
public class ToonPack : MonoBehaviour {

    public bool Preview = false;
    public string TargetPath = null;
    public Texture2D lookupTexture;
    public Texture2D gradient;

    public float OLP = 25f;
    public float Sharpness = 5f;

    private Color GetTexVal(float nl, float vdl)
    {
        Color gradcol = gradient.GetPixelBilinear(nl, vdl);
        float mult = 1f-vdl;
        mult = Mathf.Pow(mult, OLP);
        mult = Mathf.Min(100f * mult, 1f);
        mult = Mathf.Pow(mult, Sharpness);

        //return new Color(mult, mult, mult, mult);
        return new Color(gradcol.r, gradcol.g, gradcol.b, 1f-mult);
    }
    public void BakeTex()
    {
        if (gradient)
        {
            int width = gradient.width;
            int height = gradient.height;
            DestroyImmediate(lookupTexture);
            lookupTexture = new Texture2D(width, height, TextureFormat.ARGB32, true);
            lookupTexture.wrapMode = TextureWrapMode.Clamp;
            lookupTexture.anisoLevel = 1;
            Texture2D tex = lookupTexture;
            for (int i = 0; i < tex.height; i++)
            {
                for (int j = 0; j < tex.width; j++)
                {
                    float ndl = (float)j / (float)tex.width;
                    float vdl = (float)i / (float)tex.height;

                    tex.SetPixel(j, i, GetTexVal(ndl, vdl));
                }
            }
            tex.Apply();
        }
        
    }

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
