Shader "Chickenlord/Mobile/Bumped Specular" {
Properties {
	_KColor ("Key Color", Color) = (1,1,1,1)
	_FillColor ("Fill Color", Color) = (0.651,0.493,0.365,1)
	_BackColor ("Back Color", Color) = (0.102,0.1294,0.42,1)
	_FillAmmount("Fill Amount",Range(0,1)) = 1
	_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_LUT ("Lookup Texture (RGBA)", 2D) = "white" {}
	_GM ("Intensity Adjsutment",Float) = 1
}
SubShader { 
	Tags { "RenderType"="Opaque" }
	LOD 400
	
	Pass {
		Name "FORWARD"
		Tags { "LightMode" = "ForwardBase" }
CGPROGRAM
#pragma vertex vert_surf
#pragma fragment frag_surf
#pragma fragmentoption ARB_precision_hint_fastest
#pragma multi_compile_fwdbase nolightmap nodirlightmap noforwardadd
#include "HLSLSupport.cginc"
#define UNITY_PASS_FORWARDBASE
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#line 1
#line 14

#pragma target 2.0
#pragma exclude_renderers flash

sampler2D _MainTex;
sampler2D _BumpMap;
fixed3 _KColor;
fixed3 _BackColor;
fixed3 _FillColor;
half _FillAmmount;
sampler2D _LUT;
half _ISI;
fixed _GM;

struct Input {
	float2 uv_MainTex;
	float2 uv_BumpMap;
	half3 viewDir;
	fixed3 probes;
};

struct SurfaceOutputPS {
	fixed3 Albedo;
	fixed3 Normal;
	fixed3 DiffuseProbes;
	fixed Gloss;
	fixed Alpha;
	half3 viewDir;
};


inline fixed4 LightingBlinnPhongPS (SurfaceOutputPS s, fixed3 lightDir, fixed atten)
{
	fixed sp = (dot (s.Normal, lightDir))*0.5+0.5;
	
	half vdl = (dot (s.Normal, s.viewDir));
	half4 lut = tex2D(_LUT,float2(sp,vdl));
	half dl = lut.r;
	half bl = lut.g;
	half spec = lut.b;
	half is = lut.a;
	
	fixed4 c;
	c.rgb = _GM*s.Albedo*(spec*s.Gloss*2.6f+s.DiffuseProbes+(dl*_KColor+max(0,_FillAmmount-dl-bl)*_FillColor+bl*_BackColor));
	c.a = 0;
	return c;
}

void surf (Input IN, inout SurfaceOutputPS o) {
	fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
	o.Albedo = tex.rgb;
	o.Gloss = tex.a;
	o.Alpha = tex.a;
	o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
	o.viewDir = IN.viewDir;
	o.DiffuseProbes = IN.probes;
	
}

struct v2f_surf {
  float4 pos : SV_POSITION;
  float2 pack0 : TEXCOORD0;
  float2 pack1 : TEXCOORD1;
  float3 viewDir : TEXCOORD2;
  fixed3 worldRefl : TEXCOORD3;
  fixed3 lightDir : TEXCOORD4;
  fixed3 vlight : TEXCOORD5;
  fixed3 probes : TEXCOORD6;
  LIGHTING_COORDS(7,8)
};

float4 _MainTex_ST;
float4 _BumpMap_ST;
v2f_surf vert_surf (appdata_full v) {
  v2f_surf o;
  o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
  
  o.pack0 = TRANSFORM_TEX(v.texcoord, _MainTex);
  o.pack1 = TRANSFORM_TEX(v.texcoord, _BumpMap);
  float3 viewDir = -ObjSpaceViewDir(v.vertex);
  float3 worldN = mul((float3x3)_Object2World, SCALED_NORMAL);
  TANGENT_SPACE_ROTATION;
  
  float3 lightDir = mul (rotation, ObjSpaceLightDir(v.vertex));
  
  o.lightDir = lightDir;
  
  float3 viewDirForLight = mul (rotation, ObjSpaceViewDir(v.vertex));
  viewDirForLight = normalize(viewDirForLight);
  o.viewDir = viewDirForLight;
  
  o.vlight = 0;
  o.probes = ShadeSH9(float4(worldN,1));
  #ifdef VERTEXLIGHT_ON
  float3 worldPos = mul(_Object2World, v.vertex).xyz;
  o.vlight += Shade4PointLights (
  unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
  unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
  unity_4LightAtten0, worldPos, worldN );
  #endif // VERTEXLIGHT_ON
  
  // multipliy vertex light with lightporbes, so they fit in nicely. Not using half lighting, because it doesn't work due to the misiing tex lookup.
  o.vlight = o.vlight;
  TRANSFER_VERTEX_TO_FRAGMENT(o);
  return o;
}

fixed4 frag_surf (v2f_surf IN) : COLOR {
  Input surfIN;
  surfIN.uv_MainTex = IN.pack0;
  surfIN.uv_BumpMap = IN.pack1;
  surfIN.viewDir = IN.viewDir.xyz;
  surfIN.probes = IN.probes;
  SurfaceOutputPS o;
  o.Albedo = 0.0;
  o.DiffuseProbes = 0.0;
  o.Alpha = 0.0;
  o.Gloss = 0.0;
  surf (surfIN, o);
  fixed4 c = 0;
  c = LightingBlinnPhongPS (o, IN.lightDir,0);
  c.rgb += o.Albedo*IN.vlight;
  return c;
}

ENDCG
}

}
}