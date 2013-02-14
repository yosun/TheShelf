Shader "Chickenlord/Skin/S5 Skinshader Deferred"{
	Properties {
	_Color ("Layer 1 Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color L3", Color) = (0.5, 0.5, 0.5, 1)	
	_Shininess ("Shininess L1", Range (0.01, 1)) = 0.078125
	_MainTex ("Layer1 Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap L1", 2D) = "bump" {}
	
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Scattering"="true"}
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhongS5 nolightmap addshadow noambient
		
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		float _Shininess;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
		};
		
		inline fixed4 LightingBlinnPhongS5 (SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten)
		{
			float diff =max(0,dot(lightDir,s.Normal));
			return half4(diff,diff,diff,diff);
		}
		inline fixed4 LightingBlinnPhongS5_PrePass (SurfaceOutput s, half4 light)
		{
			fixed spec = light.a * s.Gloss;
			
			fixed4 c;
			c.rgb = (s.Albedo.rgb*light.rgb);
			c.a = (spec * _SpecColor.a)/2;
			return c;
		}

		void surf (Input IN, inout SurfaceOutput o) {
		
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = half3(1,1,1);
			o.Gloss = 	c.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.Alpha = c.a;
		}
		ENDCG
	} 
	FallBack "Chickenlord/FastSkin"
}
