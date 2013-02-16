Shader "Hidden/Render Overdraw Z" {
SubShader {
	Tags { "RenderType"="Opaque" }
	Pass {
		Fog { Mode Off }
		Blend One One
		Color (0.1, 0.04, 0.02, 0)		
	}
} 
SubShader {
	Tags { "RenderType"="Transparent" }
	Pass {
		Fog { Mode Off }
		ZWrite Off Cull Off Blend One One
		Color (0.1, 0.04, 0.02, 0)		
	}
} 
}
