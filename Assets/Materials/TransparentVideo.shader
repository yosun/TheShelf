Shader "TransparentVideo" 
{ 
Properties 
{ 
_MainTex ("Base (RGB)", 2D) = "white" {}
_Mask ("Culling Mask", 2D) = "white" {}
_Cutoff ("Cutoff", Range (0,1)) = .5 
} 

SubShader 
{
Tags {"Queue"="Transparent"}

ZWrite Off
Blend SrcAlpha OneMinusSrcAlpha

Pass 
{ 
CGPROGRAM 
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it does not contain a surface program or both vertex and fragment programs.
#pragma exclude_renderers gles
#pragma fragment frag 
#include "UnityCG.cginc" 

sampler2D _MainTex; 
sampler2D _Mask; 

struct v2f 
{ 
float4 pos : POSITION; 
float4 uv : TEXCOORD0; 
}; 

half4 frag (v2f i) : COLOR 
{ 
half4 color = tex2D(_MainTex, i.uv.xy); 
half4 color2 = tex2D(_Mask, i.uv.xy); 

return half4(color.r, color.g, color.b, color2.r); 
} 
ENDCG 
} 
}

Fallback "Transparent/Diffuse" 
}