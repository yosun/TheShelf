Shader "Chickenlord/3.5/Relief Mapping Shaded Specular Silhouette Clipped" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
	_Parallax ("Height", Range (0.005, 0.18)) = 0.02
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_ParallaxMap ("Heightmap (A)", 2D) = "black" {}
	_ShadeRange("Shading Range",Float) = 0.02
	_ShadingStrength("Shading Strength",Range(0,1)) = 1
	_AlphaCutRange("Alpha Cut Range",Float) = 1
	_UseAlpha ("Use Alpha",Range(0,1)) = 1
}
SubShader { 
	Tags {"Queue"="Transparent-15" "IgnoreProjector"="false" "RenderType"="Transparent"}
	LOD 600
	ZWrite On
	CGPROGRAM

	#define SHADOW_STEPS 7
	#define LINEAR_STEPS 20
	#define BINARY_STEPS 6

	#pragma surface surf BlinnPhongShifted alpha novertexlights
	#pragma target 3.0
	//#pragma only_renderers d3d9

	sampler2D _MainTex;
	sampler2D _BumpMap;
	sampler2D _ParallaxMap;
	fixed4 _Color;
	half _Shininess;
	float _Parallax;
	float _ShadingStrength;
	float _ShadeRange;
	float _AlphaCutRange;
	half _UseAlpha;

	struct Input {
		float2 uv_MainTex;
		float2 uv_BumpMap;
		float3 viewDir;
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

	inline float3 BinaryRefine(sampler2D heightTex, float3 p,float3 off)
	{	
		for(int i = 0; i<BINARY_STEPS;i++)
		{
			off *= 0.5;
			half tex = tex2D(heightTex,p.xy).a;
			if(p.z<tex)
			{
				p += off;
			}
			else
			{
				p -= off;
			}
		}
		return p;
	}

	inline float CheckShading(sampler2D heightTex,float2 uv,float3 lightDir)
	{
		half hn = 1-tex2D (heightTex, uv).a;
		half ret = 1;
		float3 off = ((1-hn)*lightDir)/SHADOW_STEPS;
		half hld = 1;
		half tx = 0;
		for(int i = 1;i<SHADOW_STEPS;i++)
		{
			uv-=off;
			hld = 1-tex2D (heightTex, uv).a;
			if(hld+off.z*i>=hn)
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

	inline float2 RealOffset(float2 uv,sampler2D heightTex,half h,float3 viewDir,float height)
	{
		float3 offset = float3(uv,0);
		float xxx = 1-viewDir.z;
		xxx = 1-(pow(xxx,3));
		float3 off = normalize(viewDir*-1);
		off.z = abs(viewDir.z);
		off.xy *= (xxx*height);
		off /= (viewDir.z*LINEAR_STEPS);
		float3 tvec = float3(uv,0);
		half nh = 0;
		for(int i = 0; i<LINEAR_STEPS;i++)
		{
			nh = tex2D(heightTex,tvec.xy).a;
			if(tvec.z < nh)
			{
				tvec += off;
			}
		}
		offset = BinaryRefine(heightTex,tvec,off);
		float2 ret = offset.xy-uv;
		return ret;
	}


	inline fixed4 LightingBlinnPhongShifted (SurfaceOutputPS s, float3 lightDir, float3 viewDir, fixed atten)
	{
		float3 xdir = -lightDir*(_ShadeRange+_Parallax);
		float mixVal = (_ShadingStrength)+(1-_ShadingStrength)*CheckShading(_ParallaxMap,s.ShadeMapUV,xdir);
		
		fixed3 h = normalize (lightDir+viewDir);
		float3 normal = s.Normal;
		normal.z *= mixVal;
		fixed diff = mixVal*max (0, dot (normal, lightDir));
		
		float nh = max (0, dot (normal, h));
		float spec = mixVal*pow (nh, s.Specular*128.0) * s.Gloss;
		
		fixed4 c;
		
		c.rgb = mixVal*(s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten * 2);
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
		
		half h = tex2D (_ParallaxMap, IN.uv_BumpMap).w;
		float2 ox = RealOffset(IN.uv_BumpMap,_ParallaxMap,h,normalize(IN.viewDir),_Parallax);
		float2 origUV = IN.uv_BumpMap;
		IN.uv_MainTex += ox;
		IN.uv_BumpMap += ox;
		float2 pos = IN.uv_MainTex;
		if((pos.x/_AlphaCutRange>1.0f)||(pos.y/_AlphaCutRange>1.0f)||(pos.x/_AlphaCutRange<0.0f)||(pos.y/_AlphaCutRange<0.0f))
		{
			o.Alpha = 0;
		}
		else
		{
			o.Alpha = 1;
		}
		o.ShadeMapUV = origUV+(ox);
		fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
		o.Albedo = tex.rgb * _Color.rgb;
		o.Gloss = tex.a;
		
		o.Alpha += _UseAlpha;
		o.Specular = _Shininess;
		o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
		float3 worldNormal = WorldNormalVector(IN,o.Normal);
		o.Emission += o.Albedo*ShadeSH9(float4(worldNormal,1));
	}
	ENDCG
	}

FallBack "Bumped Specular"
}
