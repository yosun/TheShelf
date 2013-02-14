using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using System.IO;


/// <summary>
/// Creates a RGBA32 Lookup texture. r contains the diffuse, g the backdiffuse, b the direct spec and a the indirect spec. Needs to be uncompressed 32bit or dxt5 (other formats won't work as well).
/// 
/// Backlight and front colors are controlled via shader, specular highlights don't get seperate colors.
/// </summary>
[ExecuteInEditMode]
[AddComponentMenu("Chickenlord/Mobile Skin Lookup Texture")]
public class MobileSkinLookupTexture : MonoBehaviour
{

    //Standard diffuse (front light)
    public float DiffuseStrength = 1f;
    public Color KeyColor = Color.white;
    public Color FillColor = new Color(0.42353f, 0.5f, 0.53333333333f);
    //Backlight
    public float BackColorStrength = 1f;
    public Color BackColor = new Color(0.1294f,0.1294f,0.1294f);

    public float SkinPreMul = 0.8f;
    public float SkinPow = 5f;
    public float SkinMul = 0.35f;
    public float SkinFrontKill = 2.3f;
    public float SkinBackKill = 0.15f;
	public bool ReplaceFill = false;

    public float SkinOffset = 0.05f;

    public Color SkinColor = new Color(1f, 0.153f, 0.0625f);

    public bool Preview = false;

    public int width = 32;
    public int height = 32;

    public string TargetPath = null;

    public Texture2D lookupTexture;

    //NOTE: Nice it works. But add left right adjustment as well.

    //Range 0,1 (so wrapped for diff, and standard for vdl)
    private Color GetTexVal(float nl, float vdl)
    {
        float diffR11 = (nl - 0.5f) * 2f;
        float diffuse = DiffuseStrength * Mathf.Max(0, diffR11);
        float dx = SkinFrontKill * Mathf.Max(0, diffR11);
        float bx = SkinBackKill * Mathf.Max(0, -diffR11);
        float back = BackColorStrength * Mathf.Max(0, -diffR11);
        float sk = (Mathf.Max(0f, 1f - dx - bx)) * SkinPreMul;
        float skinoff = 0.01f + SkinOffset;
        float mult = 1f / skinoff;
        sk = Mathf.Clamp01(sk * Mathf.Clamp01((Mathf.Clamp(vdl - skinoff, 0, 1) * mult)));

        float skin = Mathf.Pow(sk, 1f + SkinPow * (1-vdl)) * SkinMul;
        float f2 = Mathf.Max(0f, 1f - diffuse - back);
        
		if(!ReplaceFill)
		{
			skin = Mathf.Max(0f, skin - back*Mathf.Min(1f,SkinMul));
		}
        f2 = Mathf.Max(0f, f2 - skin);
		if(ReplaceFill)
		{
			skin = Mathf.Max(0f, skin - back*Mathf.Min(1f,SkinMul));
		}
        

        //return (Mathf.Max(0f, 1f - diffuse - back) * FillColor);
        return diffuse * KeyColor + back * BackColor+(f2 * FillColor) + (skin * SkinColor);
    }

    /// <summary>
    /// Bake stuff using assigned values into given texture.
    /// </summary>
    /// <param name="tex"></param>
    public void BakeTex()
    {
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
