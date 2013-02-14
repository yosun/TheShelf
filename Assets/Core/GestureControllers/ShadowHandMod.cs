/*******************************************************************************

INTEL CORPORATION PROPRIETARY INFORMATION
This software is supplied under the terms of a license agreement or nondisclosure
agreement with Intel Corporation and may not be copied or disclosed except in
accordance with the terms of that agreement
Copyright(c) 2012 Intel Corporation. All Rights Reserved.

*******************************************************************************/
using UnityEngine;
using System;
public class ShadowHandMod: MonoBehaviour {
	

	
	public void	ProcessTexture(Texture2D handImage,int[] labels,byte[] labelmap){
				
	    Color32[] pixels=handImage.GetPixels32(0);
		for (int y=0, yy1=0, yy2=(handImage.height-1)*handImage.width;y<handImage.height;y++,yy1+=handImage.width,yy2-=handImage.width) {
			for (int x=0;x<handImage.width;x++) {
				int pixel=labelmap[yy1+x];
				pixels[yy2+(handImage.width-1-x)]=new Color32(0,0,0,(byte)((pixel==labels[1] || pixel==labels[2])?160:0));
			}
		}
        handImage.SetPixels32 (pixels, 0);
		handImage.Apply();
		renderer.material.mainTexture = handImage;
		//return handImage;
				
	}
	
	public void ZeroImage(Texture2D image) {
		Color32[] pixels=image.GetPixels32(0);
		for (int x=0;x<image.width*image.height;x++) pixels[x]=new Color32(255,255,255,128);
	    image.SetPixels32(pixels, 0);
		image.Apply();
	}
}
