Shader "Hidden/Show Render Types" {
Properties {
	_MainTex ("Base", 2D) = "white" {}
	_Cutoff ("Cutoff", float) = 0.5
	_Color ("Color", Color) = (1,1,1,1)
}
Category {
	Fog { Mode Off }

SubShader {
	Tags { "RenderType"="Opaque" }
	Pass {
		Lighting On
		Material {
			Diffuse (1.0,0.4,0.4,0)
			Ambient (1.0,0.4,0.4,0)
		}
	}
}

SubShader {
	Tags { "RenderType"="Transparent" }
	Pass {
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Color (0.5,0.5,1.0,0.5)
	}
}

SubShader {
	Tags { "RenderType"="TransparentCutout" }
	Pass {
		AlphaTest Greater [_Cutoff]
		SetTexture[_MainTex] { constantColor(0.3,0.3,1.0,0.5) combine constant, texture }
	}
}

SubShader {
	Tags { "RenderType"="TreeOpaque" }
	Pass {
		
CGPROGRAM
#pragma exclude_renderers gles
#pragma vertex vert
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"

struct v2f {
	float4 pos : POSITION;
	float4 color : COLOR;
};
struct appdata {
    float4 vertex : POSITION;
    float4 color : COLOR;
};
v2f vert( appdata v ) {
	v2f o;
	TerrainAnimateTree(v.vertex, v.color.w);
	o.pos = mul( UNITY_MATRIX_MVP, v.vertex );
	o.color = float4(0.6,1,0.5,0);
	return o;
}
ENDCG
	}
} 

SubShader {
	Tags { "RenderType"="TreeTransparentCutout" }
	Pass {
		Cull Off
CGPROGRAM
#pragma exclude_renderers gles
#pragma vertex vert
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"

struct v2f {
	float4 pos : POSITION;
	float4 color : COLOR;
	float4 uv : TEXCOORD0;
};
struct appdata {
    float4 vertex : POSITION;
    float4 color : COLOR;
    float4 texcoord : TEXCOORD0;
};
v2f vert( appdata v ) {
	v2f o;
	TerrainAnimateTree(v.vertex, v.color.w);
	o.pos = mul( UNITY_MATRIX_MVP, v.vertex );
	o.uv = v.texcoord;
	o.color = float4(0.3,0.8,0.3,0);
	return o;
}
ENDCG
		AlphaTest GEqual [_Cutoff]
		SetTexture [_MainTex] { combine primary, texture }
	}
}

SubShader {
	Tags { "RenderType"="TreeBillboard" }
	Pass {
		Cull Off
		
CGPROGRAM
#pragma exclude_renderers gles
#pragma vertex vert
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"

struct v2f {
	float4 pos : POSITION;
	float4 color : COLOR;
	float2 uv : TEXCOORD0;
};

v2f vert (appdata_tree_billboard v) {
	v2f o;
	TerrainBillboardTree(v.vertex, v.texcoord1.xy, v.texcoord.y);
	o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
	o.uv.x = v.texcoord.x;
	o.uv.y = v.texcoord.y > 0;
	o.color = float4(0.1,0.6,0.1,0);
	return o;
}
ENDCG
		AlphaTest Greater 0
		SetTexture [_MainTex] { combine primary, texture }
	}
}


SubShader {
	Tags { "RenderType"="GrassBillboard" }
	Pass {
		Cull Off
		
CGPROGRAM
#pragma exclude_renderers gles
#pragma vertex vert
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"

struct v2f {
	float4 pos : POSITION;
	float4 color : COLOR;
	float2 uv : TEXCOORD0;
};

v2f vert (appdata_full v) {
	v2f o;
	WavingGrassBillboardVert (v);
	o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
	o.uv = v.texcoord;
	o.color = float4(0.9,0.4,0.2,1);
	return o;
}
ENDCG
		AlphaTest Greater [_Cutoff]
		SetTexture [_MainTex] { combine primary, texture }
	}
}

SubShader {
	Tags { "RenderType"="Grass" }
	Pass {
		Cull Off
		
CGPROGRAM
#pragma exclude_renderers gles
#pragma vertex vert
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"

struct v2f {
	float4 pos : POSITION;
	float4 color : COLOR;
	float2 uv : TEXCOORD0;
};

v2f vert (appdata_full v) {
	v2f o;
	WavingGrassVert (v);
	o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
	o.uv = v.texcoord;
	o.color = float4(0.9,0.5,0.3,1);
	return o;
}
ENDCG
		AlphaTest Greater [_Cutoff]
		SetTexture [_MainTex] { combine primary, texture * primary }
	}
}

}
}
