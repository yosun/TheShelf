Shader "Chickenlord/3.5/Reflective/Fresnel/Bumped Diffuse" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_ReflectColor ("Reflection Color", Color) = (1,1,1,0.5)
	_Fresnel("Reflection Fresnel Exponent",Range(0,6)) = 1
	_MainTex ("Base (RGB) RefStrength (A)", 2D) = "white" {}
	_Cube ("Reflection Cubemap", Cube) = "_Skybox" { TexGen CubeReflect }
	_BumpMap ("Normalmap", 2D) = "bump" {}
}

SubShader {
	Tags { "RenderType"="Opaque" }
	LOD 300
	
CGPROGRAM
#pragma surface surf Lambert fullforwardshadows addshadow novertexlights
#pragma target 3.0

sampler2D _MainTex;
sampler2D _BumpMap;
samplerCUBE _Cube;

fixed4 _Color;
fixed4 _ReflectColor;
half _Fresnel;

struct Input {
	float2 uv_MainTex;
	float2 uv_BumpMap;
	float3 worldRefl;
	float3 viewDir;
	float3 worldNormal;
	INTERNAL_DATA
};

inline float Schlick2(float Rzero,float3 lightDir,float3 normal,float exponent)
{
	return Rzero + (1 - Rzero)*pow((1 - dot(lightDir,normal)),exponent);
}

void surf (Input IN, inout SurfaceOutput o) {
	fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
	fixed4 c = tex * _Color;
	o.Albedo = c.rgb;
	
	o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
	
	float3 worldRefl = WorldReflectionVector (IN, o.Normal);
	fixed4 reflcol = texCUBE (_Cube, worldRefl);
	reflcol *= tex.a;
	reflcol *= Schlick2(0,normalize(IN.viewDir),o.Normal,_Fresnel);
	o.Emission = reflcol.rgb * _ReflectColor.rgb;
	o.Alpha = reflcol.a * _ReflectColor.a;
	float3 worldNormal = WorldNormalVector(IN,o.Normal);
	o.Emission += o.Albedo*ShadeSH9(float4(worldNormal,1));
}
ENDCG
}

FallBack "Reflective/VertexLit"
}
