Shader "Chickenlord/Reflective/Fresnel/Diffuse" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_ReflectColor ("Reflection Color", Color) = (1,1,1,0.5)
	_Fresnel("Reflection Fresnel Exponent",Range(0,6)) = 1
	_MainTex ("Base (RGB) RefStrength (A)", 2D) = "white" {} 
	_Cube ("Reflection Cubemap", Cube) = "_Skybox" { TexGen CubeReflect }
}
SubShader {
	LOD 200
	Tags { "RenderType"="Opaque" }
	
CGPROGRAM
#pragma surface surf Lambert

sampler2D _MainTex;
samplerCUBE _Cube;

fixed4 _Color;
fixed4 _ReflectColor;
half _Fresnel;

struct Input {
	float2 uv_MainTex;
	float3 worldRefl;
	float3 viewDir;
};

inline float Schlick2(float Rzero,float3 lightDir,float3 normal,float exponent)
{
	return Rzero + (1 - Rzero)*pow((1 - dot(lightDir,normal)),exponent);
}

void surf (Input IN, inout SurfaceOutput o) {
	fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
	fixed4 c = tex * _Color;
	o.Albedo = c.rgb;
	
	fixed4 reflcol = texCUBE (_Cube, IN.worldRefl);
	reflcol *= tex.a;
	reflcol *= Schlick2(0,normalize(IN.viewDir),o.Normal,_Fresnel);
	o.Emission = reflcol.rgb * _ReflectColor.rgb;
	o.Alpha = reflcol.a * _ReflectColor.a;
}
ENDCG
}
	
FallBack "Reflective/VertexLit"
} 
