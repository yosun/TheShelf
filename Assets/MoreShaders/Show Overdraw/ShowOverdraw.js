@script ExecuteInEditMode
@script RequireComponent(Camera)

var fullOverdraw = false;
var shaderWithZ : Shader;
var shaderWithoutZ : Shader;

private var oldColor : Color;
private var oldClear : CameraClearFlags;

function OnPreCull()
{
	if (!enabled)
		return;
	oldColor = camera.backgroundColor;
	oldClear = camera.clearFlags;
	camera.backgroundColor = Color(0,0,0,0);
	camera.clearFlags = CameraClearFlags.SolidColor;
	camera.SetReplacementShader (fullOverdraw ? shaderWithoutZ : shaderWithZ, "RenderType");
}

function OnPostRender() {
	if (!enabled)
		return;
	camera.ResetReplacementShader();
	camera.backgroundColor = oldColor;
	camera.clearFlags = oldClear;
}
