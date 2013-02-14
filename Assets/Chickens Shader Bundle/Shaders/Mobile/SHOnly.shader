Shader "Chickenlord/Mobile/Mod/Vertex Lit + Indirect Specular" {
	Properties {
		_Color("Main Color",Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_SpecPow("Specular Power",Range(0.03,0.9)) = 0.1
		_SpecInt("Specular Intensity",Float) = 2
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Cull Back			
		CGPROGRAM
		#pragma surface surf LambertXG vertex:vert noambient noforwardadd  nolightmap nodirlightmap

		sampler2D _MainTex;
		fixed _SpecPow;
		half _SpecInt;
		fixed4 _Color;
		
		struct SurfaceOutputPS {
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			half Specular;
			fixed Gloss;
			fixed Alpha;
			fixed3 sha;
		};

		struct Input {
			half2 uv_MainTex;
			half3 shV;
			half3 shVs;
		};
		
		inline fixed4 LightingLambertXG (SurfaceOutputPS s, fixed3 lightDir, fixed atten)
		{
			fixed4 c;
			c.rgb = (s.Albedo)*(s.sha);
			c.a = s.Alpha;
			return c;
		}
		
		void vert (inout appdata_full v, out Input o)
		{
			fixed3 worldN = mul ((float3x3)_Object2World, SCALED_NORMAL);
			fixed3 shv = ShadeSH9 (float4(worldN,1.0));
			o.shV = shv;
			fixed3 viewDir = (WorldSpaceViewDir(v.vertex));
			float3 reflected = normalize(reflect(-viewDir,worldN));
			o.shVs = pow(saturate(dot((reflected),worldN)),_SpecPow*128)*ShadeSH9(float4(reflected,1.0));
			#ifndef VERTEXLIGHT_ON
			o.shV *= (saturate(dot(worldN,_WorldSpaceLightPos0.xyz))*0.5+0.5)*2;
			o.shVs = o.shVs+o.shVs*pow(saturate(dot(normalize(normalize(viewDir)+_WorldSpaceLightPos0.xyz),worldN)),_SpecPow*128);
			#endif
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb*_Color.rgb;
			o.Alpha = c.a*_Color.a;
			o.sha = IN.shVs*c.a*2*_SpecInt+IN.shV;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
