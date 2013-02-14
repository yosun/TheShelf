Shader "Chickenlord/Rim Lighting" {
	Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_RimColor("Rim Color",Color) = (1,1,1,1)
	_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_RS("Rim Power",Range(0.2,6)) = 2.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Cull Back
		CGPROGRAM
		#pragma surface surf BlinnPhong nodirlightmap
		#pragma target 2.0
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		sampler2D _BumpMap;
		fixed4 _Color;
		fixed4 _RimColor;
		half _Shininess;
		half _RS;

		
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 viewDir;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Gloss = tex.a;
			o.Alpha = tex.a * _Color.a;
			o.Specular = _Shininess;
			o.Emission = o.Alpha*_Color;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			float vdn = 1- saturate(dot(o.Normal,normalize(IN.viewDir)));
			vdn = pow(vdn,_RS);
			o.Emission = vdn*_RimColor;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
