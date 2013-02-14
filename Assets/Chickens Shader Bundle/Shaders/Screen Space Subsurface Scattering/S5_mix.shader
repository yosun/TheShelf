Shader "Hidden/S5" {
Properties {
	_MainTex ("", 2D) = "" {}
	_MainTex2 ("", 2D) = "" {}
	_SSAO ("", 2D) = "" {}
	_Bl1 ("", 2D) = "" {}
	_Bl2 ("", 2D) = "" {}
	_Bl3 ("", 2D) = "" {}
	_Bl4 ("", 2D) = "" {}
	_Bl5 ("", 2D) = "" {}
	_SecDepth ("", 2D) = "" {}
	_direct ("",Vector) = (0,0,0,0)
	_b1 ("",Vector) = (0,0,0,0)
	_b2 ("",Vector) = (0,0,0,0)
	_b3 ("",Vector) = (0,0,0,0)
	_b4 ("",Vector) = (0,0,0,0)
	_b5 ("",Vector) = (0,0,0,0)
}
Subshader {
	ZTest Always Cull Off ZWrite Off Fog { Mode Off }

CGINCLUDE
#define NUM_BLUR_SAMPLES 7
#include "UnityCG.cginc"
#pragma exclude_renderers gles

uniform float2 _NoiseScale;
float4 _CameraDepthNormalsTexture_ST;
float4 _SecDepth_ST;
float Forward_S5;

sampler2D _MainTex;
sampler2D _MainTex2;
sampler2D _SecDepth;
sampler2D _RandomTexture;
sampler2D _CameraDepthNormalsTexture;
float4 _direct;
float4 _b1;
float4 _b2;
float4 _b3;
float4 _b4;
float4 _b5;
ENDCG

// ---- Blur pass
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 3.0
#pragma fragmentoption ARB_precision_hint_fastest
#include "UnityCG.cginc"

struct v2f {
	float4 pos : POSITION;
	float2 uv : TEXCOORD0;
};

float4 _MainTex_ST;

v2f vert (appdata_img v)
{
	v2f o;
	o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
	o.uv = v.texcoord.xy;
	return o;
}

sampler2D _SSAO;
float3 _TexelOffsetScale;
//SecDepth
inline half CheckSame (half4 n, half4 nn)
{
	// difference in normals
	half2 diff = abs(n.xy - nn.xy);
	half sn = (diff.x + diff.y) < 0.0001;
	// difference in depth
	float z = DecodeFloatRG (n.zw);
	float zz = DecodeFloatRG (nn.zw);
	float zdiff = abs(z-zz) * _ProjectionParams.z;
	half sz = zdiff < 0.0001;
	return sn * sz;
}


half4 frag( v2f i ) : COLOR
{
	
    float2 o = _TexelOffsetScale.xy;
    
    half4 sum = tex2D(_SSAO, i.uv);
	
	sum *= (NUM_BLUR_SAMPLES + 1);
    half denom = NUM_BLUR_SAMPLES + 1;
    
    half4 geom = tex2D (_SecDepth, i.uv);
	float temp = DecodeFloatRG(geom.zw)*_ProjectionParams.z;
    o /= temp;
    for (int s = 0; s < NUM_BLUR_SAMPLES; ++s)
    {
        float2 nuv = i.uv + o * (s+1);
        half4 ngeom = tex2D (_SecDepth, nuv.xy);
        half coef = (NUM_BLUR_SAMPLES - s) * CheckSame (geom, ngeom);
        sum += tex2D (_SSAO, nuv.xy) * coef;
        denom += coef;
    }
    for (int s = 0; s < NUM_BLUR_SAMPLES; ++s)
    {
        float2 nuv = i.uv - o * (s+1);
        half4 ngeom = tex2D (_SecDepth, nuv.xy);
        half coef = (NUM_BLUR_SAMPLES - s) * CheckSame (geom, ngeom);
        sum += tex2D (_SSAO, nuv.xy) * coef;
        denom += coef;
    }
    sum /= denom;
	return sum;
}
ENDCG
}
	
	// ---- Composite pass
	Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest
#pragma target 3.0
#include "UnityCG.cginc"

struct v2f {
	float4 pos : POSITION;
	float2 uv[2] : TEXCOORD0;
};

v2f vert (appdata_img v)
{
	v2f o;
	o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
	
	o.uv[0] = v.texcoord.xy;
	o.uv[1] = o.uv[0];
	if(Forward_S5<0.5)
	{
		o.uv[0].y = 1-o.uv[0].y;
	}
	
	#if !defined (UNITY_UV_STARTS_AT_TOP)
	o.uv[1].y = 1-o.uv[1].y;
	#endif
	
	
	return o;
}

sampler2D _SSAO;

sampler2D _Bl1;
sampler2D _Bl2;
sampler2D _Bl3;
sampler2D _Bl4;
sampler2D _Bl5;

inline half CheckSame (half4 n, half4 nn)
{
	// difference in normals
	half2 diff = abs(n.xy - nn.xy);
	half sn = (diff.x + diff.y) < 0.1;
	// difference in depth
	float z = DecodeFloatRG (n.zw);
	float zz = DecodeFloatRG (nn.zw);
	float zdiff = abs(z-zz) * _ProjectionParams.z;
	half sz = zdiff < 0.2;
	return sn * sz;
}


half4 frag( v2f i ) : COLOR
{
	half4 albedo = tex2D (_MainTex2, i.uv[0]);
	half4 albedo2 = tex2D (_MainTex, i.uv[1]);
	half4 c = tex2D (_SSAO, i.uv[0]);
	half4 cb1 = tex2D (_Bl1, i.uv[0]);
	half4 cb2 = tex2D (_Bl2, i.uv[0]);
	half4 cb3 = tex2D (_Bl3, i.uv[0]);
	half4 cb4 = tex2D (_Bl4, i.uv[0]);
	half4 cb5 = tex2D (_Bl5, i.uv[0]);
	half4 OrigDepth = tex2D (_CameraDepthNormalsTexture, i.uv[0]);
	half4 SecDepth = tex2D (_SecDepth, i.uv[0]);
	
	
	half blending = clamp(CheckSame(OrigDepth,SecDepth),0,1);
	half3 blurred = 0;
	
	
	
	blurred+= cb1*(float3)_b1;
	blurred+= cb2*(float3)_b2;
	blurred+= cb3*(float3)_b3;
	blurred+= cb4*(float3)_b4;
	blurred+= cb5*(float3)_b5;
	
	half3 ret = c*_direct+blurred + UNITY_LIGHTMODEL_AMBIENT;
	ret = blending*ret;
	return half4(ret,1)*albedo+ blending*c.a*_direct*1.33 + (1-blending)*albedo2;
	//return cb1;
}
ENDCG
}

