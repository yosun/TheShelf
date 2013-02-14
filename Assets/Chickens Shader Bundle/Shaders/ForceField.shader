Shader "Chickenlord/FX/Forcefield 2Sided" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
	_Parallax ("Distortion", Range (0.0, 1.0)) = 0.02
	_MainTex ("Base (RGB) Transparency (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_ParallaxMap ("Distortion Map (A)", 2D) = "black" {}
	_Amount("Vertex Scaling",Float) = 0
	_Movement("Movement",Range(0,2)) = 1
}
SubShader { 
	Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
	LOD 600

	Cull Front
CGPROGRAM
#pragma surface surf BlinnPhong alpha vertex:vert

sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _ParallaxMap;
fixed4 _Color;
half _Shininess;
float _Parallax;
float _Amount;
float _Movement;

struct Input {
	float2 uv_MainTex;
	float2 uv_BumpMap;
	float3 viewDir;
};

void vert (inout appdata_full v) 
{
	v.vertex.xyz += v.normal * _Amount;
}

void surf (Input IN, inout SurfaceOutput o) {
	half h = tex2D (_ParallaxMap, IN.uv_BumpMap+_Time[0]*_Movement).w;
	float2 offset = (((h *-IN.viewDir)/IN.viewDir.z).xy+h)*_Parallax;
	IN.uv_MainTex += offset;
	IN.uv_BumpMap += offset;
	
	fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
	o.Albedo = tex.rgb * _Color.rgb;
	o.Gloss = tex.a;
	o.Alpha = tex.a * _Color.a;
	o.Specular = _Shininess;
	o.Emission = o.Alpha*_Color;
	o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
}
ENDCG

Cull Back
CGPROGRAM
#pragma surface surf BlinnPhong alpha vertex:vert

sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _ParallaxMap;
fixed4 _Color;
half _Shininess;
float _Parallax;
float _Amount;
float _Movement;

struct Input {
	float2 uv_MainTex;
	float2 uv_BumpMap;
	float3 viewDir;
};

void vert (inout appdata_full v) 
{
	v.vertex.xyz += v.normal * _Amount;
}

void surf (Input IN, inout SurfaceOutput o) {
	half h = tex2D (_ParallaxMap, IN.uv_BumpMap+_Time[0]*_Movement).w;
	float2 offset = (((h *-IN.viewDir)/IN.viewDir.z).xy+h)*_Parallax;
	IN.uv_MainTex += offset;
	
	fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
	o.Albedo = tex.rgb * _Color.rgb;
	o.Gloss = tex.a;
	o.Alpha = tex.a * _Color.a;
	o.Specular = _Shininess;
	o.Emission = o.Alpha*_Color;
	o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
}
ENDCG
}

FallBack "Bumped Specular"
}
