Shader "Hidden/Funky Things Composite" {
Properties {
	_MainTex ("", RECT) = "white" {}
	_BlurTex ("", RECT) = "white" {}
	_ColorRamp ("", 2D) = "gray" {}
	_BlurRamp ("", 2D) = "gray" {}
}

SubShader {
	Pass {
		ZTest Always Cull Off ZWrite Off Fog { Mode off }

CGPROGRAM
#pragma exclude_renderers gles
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest 
#include "UnityCG.cginc"

uniform sampler2D _MainTex : register(s0);
uniform sampler2D _BlurTex : register(s1);
uniform sampler2D _ColorRamp : register(s2);
uniform sampler2D _BlurRamp : register(s3);

struct v2f {
	float2 uv[2] : TEXCOORD0;
};

half4 frag (v2f i) : COLOR
{
	half4 original = tex2D(_MainTex, i.uv[0]);
	
	half intensity = Luminance(original.rgb);
	half4 colorRamped = tex2D(_ColorRamp, half2(intensity, intensity));
	
	half mask = tex2D(_BlurTex, i.uv[1]).r;
	half4 maskRamped = tex2D(_BlurRamp, float2(mask,mask));
	
	half4 color = lerp (colorRamped, original, maskRamped.a);
	color.rgb *= maskRamped.rgb;
	return color;
}
ENDCG
	}
}

Fallback off

}