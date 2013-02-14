using UnityEngine;
using System.Collections;
using System.Collections.Generic;


[RequireComponent(typeof(Camera))]
[AddComponentMenu("Image Effects/Outline Glow Effect")]
public class OutlineGlowEffectScript : MonoBehaviour {

    /// <summary>
    /// Renderers stores all the renderers which might be drawn with an outline.
    /// Static so that multiple cameras don't have to use multiple dictionaries.
    /// </summary>
    private static Dictionary<int, OutlineGlowRenderer> renderers;

    private static OutlineGlowEffectScript instance;

    /// <summary>
    /// Instance of OutlineGlowEffectScript. If there are multiple cameras using this effect, it is the first one of them which has been initialized.
    /// </summary>
    public static OutlineGlowEffectScript Instance
    {
        get
        {
            return instance;
        }
    }


    /// <summary>
    /// The Layer for the second camera. This is needed to draw only the objects, which should recevie an outline.
    /// </summary>
    public int SecondCameraLayer = 31;

    /// <summary>
    /// The amount of blursteps. The more blursteps, the smoother and bigger your outline gets. But it also takes up
    /// more performance.
    /// </summary>
    public int BlurSteps = 2;

    /// <summary>
    /// Larger values create a bigger outline but may also become uglier at some point.
    /// </summary>
    public float BlurSpread = 0.6f;

    /// <summary>
    /// Wether or not you want to render the outlines at one fourth of the original resolution. This won't look
    /// a lot worse, but give a good performance boost.
    /// </summary>
    public bool QuarterResolutionSecondRender = true;

    /// <summary>
    /// Creates smoother outlines when using quarter resolution. Won't have any effect if quarter resolution is not turned on.
    /// </summary>
    public bool SmootherOutlines = true;

    /// <summary>
    /// Render each object seperately. Makes different color per object possible, but heavily increases performance hit.
    /// </summary>
    public bool SplitObjects = false;

    /// <summary>
    /// Use the color defined in the OutlineGlowRenderer script, or the same color for each object. Has no effect if split objects is not turned on.
    /// </summary>
    public bool UseObjectColors = false;

    /// <summary>
    /// Use the blur settings defined in the OutlineGlowRenderer script. Only works for split objects.
    /// </summary>
    public bool UseObjectBlurSettings = false;

    public bool UseObjectOutlineStrength = false;

    /// <summary>
    /// Should the outlines be visible through other outline objects? Has no effect if split objects is not turned on.
    /// </summary>
    public bool SeeThrough = false;

    /// <summary>
    /// Use depth tested outlines.
    /// </summary>
    public bool DepthTest = false;

    public float MinZ = 0.1f;

    public Color OutlineColor = Color.cyan;

    public float OutlineStrength = 3.0f;

    public bool DrawObjectsOnTop = false;

    public GameObject[] TopDrawObjects = null;


    /// <summary>
    /// Standard depth normals shader.
    /// </summary>
    public Shader DephtPassShader;

    /// <summary>
    /// Shader used for the second rendering. Should usuaully be the "WhiteDraw" shader.
    /// </summary>
    public Shader SecondPassShader;

    public Shader TopDrawShader;

    /// <summary>
    /// Shader used for the blur passes.
    /// </summary>
    public Shader BlurPassShader;

    /// <summary>
    /// Shader used for blending.
    /// </summary>
    public Shader MixPassShader;
    

    //Effect Material used for blur-pass and blending.
    private Material e_Mat;

    //Second pass material. Used to draw the object another time.
    private Material d_Mat;

    //Mix material.
    private Material m_Mat;

    //Second camera
    private Camera scam;
    private GameObject camObject;
    private Transform scam_transform;

    private float InternalBlurSpread = 0.6f;

    private List<OutlineGlowRenderer> temp_renderers;

