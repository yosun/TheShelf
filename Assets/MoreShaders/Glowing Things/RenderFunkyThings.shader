Shader "Hidden/RenderFunkyThings" {
SubShader {
	Tags { "RenderType"="Funky" }
	Pass {
		Fog { Mode Off }		
		Color (1,1,1,1)
	}
}
SubShader {
	Tags { "RenderType"="Opaque" }
	Pass {
		Fog { Mode Off }
		Color (0,0,0,0)
	}
} 
}
