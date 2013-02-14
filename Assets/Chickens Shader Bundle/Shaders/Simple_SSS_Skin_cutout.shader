Shader "Chickenlord/Skin/Cutout/Simple SSS Skinshader Specularmap" {
	Properties {
	_Color ("Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
	_MainTex ("Diffuse (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_SpecularMap("Specular Color(RGB) Power (A)",2D) = ""{}
	_ScatterMap ("Blend Map (A)", 2D) = "white" {}
	_BlendAdjust1 ("Blend Adjust",Range(-1,1)) = 0
	_ExitColorMap("Exit Color Map (RGB) Scattering (A)",2D) = "ecm" {}
	_GVar("Gauss Variance (Brightness)",Range(0,10)) = 1
	_SSSC ("SSSC",Color) = (1,1,1,1)
	_Smoothness("Smoothness",Range(0,1)) = 1
	_Cutout("Cutout",Range(0,1)) = 0
	
	}
	SubShader {
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhongSSSLayer3 nolightmap fullforwardshadows addshadow alphatest:_Cutout
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
		sampler2D _SpecularMap;
		
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
		
		float _Smoothness;

		
		
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
			float2 BumpMapUV;
			fixed3 Spec;
			fixed Blend;
		};
		
		void SetValues()
		{
			_SpecSmoothing = (1.3*_Smoothness)+0.7;
			_Layer1Thickness = _Smoothness*0.45;
			_Layer2Thickness = _Smoothness*0.1;
			_ExitColorMultiplier = 0.001;
			_DDXP = 3.5;
			_DDXM = 7;
			_ExitColorRadius = _Smoothness;
		}
		
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
			float3 Normal3 = s.Normal;
			
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
			
			float spec = min(1,max(0,BDist(Normal3,h,(_SpecSmoothing))*Schlick(1-s.Specular,h,Normal3)*s.Gloss/(dot(viewDir,Normal3))))*G;
			spec += (pow (max(0,hn), s.Specular*128.0) * s.Gloss)/2;
			spec *= GB;
			spec = clamp(spec,0,1);
			
			fixed4 c3;
			float poff = clamp(1-diff,0,1);
			poff = pow(poff,_DDXP);
			poff *= _DDXM;
			poff = clamp(poff*outCol.a*atten,0,1);
			
			half3 lightColor = (1-colMul)*_LightColor0.rgb+colMul*(_LightColor0.rgb*outCol.rgb);
			lightColor = (1-poff)*lightColor+mAtten*poff*outCol*_SSSC;
			c3.rgb = (s.Albedo * (lightColor) * diff +_LightColor0.rgb* _SpecColor.rgb*s.Spec.rgb * spec) * (atten * 2);
			c3.a = 1;

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
			
			spec = min(1,max(0,BDist(Normal3,h,(_SpecSmoothing))*Schlick(1-s.Specular,h,Normal3)*s.Gloss/(dot(viewDir,Normal3))))*G;
			spec += (pow (max(0,hn), s.Specular*128.0) * s.Gloss)/2;
			spec *= GB;
			spec = clamp(spec,0,1);
			
			lightColor = (1-colMul)*_LightColor0.rgb+colMul*(_LightColor0.rgb*outCol.rgb);
			fixed4 c2;
			
			poff = clamp(1-diff,0,1);
			poff = pow(poff,_DDXP);
			poff *= _DDXM;
			poff = clamp(poff*outCol.a*atten,0,1);
			lightColor = (1-poff)*lightColor+mAtten*poff*outCol*_SSSC;
			
			c2.rgb = (s.Albedo * (lightColor) * diff + _LightColor0.rgb* _SpecColor.rgb*s.Spec.rgb * spec) * (atten * 2);
			c2.a = s.Blend + _LightColor0.a * _SpecColor.a * spec * atten;
			
			h = normalize (lightDir + viewDir);
	
			diff = max (0, dot (s.Normal, lightDir));
				
			hn = max (0, dot (s.Normal, h));
			spec = pow (hn, s.Specular*128.0) * s.Gloss;
			spec = clamp(spec,0,1);

			fixed4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb*s.Spec.rgb * spec) * (atten * 2);
			c.a = s.Blend + _LightColor0.a * _SpecColor.a * spec * atten;
			
			c3 = (1-s.Blend)*c3+s.Blend*c2;
			c3 = (1-s.Blend)*c3+s.Blend*c;
			return c3;
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			SetValues();
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			fixed4 spec = tex2D(_SpecularMap, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = spec.a;
			o.Specular = _Shininess;
			o.ShadeMapUV = IN.uv_MainTex;
			o.BumpMapUV = IN.uv_BumpMap;
			o.Alpha = c.a;
			o.Spec.rgb = spec.rgb;
			o.Blend = clamp(tex2D(_ScatterMap,IN.uv_MainTex).a+_BlendAdjust1,0,1);
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
		}
		ENDCG
	} 
	FallBack "Chickenlord/FastSkin"
}
