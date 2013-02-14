Shader "Chickenlord/Skin/Multilayer SSS Skinshader 1.21" {
	Properties {
	_Color ("Layer 1 Color", Color) = (1,1,1,1)
	_Color2 ("Layer 2 Color", Color) = (1,1,1,1)
	_Color3 ("Layer 3 Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color L3", Color) = (0.5, 0.5, 0.5, 1)
	_SpecColor2 ("Specular Color L3", Color) = (0.5, 0.5, 0.5, 1)
	_SpecColor3 ("Specular Color L3", Color) = (0.5, 0.5, 0.5, 1)
	_Shininess ("Shininess L1", Range (0.01, 1)) = 0.078125
	_Shininess2 ("Shininess L2", Range (0.01, 1)) = 0.078125
	_Shininess3 ("Shininess L3", Range (0.01, 1)) = 0.078125
	_MainTex ("Layer1 Base (RGB) Gloss (A)", 2D) = "white" {}
	_MainTex2 ("Layer2 Base (RGB) Gloss (A)", 2D) = "white" {}
	_MainTex3 ("Layer3 Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap L1", 2D) = "bump" {}
	_BumpMap2 ("Normalmap L2", 2D) = "bump2" {}
	_BumpMap3 ("Normalmap L3", 2D) = "bump3" {}
	_ScatterMap ("Blend Map 1 to 2 (A)", 2D) = "white" {}
	_BlendAdjust1 ("Blend Adjust 2-1",Range(-1,1)) = 0
	_ScatterMap2 ("Blend Map 2 to 3 (A)", 2D) = "white" {}
	_BlendAdjust2 ("Blend Adjust 3-2",Range(-1,1)) = 0
	_ExitColorMap("Exit Color Map (RGB) Scattering (A)",2D) = "ecm" {}
	_ExitColorMultiplier("Exit Color Displacement Range",Range(0,1)) = 1
	_ExitColorRadius ("Exit Color Ammount",Range(0,6)) = 1
	_Layer1Thickness ("Layer 1 Thickness",Range(0,1)) = 0.1
	_Layer2Thickness ("Layer 2 Thickness",Range(0,1)) = 0.1
	
	_GVar("Gauss Variance (Brightness)",Range(0,10)) = 1
	_SpecSmoothing("Specularity Smoothness",Range(0.1,2)) = 0.70710678118654752440084436210485
	_SSSC ("SSSC",Color) = (1,1,1,1)
	_DDXP ("SSS Power",Float )  = 4
	_DDXM ("SSS Multplier",Float) = 5
	
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhongSSSLayer3 nolightmap fullforwardshadows addshadow
		#pragma target 3.0
		#include "CgHelper.cginc"
		#define _ARI 1.000293
		#define _SRI 1.36
		#define _SRI2 1.37

		fixed4 _Color3;
		sampler2D _MainTex3;
		sampler2D _BumpMap3;
		float _Shininess3;
		fixed4 _SpecColor3;
		
		sampler2D _ScatterMap;
		sampler2D _ScatterMap2;
		sampler2D _ExitColorMap;
		
		float _Layer1Thickness;
		float _Layer2Thickness;
		float _GVar;
		float _ExitColorMultiplier;
		float _ExitColorRadius;
		float _SpecSmoothing;
		
		fixed4 _Color2;
		sampler2D _MainTex2;
		sampler2D _BumpMap2;
		float _Shininess2;
		fixed4 _SpecColor2;
		float _BlendAdjust2;
		
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		float _Shininess;
		float _BlendAdjust1;
		float _DDXP;
		float _DDXM;
		fixed4 _SSSC;
		
		
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
			fixed3 Albedo2;
			half Specular2;
			fixed Gloss2;
			fixed Alpha2;
			fixed3 Albedo3;
			half Specular3;
			fixed Gloss3;
			fixed3 Emission;
			float2 ShadeMapUV;
			float2 BumpMapUV;
		};
		
		inline float gauss(float x,float mvar)
		{
			float ret = 1.0f/(sqrt(2*PI))*pow(exp(1.0f),-(pow(x,2)/2*mvar*mvar));
			return ret;
		}
		
		inline float BDist(float3 N,float3 H,float m)
		{
			float alpha = acos(dot(N,H));
			float caq = pow(cos(alpha),2);
			float simp = (1-caq)/(caq*m*m);
			float kspec = exp(-simp)/(PI*m*m*caq*caq);
			return kspec;
		}

		inline float Schlick(float Rzero,float3 lightDir,float3 normal)
		{
			return Rzero + (1 - Rzero)*pow((1 - dot(lightDir,normal)),5);
		}
		
		inline float3 Layer3LightVector(float MatThickness,float PrevThickness,sampler2D PrevLayerMap,float3 LightVector)
		{
			float3 normal = float3(0,0,-1);
			float3 refVector = RefractedVector3(LightVector,normal,_SRI,_SRI2);
			return (refVector);
		}

		inline float3 Layer2LightVector(float MatThickness,sampler2D PrevLayerMap,float3 LightVector)
		{
			float3 normal = float3(0,0,-1);
			float3 refVector = RefractedVector3(LightVector,normal,_ARI,_SRI);
			return (refVector);
		}
		
		inline fixed4 LightingBlinnPhongSSSLayer3 (SurfaceOutputPS s, fixed3 lightDir, fixed3 viewDir, fixed atten)
		{
			float mAtten = Luminance(_LightColor0.rgb);
			float3 Layer2Light = Layer2LightVector(_Layer1Thickness,_ScatterMap,lightDir);
			float3 Layer3Light = Layer3LightVector(_Layer2Thickness,_Layer1Thickness,_ScatterMap2,Layer2Light);
			float3 Normal3 = UnpackNormal(tex2D(_BumpMap3,s.BumpMapUV));
			
			float3 ld = (lightDir-_Layer1Thickness*normalize(Layer2Light)-_Layer2Thickness*normalize(Layer3Light));
			float colMul = clamp(_ExitColorRadius*dot(ld,lightDir),0,1);
			float2 nUV = s.ShadeMapUV-(((ld-lightDir).xy*_Layer2Thickness)*(Vector3Length(ld)/Vector3Length(lightDir)))*_ExitColorMultiplier;
			float2 texDif = (_Layer2Thickness);
			half4 outCol = tex2D(_ExitColorMap,(nUV));
			ld = normalize(ld);
			
			float3 h = normalize (ld + viewDir);
			
			float diff = max (0, dot (Normal3, ld));
			float GB = 1-gauss((diff),_GVar*Vector3Length(lightDir-Layer3Light)*(1-_Layer2Thickness+1-_Layer1Thickness));
			diff *= GB;
			
			float hn = dot(h,Normal3);
			float vh = dot(viewDir,h);
			float G = max(0,min(1,min((2*hn*dot(viewDir,Normal3))/vh,(2*hn*dot(lightDir,Normal3))/vh)));
			
			float spec = min(1,max(0,BDist(Normal3,h,(_SpecSmoothing))*Schlick(1-s.Specular3,h,Normal3)*s.Gloss3/(dot(viewDir,Normal3))))*G;
			spec += (pow (max(0,hn), s.Specular3*128.0) * s.Gloss3)/2;
			spec *= GB;
			spec = clamp(spec,0,1);
			
			fixed4 c3;
			float poff = clamp(1-diff,0,1);
			poff = pow(poff,_DDXP);
			poff *= _DDXM;
			poff = clamp(poff*outCol.a*atten,0,1);
			
			half3 lightColor = (1-colMul)*_LightColor0.rgb+colMul*(_LightColor0.rgb*outCol.rgb);
			lightColor = (1-poff)*lightColor+mAtten*poff*outCol*_SSSC;
			c3.rgb = (s.Albedo3 * (lightColor) * diff +_LightColor0.rgb* _SpecColor3.rgb * spec) * (atten * 2);
			c3.a = 1;
			
			
			Normal3 = UnpackNormal(tex2D(_BumpMap2,s.BumpMapUV));
			ld = (lightDir-_Layer1Thickness*normalize(Layer2Light));
			colMul = clamp(_ExitColorRadius*dot(ld,lightDir),0,1);
			nUV = s.ShadeMapUV-(((ld-lightDir).xy*_Layer1Thickness)*(Vector3Length(ld)/Vector3Length(lightDir)))*_ExitColorMultiplier;
			texDif = (_Layer2Thickness);
			outCol = tex2D(_ExitColorMap,(nUV));
			ld = normalize(ld);
			h = normalize (ld + viewDir);
			
			diff = max (0, dot (Normal3, ld));
			GB = 1-gauss((diff),_GVar*Vector3Length(lightDir-Layer2Light)*(1-_Layer1Thickness));
			diff *= GB;
			
			hn = dot(h,Normal3);
			vh = dot(viewDir,h);
			G = max(0,min(1,min((2*hn*dot(viewDir,s.Normal))/vh,(2*hn*dot(lightDir,s.Normal))/vh)));
			
			spec = min(1,max(0,BDist(Normal3,h,(_SpecSmoothing))*Schlick(1-s.Specular2,h,Normal3)*s.Gloss/(dot(viewDir,Normal3))))*G;
			spec += (pow (max(0,hn), s.Specular2*128.0) * s.Gloss2)/2;
			spec *= GB;
			spec = clamp(spec,0,1);
			
			lightColor = (1-colMul)*_LightColor0.rgb+colMul*(_LightColor0.rgb*outCol.rgb);
			fixed4 c2;
			
			poff = clamp(1-diff,0,1);
			poff = pow(poff,_DDXP);
			poff *= _DDXM;
			poff = clamp(poff*outCol.a*atten,0,1);
			lightColor = (1-poff)*lightColor+mAtten*poff*outCol*_SSSC;
			
			c2.rgb = (s.Albedo2 * (lightColor) * diff + _LightColor0.rgb* _SpecColor2.rgb * spec) * (atten * 2);
			c2.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec * atten;
			
			h = normalize (lightDir + viewDir);
	
			diff = max (0, dot (s.Normal, lightDir));
				
			hn = max (0, dot (s.Normal, h));
			spec = pow (hn, s.Specular*128.0) * s.Gloss;
			spec = clamp(spec,0,1);

			fixed4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten * 2);
			c.a = s.Alpha2 + _LightColor0.a * _SpecColor.a * spec * atten;
			
			c3 = (1-s.Alpha)*c3+s.Alpha*c2;
			c3 = (1-s.Alpha2)*c3+s.Alpha2*c;
			return c3;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			half4 c = tex2D (_MainTex3, IN.uv_MainTex);
			o.Albedo3 = c.rgb * _Color3.rgb;
			o.Gloss3 = c.a;
			o.Specular3 = _Shininess3;
			o.ShadeMapUV = IN.uv_MainTex;
			o.BumpMapUV = IN.uv_BumpMap;
			o.Alpha2 = clamp(tex2D(_ScatterMap,IN.uv_MainTex).a+_BlendAdjust1,0,1);
			
			c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = 	c.a;
			o.Alpha2 = clamp(tex2D(_ScatterMap,IN.uv_MainTex).a+_BlendAdjust1,0,1);
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			
			c = tex2D (_MainTex2, IN.uv_MainTex);
			o.Albedo2 = c.rgb * _Color2.rgb;
			o.Gloss2 = c.a;
			o.Alpha = clamp(tex2D(_ScatterMap2,IN.uv_MainTex).a+_BlendAdjust2,0,1);
			o.Specular2 = _Shininess2;
		}
		ENDCG
	} 
	FallBack "Chickenlord/FastSkin"
}
