Shader "Chickenlord/Reflective/Cook-Torrance Parallax Shaded Specular" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_Shininess ("Shininess", Range (0.03, 1)) = 0.078125
	_RMS("BDF RMS (Specular spread)",Range(0.001,1)) = 0.70710678118654752440084436210485
	_ReflectColor ("Reflection Color", Color) = (1,1,1,0.5)
	_Parallax ("Height", Range (0.005, 0.08)) = 0.02
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_Cube ("Reflection Cubemap", Cube) = "_Skybox" { TexGen CubeReflect }
	_ParallaxMap ("Heightmap (A)", 2D) = "black" {}
	_ShadeRange("Shading Range",Float) = 0.02
	_ShadingStrength("Shading Strength",Range(0,1)) = 1
}
SubShader { 
	Tags { "RenderType"="Opaque" }
	LOD 600
	
	CGPROGRAM
	#define SHADOW_STEPS 7
	
	#include "CgHelper.cginc"
	#pragma surface surf CookTorrance fullforwardshadows addshadow
	#pragma target 3.0

	sampler2D _MainTex;
	sampler2D _BumpMap;
	sampler2D _ParallaxMap;
	fixed4 _Color;
	half _Shininess;
	float _Parallax;
	float _RMS;
	samplerCUBE _Cube;
	fixed4 _ReflectColor;
	float _ShadingStrength;
	float _ShadeRange;

	inline float BDist(float3 N,float3 H,float m)
	{
		float alpha = acos(dot(N,H));
		float caq = pow(cos(alpha),2);
		float simp = (1-caq)/(caq*m*m);
		float kspec = exp(-simp)/(PI*m*m*caq*caq);
		return kspec;
	}

	inline float Schlick(float Rzero,float3 lightDir,float3 normal)
	{
		return Rzero + (1 - Rzero)*pow((1 - dot(lightDir,normal)),5);
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
	
	struct Input {
		float2 uv_MainTex;
		float2 uv_BumpMap;
		float3 viewDir;
		float3 worldRefl;
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

	inline fixed4 LightingCookTorrance (SurfaceOutputPS s, fixed3 lightDir, fixed3 viewDir, fixed atten)
	{
		float3 xdir = -lightDir*(_ShadeRange+_Parallax);
		float mixVal = (_ShadingStrength)+(1-_ShadingStrength)*CheckShading(_ParallaxMap,s.ShadeMapUV,xdir);
	
		float3 h = normalize (lightDir + viewDir);
		float3 normal = s.Normal;
		normal.z *= mixVal;
		
		float hn = dot(h,normal);
		float vh = dot(viewDir,h);
		float G = max(0,min(1,min((2*hn*dot(viewDir,normal))/vh,(2*hn*dot(lightDir,normal))/vh)));
		float diff = mixVal*max (0, dot (normal, lightDir));
		float spec = min(1,max(0,BDist(normal,h,(_RMS))*Schlick(1-s.Specular,h,normal)*s.Gloss/(dot(viewDir,normal))));
		float4 c;
		c.rgb = (s.Albedo * _LightColor0.rgb*diff + _LightColor0.rgb * _SpecColor.rgb*spec) * (G*atten*2);
		c.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec * G*atten;
		return c;
	}

	void surf (Input IN, inout SurfaceOutputPS o) 
	{
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
		o.Emission = reflcol.rgb * _ReflectColor.rgb;
	}
	ENDCG
	}

	FallBack "Reflective/Parallax Specular"
}
