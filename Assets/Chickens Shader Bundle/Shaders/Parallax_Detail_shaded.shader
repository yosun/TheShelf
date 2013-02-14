Shader "Chickenlord/Detail/Parallax Shaded Specular" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_Shininess ("Shininess", Range (0.03, 1)) = 0.078125
	_Parallax ("Height", Range (0.005, 0.08)) = 0.02
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_Detail ("Detail Base (RGB) Gloss (A)", 2D) = "white" {}
	_DetailBump ("Detail Normalmap", 2D) = "bump" {}
	_ParallaxMap ("Heightmap (A)", 2D) = "black" {}
	
	_ShadeRange("Shading Range",Float) = 0.02
	_ShadingStrength("Shading Strength",Range(0,1)) = 1
}
SubShader { 
	Tags { "RenderType"="Opaque" }
	LOD 400
	
CGPROGRAM
#define SHADOW_STEPS 10

#pragma surface surf BlinnPhongShifted
#pragma target 3.0

sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _Detail;
sampler2D _DetailBump;
sampler2D _ParallaxMap;
float _Parallax;
fixed4 _Color;
half _Shininess;
float _ShadingStrength;
float _ShadeRange;

struct Input {
	float2 uv_MainTex;
	float2 uv_BumpMap;
	float2 uv_Detail;
	float3 viewDir;
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



void surf (Input IN, inout SurfaceOutputPS o) {
	o.ShadeMapUV = IN.uv_BumpMap;
	half h = tex2D (_ParallaxMap, IN.uv_BumpMap).w;
	float2 offset = ParallaxOffset (h, _Parallax, IN.viewDir);
	IN.uv_MainTex += offset;
	IN.uv_BumpMap += offset;
	IN.uv_Detail += offset;


	fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
	fixed4 td = tex2D(_Detail,IN.uv_Detail);
	td= min(td*1.8,0.9)+0.1;
	tex *= td;
	o.Albedo = tex.rgb * _Color.rgb;
	o.Gloss = tex.a;
	o.Alpha = tex.a * _Color.a;
	o.Specular = _Shininess;
	o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
	o.Normal = normalize(o.Normal+UnpackNormal(tex2D(_DetailBump, IN.uv_Detail)));
}
ENDCG
}

FallBack "Specular"
}
