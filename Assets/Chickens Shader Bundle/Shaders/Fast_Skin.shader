Shader "Chickenlord/Skin/Fast SM2 Skinshader" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
		_ExitColorMap("Exit Color Map (RGB) Scattering (A)",2D) = "ecm" {}
		_SSSC ("SSSC",Color) = (1,1,1,1)
		_Layer1Thickness ("Layer 1 Thickness",Range(0,1)) = 0.1
		_Layer2Thickness ("Layer 2 Thickness",Range(0,1)) = 0.1

	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf LS
		#include "UnityCG.cginc"

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		fixed4 _SSSC;
		sampler2D _ExitColorMap;
		float _Layer1Thickness;
		float _Layer2Thickness;

		
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
		};
		
		struct SurfaceOutputPS {
			fixed3 Albedo;
			fixed3 Normal;
			fixed Gloss;
			half Specular;	
			fixed Alpha;
			fixed3 Emission;
			float2 ShadeMapUV;
		};
		
		inline void fastskin(float3 normal, float3 lightDir, float3 DiffColor, float3 subcol, float thickness, out float3 diffuse, out float3 Subsurface) 
		{
			float diff = dot(lightDir,normal);
			float diffComp = max(0,diff);
			diffuse = diffComp * DiffColor;
			float subLamb = smoothstep(-thickness,1.0,diff) - smoothstep(0.0,1.0,diff);
			subLamb = max(0.0,subLamb);
			Subsurface = subLamb * subcol;
		}
		
		inline fixed4 LightingLS (SurfaceOutputPS s, fixed3 lightDir, half3 viewDir, fixed atten)
		{
			fixed4 c;
			float3 diffuse;
			float3 subsurface;
			half4 outCol = tex2D(_ExitColorMap,s.ShadeMapUV);
			fastskin(s.Normal,normalize(lightDir),s.Albedo,outCol.rgb*_SSSC,_Layer1Thickness+_Layer2Thickness,diffuse,subsurface);
			float3 lightColor = (diffuse+subsurface*outCol.a)*_LightColor0.rgb;
			c.rgb = ((lightColor).rgb) * (atten * 2);
			c.a = s.Alpha + _LightColor0.a * atten;
			return c;
		}
		
		void surf (Input IN, inout SurfaceOutputPS o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color.rgb;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.ShadeMapUV = IN.uv_MainTex;
		}
		ENDCG
	} 
	FallBack "VertexLit"
}
