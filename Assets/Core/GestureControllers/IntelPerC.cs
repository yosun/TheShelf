using UnityEngine;
using System.Collections;

public class IntelPerC : MonoBehaviour {
	
	// v0.1 
	// voice - dictation/resetdictation 
	// gesture - returns conf, openness, worldposition, normal
	
	public Texture2D 			m_Texture;
	private PXCUPipeline 		pp;
    private int[] 				size=new int[2]{0,0};
	private PXCUPipeline.Mode 	mode=PXCUPipeline.Mode.GESTURE | PXCUPipeline.Mode.VOICE_RECOGNITION | PXCUPipeline.Mode.FACE_LOCATION ;
	
	int openness=-1; int confidence=0;
	Vector3 worldPosition=Vector3.zero;
	Vector3 normal=Vector3.zero;
	
	uint faceConfidence=0;
	PXCMFaceAnalysis.Detection.ViewAngle faceViewAngle=PXCMFaceAnalysis.Detection.ViewAngle.VIEW_ANGLE_OMNI;
	Vector2 faceRectCenter=Vector2.zero;
	
	bool cameraFound=false;
	
	int[] labels=new int[3]{0,256,256};
	byte[] labelmap;
	
	ShadowHandMod shm;
	
	string dictation="DUNNO";
	
	public bool GetCameraStatus(){
		return cameraFound;	
	}
	public uint GetFaceConfidence(){
		return faceConfidence;	
	}
	public Vector2 GetFaceRectCenter(){
		return faceRectCenter;	
	}
	
	public bool GetClosedCertain(){
		if(openness<5&&openness>=0&&confidence>80)return true;
		else return false;
	}
	public bool GetOpenCertain(){
		if(confidence>80&&openness>80)return true;
		else return false;
	}
	public int GetOpenness(){
		return openness;
	}
	public int GetConfidence(){
		return confidence;	
	}
	public Vector3 GetWorldPosition(){
		return worldPosition;	
	}
	public Vector3 GetNormal(){
		return normal;	
	}
	public string GetDictation(){
		return dictation;	
	}
	public void ResetDictation(){
		dictation="DUNNO";	
	}
	
	void Start () {
		pp=new PXCUPipeline();
		shm=GetComponent<ShadowHandMod>();
		
		if (!pp.Init(mode)) {
			print("Unable to initialize the PXCUPipeline");
			cameraFound=false;
			return;
		}else 
			cameraFound=true;
		
        if (pp.QueryLabelMapSize(size))
	        print("LabelMap: width=" + size[0] + ", height=" + size[1]);
		
		if (size[0]>0) {
			m_Texture = new Texture2D (size[0], size[1], TextureFormat.ARGB32,false);
	        renderer.material.mainTexture = m_Texture;
			
			labelmap=new byte[size[0]*size[1]];
			
			//shm.ZeroImage(m_Texture);
		}	
	}
	
	void Update () {
		if (!pp.AcquireFrame(false)) return;

		if (pp.QueryLabelMapAsImage(m_Texture)) 
			m_Texture.Apply();	
			
		/*int[] labels=new int[3]{0,256,256};
		pp.QueryLabelMap(labelmap,labels);
		shm.ProcessTexture(m_Texture,labels,labelmap);	*/
	   			
		// face stuff
		int face; ulong timestamp;
		if(pp.QueryFaceID(0,out face,out timestamp)){
			PXCMFaceAnalysis.Detection.Data datafacedetect;
			if(pp.QueryFaceLocationData(face,out datafacedetect)){
				faceConfidence = datafacedetect.confidence;
				faceViewAngle = datafacedetect.viewAngle;
				faceRectCenter = new Vector2(datafacedetect.rectangle.x,datafacedetect.rectangle.y);
				//print (faceRectCenter+" "+faceConfidence);
			}
		}
		/*
		 * GeoNode 
		 * timeStamp
		 * user
		 * body - LABEL
		 * side - Side	
		 * confidence - 0 to 100
		 * positionWorld - node pos, world coords
		 * positionImage - node pos, image specific (x,y,d)
		 * 
		 * finger tip
		 * radiusWorld - volume of fingertip 3D in meters
		 * radiusImage - volume of fingertip in 2D in pixels
		 * 
		 * hand/palm
		 * normal - vec perp palm center
		 * openness - 0 to 100
		 * opennessState - Openness.LABEL_OPEN,_CLOSE,_OPENNESS_ANY (unknown)
		 		 **/

		PXCMGesture.GeoNode gnode;
		if (pp.QueryGeoNode(PXCMGesture.GeoNode.Label.LABEL_BODY_HAND_PRIMARY,out gnode)){
			openness = (int)gnode.openness;
			worldPosition = new Vector3(gnode.positionWorld.x,-gnode.positionWorld.y,gnode.positionWorld.z);
			normal = new Vector3(gnode.normal.x,gnode.normal.y,gnode.normal.z);
			confidence = (int)gnode.confidence;
		}
		
		PXCMVoiceRecognition.Recognition rdata;
		if (pp.QueryVoiceRecognized(out rdata)){
			print ("voice rec (label="+rdata.label+","+rdata.confidence+",size="+rdata.dictation.Length+", dictation="+rdata.dictation+")");
			dictation = rdata.dictation;
		}
		
		pp.ReleaseFrame();		
	}
	
    void OnDisable() {
		pp.Close();
		pp.Dispose();
	}
	
}
