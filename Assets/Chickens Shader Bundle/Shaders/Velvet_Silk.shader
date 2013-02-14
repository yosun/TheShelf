Shader "Chickenlord/Velvet-Silk" {
	Properties {
		_Color("Main Color",Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap("Bump Map",2D) = "bump" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf ST
		#pragma target 2.0

		sampler2D _MainTex;
		sampler2D _BumpMap;
		fixed4 _Color;
				
		struct Input {
			half2 uv_MainTex;
			half2 uv_BumpMap;
		};
		
		struct SurfaceOutputPS {
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			fixed Specular;
			fixed Gloss;
			fixed Alpha;
		};
		
		inline float VelvetDistribution(float x)
		{
			float z = x*x;
			float y = (1-z);
			return y*y*z;
		}
		
		inline fixed4 LightingST (SurfaceOutputPS s, float3 lightDir, half3 viewDir, fixed atten)
		{
			fixed diff = max (0, dot (s.Normal, lightDir));
			
			diff = (saturate(VelvetDistribution(clamp(dot (s.Normal, viewDir),-1,1)))*2+0.25)*diff*2;
			
			fixed4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb*diff) * (atten * 2);
			c.a = s.Alpha;
			return c;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb*_Color.rgb;
			o.Alpha = c.a;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
