Shader "Chickenlord/3.5/Reflective/Fresnel/Parallax Shaded Specular" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
	_Parallax ("Height", Range (0.005, 0.08)) = 0.02
	_ReflectColor ("Reflection Color", Color) = (1,1,1,0.5)
	_Fresnel("Reflection Fresnel Exponent",Range(0,6)) = 1
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_ParallaxMap ("Heightmap (A)", 2D) = "black" {}
	_Cube ("Reflection Cubemap", Cube) = "_Skybox" { TexGen CubeReflect }
	_ShadeRange("Shading Range",Float) = 0.02
	_ShadingStrength("Shading Strength",Range(0,1)) = 1
}
SubShader { 
	Tags { "RenderType"="Opaque" }
	LOD 600
	
	CGPROGRAM
	#define SHADOW_STEPS 7

	#pragma surface surf BlinnPhongShifted fullforwardshadows addshadow novertexlights
	#pragma target 3.0

	sampler2D _MainTex;
	sampler2D _BumpMap;
	sampler2D _ParallaxMap;
	fixed4 _Color;
	half _Shininess;
	float _Parallax;
	float _ShadingStrength;
	float _ShadeRange;
	samplerCUBE _Cube;
	fixed4 _ReflectColor;
	half _Fresnel;

	struct Input {
		float2 uv_MainTex;
		float2 uv_BumpMap;
		float3 viewDir;
		float3 worldRefl;
		float3 worldNormal;
		INTERNAL_DATA
	};

	struct SurfaceOutputPS {
		fixed3 Albedo;
		fixed3 Normal;
		fixed3 Emission;
		half Specular;
		fixed Gloss;
		fixed Alpha;
		float2 ShadeMapUV;
	};
	
	inline float Schlick2(float Rzero,float3 lightDir,float3 normal,float exponent)
	{
		return Rzero + (1 - Rzero)*pow((1 - dot(lightDir,normal)),exponent);
	}


	inline float CheckShading(sampler2D heightTex,float2 uv,float3 lightDir)
	{
		float hn = tex2D (heightTex, uv).a;
		float ret = 1;
		float2 off = lightDir.xy/SHADOW_STEPS;
		float hld = 0;
		half tx = 0;
		for(int i = 1;i<=SHADOW_STEPS;i++)
		{
			uv-= off;
			hld = tex2D (heightTex,uv).a;
			if(hld+lightDir.z>hn)
			{
				tx = 1-(hld-hn);
				if(ret>tx)
				{
					ret = tx;
				}
			}
		}
		return (ret);
	}


	inline fixed4 LightingBlinnPhongShifted (SurfaceOutputPS s, fixed3 lightDir, fixed3 viewDir, fixed atten)
	{
		float3 xdir = -lightDir*(_ShadeRange+_Parallax);
		float mixVal = (_ShadingStrength)+(1-_ShadingStrength)*CheckShading(_ParallaxMap,s.ShadeMapUV,xdir);
		
		fixed3 h = normalize (lightDir+viewDir);
		float3 normal = s.Normal;
		normal.z *= mixVal;
		fixed diff = mixVal*max (0, dot (normal, lightDir));
		
		float nh = max (0, dot (normal, h));
		float spec = pow (nh, s.Specular*128.0) * s.Gloss;
		
		fixed4 c;
		
		c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten * 2);
		c.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec * atten;
		return c;
	}
	
	inline half4 LightingBlinnPhongShifted_DirLightmap (SurfaceOutputPS s, fixed4 color, fixed4 scale, half3 viewDir, bool surfFuncWritesNormal, out half3 specColor)
	{
		UNITY_DIRBASIS
		half3 scalePerBasisVector;
		
		half3 lm = DirLightmapDiffuse (unity_DirBasis, color, scale, s.Normal, surfFuncWritesNormal, scalePerBasisVector);
		
		half3 lightDir = normalize (scalePerBasisVector.x * unity_DirBasis[0] + scalePerBasisVector.y * unity_DirBasis[1] + scalePerBasisVector.z * unity_DirBasis[2]);
		
		float3 xdir = -lightDir*(_ShadeRange+_Parallax);
		float mixVal = (_ShadingStrength)+(1-_ShadingStrength)*CheckShading(_ParallaxMap,s.ShadeMapUV,xdir);
		
		half3 h = normalize (lightDir+viewDir);
		float3 normal = s.Normal;
		normal.z *= mixVal;

		float nh = max (0, dot (normal, h));
		float spec = pow (nh, s.Specular * 128.0);
		
		spec *= mixVal;
		// specColor used outside in the forward path, compiled out in prepass
		specColor = lm * _SpecColor.rgb * s.Gloss * spec;
		
		// spec from the alpha component is used to calculate specular
		// in the Lighting*_Prepass function, it's not used in forward
		return half4(lm*mixVal, spec);
	}


	void surf (Input IN, inout SurfaceOutputPS o) {
		o.ShadeMapUV = IN.uv_BumpMap;
		half h = tex2D (_ParallaxMap, IN.uv_BumpMap).w;
		float2 offset = ParallaxOffset (h, _Parallax, IN.viewDir);
		IN.uv_MainTex += offset;
		IN.uv_BumpMap += offset;
		
		fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
		o.Albedo = tex.rgb * _Color.rgb;
		o.Gloss = tex.a;
		o.Alpha = tex.a * _Color.a;
		o.Specular = _Shininess;
		o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
		float3 worldRefl = WorldReflectionVector (IN, o.Normal);
		fixed4 reflcol = texCUBE (_Cube, worldRefl);
		reflcol *= tex.a;
		reflcol *= Schlick2(0,normalize(IN.viewDir),o.Normal,_Fresnel);
		o.Emission = reflcol.rgb * _ReflectColor.rgb;
		float3 worldNormal = WorldNormalVector(IN,o.Normal);
		o.Emission += o.Albedo*ShadeSH9(float4(worldNormal,1));
	}
	ENDCG
	}

FallBack "Reflective/Parallax Specular"
}
