Shader "Hidden/RenderNormalsAndDepth" {
SubShader {
	Tags { "RenderType"="Opaque" }
	Pass {
		Fog { Mode Off }
		
CGPROGRAM
#pragma exclude_renderers gles
#pragma vertex vert
#include "UnityCG.cginc"

struct v2f {
	float4 pos : POSITION;
	float4 color : COLOR;
};

v2f vert( appdata_base v ) {
	v2f o;
	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
	o.color.rgb = viewNormal * 0.5 + 0.5;
	float z = mul(UNITY_MATRIX_MV, v.vertex).z;
	o.color.a = -z / _ProjectionParams.z;
	return o;
}

ENDCG

	}
} 
}
