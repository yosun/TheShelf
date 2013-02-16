@script ExecuteInEditMode
@script RequireComponent(Camera)

var shader : Shader;

private var shaderCamera : GameObject;

function OnPostRender()
{
	if (!enabled || !gameObject.active || !shader)
		return;

	if (!shaderCamera) {
		shaderCamera = new GameObject("ShaderCamera", Camera);
		shaderCamera.camera.enabled = false;
		shaderCamera.hideFlags = HideFlags.HideAndDontSave;
	}
	
	var cam = shaderCamera.camera;
	cam.CopyFrom (camera);
	cam.backgroundColor = Color(0,0,0,0);
	cam.clearFlags = CameraClearFlags.SolidColor;
	cam.RenderWithShader (shader, "RenderType");
}

function OnDisable() {
	DestroyImmediate(shaderCamera);
}

function OnGUI() {
	GUILayout.BeginArea (Rect(5,5,300,140), null, GUI.skin.button);
	GUILayout.Label ("Renders everything with different colors based on shader's RenderType");
	GUILayout.Label ("Not that useful by itself; just shows how to replace shaders with different RenderTypes");
	GUILayout.Label ("Most of complexity in replacement shaders is to support terrain. If you don't need terrain, the replacement shaders can be much simpler.");
	GUILayout.EndArea ();
}