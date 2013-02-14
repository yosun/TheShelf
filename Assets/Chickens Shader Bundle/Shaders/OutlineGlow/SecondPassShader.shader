Shader "Hidden/WhiteDraw" {
	Properties {
	_MainTex ("", 2D) = "white" {}
	_Cutoff ("", Float) = 0.0
	_Color ("", Color) = (1,1,1,1)
	}
	SubShader {
		Tags { "RenderType"="TransparentCutout" }
		LOD 200
		
	Pass {
		AlphaToMask True ColorMask RGB
		CGPROGRAM
		#pragma vertex vert_surf
		#pragma fragment frag_surf
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma multi_compile_fwdbase nodirlightmap
		#include "HLSLSupport.cginc"
		#define UNITY_PASS_FORWARDBASE
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"

		float _DrawMe;
		sampler2D _MainTex;
		uniform fixed4 _Color;


		struct v2f_surf {
		  float4 pos : SV_POSITION;
		  float2 pack0 : TEXCOORD0;
		  fixed3 normal : TEXCOORD1;
		  fixed3 vlight : TEXCOORD2;
		  LIGHTING_COORDS(3,4)
		};

		float4 _MainTex_ST;
		v2f_surf vert_surf (appdata_full v) {
		  v2f_surf o;
		  o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
		  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		  TRANSFER_VERTEX_TO_FRAGMENT(o);
		  return o;
		}

		fixed _Cutoff;
		fixed4 frag_surf (v2f_surf IN) : COLOR {
			fixed tex = tex2D(_MainTex,IN.pack0.xy).a;
			clip(tex*_Color.a-_Cutoff);
			fixed4 c = fixed4(1,1,1,1);
			return c;
		}

		ENDCG
		}
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
	Pass {
		CGPROGRAM
		#pragma vertex vert_surf
		#pragma fragment frag_surf
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma multi_compile_fwdbase nodirlightmap
		#include "HLSLSupport.cginc"
		#define UNITY_PASS_FORWARDBASE
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"

		float _DrawMe;
		sampler2D _MainTex;
		uniform fixed4 _Color;


		struct v2f_surf {
		  float4 pos : SV_POSITION;
		  float2 pack0 : TEXCOORD0;
		  fixed3 normal : TEXCOORD1;
		  fixed3 vlight : TEXCOORD2;
		  LIGHTING_COORDS(3,4)
		};

		float4 _MainTex_ST;
		v2f_surf vert_surf (appdata_full v) {
		  v2f_surf o;
		  o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
		  o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		  TRANSFER_VERTEX_TO_FRAGMENT(o);
		  return o;
		}

		fixed4 frag_surf (v2f_surf IN) : COLOR {
			fixed4 c = fixed4(1,1,1,1);
			return c;
		}

		ENDCG
		}
	}
}