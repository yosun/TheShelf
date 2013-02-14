Shader "Chickenlord/Mobile/Free/Rim Lighting" {
	Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_RimColor("Rim Color",Color) = (1,1,1,1)
	_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_RS("Rim Power",Range(0.2,6)) = 2.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Cull Back
		CGPROGRAM
		#pragma surface surf RS vertex:vert nodirlightmap noforwardadd noambient
		#pragma target 2.0
		#include "UnityCG.cginc"
		#include "GSH9.cginc"
		sampler2D _MainTex;
		sampler2D _BumpMap;
		fixed4 _Color;
		fixed4 _RimColor;
		half _Shininess;
		half _RS;

		
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			fixed spec;
			fixed vdn;
			fixed3 SH9;
		};
		
		void vert (inout appdata_full v, out Input o)
		{
			fixed3 worldN = normalize(mul((float3x3)_Object2World, SCALED_NORMAL));
			fixed3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
			o.vdn = pow(1- saturate(dot(viewDir,worldN)),_RS);
			o.SH9 = CSBShadeSH9(float4(worldN,1))+UNITY_LIGHTMODEL_AMBIENT.rgb;
			#ifndef VERTEXLIGHT_ON
			o.spec = pow(saturate(dot(normalize(viewDir+_WorldSpaceLightPos0.xyz),worldN)),_Shininess*128);
			#endif
		}
		
		inline fixed4 LightingRS (SurfaceOutput s, fixed3 lightDir, fixed atten)
		{
			fixed diff = max (0, dot (s.Normal, lightDir));
			
			fixed4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb * diff)+s.Specular;
			c.a = s.Alpha;
			return c;
		}

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Alpha = tex.a * _Color.a;
			o.Specular = IN.spec*tex.a;
			o.Emission = o.Alpha*_Color;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			o.Emission = IN.vdn*_RimColor + o.Albedo*IN.SH9;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
