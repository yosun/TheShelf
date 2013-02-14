Shader "Chickenlord/Transparent Rim Lighting 1Side Unlit" {
	Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_RS("Pre Power",Range(1,10)) = 2.5
	_RM("Post Multiplier",Range(0,5)) = 2
	_RPS("Post Power",Range(1,5)) = 2
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 200
		
		Cull Back
		CGPROGRAM
		#pragma surface surf BlinnPhongPS alpha
		#pragma target 3.0
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		sampler2D _BumpMap;
		fixed4 _Color;
		half _Shininess;
		half _RS;
		half _RM;
		half _RPS;

		
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 viewDir;
		};
		
		inline fixed4 LightingBlinnPhongPS (SurfaceOutput s, fixed3 lightDir, fixed atten)
		{
			return 0;
		}
		
		inline fixed4 LightingBlinnPhongPS_PrePass (SurfaceOutput s, half4 light)
		{
			return 0;
		}

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Gloss = tex.a;
			o.Alpha = _Color.a;
			o.Specular = _Shininess;
			o.Emission = o.Alpha*_Color;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			float vdn = dot(o.Normal,normalize(IN.viewDir));
			fixed mult = min(1-clamp(vdn,0,1),1);
			mult = pow(mult,_RS);
			mult = min(_RM*mult,1);
			mult = pow(mult,_RPS);
			
			o.Alpha *= mult;
			float GlossVal = max(0,pow(clamp(vdn,0,1),o.Specular*128)*o.Gloss);
			o.Alpha+=GlossVal-Luminance(UNITY_LIGHTMODEL_AMBIENT);
			o.Albedo+=_SpecColor*GlossVal;
			o.Albedo*=o.Alpha;
			o.Emission += o.Albedo;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
