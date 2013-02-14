Shader "Chickenlord/Mobile/Translucency"{
	Properties {
	_Color ("Layer 1 Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color L3", Color) = (0.5, 0.5, 0.5, 1)	
	_Shininess ("Shininess L1", Range (0.01, 1)) = 0.078125
	_MainTex ("Layer1 Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap L1", 2D) = "bump" {}
	
	_SSSC ("SSSC",Color) = (1,1,1,1)
	_TMAP("Translucency Map Color(RGB) Strength(A)",2D) = ""{}
	_TMUL("Translucency Multiplier",Float) = 1
	_Dist("Translucency Distortion",Range(0,1)) = 1
	
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhongTranslucent vertex:vert halfasview nolightmap noforwardadd
		#pragma target 2.0
		#pragma exclude_renderers flash
		
		sampler2D _TMAP;
	
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		half _Shininess;
		fixed4 _SSSC;
		half _TMUL;
		half _Dist;
		half _TPOW;
		
		struct Input {
			half2 uv_MainTex;
			half2 uv_BumpMap;
			half3 transVal;
			half spec;
		};
		
		struct SurfaceOutputPS {
			fixed3 Albedo;
			fixed3 Normal;
			fixed Gloss;
			half Specular;	
			fixed Alpha;
			fixed3 Emission;
			float2 ShadeMapUV;
			half3 trans;
		};
		
		inline void vert (inout appdata_full v, out Input o)
		{
			fixed3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
			half3 worldN =  mul((float3x3)_Object2World, SCALED_NORMAL).xyz;
			
			half3 trans = saturate(ShadeSH9(float4(-viewDir,0)));
			o.transVal = _SSSC.rgb*trans*_TMUL;
			o.spec = pow(saturate(dot(normalize(normalize(viewDir)+_WorldSpaceLightPos0.xyz),worldN)),_Shininess*128);
		}
		
		inline fixed4 LightingBlinnPhongTranslucent (SurfaceOutputPS s, fixed3 lightDir, fixed atten)
		{
			fixed sub = tex2D(_TMAP,s.ShadeMapUV).g;
			fixed diff = max (0, dot (s.Normal, lightDir));
			
			fixed4 c;
			c.rgb = ((s.Albedo) * (diff+s.trans*sub) + _SpecColor.rgb * s.Specular) * (2);
			c.a = s.Alpha;
			return c;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.ShadeMapUV = IN.uv_MainTex;
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = 	c.a;
			o.Specular = IN.spec*c.a;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.Alpha = c.a;
			o.trans = IN.transVal;
		}
		ENDCG
	} 
	FallBack "Chickenlord/FastSkin"
}
