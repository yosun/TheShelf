using UnityEngine;
using System.Collections;

/// <summary>
/// Used to add additional lights to the baked lightprobes or one global lightprobe (used for the free vertsion).
/// Only point and directional lights can be added.
/// Point lights can only be added to baked light probes and are ignored for the global probe.
/// </summary>
[AddComponentMenu("Chickenlord/Spherical Harmonics Calculator")]
public class CSB_SHLightHelper : MonoBehaviour
{
    public GameObject[] Lights;
    public bool SearchForLights;
    public bool OnlyUseActiveLights;
    public bool DeactivateLightsWhenFinished;
    public bool AddToBakedProbes = false;
    LightProbes lightProbes;
	
    // Use this for initialization
    void Start()
    {
        float[] globalCoeffs = new float[27];
        for (int i = 0; i < globalCoeffs.Length; i++)
        {
            globalCoeffs[i] = 0;
        }
        Light[] lights = null;
        {
            if (SearchForLights)
            {
                GameObject[] temp = (GameObject[])FindObjectsOfType(typeof(GameObject));
                int lcount = 0;
                for (int i = 0; i < temp.Length; i++)
                {
                    if (temp[i].GetComponent<Light>() != null)
                    {
                        lcount++;
                    }
                }
                lights = new Light[lcount];
                GameObject[] tars = new GameObject[lcount];
                int pos = 0;
                for (int i = 0; i < temp.Length; i++)
                {
                    Light tl = temp[i].GetComponent<Light>();

                    if (tl != null)
                    {
                        lights[pos] = tl;
                        tars[pos] = temp[i];
                        pos++;
                    }
                }
                Lights = tars;
            }
            else
            {
                GameObject[] temp = Lights;
                int lcount = 0;
                for (int i = 0; i < temp.Length; i++)
                {
                    if (temp[i] != null && temp[i].GetComponent<Light>() != null)
                    {
                        lcount++;
                    }
                }
                lights = new Light[lcount];
                GameObject[] tars = new GameObject[lcount];
                int pos = 0;
                for (int i = 0; i < temp.Length; i++)
                {
                    if (temp[i] != null)
                    {
                        Light tl = temp[i].GetComponent<Light>();

                        if (tl != null)
                        {
                            lights[pos] = tl;
                            tars[pos] = temp[i];
                            pos++;
                        }
                    }
                }
                Lights = tars;
            }
        }
        Color ambient = Color.black;

        {
            float[] coefficients = null;
            int coefficientsPerProbe = 27;
            int probeCount = 0;
            Vector3[] probePositions = null;
            if (AddToBakedProbes)
            {
                try
                {
                    lightProbes = Instantiate(LightmapSettings.lightProbes) as LightProbes;
                    coefficients = lightProbes.coefficients;
                    coefficientsPerProbe = 27;
                    probeCount = lightProbes.count;
                    probePositions = lightProbes.positions;
                }
                catch
                {
                    lightProbes = null;

                    return;
                }
            }
            if (coefficients == null)
            {
                coefficients = new float[0];
                probeCount = 0;
                probePositions = new Vector3[0];
            }
            int i = 0;
            foreach (Light l in lights)
            {
                if (!OnlyUseActiveLights || (OnlyUseActiveLights && l.enabled && l.gameObject.active))
                {
                    if (l.type == LightType.Directional)
                    {
                        i = 0;
                        while (i < probeCount)
                        {
                            //Debug.Log("Added Directional Light");
                            if (AddToBakedProbes)
                            {
                                AddSHDirectionalLight(l.color, -l.transform.forward, l.intensity, coefficients, i * coefficientsPerProbe);
                            }
                            i++;
                        }
                        AddSHDirectionalLight(l.color, -l.transform.forward, l.intensity, globalCoeffs, 0);
                    }
                    else if(AddToBakedProbes)
                        if (l.type == LightType.Point)
                        {
                            i = 0;
                            while (i < probeCount)
                            {
                                //Debug.Log("Added Point Light");
                                AddSHPointLight(l.color, l.transform.position, l.range, l.intensity, coefficients, i * coefficientsPerProbe, probePositions[i]);
                                i++;
                            }
                        }
                }
                if (DeactivateLightsWhenFinished)
                {
                    l.enabled = false;
                }
            }
            if (AddToBakedProbes && lightProbes!= null)
            {
                lightProbes.coefficients = coefficients;
                LightmapSettings.lightProbes = lightProbes;
            }
			
            int pos = 0;
            float[] tcoffs = new float[27];
            for (int j = 0; j < 3; j++)
            {
                for(int k = 0; k<9;k++)
                {
                    tcoffs[pos] = globalCoeffs[k * 3 + j];
                    pos++;
                }
            }
            globalCoeffs = tcoffs;
            Norm(globalCoeffs);
            SetCoefficients(globalCoeffs);
        }
    }

    float abs(float x)
    {
        if (x < 0)
            return -x;
        return x;
    }

    float max(float a, float b)
    {
        if (a < b)
            return b;
        return a;
    }

    void Norm(float[] vals)
    {
        float maxv = 0;
        for (int i = 0; i < vals.Length; i++)
        {
            maxv = max(maxv, abs(vals[i]));
        }

        for (int i = 0; i < vals.Length; i++)
        {
            vals[i] /= maxv;
        }
    }


