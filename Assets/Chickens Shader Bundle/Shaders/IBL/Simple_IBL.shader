Shader "Chickenlord/Simple IBL" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_BumpMap ("Normalmap", 2D) = "bump" {}
		_Normals ("Light Vector Distribution",2D) = "dist"{}
		_IBLC("IBL Color",Color) = (1,1,1,1)
		_Cube("IBL CubeMap", Cube) = "_Skybox" { TexGen CubeReflect }
		_IMulti("Multiplicator",Float) = 1
		_IPow("Power",Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		//Real amount of samples taken is LIGHTING_SAMPLES*LIGHTING_SAMPLES
		//Minimum value should be 2.
		//Values bigger than 3 are only working with d3d9. Include the pragma below
		//if you're not using opengl and want to use higher sample counts.
		//Be careful though, high values are really slow and might overheat your graphics card!
		
		#define LIGHTING_SAMPLES 3
		//#pragma only_renderers d3d9
		
		#pragma surface surf BlinnPhongIBL noforwardadd novertexlights
		#pragma target 3.0
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _Normals;
		fixed4 _Color;
		fixed4 _IBLC;
		half _Shininess;
		samplerCUBE _Cube;
		half _IMulti;
		half _IPow;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 worldNormal;
			float3 viewDir;
			INTERNAL_DATA
		};
		
		struct SurfaceOutputPS {
			fixed3 Albedo;
			fixed3 Normal;
			fixed Gloss;
			half Specular;	
			fixed Alpha;
			fixed3 Emission;
		};
		
		inline fixed4 LightingBlinnPhongIBL (SurfaceOutputPS s, fixed3 lightDir, half3 viewDir, fixed atten)
		{
			return fixed4(s.Albedo.rgb,s.Alpha);
		}
		
		
		inline fixed4 LightingBlinnPhongIBL_PrePass (SurfaceOutputPS s, half4 light)
		{
			return fixed4(s.Albedo.rgb,s.Alpha);
		}
		
		inline half3 UPN(half3 n)
		{
			return half3((n.x-0.5)*2,(n.y-0.5)*2,(n.z-0.5)*2);
		}

		void surf (Input IN, inout SurfaceOutputPS o) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Gloss = tex.a;
			o.Alpha = tex.a * _Color.a;
			o.Specular = _Shininess;
			
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));

			float2 uv = float2(_Time[0],_Time[0]);
			half3 rand = float3(0,0,0);
			float3 light = float3(0,0,0);
			float3 spec = float3(0,0,0);
			float3 sl = float3(0,0,0);
			float3 svec;
			
			for(int i = 0; i< LIGHTING_SAMPLES;i++)
			{
				for(int j = 0; j<LIGHTING_SAMPLES;j++)
				{
					uv = float2((float)j/(float)LIGHTING_SAMPLES,(float)i/(float)LIGHTING_SAMPLES);
					rand = tex2D(_Normals,uv);
					rand = UPN(rand);
					svec = normalize(o.Normal + rand.rgb);
					float3 lsample = pow(texCUBE(_Cube,WorldNormalVector(IN,svec)),2.2);
					light += max(0,dot(svec,o.Normal))*lsample.rgb;
					sl+=Luminance(lsample)*rand;
				}
			}
			sl = normalize(sl);
			float nh = max(0,dot(o.Normal,normalize(sl+IN.viewDir)));
			nh = pow(nh,_Shininess*58.0)*o.Gloss;
			spec = nh*_SpecColor.rgb*light/(LIGHTING_SAMPLES*LIGHTING_SAMPLES);
			spec = pow(spec,_IPow);
			spec*=_IMulti;
			light = pow(light,_IPow);
			light *= _IMulti;
			//o.Albedo = pow((pow(o.Albedo,2.2) * light/(LIGHTING_SAMPLES*LIGHTING_SAMPLES) + spec/(LIGHTING_SAMPLES*LIGHTING_SAMPLES)),0.45);
			o.Albedo = pow((pow(o.Albedo,2.2) * light/(LIGHTING_SAMPLES*LIGHTING_SAMPLES)*_IBLC.rgb + spec),0.45);
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
