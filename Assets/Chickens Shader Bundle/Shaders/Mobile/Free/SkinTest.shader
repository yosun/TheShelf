Shader "Chickenlord/Mobile/Free/Mod/Skin" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap("Bump Map",2D) = "bump" {}
		_CurveM("Curve Map",2D) = "" {}
		_BlendMap("Blend Map",2D) = "" {}
		_Shininess ("Shininess L1", Range (0.01, 1)) = 0.078125
		_SpecColor("SpecColor",Color) = (1,1,1,1)
		_GM ("Intensity Adjsutment",Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf ST noforwardadd vertex:vert nolightmap nodirlightmap noambient
		#pragma target 2.0
		#include "GSH9.cginc"

		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _CurveM;
		sampler2D _BlendMap;
		fixed _Shininess;
		fixed _GM;
				
		struct Input {
			half2 uv_MainTex;
			half2 uv_BumpMap;
			fixed3 sh;
			half2 skySpec;
		};
		
		struct SurfaceOutputPS {
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			fixed Specular;
			fixed Gloss;
			fixed Alpha;
			fixed bv;
			fixed3 sh;
			fixed3 SkySpec;
			fixed difx;
		};
		
		void vert (inout appdata_full v, out Input o)
		{
			fixed3 worldN = mul ((float3x3)_Object2World, SCALED_NORMAL);
			o.sh = CSBShadeSH9(float4(worldN,1))*_GM+UNITY_LIGHTMODEL_AMBIENT.rgb;
			fixed3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
			o.skySpec.x = (pow(saturate(dot(normalize(viewDir+WorldSpaceLightDir(v.vertex)),worldN)),_Shininess*128))*_GM;
			o.skySpec.y = (dot(_WorldSpaceLightPos0,worldN)*0.5f+0.5f);
		}
		
		inline fixed4 LightingST (SurfaceOutputPS s, fixed3 lightDir, fixed atten)
		{
			
			fixed diff = (dot (s.Normal, lightDir)*0.5+0.5);
			fixed difx = s.difx;
			fixed dif = (1-(difx-diff))*s.bv;
			
			fixed3 colv = tex2D(_CurveM,half2(diff,dif)).rgb;
			
			
			fixed4 c;
			c.rgb = s.sh*(s.Albedo*colv) + s.SkySpec;
			c.a = s.Alpha;
			return c;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.bv = 1-tex2D(_BlendMap,IN.uv_MainTex).a;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.sh = IN.sh;
			o.SkySpec = IN.skySpec.x*_SpecColor*c.a;
			o.difx = IN.skySpec.y;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
