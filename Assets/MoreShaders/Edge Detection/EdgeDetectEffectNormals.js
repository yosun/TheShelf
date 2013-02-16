@script ExecuteInEditMode

class EdgeDetectEffectNormals extends ImageEffectBase
{	
	var activated:boolean=true;

	function Start() {
		camera.depthTextureMode = DepthTextureMode.DepthNormals;
	}
	
	public function ActivateToggle(flip:boolean){
		activated=flip;
	}
		
	function OnRenderImage (source : RenderTexture, destination : RenderTexture)
	{
	if(activated)
		ImageEffects.BlitWithMaterial (material, source, destination);
	}
}
