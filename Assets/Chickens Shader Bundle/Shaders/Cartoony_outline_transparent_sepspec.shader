Shader "Chickenlord/Toony/Transparent/Outline Specularmap" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
		_SpecularMap("Specular Color(RGB) Power (A)",2D) = ""{}
		_OLC ("Outline Color",Color) = (0,0,0,1)
		_OLP ("Outline Strength",Range(5,32)) = 25
		
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhongPS alpha
		#include "UnityCG.cginc"

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _SpecularMap;
		half _Shininess;
		fixed4 _OLC;
		half _OLP;
		
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 vNormal;
			float3 viewDir;
		};
		
		struct SurfaceOutputPS {
			fixed3 Albedo;
			fixed3 Normal;
			fixed Gloss;
			half Specular;	
			fixed Alpha;
			fixed3 Emission;
			fixed3 Spec;
		};
		
		inline fixed4 LightingBlinnPhongPS (SurfaceOutputPS s, fixed3 lightDir, half3 viewDir, fixed atten)
		{
			half3 h = normalize (lightDir + viewDir);
			
			fixed diff = max (0, dot (s.Normal, lightDir));
			
			float nh = max (0, dot (s.Normal, h));
			float spec = pow (nh, s.Specular*128.0) * s.Gloss;
			
			fixed4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb * s.Spec.rgb * spec) * (atten * 2);
			c.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec * atten;
			return c;
		}

		inline fixed4 LightingBlinnPhongPS_PrePass (SurfaceOutputPS s, half4 light)
		{
			fixed spec = light.a * s.Gloss;
			
			fixed4 c;
			c.rgb = (s.Albedo * light.rgb + light.rgb * _SpecColor.rgb * s.Spec.rgb * spec);
			c.a = s.Alpha + spec * _SpecColor.a;
			return c;
		}
		
		void surf (Input IN, inout SurfaceOutputPS o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			fixed4 spec = tex2D(_SpecularMap, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = 	spec.a;
			o.Alpha = c.a * _Color.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.Spec = spec.rgb;
			fixed mult = 1-clamp(dot(o.Normal,normalize(IN.viewDir)),0,1);
			mult = pow(mult,_OLP);
			mult = min(100*mult,1);
			o.Albedo = (1-mult)*o.Albedo+(mult)*_OLC.rgb;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
