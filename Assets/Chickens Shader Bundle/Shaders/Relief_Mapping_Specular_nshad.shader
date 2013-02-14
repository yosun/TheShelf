Shader "Chickenlord/Relief Mapping Specular" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
	_Parallax ("Height", Range (0.005, 0.18)) = 0.02
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_ParallaxMap ("Heightmap (A)", 2D) = "black" {}
}
SubShader { 
	Tags {"Queue"="Geometry" "IgnoreProjector"="false" "RenderType"="Opaque"}
	LOD 600
	ZWrite On
	CGPROGRAM

	#define LINEAR_STEPS 20
	#define BINARY_STEPS 6

	#pragma surface surf BlinnPhong addshadow fullforwardshadows
	#pragma target 3.0
	//#pragma only_renderers d3d9

	sampler2D _MainTex;
	sampler2D _BumpMap;
	sampler2D _ParallaxMap;
	fixed4 _Color;
	half _Shininess;
	float _Parallax;

	struct Input {
		float2 uv_MainTex;
		float2 uv_BumpMap;
		float3 viewDir;
	};

	inline float3 BinaryRefine(sampler2D heightTex, float3 p,float3 off)
	{	
		for(int i = 0; i<BINARY_STEPS;i++)
		{
			off *= 0.5;
			half tex = tex2D(heightTex,p.xy).a;
			if(p.z<tex)
			{
				p += off;
			}
			else
			{
				p -= off;
			}
		}
		return p;
	}

	inline float2 RealOffset(float2 uv,sampler2D heightTex,half h,float3 viewDir,float height)
	{
		float3 offset = float3(uv,0);
		float xxx = 1-viewDir.z;
		xxx = 1-(pow(xxx,3));
		float3 off = normalize(viewDir*-1);
		off.z = abs(viewDir.z);
		off.xy *= (xxx*height);
		off /= (viewDir.z*LINEAR_STEPS);
		float3 tvec = float3(uv,0);
		half nh = 0;
		for(int i = 0; i<LINEAR_STEPS;i++)
		{
			nh = tex2D(heightTex,tvec.xy).a;
			if(tvec.z < nh)
			{
				tvec += off;
			}
		}
		offset = BinaryRefine(heightTex,tvec,off);
		float2 ret = offset.xy-uv;
		return ret;
	}

	void surf (Input IN, inout SurfaceOutput o) {
		
		half h = tex2D (_ParallaxMap, IN.uv_BumpMap).w;
		float2 ox = RealOffset(IN.uv_BumpMap,_ParallaxMap,h,normalize(IN.viewDir),_Parallax);
		float2 origUV = IN.uv_BumpMap;
		IN.uv_MainTex += ox;
		IN.uv_BumpMap += ox;
		fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
		o.Albedo = tex.rgb * _Color.rgb;
		o.Gloss = tex.a;
		o.Alpha = 1;
		o.Specular = _Shininess;
		o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));
	}
	ENDCG
	}

FallBack "Bumped Specular"
}
