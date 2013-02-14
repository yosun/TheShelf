Shader "Chickenlord/Mobile/Free/Mod/Toon Lightmap" {
	Properties {
		_Color("Main Color",Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
		_Ramp ("Ramp",2D) = "" {}
		_SkySpec("SkySpec",Range(0.03,0.9)) = 0.1
		_Shift("Lightmap Intensity Adjustment (0 to 1)",Float) = 0.5
		_GM ("Intensity Adjsutment",Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Cull Back			
			

	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }

CGPROGRAM
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma fragmentoption ARB_precision_hint_fastest
#pragma multi_compile_fwdbase nodirlightmap novertexlight
#include "HLSLSupport.cginc"
#define UNITY_PASS_FORWARDBASE
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "GSH9.cginc"

#define INTERNAL_DATA
#define WorldReflectionVector(data,normal) data.worldRefl
#define WorldNormalVector(data,normal) normal
#line 1
#line 14

		//#pragma surface surf LambertXG vertex:vert noambient novertexlights noforwardadd approxview
		#pragma debug

		sampler2D _MainTex;
		sampler2D _Ramp;
		fixed4 _Color;
		fixed _Fresnel;
		fixed _Fresnel2;
		fixed _SkySpec;
		fixed _Shift;
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
		};
		
		inline fixed4 LightingLambertXG (SurfaceOutputPS s, fixed3 lightDir, fixed atten)
		{
			return float4(s.Albedo,s.Alpha);
		}
		
		void vert (inout appdata_full v, out Input o)
		{
			fixed3 worldN = mul ((float3x3)_Object2World, SCALED_NORMAL);
			fixed3 shv = CSBShadeSH9(float4(worldN,1));
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb*_Color.rgb;
			o.Alpha = c.a*_Color.a;
		}
		#ifdef LIGHTMAP_OFF
struct v2f_surf {
  float4 pos : SV_POSITION;
  half4 pack0 : TEXCOORD0;
  fixed3 lightDir : TEXCOORD1;
  fixed3 vlight : TEXCOORD2;
  LIGHTING_COORDS(3,4)
};
#endif
#ifndef LIGHTMAP_OFF
struct v2f_surf {
  float4 pos : SV_POSITION;
  half4 pack0 : TEXCOORD0;
  float2 lmap : TEXCOORD1;
  LIGHTING_COORDS(2,3)
};
#endif
#ifndef LIGHTMAP_OFF
float4 unity_LightmapST;
float4 unity_ShadowFadeCenterAndType;
#endif
float4 _MainTex_ST;
v2f_surf vert_surf (appdata_full v) {
  v2f_surf o;
  Input customInputData;
  vert (v, customInputData);
  o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  #ifndef LIGHTMAP_OFF
  o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
  #endif
  float3 worldN = mul((float3x3)_Object2World, SCALED_NORMAL);
  TANGENT_SPACE_ROTATION;
  float3 lightDir = mul (rotation, ObjSpaceLightDir(v.vertex));
  #ifdef LIGHTMAP_OFF
  o.lightDir = lightDir;
  #endif
  #ifdef LIGHTMAP_OFF
  o.vlight = 0.0;
  #endif // LIGHTMAP_OFF
  TRANSFER_VERTEX_TO_FRAGMENT(o);
  return o;
}
#ifndef LIGHTMAP_OFF
sampler2D unity_Lightmap;
#ifndef DIRLIGHTMAP_OFF
sampler2D unity_LightmapInd;
#endif
#endif
fixed4 frag_surf (v2f_surf IN) : COLOR {
  Input surfIN;
  surfIN.uv_MainTex = IN.pack0.xy;
  SurfaceOutputPS o;
  o.Albedo = 0.0;
  o.Emission = 0.0;
  o.Specular = 0.0;
  o.Alpha = 0.0;
  surf (surfIN, o);
  fixed atten = LIGHT_ATTENUATION(IN);
  fixed4 c = 0;
  #ifdef LIGHTMAP_OFF
  c = LightingLambertXG (o, IN.lightDir, atten);
  #endif // LIGHTMAP_OFF
  #ifdef LIGHTMAP_OFF
  #endif // LIGHTMAP_OFF
  #ifndef LIGHTMAP_OFF
  #ifdef DIRLIGHTMAP_OFF
  fixed4 lmtex = tex2D(unity_Lightmap, IN.lmap.xy);
  half3 lm = DecodeLightmap (lmtex)+0.01;
  fixed lum = (0.5*lm.r+lm.g+0.5*lm.b)*0.5;
  lm /= lum;
  fixed3 rc = tex2D(_Ramp,half2(((lum*_Shift+(1-_Shift))),1));
  lm = ((lm*rc.rgb)-0.01)*_GM;
  #else
  // no directional lightmapping
  #endif
  #ifdef SHADOWS_SCREEN
  #if defined(SHADER_API_GLES) && defined(SHADER_API_MOBILE)
  c.rgb += o.Albedo * lm;
  #else
  c.rgb += o.Albedo * lm;
  #endif
  #else // SHADOWS_SCREEN
  c.rgb += o.Albedo * lm;
  #endif // SHADOWS_SCREEN
  c.a = o.Alpha;
#endif // LIGHTMAP_OFF
  return c;
}

ENDCG
}
}
}