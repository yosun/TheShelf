Shader "Chickenlord/Mobile/Rim Transparent Unlit 2Side" {
	Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_RimColor("Rim Color",Color) = (1,1,1,1)
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_RS("Rim Power",Range(0.2,6)) = 2.5
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 200
		
		Cull Front
		CGPROGRAM
		#pragma surface surf RS vertex:vert nodirlightmap noforwardadd alpha
		#pragma target 2.0
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		fixed4 _Color;
		fixed4 _RimColor;
		half _Shininess;
		half _RS;

		
		struct Input {
			float2 uv_MainTex;
			fixed spec;
			fixed vdn;
		};
		
		void vert (inout appdata_full v, out Input o)
		{
			fixed3 worldN = normalize(mul((float3x3)_Object2World, SCALED_NORMAL));
			fixed3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
			o.vdn = pow(1-saturate(dot(viewDir,-worldN)),_RS);
		}
		
		inline fixed4 LightingRS (SurfaceOutput s, fixed3 lightDir, fixed atten)
		{
			return 0;
		}

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Alpha = tex.a * _Color.a+IN.vdn;
			o.Emission = IN.vdn*_RimColor;
		}
		ENDCG
		
		Cull Back
		CGPROGRAM
		#pragma surface surf RS vertex:vert nodirlightmap noforwardadd alpha
		#pragma target 2.0
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		fixed4 _Color;
		fixed4 _RimColor;
		half _Shininess;
		half _RS;

		
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			fixed spec;
			fixed vdn;
		};
		
		void vert (inout appdata_full v, out Input o)
		{
			fixed3 worldN = normalize(mul((float3x3)_Object2World, SCALED_NORMAL));
			fixed3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
			o.vdn = pow(1- saturate(dot(viewDir,worldN)),_RS);
		}
		
		inline fixed4 LightingRS (SurfaceOutput s, fixed3 lightDir, fixed atten)
		{
			return 0;
		}

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Alpha = tex.a * _Color.a+IN.vdn;
			o.Emission = IN.vdn*_RimColor;
		}
		ENDCG
	
	} 
	FallBack "Diffuse"
}
