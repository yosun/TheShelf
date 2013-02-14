using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
[AddComponentMenu("Image Effects/Screen Space Subsurface Scattering")]
public class ScreenSpaceSubsurfaceScattering : MonoBehaviour {


    public float m_Blur = 2.51f;
    public int m_blursteps = 4;
    public Shader m_PassTwoShader;
    public Shader m_MixShader;
    public Shader m_DepthShader;
	public bool ConsecutiveDownsampling = true;
    private Vector3[] CheckVals = new Vector3[6];
    private bool m_Supported;
    private RenderTexture tempDepth;

    private Material m_MixMaterial;

    private Material smat;

    private Camera scam;
    private GameObject camObject;
    private Transform scam_transform;
    private Transform myTransform;
    private Camera myCamera;
    private Vector3 nvec = new Vector3(0, 0, 0);

    private Vector4[] blends = {    new Vector4(0.233f, 0.455f, 0.649f,0.0f),
                                    new Vector4(0.100f, 0.336f, 0.344f,0.0f),
                                    new Vector4(0.118f, 0.198f, 0.0f,0.0f),
                                    new Vector4(0.113f, 0.007f, 0.007f,0.0f),
                                    new Vector4(0.358f, 0.004f, 0.0f,0.0f),
                                    new Vector4(0.078f, 0.0f, 0.0f,0.0f)      };

	

	 void Start()
    {
        if (!SystemInfo.supportsImageEffects || !SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.Depth))
        {
        
            enabled = false;
            return;
        }
        myTransform = this.transform;
        camera.depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    void OnDisable()
    {
        Material.DestroyImmediate(m_MixMaterial);
		if (scam != null)
        {
			DestroyImmediate(camObject);
        }
    }
	
	void OnApplicationQuit()
	{
		if (scam != null)
        {
			DestroyImmediate(camObject);
        }
	}

    void OnRenderImage(RenderTexture source,RenderTexture destination)
    {
		if (!m_PassTwoShader || !m_MixShader || !m_DepthShader)
        {
            Graphics.Blit(source, destination);
            return;
        }
        if(!smat)
        {
            smat = new Material(m_MixShader);
        }
        camera.depthTextureMode |= DepthTextureMode.DepthNormals;
        if (scam == null)
        {
			if(camObject != null)
			{
				DestroyImmediate(camObject);
			}
            GameObject go = new GameObject();
            scam = go.AddComponent<Camera>();
            scam_transform = scam.transform;
            scam.gameObject.name = "S5 Cam";
			camObject = go;
            camObject.hideFlags = HideFlags.HideAndDontSave;
        }
        if (!m_MixMaterial)
        {
            m_MixMaterial = new Material(m_MixShader);
        }
		if(tempDepth != null)
		{
			tempDepth.Release();
		}
		
		{
			tempDepth = RenderTexture.GetTemporary(source.width,source.height,24,RenderTextureFormat.ARGB32);
			Graphics.Blit(source, tempDepth, m_MixMaterial, 3);
		}
        m_blursteps = Mathf.Clamp(m_blursteps, 1, 5);
        m_Blur = Mathf.Clamp(m_Blur, 0, 10);
        scam.depthTextureMode = DepthTextureMode.DepthNormals;
		
        scam.enabled = false;
        RenderTexture scam_aTex = RenderTexture.GetTemporary(source.width, source.height, 24, RenderTextureFormat.Default);
        RenderTexture scam_dTex = RenderTexture.GetTemporary(source.width, source.height, 24, RenderTextureFormat.Default);
        scam.hdr = this.camera.hdr;
        RenderTexture[] blurs = new RenderTexture[5];
        for (int i = 0; i < m_blursteps; i++)
        {
			if(ConsecutiveDownsampling)
			{
				blurs[i] = RenderTexture.GetTemporary(source.width/((i+1)*2), source.height/((i+1)*2), 0, RenderTextureFormat.Default);
			}
			else
			{
				blurs[i] = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.Default);
			}
        }
        #region SetupSecondCam
        scam.renderingPath = RenderingPath.Forward;
        scam_transform.position = myTransform.position;
        scam_transform.rotation = myTransform.rotation;
        scam.fieldOfView = this.camera.fieldOfView;
        scam.near = this.camera.near;
        scam.far = this.camera.far;
        scam.targetTexture = scam_aTex;
        #endregion
        //Render second cam with replaced albedo only shader.
        //Hidden/Camera-DepthNormalTexture
        scam.RenderWithShader(m_PassTwoShader, "Scattering");
        scam.targetTexture = scam_dTex;
        scam.RenderWithShader(m_DepthShader, "Scattering");
        //Graphics.Blit(source, depth, m_MixMaterial, 2);
		m_MixMaterial.SetTexture("_SecDepth", scam_dTex);
		if(this.camera.renderingPath == RenderingPath.Forward && tempDepth != null)
			Shader.SetGlobalTexture("_CameraDepthNormals",tempDepth);
		RenderTexture tempLight = RenderTexture.GetTemporary(source.width, source.height, 0);
		Graphics.Blit(source, tempLight, m_MixMaterial, 2);
        RenderTexture tex = tempLight;
        for (int i = 0; i < m_blursteps; i++)
        {
            // Blur SSAO horizontally
            RenderTexture rtBlurX = RenderTexture.GetTemporary(tex.width, tex.height, 0);
            m_MixMaterial.SetVector("_TexelOffsetScale",
                new Vector4((float)m_Blur / tex.width, 0, 0, 0));
            m_MixMaterial.SetTexture("_SSAO", tex);
            Graphics.Blit(null, rtBlurX, m_MixMaterial, 0);
            //RenderTexture.ReleaseTemporary(rtAO); // original rtAO not needed anymore

            // Blur SSAO vertically
            RenderTexture rtBlurY = blurs[i];
            m_MixMaterial.SetVector("_TexelOffsetScale",
                new Vector4(0, (float)m_Blur / tex.height, 0, 0));
            m_MixMaterial.SetTexture("_SSAO", rtBlurX);
            Graphics.Blit(tex, rtBlurY, m_MixMaterial, 0);
            RenderTexture.ReleaseTemporary(rtBlurX); // blurX RT not needed anymore
            tex = rtBlurY; // AO is the blurred one now
        }

