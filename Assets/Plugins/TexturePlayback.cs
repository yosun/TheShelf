/*******************************************************************************

INTEL CORPORATION PROPRIETARY INFORMATION
This software is supplied under the terms of a license agreement or nondisclosure
agreement with Intel Corporation and may not be copied or disclosed except in
accordance with the terms of that agreement
Copyright(c) 2012 Intel Corporation. All Rights Reserved.

*******************************************************************************/
using UnityEngine;
using System;
using System.Runtime.InteropServices;

public class TexturePlayback : MonoBehaviour {
    private Texture2D 			m_Texture;
	private PXCUPipeline 		pp;
    private int[] 				size=new int[2]{0,0};
	private PXCUPipeline.Mode 	mode=PXCUPipeline.Mode.GESTURE;
	
    void Start () {
		pp=new PXCUPipeline();
		if (!pp.Init(mode)) {
			print("Unable to initialize the PXCUPipeline");
			return;
		}
		
		//pp.SetVoiceCommands(new string[]{ "one", "two", "three" });
		
        if (pp.QueryLabelMapSize(size))
	        print("LabelMap: width=" + size[0] + ", height=" + size[1]);
		else if (pp.QueryRGBSize(size))
			print("RGB: width="+size[0]+", height="+size[1]);
		
		if (size[0]>0) {
			m_Texture = new Texture2D (size[0], size[1], TextureFormat.ARGB32, false);
	        renderer.material.mainTexture = m_Texture;
		}
    }
    
    void OnDisable() {
		pp.Close();
		pp.Dispose();
    }

    void Update () {
		if (!pp.AcquireFrame(false)) return;

		if (pp.QueryLabelMapAsImage(m_Texture)) 
			m_Texture.Apply();
		else if (pp.QueryRGB(m_Texture)) 
			m_Texture.Apply();
		
		for (int i=0;;i++) {
			int face; ulong timeStamp;
			if (!pp.QueryFaceID(i,out face, out timeStamp)) break;
			print("face "+i+" (id=" + face + ", timeStamp=" + timeStamp+")");
				
			PXCMFaceAnalysis.Detection.Data ddata;
			if (pp.QueryFaceLocationData(face,out ddata))
				print ("\tlocation(id="+face+", x="+ddata.rectangle.x+", y="+ddata.rectangle.y+", w="+ddata.rectangle.w+", h="+ddata.rectangle.h+")");

			PXCMFaceAnalysis.Landmark.LandmarkData ldata;
			if (pp.QueryFaceLandmarkData(face, PXCMFaceAnalysis.Landmark.Label.LABEL_NOSE_TIP, 0, out ldata))
				print ("\tleft-eye (id="+face+", x="+ldata.position.x+", y="+ldata.position.y+")");
		}
		
		PXCMGesture.GeoNode ndata;
		if (pp.QueryGeoNode(PXCMGesture.GeoNode.Label.LABEL_BODY_HAND_LEFT|PXCMGesture.GeoNode.Label.LABEL_HAND_MIDDLE,out ndata))
			print ("geonode left-hand (x="+ndata.positionImage.x+", y="+ndata.positionImage.y+")");
		
		PXCMGesture.Gesture gdata;
		if (pp.QueryGesture(PXCMGesture.GeoNode.Label.LABEL_ANY, out gdata))
			print ("gesture (label="+gdata.label+")");
		
		PXCMVoiceRecognition.Recognition rdata;
		if (pp.QueryVoiceRecognized(out rdata))
			print ("voice rec (label="+rdata.label+",size="+rdata.dictation.Length+", dictation="+rdata.dictation+")");
		
		pp.ReleaseFrame();
    }
}
