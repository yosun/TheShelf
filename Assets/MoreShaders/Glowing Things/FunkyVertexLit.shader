Shader "VertexLit Funky" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB)", 2D) = "white" {}
}

SubShader {
	Tags { "RenderType"="Funky" }
	
	Pass {
		Material {
			Diffuse [_Color]
			Ambient [_Color]
		} 
		Lighting On
		SetTexture [_MainTex] {
			Combine texture * primary DOUBLE, texture * primary
		} 
	}
}
}