        Vector4 tv = new Vector4(0,0,0,0);
        for (int i = m_blursteps; i < blends.Length; i++)
        {
            tv += blends[i];
        }

        m_MixMaterial.SetVector("_direct", blends[0]);
        CheckVals[0] = blends[0];

        m_MixMaterial.SetTexture("_SSAO", tempLight);
        for (int i = 1; i < blends.Length; i++)
        {
            if(i<m_blursteps)
            {
                m_MixMaterial.SetVector("_b"+i, blends[i]);
                CheckVals[i] = blends[i];
            }
            else if(i== m_blursteps)
            {
                m_MixMaterial.SetVector("_b" + i, tv);
                CheckVals[i] = tv;
            }
            else
            {
                m_MixMaterial.SetVector("_b" + i, nvec);
                CheckVals[i] = nvec;
            }
            m_MixMaterial.SetTexture("_Bl" + i, blurs[i-1]);
        }

        //Realsing textures
        //m_MixMaterial

        if (this.camera.actualRenderingPath != RenderingPath.DeferredLighting && QualitySettings.antiAliasing != 0)
        {
            m_MixMaterial.SetFloat("Forward_S5", 0);
        }
        else
        {
            m_MixMaterial.SetFloat("Forward_S5", 1);
        }
		m_MixMaterial.SetTexture("_MainTex2",scam_aTex);
        Graphics.Blit(source, destination, m_MixMaterial, 1);
		
		
        //Graphics.Blit(tex, destination);
		//Graphics.Blit(tempLight, destination);
		//Graphics.Blit(source, destination, m_MixMaterial, 3);
        RenderTexture.ReleaseTemporary(scam_aTex);
        RenderTexture.ReleaseTemporary(scam_dTex);
		RenderTexture.ReleaseTemporary(tempLight);
        for (int i = 0; i < blurs.Length; i++)
        {
            if (blurs[i] != null)
                RenderTexture.ReleaseTemporary(blurs[i]);
        }
        
    }

    void OnDestroy()
    {
        if (scam != null)
        {
			DestroyImmediate(camObject);
        }
    }
}
