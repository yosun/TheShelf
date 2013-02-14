Shader "Chickenlord/3.5/Toony/Lighted Outline" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
		_OLC ("Outline Color",Color) = (0,0,0,1)
		_OLP ("Outline Strength",Range(5,32)) = 25
		_Steps("Lighting Steps",Range(1,128)) = 32
		
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf ToonyBlinnPhong addshadow fullforwardshadows novertexlights
		#pragma target 3.0
		#include "UnityCG.cginc"

		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		half _Shininess;
		fixed4 _OLC;
		half _OLP;
		half _Steps;
		
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 viewDir;
			float3 worldNormal;
			INTERNAL_DATA
		};
		
		struct SurfaceOutputPS {
			fixed3 Albedo;
			fixed3 Normal;
			fixed Gloss;
			half Specular;	
			fixed Alpha;
			fixed3 Emission;
			fixed3 Indl;
		};
		
		inline fixed4 LightingToonyBlinnPhong (SurfaceOutputPS s, fixed3 lightDir, half3 viewDir, fixed atten)
		{
			half3 h = normalize (lightDir + viewDir);
			float stx = _Steps/256;
			float sadd = _Steps/2;
			fixed diff = max (0, dot (s.Normal, lightDir));
			diff = (floor((diff*256+sadd)/_Steps))*stx;
			
			float nh = max (0, dot (s.Normal, h));
			float spec = pow (nh, s.Specular*128.0) * s.Gloss;
			spec = (floor((spec*256+sadd)/_Steps))*stx;
			
			fixed4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * _SpecColor.rgb * spec) * (atten*2);
			c.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec * atten;
			c.rgb += s.Indl*saturate((floor((Luminance(s.Indl)*256+sadd)/_Steps))*stx);
			return c;
		}
		
		inline fixed4 LightingToonyBlinnPhong_PrePass (SurfaceOutputPS s, half4 light)
		{
			fixed spec = light.a * s.Gloss;
			half stx = _Steps/256;
			float sadd = _Steps/2;
			spec = (floor((spec*256+sadd)/_Steps))*stx;
			fixed diff = Luminance(light.rgb);
			diff = clamp((floor((diff*256+sadd)/(_Steps)))*(stx),0,1);
			
			fixed4 c;
			c.rgb = (s.Albedo * light.rgb*diff + light.rgb * _SpecColor.rgb * spec);
			c.a = s.Alpha + spec * _SpecColor.a;
			c.rgb += s.Indl*saturate((floor((Luminance(s.Indl)*256+sadd)/_Steps))*stx);
			return c;
		}
		
		inline half4 LightingToonyBlinnPhong_DirLightmap (SurfaceOutputPS s, fixed4 color, fixed4 scale, half3 viewDir, bool surfFuncWritesNormal, out half3 specColor)
		{
			UNITY_DIRBASIS
			half3 scalePerBasisVector;
			half stx = _Steps/256;
			float sadd = _Steps/2;
			
			half3 lm = DirLightmapDiffuse (unity_DirBasis, color, scale, s.Normal, surfFuncWritesNormal, scalePerBasisVector);
			half diff = Luminance(lm);
			half lum = diff;
			diff = ((floor((diff*256+sadd)/(_Steps)))*(stx));
			
			half3 lightDir = normalize (scalePerBasisVector.x * unity_DirBasis[0] + scalePerBasisVector.y * unity_DirBasis[1] + scalePerBasisVector.z * unity_DirBasis[2]);
			half3 h = normalize (lightDir + viewDir);

			float nh = max (0, dot (s.Normal, h));
			float spec = pow (nh, s.Specular*128.0) * s.Gloss;
			spec = (floor((spec*256+sadd)/_Steps))*stx;
			
			diff = clamp(diff,0,0.9999f);
			lum = clamp(lum,0,0.9999f);
			lm /= lum;
			lm *= pow(lum,log(diff)/log(lum));
			// specColor used outside in the forward path, compiled out in prepass
			specColor = lm * _SpecColor.rgb * s.Gloss * spec;
			
			// spec from the alpha component is used to calculate specular
			// in the Lighting*_Prepass function, it's not used in forward
			
			return half4(lm, spec);
		}
		
		void surf (Input IN, inout SurfaceOutputPS o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color.rgb;
			o.Gloss = 	c.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
			fixed mult = 1-clamp(dot(o.Normal,normalize(IN.viewDir)),0,1);
			mult = pow(mult,_OLP);
			mult = min(100*mult,1);
			o.Albedo = (1-mult)*o.Albedo+(mult)*_OLC.rgb;
			float3 worldNormal = WorldNormalVector(IN,o.Normal);
			o.Indl += o.Albedo*ShadeSH9(float4(worldNormal,1));
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
