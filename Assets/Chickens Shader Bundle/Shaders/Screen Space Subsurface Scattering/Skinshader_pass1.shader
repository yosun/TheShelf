Shader "Chickenlord/Skin/S5 Skinshader"{
	Properties {
	_Color ("Layer 1 Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color L3", Color) = (0.5, 0.5, 0.5, 1)	
	_Shininess ("Shininess L1", Range (0.01, 1)) = 0.078125
	_MainTex ("Layer1 Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap L1", 2D) = "bump" {}
	_ScatterMap ("Blend Map 1 to 2 (A)", 2D) = "white" {}
	_BlendAdjust1 ("Blend Adjust 2-1",Range(-1,1)) = 0
	_ExitColorMap("Exit Color Map (RGB)",2D) = "ecm" {}
	_ExitColorRadius ("Exit Color Ammount",Range(0,1)) = 1
	
	_GVar("Gauss Variance (Brightness)",Range(0,10)) = 1
	_SSSC ("SSSC",Color) = (1,1,1,1)
	_DDXP ("SSS Power",Float )  = 4
	_DDXM ("SSS Multplier",Float) = 5
	_TMAP("Translucency Map (A)",2D) = ""{}
	_TMUL("Translucency Strength",Float) = 1
	_LightBending("Light Bend(RGB)",Vector) = (0.6,0.3,0.1)
	_Smoothness("Smoothness",Range(0,1)) = 1
	
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Scattering"="true"}
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhongSSSLayer3 fullforwardshadows addshadow noambient
		#pragma target 3.0
		#include "CgHelper.cginc"
		#define _ARI 1.000293
		#define _SRI 1.36
		#define _SRI2 1.37
		#define UP_NORMAL float3(0,0,1)
		half4 _LightBending;
		half _Smoothness;
		
		sampler2D _TMAP;
		
		sampler2D _ScatterMap;
		sampler2D _ExitColorMap;
	
		float _GVar;
		float _ExitColorRadius;
		float _SpecSmoothing;
	
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		float _Shininess;
		float _BlendAdjust1;
		float _DDXP;
		float _DDXM;
		fixed4 _SSSC;
		half _TMUL;
		
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
		
		inline float gauss(float x,float mvar)
		{
			float ret = 1.0f/(sqrt(2*PI))*pow(exp(1.0f),-(pow(x,2)/2*mvar*mvar));
			return ret;
		}
		
		inline float3 Layer2LightVector(float MatThickness,sampler2D PrevLayerMap,float3 LightVector)
		{
			float3 normal = float3(0,0,-1);
			float3 refVector = RefractedVector3(LightVector,normal,_ARI,_SRI);
			return (refVector);
		}
		
		inline float3 bend(float3 n,float val)
		{
			return n*(1-val)+val*UP_NORMAL;
		}
		
		inline fixed4 LightingBlinnPhongSSSLayer3 (SurfaceOutputPS s, fixed3 lightDir, fixed3 viewDir, fixed atten)
		{
			float3 Layer2Light = Layer2LightVector(0,_ScatterMap,lightDir);
			half4 outCol = tex2D(_ExitColorMap,(s.ShadeMapUV));
			
			float3 ld = (lightDir);
			float colMul = _ExitColorRadius;
			outCol = tex2D(_ExitColorMap,s.ShadeMapUV);
			ld = normalize(ld);
			float3 h = normalize (ld + viewDir);
			
			float diff = max (0, dot (s.Normal, ld));
			float GB = 1-gauss((diff),_GVar*Vector3Length(lightDir-Layer2Light));
			diff *= GB;
			
			float3 bentR = bend(s.Normal, _LightBending.r);
			float3 bentG = bend(s.Normal, _LightBending.g);
			float3 bentB = bend(s.Normal, _LightBending.b);
			float dr = lerp(max(0,dot(bentR,ld)),diff,1-(_Smoothness*outCol.a));
			float dg = lerp(max(0,dot(bentG,ld)),diff,1-(_Smoothness*outCol.a));
			float db = lerp(max(0,dot(bentB,ld)),diff,1-(_Smoothness*outCol.a));
			
			
			float mAtten = Luminance(_LightColor0.rgb);
			fixed3 lightColor = (1-colMul)*_LightColor0.rgb+colMul*(_LightColor0.rgb*(outCol.rgb));
			fixed4 c2;
			
			float poff = clamp(1-diff,0,1);
			poff = pow(poff,_DDXP);
			poff *= _DDXM;
			poff = clamp(poff*outCol.a*atten,0,1);
			lightColor = (1-poff)*lightColor+poff*(mAtten*outCol*_SSSC);
			float sub = (max(0,saturate(dot(normalize (s.Normal + viewDir),-ld))))*tex2D(_TMAP,s.ShadeMapUV).a*_TMUL;
			dr+=sub;
			dg+=sub;
			db+=sub;
			c2.rgb = (s.Albedo * float3(lightColor.r * dr, lightColor.g * dg,lightColor.b * db)) * (atten * 2);
			c2.a = 0;
			
			h = normalize (lightDir + viewDir);
	
			diff = max (0, dot (s.Normal, lightDir));
			dr = lerp(max(0,dot(bentR,lightDir)),diff,1-(_Smoothness*outCol.a));
			dg = lerp(max(0,dot(bentG,lightDir)),diff,1-(_Smoothness*outCol.a));
			db = lerp(max(0,dot(bentB,lightDir)),diff,1-(_Smoothness*outCol.a));
				
			float hn = max (0, dot (s.Normal, h));
			float spec = pow (hn, s.Specular*128.0) * s.Gloss;
			spec = clamp(spec,0,1);

			fixed4 c;
			fixed tspec = (_LightColor0.a * _SpecColor.a * spec * atten);
			c.rgb = (s.Albedo * float3(_LightColor0.r * dr, _LightColor0.g * dg,_LightColor0.b * db)) * (atten * 2);
			
			c = (1-s.Alpha)*c2+s.Alpha*c;
			c.a = pow(tspec*Luminance(_SpecColor.rgb),2);
			c.rgb += (_LightColor0.rgb * _SpecColor.rgb * spec)*(atten);
			
			return c;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
		
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			c.rgb = half3(1,1,1);
			o.ShadeMapUV = IN.uv_MainTex;
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = 	c.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			o.Alpha = clamp(tex2D(_ScatterMap,IN.uv_MainTex).a+_BlendAdjust1,0,1);
		}
		ENDCG
	} 
	FallBack "Chickenlord/FastSkin"
}
