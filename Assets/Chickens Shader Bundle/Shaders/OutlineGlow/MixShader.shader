Shader "Hidden/OutlineMix" {
Properties {
	_MainTex ("", 2D) = "" {}
}
Subshader {
	ZTest Always Cull Off ZWrite Off Fog { Mode Off }

CGINCLUDE
#include "UnityCG.cginc"
#pragma exclude_renderers gles

sampler2D _MainTex;
sampler2D _CameraDepthNormalsTexture;
sampler2D _AddTex;
float _MinZ;
ENDCG

	//0
	// --  Overlay Mix Pass
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};
		
		sampler2D _BlurTex;
		sampler2D _WhiteTex;
		float4 _TexSize;
		half4 _OutlineColor;
		fixed _Glow;
		float _Mult;
		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 sourceTex = tex2D(_MainTex, i.uv);
			
			half whiteTex = tex2D(_WhiteTex, i.uv).r;
			half4 blurTex = tex2D(_BlurTex, i.uv);
			half3 dif = saturate((blurTex-whiteTex).rgb);
			half lum = saturate(Luminance(dif*_Mult));
			half x = (lum*dif *_Mult);
			if(_Glow<0.5)
				x = saturate(x);
			
			sourceTex.rgb =(1-lum)*(sourceTex.rgb)+x*_OutlineColor;
			sourceTex.a = sourceTex.a + x;
			return sourceTex;
		}
	  ENDCG
  }
    
	
	//1
	// -- Overlay Mix Pass. Smooth outline version.
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};
		
		sampler2D _BlurTex;
		sampler2D _WhiteTex;
		float4 _TexSize;
		half4 _OutlineColor;
		fixed _Glow;
		float _Mult;
		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 sourceTex = tex2D(_MainTex, i.uv);
			
			// Picking 5 samples creates smoother looking outlines. (Note: 5 samples are needed. 4 samples don't look as good and 9 don't as well.
			half whiteTex = tex2D(_WhiteTex, i.uv).r;
			
			whiteTex += tex2D(_WhiteTex, i.uv-_TexSize.xy).r;
			
			whiteTex += tex2D(_WhiteTex, i.uv+_TexSize.xy).r;
			whiteTex += tex2D(_WhiteTex, i.uv+float2(_TexSize.x,-_TexSize.y)).r;
			whiteTex += tex2D(_WhiteTex, i.uv+float2(-_TexSize.x,_TexSize.y)).r;
			
			
			whiteTex *=0.2;
			if(whiteTex<0.5)
				whiteTex = 0;
			else
				whiteTex = 1;
			
			half4 blurTex = tex2D(_BlurTex, i.uv);
			half3 dif = saturate((blurTex-whiteTex).rgb);
			half lum = saturate(Luminance(dif*_Mult));
			half x = (lum*dif *_Mult);
			if(_Glow<0.5)
				x = saturate(x);
			sourceTex.rgb =(1-lum)*(sourceTex.rgb)+x*_OutlineColor;
			sourceTex.a = sourceTex.a + x;
			return sourceTex;
		}
	  ENDCG
  }
  
	//2
	// Clear pass
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};
		
		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			return half4(0,0,0,0);
		}
	  ENDCG
  }
    
	//3
	// -- Sperate Objects: Final Pass
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};
		
		sampler2D _BlurTex;
		sampler2D _WhiteTex;
		float4 _TexSize;
		half4 _OutlineColor;
		fixed _Glow;
		float _Mult;
		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 sourceTex = tex2D(_MainTex, i.uv);
			half4 add = tex2D(_AddTex, i.uv);
			sourceTex.rgb = (1-add.a)*sourceTex.rgb+ add.a*add.rgb;
			return sourceTex;
		}
	  ENDCG
  }
  
  	//4
	// --  Overlay Mix Pass
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};
		
		sampler2D _BlurTex;
		sampler2D _WhiteTex;
		float4 _TexSize;
		half4 _OutlineColor;
		fixed _Glow;
		float _Mult;
		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 sourceTex = tex2D(_MainTex, i.uv);
			
			half whiteTex = tex2D(_WhiteTex, i.uv).r;
			half4 blurTex = tex2D(_BlurTex, i.uv);
			half3 dif = saturate((blurTex-whiteTex).rgb);
			half lum = saturate(Luminance(dif*_Mult));
			half x = (lum*dif *_Mult);
			if(_Glow<0.5)
				x = saturate(x);
			sourceTex = (sourceTex-whiteTex);
			sourceTex.rgb =(1-lum)*(sourceTex.rgb)+x*_OutlineColor;
			sourceTex.a = sourceTex.a + x;
			return sourceTex;
		}
	  ENDCG
  }
    
	
	//5
	// -- Overlay Mix Pass. Smooth outline version.
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};
		
		sampler2D _BlurTex;
		sampler2D _WhiteTex;
		float4 _TexSize;
		half4 _OutlineColor;
		fixed _Glow;
		float _Mult;
		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 sourceTex = tex2D(_MainTex, i.uv);
			
			// Picking 5 samples creates smoother looking outlines. (Note: 5 samples are needed. 4 samples don't look as good and 9 don't as well.
			half whiteTex = tex2D(_WhiteTex, i.uv).r;
			
			whiteTex += tex2D(_WhiteTex, i.uv-_TexSize.xy).r;
			
			whiteTex += tex2D(_WhiteTex, i.uv+_TexSize.xy).r;
			whiteTex += tex2D(_WhiteTex, i.uv+float2(_TexSize.x,-_TexSize.y)).r;
			whiteTex += tex2D(_WhiteTex, i.uv+float2(-_TexSize.x,_TexSize.y)).r;
			
			
			whiteTex *=0.2;
			if(whiteTex<0.5)
				whiteTex = 0;
			else
				whiteTex = 1;
			
			half4 blurTex = tex2D(_BlurTex, i.uv);
			half3 dif = saturate((blurTex-whiteTex).rgb);
			half lum = saturate(Luminance(dif*_Mult));
			half x = (lum*dif *_Mult);
			if(_Glow<0.5)
				x = saturate(x);
			sourceTex = (sourceTex-whiteTex);
			sourceTex.rgb =(1-lum)*(sourceTex.rgb)+x*_OutlineColor;
			sourceTex.a = sourceTex.a + x;
			return sourceTex;
		}
	  ENDCG
  }
  
  //6
	// -- DepthCopy
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 OrigDepth = tex2D (_CameraDepthNormalsTexture, i.uv);
			return OrigDepth;
		}
	  ENDCG
  }
  
  //7
	// -- DepthPrePass
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 tex = tex2D(_MainTex,i.uv);
			half depth = DecodeFloatRG(tex2D (_CameraDepthNormalsTexture, i.uv).zw);
			tex.a = depth;
			return tex.a;
		}
	  ENDCG
  }
  
  //8
  // -- DepthTestedPrePass
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  sampler2D _SecDepth;
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 tex = tex2D(_MainTex,i.uv);
			half depth = (DecodeFloatRG(tex2D (_CameraDepthNormalsTexture, i.uv).zw));
			half ndepth = (DecodeFloatRG(tex2D (_SecDepth, i.uv).zw));
			if(ndepth<=depth)
			{
				return tex;
			}
			else
			{
				return 0;
			}
		}
	  ENDCG
  }
  
   //9
  // -- DepthTestedPrePass
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  sampler2D _SecDepth;
	  sampler2D _DSD;
	  float4 _DTexelOffset;
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 tex = tex2D(_MainTex,i.uv);
			half depth = (DecodeFloatRG(tex2D (_DSD, i.uv).zw)) * _ProjectionParams.z;
			half ndepth = (DecodeFloatRG(tex2D (_SecDepth, i.uv).zw)) * _ProjectionParams.z;
			if(ndepth<=depth+0.3)
			{
				return tex;
			}
			else
			{
				return 0;
			}
		}
	  ENDCG
  }
  
     //10
  // -- Quick Erosion
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  sampler2D _SecDepth;
	  float4 _DTexelOffset;
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 t1 = tex2D(_MainTex, i.uv+_DTexelOffset.xy).g;
			t1 += tex2D(_MainTex, i.uv-_DTexelOffset.xy).g;
			t1 += tex2D(_MainTex, i.uv+_DTexelOffset.zw).g;
			t1 += tex2D(_MainTex, i.uv-_DTexelOffset.zw).g;
			return ceil(t1*0.25-0.5);
		}
	  ENDCG
  }
  
     //11
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  sampler2D _SecDepth;
	  float4 _DTexelOffset;
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			half4 d = tex2D(_CameraDepthNormalsTexture, i.uv);
			return d;
		}
	  ENDCG
  }
  
   //12 DD
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  sampler2D _SecDepth;
	  float4 _DTexelOffset;
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			float4 tex = tex2D(_MainTex,i.uv);
			float d = 1-DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, i.uv).zw);
			float ndepth = 1-DecodeFloatRG(tex2D (_SecDepth, i.uv).zw);
			return ceil(ndepth-d+_MinZ*_ProjectionParams.w)*tex;
		}
	  ENDCG
  }
  
   //13 DD Quarter
	 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	  CGPROGRAM
	  #pragma fragmentoption ARB_precision_hint_fastest
	  #pragma vertex vert
	  #pragma fragment frag
	  
	  sampler2D _SecDepth;
	  sampler2D _DSD;
	  float4 _DTexelOffset;
	  #include "UnityCG.cginc"
		struct v2f {
			float4 pos : POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vert( appdata_img v ) {
			v2f o; 
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}
		half4 frag(v2f i) : COLOR {
			float4 tex = tex2D(_MainTex,i.uv);
			float d = 1-DecodeFloatRG(tex2D(_DSD, i.uv).zw);
			float ndepth = 1-DecodeFloatRG(tex2D (_SecDepth, i.uv).zw);
			return ceil(ndepth-d+_MinZ*_ProjectionParams.w)*tex;
		}
	  ENDCG
  }
  

}

Fallback off
}
