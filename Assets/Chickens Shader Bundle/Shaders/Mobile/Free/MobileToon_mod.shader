Shader "Chickenlord/Mobile/Free/Mod/Toon" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
		_Ramp ("Ramp",2D) = "" {}
		_SkySpec("Specular",Range(0.03,0.9)) = 0.1
		_GM ("Intensity Adjsutment",Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Cull Back			
		CGPROGRAM
		#pragma surface surf LambertXG vertex:vert noambient novertexlights noforwardadd approxview
		#include "GSH9.cginc"

		sampler2D _MainTex;
		sampler2D _Ramp;
		sampler2D _BumpMap;
		fixed _Fresnel;
		fixed _Fresnel2;
		fixed _SkySpec;
		half _GM;
		
		struct SurfaceOutputPS {
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			half Specular;
			fixed Gloss;
			fixed Alpha;
			fixed3 sha;
			fixed2 skySpec;
			fixed vdl;
		};

		struct Input {
			half2 uv_MainTex;
			half2 uv_BumpMap;
			half4 shV;
			half2 fresnelFacs;
			half vdl;
		};
		
		inline fixed4 LightingLambertXG (SurfaceOutputPS s, fixed3 lightDir, fixed atten)
		{
			fixed diff =dot (s.Normal, lightDir);
			
			fixed4 rc = tex2D(_Ramp,float2(((diff*0.5+0.5))+s.skySpec.g*0.5,s.vdl));
			rc.rgb *= s.sha.rgb*rc.a;
			fixed4 c;
			c.rgb = (s.Albedo+s.skySpec.r)*(rc)*2*_GM;
			c.a = s.Alpha;
			return c;
		}
		
		void vert (inout appdata_full v, out Input o)
		{
			fixed3 worldN = mul ((float3x3)_Object2World, SCALED_NORMAL);
			fixed3 shv = CSBShadeSH9(float4(worldN,1))+UNITY_LIGHTMODEL_AMBIENT.rgb;
			half mid = shv.r+shv.g+shv.b;
			shv/=mid;
			shv.b = max(0,1-shv.r-shv.g);
			o.shV = fixed4(shv,mid*0.3333333f);
			fixed3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
			o.vdl = saturate(dot(viewDir,worldN));
			o.fresnelFacs.y = pow(saturate(dot(normalize(viewDir+_WorldSpaceLightPos0),worldN)),_SkySpec*128);
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.skySpec.r = IN.fresnelFacs.y*c.a;
			o.sha = IN.shV;
			o.skySpec.g = IN.shV.a;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.vdl = IN.vdl;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