    void SetCoefficients(float[] coeffs)
    {
        Vector4 half = new Vector4(0.5f, 0.5f, 0.5f, 0.5f);
        Vector4[] vCoeff = new Vector4[3];
        float s_fSqrtPI = (Mathf.Sqrt(Mathf.PI));
        float fC0 = 1.0f/(2.0f*s_fSqrtPI);
        float fC1 = Mathf.Sqrt(3.0f) / (3.0f * s_fSqrtPI);
        float fC2 = Mathf.Sqrt(15.0f) / (8.0f * s_fSqrtPI);
        float fC3 = Mathf.Sqrt(5.0f)/(16.0f*s_fSqrtPI);
        float fC4 = 0.5f*fC2;
        int iC;
        for( iC=0; iC<3; iC++ )
        {
            vCoeff[iC].x = -fC1 * coeffs[iC * 9 + 3];
            vCoeff[iC].y = -fC1 * coeffs[iC * 9 + 1];
            vCoeff[iC].z = fC1 * coeffs[iC * 9 + 2];
            vCoeff[iC].w = fC0 * coeffs[iC * 9 + 0] - fC3 * coeffs[iC * 9 + 6];
        }
        Shader.SetGlobalVector("CSB_SHAr", vCoeff[0]);
        Shader.SetGlobalVector("CSB_SHAg", vCoeff[1]);
        Shader.SetGlobalVector("CSB_SHAb", vCoeff[2]);
        for( iC=0; iC<3; iC++ )
        {
            vCoeff[iC].x = fC2 * coeffs[iC * 9 + 4];
            vCoeff[iC].y = -fC2 * coeffs[iC * 9 + 5];
            vCoeff[iC].z = 3.0f * fC3 * coeffs[iC * 9 + 6];
            vCoeff[iC].w = -fC2 * coeffs[iC * 9 + 7];
        }
        Shader.SetGlobalVector("CSB_SHBr", vCoeff[0]);
        Shader.SetGlobalVector("CSB_SHBg", vCoeff[1]);
        Shader.SetGlobalVector("CSB_SHBb", vCoeff[2]);
        vCoeff[0].x = fC4 * coeffs[8];
        vCoeff[0].y = fC4 * coeffs[17];
        vCoeff[0].z = fC4 * coeffs[26];
        vCoeff[0].w = 1.0f;
        Shader.SetGlobalVector("CSB_SHC", vCoeff[0]);
    }

    void AddSHAmbientLight(Color color, float[] coefficients, int index)
    {
        float k2SqrtPI = 3.54490770181F;
        coefficients[index + 0] += color.r * k2SqrtPI;
        coefficients[index + 1] += color.g * k2SqrtPI;
        coefficients[index + 2] += color.b * k2SqrtPI;
    }
    void AddSHDirectionalLight(Color color, Vector3 direction, float intensity, float[] coefficients, int index)
    {
        float kInv2SqrtPI = 0.28209479177F;
        float kSqrt3Div2SqrtPI = 0.4886025119F;
        float kSqrt15Div2SqrtPI = 1.09254843059F;
        float k3Sqrt5Div4SqrtPI = 0.94617469576F;
        float kSqrt15Div4SqrtPI = 0.5462742153F;
        float kOneThird = 0.33333333333F;
        float[] dirFactors = new float[9];
        dirFactors[0] = kInv2SqrtPI;
        dirFactors[1] = -direction.y * kSqrt3Div2SqrtPI;
        dirFactors[2] = direction.z * kSqrt3Div2SqrtPI;
        dirFactors[3] = -direction.x * kSqrt3Div2SqrtPI;
        dirFactors[4] = direction.x * direction.y * kSqrt15Div2SqrtPI;
        dirFactors[5] = -direction.y * direction.z * kSqrt15Div2SqrtPI;
        dirFactors[6] = (direction.z * direction.z - kOneThird) * k3Sqrt5Div4SqrtPI;
        dirFactors[7] = -direction.x * direction.z * kSqrt15Div2SqrtPI;
        dirFactors[8] = (direction.x * direction.x - direction.y * direction.y) * kSqrt15Div4SqrtPI;
        float kNormalization = 2.95679308573F;
        intensity *= 2.0F;
        float rscale = color.r * intensity * kNormalization;
        float gscale = color.g * intensity * kNormalization;
        float bscale = color.b * intensity * kNormalization;
        int i = 0;
        while (i < 9)
        {
            float c = dirFactors[i];
            coefficients[index + 3 * i + 0] += c * rscale;
            coefficients[index + 3 * i + 1] += c * gscale;
            coefficients[index + 3 * i + 2] += c * bscale;
            ++i;
        }
    }
    void AddSHPointLight(Color color, Vector3 position, float range, float intensity, float[] coefficients, int index, Vector3 probePosition)
    {
        Vector3 probeToLight = position - probePosition;
        float attenuation = 1.0F / (1.0F + 25.0F * probeToLight.sqrMagnitude / range * range);
        AddSHDirectionalLight(color, probeToLight.normalized, intensity * attenuation, coefficients, index);
    }
}
