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
[AddComponentMenu("Chickenlord/Mobile Specular Lookup Texture")]
public class MobileISpecLookupTexture : MonoBehaviour
{

    //Standard diffuse (front light)
    public float DiffuseStrength = 1f;

    //Backlight
    public float BackColorStrength = 1f;

    public float RimStrength = 1f;

    public float RimPower = 5f;

    public float RimBalance = 0.5f;

    //DirectSpecPower
    public float DirectSpec = 1f;

    //Direct Specular Shininess factor
    public float DirectShininess  = 0.5f;

    //Direct spec slope (range 0.004 to 1). Lower value means more spread specularity (0.004 is ridiculously much, but hey somebody might need it)
    public float DirectSlope  = 1f;

    //Shininess for indirect fresnel attenuated specularity
    public float IndirectFresnel  = 0.3f;

    //Shininess for indirect view attenuated specularity
    public float IndirectView  = 0.14f;

    //IndirectBalance between View and FresnelFactor (0 is full fresnel, 1 is full view)
    public float IndirectBalance = 0.5f;

    //SpecDenom, basically just for testing.
    private float specDenom = 1.3f;

    public bool Preview = false;

    public int width = 32;
    public int height = 32;

    public string TargetPath = null;

    public Texture2D lookupTexture;

    //Range 0,1 (so wrapped for diff, and standard for vdl)
    private Color GetTexVal(float nl, float vdl)
    {
        float diffR11 = (nl-0.5f)*2f;
        float diffuse = DiffuseStrength * Mathf.Max(0, diffR11);
        float back = BackColorStrength * Mathf.Max(0, -diffR11);

        float dspec = Mathf.Pow(Mathf.Pow(Mathf.Clamp01(((vdl*0.5f+0.5f + diffR11)-0.5f) / specDenom), DirectSlope), DirectShininess * 128.0f) * DirectSpec;
        

        float fresnel = Mathf.Pow(Mathf.Clamp01(0.8f - vdl), IndirectFresnel * 9.0f);
        float view = Mathf.Pow(vdl, IndirectView * 128.0f);
        float indirectSpec = (1f - IndirectBalance) * fresnel + IndirectBalance * view;

        float rim = Mathf.Pow(1f - vdl, RimPower) * RimStrength;


        return new Color(diffuse + (1 - RimBalance) * rim, back + (RimBalance) * rim, dspec, indirectSpec);
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
