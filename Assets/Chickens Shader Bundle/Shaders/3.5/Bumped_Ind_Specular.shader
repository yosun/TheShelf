Shader "Chickenlord/3.5/Bumped Specular + Indirect Specular" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_Shininess ("Shininess", Range (0.03, 1)) = 0.078125
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
}
SubShader { 
	Tags { "RenderType"="Opaque" }
	LOD 400
	
CGPROGRAM
#pragma surface surf BlinnPhong novertexlights
#pragma target 3.0

sampler2D _MainTex;
sampler2D _BumpMap;
fixed4 _Color;
half _Shininess;

struct Input {
	float2 uv_MainTex;
	float2 uv_BumpMap;
	float3 viewDir;
	float3 worldNormal;
	float3 worldRefl;
	INTERNAL_DATA
};

void surf (Input IN, inout SurfaceOutput o) {
	fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
	o.Albedo = tex.rgb * _Color.rgb;
	o.Gloss = tex.a;
	o.Alpha = tex.a * _Color.a;
	o.Specular = _Shininess;
	o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
	float3 wr = WorldReflectionVector(IN,o.Normal);
	wr = normalize(wr);
	float3 ld = (mul((float3x3)_World2Object,(wr)))*-1;
	float3 vd = normalize(IN.viewDir);
	half3 h = normalize(vd+ld);
	float nh = saturate(dot(o.Normal,h));
	
	o.Emission = ShadeSH9(float4(WorldNormalVector(IN,o.Normal),1))*o.Albedo;
	o.Emission += pow(nh,_Shininess*128)*ShadeSH9(float4((wr),1))*tex.a*_SpecColor.rgb*2*(dot(o.Normal,(vd)));
}
ENDCG
}

FallBack "Specular"
}