    //Init stuff.
	void Start () 
    {
        //Setting instance and ditionary, if not already done.
        if (renderers == null)
        {
            renderers = new Dictionary<int, OutlineGlowRenderer>();
        }
        if (instance == null)
        {
            instance = this;
        }

        if (!SystemInfo.supportsImageEffects || !SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.Depth))
        {
            this.enabled = false;
            return;
        }
        else
        {
            if (this.DepthTest)
            {
                this.camera.depthTextureMode |= DepthTextureMode.DepthNormals;
            }
        }
	}

    /// <summary>
    /// Adds an OutlineGlowRender to the internal dictionary and returns an id, which the renderer has been given.
    /// NOTE: This method does not check, wether the object is already in the dictionary. So be careful if you call it yourself.
    /// </summary>
    /// <param name="renderer">The renderer which should be added.</param>
    /// <returns>Assigned id</returns>
    public int AddRenderer(OutlineGlowRenderer renderer)
    {
        for (int i = 0; i < int.MaxValue - 1; i++)
        {
            if (!renderers.ContainsKey(i))
            {
                renderers.Add(i, renderer);
                return i;
            }
        }
        //If for some reason this method really returns -1, then there's something badly wrong.
        return -1;
    }

    /// <summary>
    /// Removes the renderer with the given id from the dictionary, so that it doesn't have an outline anymore. Called when the OutlineGlowRenderer gets destroyed or disabled.
    /// Careful if you call it yourself.
    /// </summary>
    /// <param name="id">Renderers id</param>
    public void RemoveRenderer(int id)
    {
        if (renderers.ContainsKey(id))
        {
            renderers.Remove(id);
        }
    }

    /// <summary>
    /// Method for creating the necessary materials, if they do not yet exist and if the shaders are supported.
    /// </summary>
    private void CreateMaterials()
    {
        if(this.d_Mat == null && this.SecondPassShader!= null)
        {
            this.d_Mat = new Material(this.SecondPassShader);
        }

        if (this.e_Mat == null && this.BlurPassShader != null && this.BlurPassShader.isSupported)
        {
            this.e_Mat = new Material(this.BlurPassShader);
        }
        
        if (this.m_Mat == null && this.MixPassShader != null && this.MixPassShader.isSupported)
        {
            this.m_Mat = new Material(this.MixPassShader);
        }
    }

    /// <summary>
    /// Method for creating the second camera.
    /// </summary>
    private void CreateCamera()
    {
        if (scam == null)
        {
            if (camObject != null)
            {
                DestroyImmediate(camObject);
            }
            GameObject go = new GameObject();
            scam = go.AddComponent<Camera>();
            scam_transform = scam.transform;
            scam.gameObject.name = "Outline Glow Cam";
            camObject = go;
            camObject.hideFlags = HideFlags.HideAndDontSave;
        }
    }

    // Performs one blur iteration.
    public void FourTapCone(RenderTexture source, RenderTexture dest, int iteration)
    {
        float off = 0.5f + iteration * InternalBlurSpread;
        Graphics.BlitMultiTap(source, dest, e_Mat,
            new Vector2(-off, -off),
            new Vector2(-off, off),
            new Vector2(off, off),
            new Vector2(off, -off)
        );
    }

    // Downsamples the texture to a quarter resolution.
    private void DownSample4x(RenderTexture source, RenderTexture dest)
    {
        float off = 1.0f*InternalBlurSpread;
        Graphics.BlitMultiTap(source, dest, e_Mat,
            new Vector2(-off, -off),
            new Vector2(-off, off),
            new Vector2(off, off),
            new Vector2(off, -off)
        );
    }

    void OnRenderImage(RenderTexture source,RenderTexture destination)
    {
        CreateMaterials();
        if (!this.BlurPassShader.isSupported || !this.MixPassShader.isSupported)
        {
            this.enabled = false;
            return;
        }
        if (this.DepthTest)
        {
            this.camera.depthTextureMode |= DepthTextureMode.DepthNormals;
        }
        CreateCamera();
        this.SecondCameraLayer = Mathf.Clamp(this.SecondCameraLayer, 0, 31);
        this.BlurSteps = Mathf.Clamp(BlurSteps, 1, 6);
        this.BlurSpread = Mathf.Clamp(BlurSpread, 0, 1.5f);
        InternalBlurSpread = BlurSpread;
        scam.enabled = false;

        int sampling = 2;
		int tex_scale = 1;
        if (this.QuarterResolutionSecondRender)
		{
			tex_scale = 2;
            sampling = 4;
		}

        bool TopDrawEmpty = true;
        
        if (TopDrawObjects != null)
        {
            TopDrawEmpty = true;
            for (int i = 0; i < TopDrawObjects.Length;i++ )
            {
                if (TopDrawObjects[i] != null)
                {
                    TopDrawEmpty = false;
                    break;
                }
            }
        }


        if (!this.DepthTest)
        {
            if (!SplitObjects)
            {
                #region SetupSecondCam

                // Setting up all the here, that is needed for the second camera to work.

                RenderTexture scam_aTex;
                if(this.DrawObjectsOnTop && !TopDrawEmpty)
                    scam_aTex = RenderTexture.GetTemporary(source.width / tex_scale, source.height / tex_scale, 24, RenderTextureFormat.Default);
                else
                    scam_aTex = RenderTexture.GetTemporary(source.width / tex_scale, source.height / tex_scale, 0, RenderTextureFormat.Default);
                scam.renderingPath = RenderingPath.VertexLit;
                scam_transform.position = camera.transform.position;
                scam_transform.rotation = camera.transform.rotation;
                scam.fieldOfView = this.camera.fieldOfView;
                scam.near = this.camera.near;
                scam.far = this.camera.far;
                scam.targetTexture = scam_aTex;
                scam.backgroundColor = Color.black;
                scam.clearFlags = CameraClearFlags.SolidColor;
                scam.cullingMask = 1 << this.SecondCameraLayer;
                scam.hdr = false;
                scam.depthTextureMode = DepthTextureMode.None;
                //Setup up the cullingMask is important, as we only want specific objects to be drawn. Therefor no other objects should be assigned to that layer.
                #endregion

                #region DoTheStuff

                //DrawTopObjectsFirst, because they possibly can hide alot of other stuff.
                if (this.DrawObjectsOnTop && !TopDrawEmpty)
                {
                    #region SetupTopDrawObjectsAndRender
                    GameObject[] realTopDrawElements = new GameObject[TopDrawObjects.Length];
                    int[] layers = new int[TopDrawObjects.Length];
                    int pos = 0;
                    for (int i = 0; i < TopDrawObjects.Length; i++)
                    {
                        if (TopDrawObjects[i] != null)
                        {
                            realTopDrawElements[pos] = TopDrawObjects[i];
                            layers[pos] = TopDrawObjects[i].layer;
                            pos++;
                        }
                    }
                    for (int i = 0; i < realTopDrawElements.Length; i++)
                    {
                        realTopDrawElements[i].layer = this.SecondCameraLayer;
                    }
                    scam.RenderWithShader(this.TopDrawShader, "");
                    for (int i = 0; i < realTopDrawElements.Length; i++)
                    {
                        if(realTopDrawElements[i] != null)
                            realTopDrawElements[i].layer = layers[i];
                    }
                    scam.clearFlags = CameraClearFlags.Nothing;
                    #endregion
                }
                foreach (OutlineGlowRenderer gr in renderers.Values)
                {
                    gr.SetLayer(this.SecondCameraLayer);
                }
                scam.RenderWithShader(this.SecondPassShader, "");
                foreach (OutlineGlowRenderer gr in renderers.Values)
                {
                    gr.ResetLayer();
                }

                //BlurCode.
                //Same as the blur-effect script
                RenderTexture buffer = RenderTexture.GetTemporary(source.width / sampling, source.height / sampling, 0);
                RenderTexture buffer2 = RenderTexture.GetTemporary(source.width / sampling, source.height / sampling, 0);

                // Copy source to the 4x4 smaller texture.
                DownSample4x(scam_aTex, buffer);

                // Blur the small texture
                bool oddEven = true;
                for (int i = 0; i < BlurSteps; i++)
                {
                    if (oddEven)
                        FourTapCone(buffer, buffer2, i);
                    else
                        FourTapCone(buffer2, buffer, i);
                    oddEven = !oddEven;
                }
                m_Mat.SetTexture("_WhiteTex", scam_aTex);
                m_Mat.SetColor("_OutlineColor", this.OutlineColor);
                m_Mat.SetFloat("_Mult", this.OutlineStrength);

                //stuff for smoother outlines. only works with thicker outlines.
                m_Mat.SetVector("_TexSize", new Vector4(1.0f / source.width, 1.0f / source.height, 0, 0));
                if (oddEven)
                {
                    m_Mat.SetTexture("_BlurTex", buffer);
                }
                else
                {
                    m_Mat.SetTexture("_BlurTex", buffer2);
                }

                if (this.SmootherOutlines && this.QuarterResolutionSecondRender)
                {
                    Graphics.Blit(source, destination, m_Mat, 1);
                }
                else
                {
                    Graphics.Blit(source, destination, m_Mat, 0);
                }

                RenderTexture.ReleaseTemporary(buffer);
                RenderTexture.ReleaseTemporary(buffer2);
                RenderTexture.ReleaseTemporary(scam_aTex);
                #endregion
            }
            else
            {
                #region SetupSecondCam
                // Setting up all the here, that is needed for the second camera to work.
                RenderTexture scam_aTex;
                if (this.DrawObjectsOnTop && !TopDrawEmpty)
                    scam_aTex = RenderTexture.GetTemporary(source.width / tex_scale, source.height / tex_scale, 24, RenderTextureFormat.Default);
                else
                    scam_aTex = RenderTexture.GetTemporary(source.width / tex_scale, source.height / tex_scale, 0, RenderTextureFormat.Default);
                scam.renderingPath = RenderingPath.VertexLit;
                scam_transform.position = camera.transform.position;
                scam_transform.rotation = camera.transform.rotation;
                scam.fieldOfView = this.camera.fieldOfView;
                scam.near = this.camera.near;
                scam.far = this.camera.far;
                scam.targetTexture = scam_aTex;
                scam.backgroundColor = Color.black;
                scam.clearFlags = CameraClearFlags.SolidColor;
                scam.cullingMask = 1 << this.SecondCameraLayer;
                scam.depthTextureMode = DepthTextureMode.None;
                //Setup up the cullingMask is important, as we only want specific objects to be drawn. Therefor no other objects should be assigned to that layer.
                #endregion

                #region DoTheStuff
                RenderTexture buffer = RenderTexture.GetTemporary(source.width / sampling, source.height / sampling, 0);
                RenderTexture buffer2 = RenderTexture.GetTemporary(source.width / sampling, source.height / sampling, 0);
                RenderTexture buffer3 = RenderTexture.GetTemporary(source.width, source.height, 0);
                RenderTexture buffer4 = RenderTexture.GetTemporary(source.width, source.height, 0);

                //clearing buffers. Otherwise previous outlines would still be in there.
                Graphics.Blit(source, buffer3, m_Mat, 2);
                Graphics.Blit(source, buffer4, m_Mat, 2);

                bool oddEven2 = false;

                if (this.temp_renderers == null)
                {
                    temp_renderers = new List<OutlineGlowRenderer>();
                }
                else
                {
                    temp_renderers.Clear();
                }
                temp_renderers.AddRange(renderers.Values);
                temp_renderers.Sort(new OutlineGlowRendererSort());
                // temp_renderers.Sort(

                foreach (OutlineGlowRenderer gr in temp_renderers)
                {
                    if (this.DrawObjectsOnTop && !TopDrawEmpty)
                    {
                        #region SetupTopDrawObjectsAndRender
                        GameObject[] realTopDrawElements = new GameObject[TopDrawObjects.Length];
                        int[] layers = new int[TopDrawObjects.Length];
                        int pos = 0;
                        for (int i = 0; i < TopDrawObjects.Length; i++)
                        {
                            if (TopDrawObjects[i] != null)
                            {
                                realTopDrawElements[pos] = TopDrawObjects[i];
                                layers[pos] = TopDrawObjects[i].layer;
                                pos++;
                            }
                        }
                        for (int i = 0; i < realTopDrawElements.Length; i++)
                        {
                            realTopDrawElements[i].layer = this.SecondCameraLayer;
                        }
                        scam.RenderWithShader(this.TopDrawShader, "");
                        for (int i = 0; i < realTopDrawElements.Length; i++)
                        {
                            if (realTopDrawElements[i] != null)
                                realTopDrawElements[i].layer = layers[i];
                        }
                        scam.clearFlags = CameraClearFlags.Nothing;
                        #endregion
                    }
                    gr.SetLayer(this.SecondCameraLayer);
                    scam.RenderWithShader(this.SecondPassShader, "");
                    scam.clearFlags = CameraClearFlags.SolidColor;
                    // Copy source to the 4x4 smaller texture.
                    DownSample4x(scam_aTex, buffer);

                    // Blur the small texture
                    bool oddEven = true;
                    int tBlurSteps = BlurSteps;
                    if (UseObjectBlurSettings)
                    {
                        gr.ObjectBlurSteps = Mathf.Clamp(gr.ObjectBlurSteps, 1, 6);
                        gr.ObjectBlurSpread = Mathf.Clamp(gr.ObjectBlurSpread, 0, 1.5f);
                        tBlurSteps = gr.ObjectBlurSteps;
                        InternalBlurSpread = gr.ObjectBlurSpread;
                    }
                    else
                    {
                        InternalBlurSpread = BlurSpread;
                    }
                    for (int i = 0; i < tBlurSteps; i++)
                    {
                        if (oddEven)
                            FourTapCone(buffer, buffer2, i);
                        else
                            FourTapCone(buffer2, buffer, i);
                        oddEven = !oddEven;
                    }
                    m_Mat.SetTexture("_WhiteTex", scam_aTex);
                    if (this.UseObjectColors)
                    {
                        m_Mat.SetColor("_OutlineColor", gr.OutlineColor);
                    }
                    else
                    {
                        m_Mat.SetColor("_OutlineColor", this.OutlineColor);
                    }
                    if (UseObjectOutlineStrength)
                    {
                        m_Mat.SetFloat("_Mult", gr.ObjectOutlineStrength);
                    }
                    else
                    {
                        m_Mat.SetFloat("_Mult", this.OutlineStrength);
                    }

                    //stuff for smoother outlines. only works with thicker outlines.
                    m_Mat.SetVector("_TexSize", new Vector4(1.0f / source.width, 1.0f / source.height, 0, 0));
                    if (oddEven)
                    {
                        m_Mat.SetTexture("_BlurTex", buffer);
                    }
                    else
                    {
                        m_Mat.SetTexture("_BlurTex", buffer2);
                    }

                    if (this.SmootherOutlines && this.QuarterResolutionSecondRender)
                    {
                        if (oddEven2)
                        {
                            if (!this.SeeThrough)
                                Graphics.Blit(buffer3, buffer4, m_Mat, 5);
                            else
                                Graphics.Blit(buffer3, buffer4, m_Mat, 1);
                        }
                        else
                        {
                            if (!this.SeeThrough)
                                Graphics.Blit(buffer4, buffer3, m_Mat, 5);
                            else
                                Graphics.Blit(buffer4, buffer3, m_Mat, 1);
                        }
                    }
                    else
                    {
                        if (oddEven2)
                        {
                            if (!this.SeeThrough)
                                Graphics.Blit(buffer3, buffer4, m_Mat, 4);
                            else
                                Graphics.Blit(buffer3, buffer4, m_Mat, 0);
                        }
                        else
                        {
                            if (!this.SeeThrough)
                                Graphics.Blit(buffer4, buffer3, m_Mat, 4);
                            else
                                Graphics.Blit(buffer4, buffer3, m_Mat, 0);
                        }
                    }

                    gr.ResetLayer();
                    oddEven2 = !oddEven2;
                }
                if (oddEven2)
                {
                    m_Mat.SetTexture("_AddTex", buffer3);
                    Graphics.Blit(source, destination, m_Mat, 3);
                }
                else
                {
                    m_Mat.SetTexture("_AddTex", buffer4);
                    Graphics.Blit(source, destination, m_Mat, 3);
                }

                RenderTexture.ReleaseTemporary(buffer);
                RenderTexture.ReleaseTemporary(buffer2);
                RenderTexture.ReleaseTemporary(buffer3);
                RenderTexture.ReleaseTemporary(buffer4);
                RenderTexture.ReleaseTemporary(scam_aTex);
                #endregion
            }
        }
        else
        {
            m_Mat.SetFloat("_MinZ", this.MinZ);
            if (!SplitObjects)
            {
                #region SetupSecondCam

                // Setting up all the here, that is needed for the second camera to work.
                RenderTexture scam_aTex = RenderTexture.GetTemporary(source.width / tex_scale, source.height / tex_scale, 24, RenderTextureFormat.Default);
                RenderTexture tempdepth = RenderTexture.GetTemporary(scam_aTex.width, scam_aTex.height, 24, RenderTextureFormat.Default);
                RenderTexture dsd = null;
                if (QuarterResolutionSecondRender)
                {
                    dsd = RenderTexture.GetTemporary(scam_aTex.width, scam_aTex.height, 0);
                    m_Mat.SetVector("_DTexelOffset", new Vector4(0.5f / source.width, 0.5f / source.height, -0.5f / source.width, 0.5f / source.height));
                    Graphics.Blit(source, dsd, m_Mat, 11);
                }
                scam.renderingPath = RenderingPath.Forward;
                scam_transform.position = camera.transform.position;
                scam_transform.rotation = camera.transform.rotation;
                scam.fieldOfView = this.camera.fieldOfView;
                scam.near = this.camera.near;
                scam.far = this.camera.far;
                scam.targetTexture = scam_aTex;
                scam.backgroundColor = Color.black;
                scam.clearFlags = CameraClearFlags.SolidColor;
                scam.cullingMask = 1 << this.SecondCameraLayer;
                scam.hdr = false;
                scam.depthTextureMode = DepthTextureMode.None;
                //Setup up the cullingMask is important, as we only want specific objects to be drawn. Therefor no other objects should be assigned to that layer.
                #endregion

                #region DoTheStuff
                //DrawTopObjectsFirst, because they possibly can hide alot of other stuff.
                if (this.DrawObjectsOnTop && !TopDrawEmpty)
                {
                    #region SetupTopDrawObjectsAndRender
                    GameObject[] realTopDrawElements = new GameObject[TopDrawObjects.Length];
                    int[] layers = new int[TopDrawObjects.Length];
                    int pos = 0;
                    for (int i = 0; i < TopDrawObjects.Length; i++)
                    {
                        if (TopDrawObjects[i] != null)
                        {
                            realTopDrawElements[pos] = TopDrawObjects[i];
                            layers[pos] = TopDrawObjects[i].layer;
                            TopDrawObjects[i].layer = this.SecondCameraLayer;
                            pos++;
                        }
                    }
                    scam.RenderWithShader(this.TopDrawShader, "");
                    for (int i = 0; i < realTopDrawElements.Length; i++)
                    {
                        if (realTopDrawElements[i] != null)
                            realTopDrawElements[i].layer = layers[i];
                    }
                    scam.clearFlags = CameraClearFlags.Nothing;
                    #endregion
                }
                foreach (OutlineGlowRenderer gr in renderers.Values)
                {
                    gr.SetLayer(this.SecondCameraLayer);
                }
                scam.RenderWithShader(this.SecondPassShader, "");
                scam.targetTexture = tempdepth;
                scam.RenderWithShader(this.DephtPassShader, "RenderType");
                scam.targetTexture = scam_aTex;
                m_Mat.SetTexture("_SecDepth", tempdepth);
                foreach (OutlineGlowRenderer gr in renderers.Values)
                {
                    gr.ResetLayer();
                }

                //BlurCode.
                //Same as the blur-effect script
                RenderTexture buffer = RenderTexture.GetTemporary(source.width / sampling, source.height / sampling, 0);
                RenderTexture buffer2 = RenderTexture.GetTemporary(source.width / sampling, source.height / sampling, 0);
                RenderTexture pbuffer = RenderTexture.GetTemporary(scam_aTex.width, scam_aTex.height, 0);
                

                // Copy source to smaller texture.
                if (!QuarterResolutionSecondRender)
                {
                    m_Mat.SetVector("_DTexelOffset", new Vector4(1f / scam_aTex.width, 1f / scam_aTex.height, -1f / scam_aTex.width, 1f / scam_aTex.height));
                    Graphics.Blit(scam_aTex, pbuffer, m_Mat, 12);
                    Graphics.Blit(pbuffer, scam_aTex, m_Mat, 10);
                }
                else
                {
                    m_Mat.SetVector("_DTexelOffset", new Vector4(1f / scam_aTex.width, 1f / scam_aTex.height, -1f / scam_aTex.width, 1f / scam_aTex.height));
                    m_Mat.SetTexture("_DSD", dsd);
                    Graphics.Blit(scam_aTex, pbuffer, m_Mat, 13);
                    Graphics.Blit(pbuffer, scam_aTex, m_Mat, 10);
                }

                DownSample4x(scam_aTex, buffer);

                // Blur the small texture
                bool oddEven = true;
                for (int i = 0; i < BlurSteps; i++)
                {
                    if (oddEven)
                        FourTapCone(buffer, buffer2, i);
                    else
                        FourTapCone(buffer2, buffer, i);
                    oddEven = !oddEven;
                }
                m_Mat.SetTexture("_WhiteTex", scam_aTex);
                m_Mat.SetColor("_OutlineColor", this.OutlineColor);
                m_Mat.SetFloat("_Mult", this.OutlineStrength);

                //stuff for smoother outlines. only works with thicker outlines.
                m_Mat.SetVector("_TexSize", new Vector4(1.0f / source.width, 1.0f / source.height, 0, 0));
                if (oddEven)
                {
                    m_Mat.SetTexture("_BlurTex", buffer);
                }
                else
                {
                    m_Mat.SetTexture("_BlurTex", buffer2);
                }

                if (this.SmootherOutlines && this.QuarterResolutionSecondRender)
                {
                    Graphics.Blit(source, destination, m_Mat, 1);
                }
                else
                {
                    Graphics.Blit(source, destination, m_Mat, 0);
                }
                
                RenderTexture.ReleaseTemporary(buffer);
                RenderTexture.ReleaseTemporary(buffer2);
                RenderTexture.ReleaseTemporary(scam_aTex);
                RenderTexture.ReleaseTemporary(pbuffer);
                RenderTexture.ReleaseTemporary(tempdepth);
                if(dsd!= null)
                    RenderTexture.ReleaseTemporary(dsd);
                #endregion
            }
            else
            {
                #region SetupSecondCam
                // Setting up all the here, that is needed for the second camera to work.
                RenderTexture scam_aTex = RenderTexture.GetTemporary(source.width / tex_scale, source.height / tex_scale, 0, RenderTextureFormat.Default);
                RenderTexture tempdepth = RenderTexture.GetTemporary(source.width, source.height, 24, RenderTextureFormat.Default);
                scam.renderingPath = RenderingPath.VertexLit;
                scam_transform.position = camera.transform.position;
                scam_transform.rotation = camera.transform.rotation;
                scam.fieldOfView = this.camera.fieldOfView;
                scam.near = this.camera.near;
                scam.far = this.camera.far;
                scam.targetTexture = scam_aTex;
                scam.backgroundColor = Color.black;
                scam.clearFlags = CameraClearFlags.SolidColor;
                scam.cullingMask = 1 << this.SecondCameraLayer;
                scam.depthTextureMode = DepthTextureMode.None;
                //Setup up the cullingMask is important, as we only want specific objects to be drawn. Therefor no other objects should be assigned to that layer.
                #endregion

                #region DoTheStuff
                RenderTexture buffer = RenderTexture.GetTemporary(source.width / sampling, source.height / sampling, 0);
                RenderTexture buffer2 = RenderTexture.GetTemporary(source.width / sampling, source.height / sampling, 0);
                RenderTexture buffer3 = RenderTexture.GetTemporary(source.width, source.height, 0);
                RenderTexture buffer4 = RenderTexture.GetTemporary(source.width, source.height, 0);
                RenderTexture pbuffer = RenderTexture.GetTemporary(scam_aTex.width, scam_aTex.height, 0);

                //clearing buffers. Otherwise previous outlines would still be in there.
                Graphics.Blit(source, buffer3, m_Mat, 2);
                Graphics.Blit(source, buffer4, m_Mat, 2);

                bool oddEven2 = false;

                if (this.temp_renderers == null)
                {
                    temp_renderers = new List<OutlineGlowRenderer>();
                }
                else
                {
                    temp_renderers.Clear();
                }
                temp_renderers.AddRange(renderers.Values);
                temp_renderers.Sort(new OutlineGlowRendererSort());

                foreach (OutlineGlowRenderer gr in temp_renderers)
                {
                    //DrawTopObjectsFirst, because they possibly can hide alot of other stuff.
                    if (this.DrawObjectsOnTop && !TopDrawEmpty)
                    {
                        #region SetupTopDrawObjectsAndRender
                        GameObject[] realTopDrawElements = new GameObject[TopDrawObjects.Length];
                        int[] layers = new int[TopDrawObjects.Length];
                        int pos = 0;
                        for (int i = 0; i < TopDrawObjects.Length; i++)
                        {
                            if (TopDrawObjects[i] != null)
                            {
                                realTopDrawElements[pos] = TopDrawObjects[i];
                                layers[pos] = TopDrawObjects[i].layer;
                                TopDrawObjects[i].layer = this.SecondCameraLayer;
                                pos++;
                            }
                        }
                        scam.RenderWithShader(this.TopDrawShader, "");
                        for (int i = 0; i < realTopDrawElements.Length; i++)
                        {
                            if(realTopDrawElements[i] != null)
                                realTopDrawElements[i].layer = layers[i];
                        }
                        scam.clearFlags = CameraClearFlags.Nothing;
                        #endregion
                    }
                    gr.SetLayer(this.SecondCameraLayer);
                    scam.RenderWithShader(this.SecondPassShader, "");
                    scam.clearFlags = CameraClearFlags.SolidColor;
                    scam.targetTexture = tempdepth;
                    scam.RenderWithShader(this.DephtPassShader, "RenderType");
                    scam.targetTexture = scam_aTex;
                    m_Mat.SetTexture("_SecDepth", tempdepth);
                    
                    Graphics.Blit(scam_aTex, pbuffer, m_Mat, 8);
                    Graphics.Blit(pbuffer, scam_aTex, m_Mat, 10);

                    // Copy source to smaller texture.
                    DownSample4x(scam_aTex, buffer);

                    // Blur the small texture
                    bool oddEven = true;
                    int tBlurSteps = BlurSteps;
                    if (UseObjectBlurSettings)
                    {
                        gr.ObjectBlurSteps = Mathf.Clamp(gr.ObjectBlurSteps, 1, 6);
                        gr.ObjectBlurSpread = Mathf.Clamp(gr.ObjectBlurSpread, 0, 1.5f);
                        tBlurSteps = gr.ObjectBlurSteps;
                        InternalBlurSpread = gr.ObjectBlurSpread;
                    }
                    else
                    {
                        InternalBlurSpread = BlurSpread;
                    }
                    for (int i = 0; i < tBlurSteps; i++)
                    {
                        if (oddEven)
                            FourTapCone(buffer, buffer2, i);
                        else
                            FourTapCone(buffer2, buffer, i);
                        oddEven = !oddEven;
                    }
                    m_Mat.SetTexture("_WhiteTex", scam_aTex);
                    if (this.UseObjectColors)
                    {
                        m_Mat.SetColor("_OutlineColor", gr.OutlineColor);
                    }
                    else
                    {
                        m_Mat.SetColor("_OutlineColor", this.OutlineColor);
                    }
                    if (UseObjectOutlineStrength)
                    {
                        m_Mat.SetFloat("_Mult", gr.ObjectOutlineStrength);
                    }
                    else
                    {
                        m_Mat.SetFloat("_Mult", this.OutlineStrength);
                    }

                    //stuff for smoother outlines. only works with thicker outlines.
                    m_Mat.SetVector("_TexSize", new Vector4(1.0f / source.width, 1.0f / source.height, 0, 0));
                    if (oddEven)
                    {
                        m_Mat.SetTexture("_BlurTex", buffer);
                    }
                    else
                    {
                        m_Mat.SetTexture("_BlurTex", buffer2);
                    }

                    if (this.SmootherOutlines && this.QuarterResolutionSecondRender)
                    {
                        if (oddEven2)
                        {
                            if (!this.SeeThrough)
                                Graphics.Blit(buffer3, buffer4, m_Mat, 5);
                            else
                                Graphics.Blit(buffer3, buffer4, m_Mat, 1);
                        }
                        else
                        {
                            if (!this.SeeThrough)
                                Graphics.Blit(buffer4, buffer3, m_Mat, 5);
                            else
                                Graphics.Blit(buffer4, buffer3, m_Mat, 1);
                        }
                    }
                    else
                    {
                        if (oddEven2)
                        {
                            if (!this.SeeThrough)
                                Graphics.Blit(buffer3, buffer4, m_Mat, 4);
                            else
                                Graphics.Blit(buffer3, buffer4, m_Mat, 0);
                        }
                        else
                        {
                            if (!this.SeeThrough)
                                Graphics.Blit(buffer4, buffer3, m_Mat, 4);
                            else
                                Graphics.Blit(buffer4, buffer3, m_Mat, 0);
                        }
                    }

                    gr.ResetLayer();
                    oddEven2 = !oddEven2;
                }
                if (oddEven2)
                {
                    m_Mat.SetTexture("_AddTex", buffer3);
                    Graphics.Blit(source, destination, m_Mat, 3);
                }
                else
                {
                    m_Mat.SetTexture("_AddTex", buffer4);
                    Graphics.Blit(source, destination, m_Mat, 3);
                }

                RenderTexture.ReleaseTemporary(buffer);
                RenderTexture.ReleaseTemporary(buffer2);
                RenderTexture.ReleaseTemporary(buffer3);
                RenderTexture.ReleaseTemporary(buffer4);
                RenderTexture.ReleaseTemporary(scam_aTex);
                RenderTexture.ReleaseTemporary(tempdepth);
                RenderTexture.ReleaseTemporary(pbuffer);
                #endregion
            }
        }
    }
}

public class OutlineGlowRendererSort : IComparer<OutlineGlowRenderer>
{

    public int Compare(OutlineGlowRenderer x, OutlineGlowRenderer y)
    {
        Vector3 camPos;
        try
        {
            camPos = Camera.current.transform.position;
        }
        catch
        {
            Debug.Log("Couldn't find current camera!");
            return 0;
        }
        float sdx = (x.transform.position - camPos).magnitude;
        float sdy = (y.transform.position - camPos).magnitude;
        if (sdx > sdy)
            return -1;
        else
            return 1;
    }
}