// -- CopyPass
		Pass {
 			ZTest Always Cull Off ZWrite Off Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "UnityCG.cginc"
			
			inline half CheckSame (half4 n, half4 nn)
			{
				// difference in normals
				half2 diff = abs(n.xy - nn.xy);
				half sn = (diff.x + diff.y) < 0.1;
				// difference in depth
				float z = DecodeFloatRG (n.zw);
				float zz = DecodeFloatRG (nn.zw);
				float zdiff = abs(z-zz) * _ProjectionParams.z;
				half sz = zdiff < 0.2;
				return sn * sz;
			}

			
			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : POSITION;
				float2 texcoord[2] : TEXCOORD0;
			};

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.texcoord[0] = v.texcoord.xy;
				o.texcoord[1] = ComputeScreenPos(o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : COLOR
			{
				half4 OrigDepth = tex2D (_CameraDepthNormalsTexture, i.texcoord[1]);
				half4 SecDepth = tex2D (_SecDepth, i.texcoord[1]);
				float4 tex = tex2D(_MainTex, i.texcoord[0]);
				return tex*CheckSame(OrigDepth,SecDepth);
				//return SecDepth;
			}
			ENDCG 

		}
		
// -- DepthTextureCopy
		Pass {
 			ZTest Always Cull Off ZWrite Off Fog { Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "UnityCG.cginc"
			
			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.texcoord = ComputeScreenPos(o.vertex);
				o.texcoord.y = 1-o.texcoord.y;
				return o;
			}

			fixed4 frag (v2f i) : COLOR
			{
				half4 OrigDepth = tex2D (_CameraDepthNormalsTexture, i.texcoord);
				return OrigDepth;
			}
			ENDCG 

		}

}

Fallback off
}
