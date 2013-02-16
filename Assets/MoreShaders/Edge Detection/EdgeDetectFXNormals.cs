using UnityEngine;
using System.Collections;

public class EdgeDetectFXNormals : ImageEffectBase {




	public bool activated=true;

	void Start() {
		camera.depthTextureMode = DepthTextureMode.DepthNormals;
	}
	
	public void ActivateToggle(bool flip){
		activated=flip;
	}
		
	void OnRenderImage (RenderTexture source,  RenderTexture destination)
	{
	if(activated)
		ImageEffects.BlitWithMaterial (material, source, destination);
	}


}
