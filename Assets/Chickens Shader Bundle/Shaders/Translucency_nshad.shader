Shader "Chickenlord/Translucency NonShadowed"{
	Properties {
	_Color ("Layer 1 Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color L3", Color) = (0.5, 0.5, 0.5, 1)	
	_Shininess ("Shininess L1", Range (0.01, 1)) = 0.078125
	_MainTex ("Layer1 Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap L1", 2D) = "bump" {}
	
	_SSSC ("SSSC",Color) = (1,1,1,1)
	_TMAP("Translucency Map Color(RGB) Strength(A)",2D) = ""{}
	_TPOW("Translucency Power",Float) = 1
	_TMUL("Translucency Multiplier",Float) = 1
	_Dist("Translucency Distortion",Range(0,1)) = 1
	_AO("Ambient Occlusion Map",2D) = "" {}
	_AOST("Ambient Occlusion Strength",Range(0,1)) = 1
	_PP("Translucency Spread",Range(0.01,1)) = 1
	
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
			
/* surface debug info:
 stuff performed in tangent space
*/
/* surface debug info:
 stuff performed in tangent space
*/
	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }

CGPROGRAM
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma fragmentoption ARB_precision_hint_fastest
#pragma multi_compile_fwdbase nolightmap nodirlightmap
#include "HLSLSupport.cginc"
#define UNITY_PASS_FORWARDBASE
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#define INTERNAL_DATA
#define WorldReflectionVector(data,normal) data.worldRefl
#define WorldNormalVector(data,normal) normal
#line 1
#line 24

		//#pragma surface surf BlinnPhongTranslucent nolightmap fullforwardshadows addshadow
		#pragma target 3.0
		#pragma debug
		
		sampler2D _TMAP;
		sampler2D _AO;
		half _AOST;
	
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		float _Shininess;
		fixed4 _SSSC;
		half _TMUL;
		half _Dist;
		half _TPOW;
		half _PP;
		
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
		
		inline fixed4 LightingBlinnPhongTranslucent (SurfaceOutputPS s, fixed3 lightDir, fixed3 viewDir, fixed latten,float satten)
		{
			fixed4 sub = tex2D(_TMAP,s.ShadeMapUV);
			half3 h = normalize (lightDir + viewDir);
			fixed diff = max (0, dot (s.Normal, lightDir));
			
			float nh = max (0, dot (s.Normal, h));
			float spec = pow (nh, s.Specular*128.0) * s.Gloss;
			float3 ambient = saturate(pow(sub.a*_TMUL*_SSSC.rgb*sub.rgb,_TPOW));
			sub.rgb *= _SSSC.rgb * _LightColor0.rgb * pow(pow(clamp(dot(normalize(normalize(viewDir)+normalize(s.Normal)*_Dist), -(normalize(lightDir))),0,1),_TPOW),_PP)*_TMUL*sub.a;
			
			fixed4 c;
			c.rgb = ((s.Albedo) * (_LightColor0.rgb * diff*satten+sub.rgb)+clamp(1-_LightColor0.a*diff,0,1)*ambient + _LightColor0.rgb * _SpecColor.rgb * spec*satten) * (latten * 2);
			c.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec * satten*latten;
			
			fixed ao = tex2D(_AO,s.ShadeMapUV).g;
			c.rgb = (1-_AOST)*c.rgb+_AOST*c.rgb*ao;
			return c;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.ShadeMapUV = IN.uv_MainTex;
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = 	c.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.Alpha = c.a;
		}
		#ifdef LIGHTMAP_OFF
struct v2f_surf {
  float4 pos : SV_POSITION;
  float4 pack0 : TEXCOORD0;
  fixed3 lightDir : TEXCOORD1;
  fixed3 vlight : TEXCOORD2;
  float3 viewDir : TEXCOORD3;
  LIGHTING_COORDS(4,5)
};
#endif
#ifndef LIGHTMAP_OFF
struct v2f_surf {
  float4 pos : SV_POSITION;
  float4 pack0 : TEXCOORD0;
  float2 lmap : TEXCOORD1;
  LIGHTING_COORDS(2,3)
};
#endif
#ifndef LIGHTMAP_OFF
float4 unity_LightmapST;
float4 unity_ShadowFadeCenterAndType;
#endif
float4 _MainTex_ST;
float4 _BumpMap_ST;
v2f_surf vert_surf (appdata_full v) {
  v2f_surf o;
  o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  o.pack0.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
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
  float3 viewDirForLight = mul (rotation, ObjSpaceViewDir(v.vertex));
  o.viewDir = viewDirForLight;
  #endif
  #ifdef LIGHTMAP_OFF
  float3 shlight = ShadeSH9 (float4(worldN,1.0));
  o.vlight = shlight;
  #ifdef VERTEXLIGHT_ON
  float3 worldPos = mul(_Object2World, v.vertex).xyz;
  o.vlight += Shade4PointLights (
    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
    unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
    unity_4LightAtten0, worldPos, worldN );
  #endif // VERTEXLIGHT_ON
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
  surfIN.uv_BumpMap = IN.pack0.zw;
  SurfaceOutputPS o;
  o.Albedo = 0.0;
  o.Emission = 0.0;
  o.Specular = 0.0;
  o.Alpha = 0.0;
  surf (surfIN, o);
  fixed atten = LIGHT_ATTENUATION(IN);
  float latten = 1;
  float satten = 1;

  #ifdef POINT
	latten = (tex2D(_LightTexture0, dot(IN._LightCoord,IN._LightCoord).rr).UNITY_ATTEN_CHANNEL);
	satten = SHADOW_ATTENUATION(IN);
	#endif

	#ifdef SPOT
	latten = ( (IN._LightCoord.z > 0) * UnitySpotCookie(IN._LightCoord) * UnitySpotAttenuate(IN._LightCoord.xyz));
	satten = SHADOW_ATTENUATION(IN);
	#endif

	#ifdef DIRECTIONAL
	satten = SHADOW_ATTENUATION(IN);
	#endif
  fixed4 c = 0;
  #ifdef LIGHTMAP_OFF
  c = LightingBlinnPhongTranslucent (o, IN.lightDir, normalize(half3(IN.viewDir)), latten,satten);
  #endif // LIGHTMAP_OFF
  #ifdef LIGHTMAP_OFF
  c.rgb += o.Albedo * IN.vlight;
  #endif // LIGHTMAP_OFF
  #ifndef LIGHTMAP_OFF
  #ifdef DIRLIGHTMAP_OFF
  fixed4 lmtex = tex2D(unity_Lightmap, IN.lmap.xy);
  fixed3 lm = DecodeLightmap (lmtex);
  #else
  fixed4 lmtex = tex2D(unity_Lightmap, IN.lmap.xy);
  fixed4 lmIndTex = tex2D(unity_LightmapInd, IN.lmap.xy);
  half3 lm = LightingBlinnPhongTranslucent_DirLightmap(o, lmtex, lmIndTex, 1).rgb;
  #endif
  #ifdef SHADOWS_SCREEN
  #if defined(SHADER_API_GLES) && defined(SHADER_API_MOBILE)
  c.rgb += o.Albedo * min(lm, atten*2);
  #else
  c.rgb += o.Albedo * max(min(lm,(atten*2)*lmtex.rgb), lm*atten);
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
	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardAdd" }
		ZWrite Off Blend One One Fog { Color (0,0,0,0) }

CGPROGRAM
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma fragmentoption ARB_precision_hint_fastest
#pragma multi_compile_fwdadd_fullshadows nolightmap nodirlightmap
#include "HLSLSupport.cginc"
#define UNITY_PASS_FORWARDADD
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#define INTERNAL_DATA
#define WorldReflectionVector(data,normal) data.worldRefl
#define WorldNormalVector(data,normal) normal
#line 1
#line 24

		//#pragma surface surf BlinnPhongTranslucent nolightmap fullforwardshadows addshadow
		#pragma target 3.0
		#pragma debug
		
		sampler2D _TMAP;
		sampler2D _AO;
		half _AOST;
	
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		float _Shininess;
		fixed4 _SSSC;
		half _TMUL;
		half _Dist;
		half _TPOW;
		half _PP;
		
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
		
		inline fixed4 LightingBlinnPhongTranslucent (SurfaceOutputPS s, fixed3 lightDir, fixed3 viewDir, fixed latten, fixed satten)
		{
			fixed4 sub = tex2D(_TMAP,s.ShadeMapUV);
			half3 h = normalize (lightDir + viewDir);
			fixed diff = max (0, dot (s.Normal, lightDir));
			
			float nh = max (0, dot (s.Normal, h));
			float spec = pow (nh, s.Specular*128.0) * s.Gloss;
			float3 ambient = saturate(pow(sub.a*_TMUL*_SSSC.rgb*sub.rgb,_TPOW));
			sub.rgb *= _SSSC.rgb * _LightColor0.rgb * pow(pow(clamp(dot(normalize(normalize(viewDir)+normalize(s.Normal)*_Dist), -(normalize(lightDir))),0,1),_TPOW),_PP)*_TMUL*sub.a;
			
			fixed4 c;
			c.rgb = ((s.Albedo) * (_LightColor0.rgb * diff*satten+sub.rgb)+clamp(1-_LightColor0.a*diff,0,1)*ambient + _LightColor0.rgb * _SpecColor.rgb * spec*satten) * (latten * 2);
			c.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec * satten.r*latten.r;
			
			fixed ao = tex2D(_AO,s.ShadeMapUV).g;
			c.rgb = (1-_AOST)*c.rgb+_AOST*c.rgb*ao;
			return c;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.ShadeMapUV = IN.uv_MainTex;
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = 	c.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.Alpha = c.a;
		}
		struct v2f_surf {
  float4 pos : SV_POSITION;
  float4 pack0 : TEXCOORD0;
  half3 lightDir : TEXCOORD1;
  half3 viewDir : TEXCOORD2;
  LIGHTING_COORDS(3,4)
};
float4 _MainTex_ST;
float4 _BumpMap_ST;
v2f_surf vert_surf (appdata_full v) {
  v2f_surf o;
  o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
  o.pack0.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
  TANGENT_SPACE_ROTATION;
  float3 lightDir = mul (rotation, ObjSpaceLightDir(v.vertex));
  o.lightDir = lightDir;
  float3 viewDirForLight = mul (rotation, ObjSpaceViewDir(v.vertex));
  o.viewDir = viewDirForLight;
  TRANSFER_VERTEX_TO_FRAGMENT(o);
  return o;
}
fixed4 frag_surf (v2f_surf IN) : COLOR {
  Input surfIN;
  surfIN.uv_MainTex = IN.pack0.xy;
  surfIN.uv_BumpMap = IN.pack0.zw;
  SurfaceOutputPS o;
  o.Albedo = 0.0;
  o.Emission = 0.0;
  o.Specular = 0.0;
  o.Alpha = 0.0;
  surf (surfIN, o);
  #ifndef USING_DIRECTIONAL_LIGHT
  fixed3 lightDir = normalize(IN.lightDir);
  #else
  fixed3 lightDir = IN.lightDir;
  #endif
  fixed latten = 1;
  fixed satten = 1;

  #ifdef POINT  
	latten = (tex2D(_LightTexture0, dot(IN._LightCoord,IN._LightCoord).rr).UNITY_ATTEN_CHANNEL);
	satten = SHADOW_ATTENUATION(IN);
	#endif
	
	#ifdef SPOT
	latten = ( (IN._LightCoord.z > 0) * UnitySpotCookie(IN._LightCoord) * UnitySpotAttenuate(IN._LightCoord.xyz));
	satten = SHADOW_ATTENUATION(IN);
	#endif
	
	#ifdef DIRECTIONAL
	satten = SHADOW_ATTENUATION(IN);
	#endif
  fixed4 c = LightingBlinnPhongTranslucent (o, lightDir, normalize(half3(IN.viewDir)), latten,satten);
  c.a = 0.0;
  return c;
}

ENDCG
}
Pass {
		Name "ShadowCaster"
		Tags { "LightMode" = "ShadowCaster" }
		Fog {Mode Off}
		ZWrite On ZTest LEqual Cull Off
		Offset 1, 1

CGPROGRAM
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma fragmentoption ARB_precision_hint_fastest
#pragma multi_compile_shadowcaster nolightmap nodirlightmap
#include "HLSLSupport.cginc"
#define UNITY_PASS_SHADOWCASTER
#include "UnityCG.cginc"
#include "Lighting.cginc"

#define INTERNAL_DATA
#define WorldReflectionVector(data,normal) data.worldRefl
#define WorldNormalVector(data,normal) normal
#line 1
#line 24

		//#pragma surface surf BlinnPhongTranslucent nolightmap fullforwardshadows addshadow
		#pragma target 3.0
		#pragma debug
		
		sampler2D _TMAP;
		sampler2D _AO;
		half _AOST;
	
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		float _Shininess;
		fixed4 _SSSC;
		half _TMUL;
		half _Dist;
		half _TPOW;
		half _PP;
		
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
		
		inline fixed4 LightingBlinnPhongTranslucent (SurfaceOutputPS s, fixed3 lightDir, fixed3 viewDir, fixed atten)
		{
			fixed4 sub = tex2D(_TMAP,s.ShadeMapUV);
			half3 h = normalize (lightDir + viewDir);
			fixed diff = max (0, dot (s.Normal, lightDir));
			
			float nh = max (0, dot (s.Normal, h));
			float spec = pow (nh, s.Specular*128.0) * s.Gloss;
			float3 ambient = saturate(pow(sub.a*_TMUL*_SSSC.rgb*sub.rgb,_TPOW));
			sub.rgb *= _SSSC.rgb * _LightColor0.rgb * pow(pow(clamp(dot(normalize(normalize(viewDir)+normalize(s.Normal)*_Dist), -(normalize(lightDir))),0,1),_TPOW),_PP)*_TMUL*sub.a;
			
			fixed4 c;
			c.rgb = ((s.Albedo) * (_LightColor0.rgb * diff+sub.rgb)+clamp(1-_LightColor0.a*diff,0,1)*ambient + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten * 2);
			c.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec * atten;
			
			fixed ao = tex2D(_AO,s.ShadeMapUV).g;
			c.rgb = (1-_AOST)*c.rgb+_AOST*c.rgb*ao;
			return c;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.ShadeMapUV = IN.uv_MainTex;
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = 	c.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.Alpha = c.a;
		}
		struct v2f_surf {
  V2F_SHADOW_CASTER;
};
v2f_surf vert_surf (appdata_full v) {
  v2f_surf o;
  TRANSFER_SHADOW_CASTER(o)
  return o;
}
fixed4 frag_surf (v2f_surf IN) : COLOR {
  Input surfIN;
  SurfaceOutputPS o;
  o.Albedo = 0.0;
  o.Emission = 0.0;
  o.Specular = 0.0;
  o.Alpha = 0.0;
  surf (surfIN, o);
  SHADOW_CASTER_FRAGMENT(IN)
}

ENDCG
}
	Pass {
		Name "ShadowCollector"
		Tags { "LightMode" = "ShadowCollector" }
		Fog {Mode Off}
		ZWrite On ZTest LEqual

CGPROGRAM
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma fragmentoption ARB_precision_hint_fastest
#pragma multi_compile_shadowcollector nolightmap nodirlightmap
#include "HLSLSupport.cginc"
#define UNITY_PASS_SHADOWCOLLECTOR
#define SHADOW_COLLECTOR_PASS
#include "UnityCG.cginc"
#include "Lighting.cginc"

#define INTERNAL_DATA
#define WorldReflectionVector(data,normal) data.worldRefl
#define WorldNormalVector(data,normal) normal
#line 1
#line 24

		//#pragma surface surf BlinnPhongTranslucent nolightmap fullforwardshadows addshadow
		#pragma target 3.0
		#pragma debug
		
		sampler2D _TMAP;
		sampler2D _AO;
		half _AOST;
	
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		float _Shininess;
		fixed4 _SSSC;
		half _TMUL;
		half _Dist;
		half _TPOW;
		half _PP;
		
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
		
		inline fixed4 LightingBlinnPhongTranslucent (SurfaceOutputPS s, fixed3 lightDir, fixed3 viewDir, fixed atten)
		{
			fixed4 sub = tex2D(_TMAP,s.ShadeMapUV);
			half3 h = normalize (lightDir + viewDir);
			fixed diff = max (0, dot (s.Normal, lightDir));
			
			float nh = max (0, dot (s.Normal, h));
			float spec = pow (nh, s.Specular*128.0) * s.Gloss;
			float3 ambient = saturate(pow(sub.a*_TMUL*_SSSC.rgb*sub.rgb,_TPOW));
			sub.rgb *= _SSSC.rgb * _LightColor0.rgb * pow(pow(clamp(dot(normalize(normalize(viewDir)+normalize(s.Normal)*_Dist), -(normalize(lightDir))),0,1),_TPOW),_PP)*_TMUL*sub.a;
			
			fixed4 c;
			c.rgb = ((s.Albedo) * (_LightColor0.rgb * diff+sub.rgb)+clamp(1-_LightColor0.a*diff,0,1)*ambient + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten * 2);
			c.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec * atten;
			
			fixed ao = tex2D(_AO,s.ShadeMapUV).g;
			c.rgb = (1-_AOST)*c.rgb+_AOST*c.rgb*ao;
			return c;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.ShadeMapUV = IN.uv_MainTex;
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = 	c.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.Alpha = c.a;
		}
		struct v2f_surf {
  V2F_SHADOW_COLLECTOR;
};
v2f_surf vert_surf (appdata_full v) {
  v2f_surf o;
  TRANSFER_SHADOW_COLLECTOR(o)
  return o;
}
fixed4 frag_surf (v2f_surf IN) : COLOR {
  Input surfIN;
  SurfaceOutputPS o;
  o.Albedo = 0.0;
  o.Emission = 0.0;
  o.Specular = 0.0;
  o.Alpha = 0.0;
  surf (surfIN, o);
  SHADOW_COLLECTOR_FRAGMENT(IN)
}

ENDCG
}
}
}