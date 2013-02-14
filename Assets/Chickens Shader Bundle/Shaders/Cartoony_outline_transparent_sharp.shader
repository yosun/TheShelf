Shader "Chickenlord/Toony/Transparent/Outline Sharp" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
		_OLC ("Outline Color",Color) = (0,0,0,1)
		_OLP ("Outline Strength",Range(5,32)) = 25
		_Sharpness("Outline Sharpness",Range(1,15)) = 1
		
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhong alpha
		#include "UnityCG.cginc"

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		half _Shininess;
		fixed4 _OLC;
		half _OLP;
		half _Sharpness;
		
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 vNormal;
			float3 viewDir;
		};
		
		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = 	c.a;
			o.Alpha = c.a * _Color.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			fixed mult = 1-clamp(dot(o.Normal,normalize(IN.viewDir)),0,1);
			mult = pow(mult,_OLP);
			mult = min(100*mult,1);
			mult = pow(mult,_Sharpness);
			o.Albedo = (1-mult)*o.Albedo+(mult)*_OLC.rgb;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
