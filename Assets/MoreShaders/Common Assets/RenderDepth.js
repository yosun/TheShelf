@script RequireComponent(Camera)

var depthShader : Shader;

private var renderTexture : RenderTexture;
private var shaderCamera : GameObject;

function Start() {
	if (!SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.Depth)) {
		enabled = false;
		return;
	}
	if (!depthShader || !depthShader.isSupported) {
		enabled = false;
		return;
	}
}

function OnDisable() {
	DestroyImmediate(shaderCamera);
}

function OnPreCull()
{
	if (!enabled || !gameObject.active)
		return;
	renderTexture = RenderTexture.GetTemporary (camera.pixelWidth, camera.pixelHeight, 24, RenderTextureFormat.Depth);
	if (!shaderCamera) {
		shaderCamera = new GameObject("ShaderCamera", Camera);
		shaderCamera.camera.enabled = false;
		shaderCamera.hideFlags = HideFlags.HideAndDontSave;
	}
	
	var cam = shaderCamera.camera;
	cam.CopyFrom (camera);
	cam.backgroundColor = Color(1,1,1,1);
	cam.clearFlags = CameraClearFlags.SolidColor;
	cam.targetTexture = renderTexture;
	cam.RenderWithShader (depthShader, "RenderType");
	
	Shader.SetGlobalTexture ("_GlobalDepthTexture", renderTexture);
	Shader.SetGlobalVector ("_GlobalDepthTextureSize", Vector4(renderTexture.width, renderTexture.height, 0, 0));
}

function OnPostRender()
{
	if (!enabled || !gameObject.active)
		return;
	RenderTexture.ReleaseTemporary (renderTexture);
}
