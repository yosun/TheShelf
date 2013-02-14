Shader "Hidden/Chickenlord/Skin/S5 Skinshader pass 2"{
	Properties {
	_Color ("Layer 1 Color", Color) = (1,1,1,1)
	_MainTex ("Layer1 Base (RGB) Gloss (A)", 2D) = "white" {}
	
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Scattering"="true"}
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhongSSSLayer3 nolightmap noambient novertexlights noforwardadd
		#pragma target 2.0
		
		fixed4 _Color;
		sampler2D _MainTex;
		
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
		
		inline fixed4 LightingBlinnPhongSSSLayer3 (SurfaceOutputPS s, fixed3 lightDir, fixed3 viewDir, fixed atten)
		{
			half4 c = half4(s.Albedo,s.Alpha);
			return c;
		}
		
		inline fixed4 LightingBlinnPhongSSSLayer3_PrePass (SurfaceOutputPS s, half4 light)
		{
			half4 c = half4(s.Albedo,s.Alpha);
			return c;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex)*_Color;
			o.Alpha = c.a;
			o.Albedo = c;
		}
		ENDCG
	} 
	FallBack "Chickenlord/FastSkin"
}
