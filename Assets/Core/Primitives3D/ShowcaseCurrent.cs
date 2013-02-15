using UnityEngine;
using System.Collections;

public class ShowcaseCurrent : MonoBehaviour {
	
	Vector3 posShowcase = new Vector3(-0.5759082f,-9.067602f,0.1078462f);
	Vector3 posVFont = new Vector3(1.247647f,-17.08975f,-1.230876f);
	GameObject goVFont; 
	
	Vector3 rotateDir=Vector3.zero;
	
	IntelPerC ipc;
	
	public GameObject goVFontDir;
	
	public GameObject goBGFade;
	public Camera cam;
	
	TheShelfManager tsm;
	
	void Start(){
		tsm = GetComponent<TheShelfManager>();	
		goVFont = GameObject.Find ("VFont").gameObject;
		ipc = GameObject.Find ("ReflectiveTexture").GetComponent<IntelPerC>();
	}
	
	void Update(){
		if(tsm.GetCurrentObj()==null){
			cam.fieldOfView=12;
			goBGFade.renderer.enabled=false;
			goVFontDir.active=false;
		}else{
			if(!ipc.GetCameraStatus()){
				Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
				RaycastHit hit;
				if(Physics.Raycast(ray,out hit,1000f)){print (hit.transform.name);
					FreeRotate (hit.point,tsm.GetCurrentObj());
				}
			}else{
				string s = ObjectManipulateDictionary.SanitizeDictation(ipc.GetDictation ());
				ipc.ResetDictation();
				if(s!="UNKNOWN"){print ("S "+s);
					if(s=="ROTATE"){
						rotateDir = new Vector3(0,1f,0);
					}else if(s=="FREEZE"){
						rotateDir = Vector3.zero;
					}else{
						string[] sarr = s.Split ("|"[0]);
						if(sarr[0]=="ROTATE"){
							if(sarr[1]=="X"){
								rotateDir = new Vector3(1f,0,0);
							}else if(sarr[1]=="Y"){
								rotateDir = new Vector3(0,1f,0);
							}else if(sarr[1]=="Z"){
								rotateDir = new Vector3(0,0,1f);
							}
						}
					}
				}
				if(rotateDir!=Vector3.zero)
					tsm.GetCurrentObj().transform.Rotate (rotateDir*Time.deltaTime*20f);
				else
					tsm.GetCurrentObj().transform.up = -ipc.GetNormal ();
				//if(rotateDir!=Vector3.zero)print (tsm.GetCurrentObj().transform.name+" "+rotateDir + " "+tsm.GetCurrentObj().transform.rotation);
			}
			
			if(!tsm.GetNewlySelectedBool())
				return;
			
			GameObject g = tsm.GetCurrentObj();
			g.transform.localPosition = posShowcase;
			goBGFade.renderer.enabled=true; goVFontDir.active=true;
			cam.fieldOfView=5;
			goVFont.transform.position = posVFont;
		}
	}
	
Vector3 LookerVector;
Vector3 LookerVectorStart;

public  void FreeRotate(Vector3 CurrentPos,GameObject Looker)
{
	Looker.transform.LookAt(CurrentPos);
	LookerVector = Looker.transform.rotation.eulerAngles;
	Vector3 LookOffset = (LookerVector -LookerVectorStart);
	// Not sure why x needs to be negative but it does for me!
	LookOffset = new Vector3 ( -LookOffset.x, LookOffset.y, LookOffset.z);
	Looker.transform.Rotate( LookOffset, Space.World);
	LookerVectorStart = LookerVector;

}
	

}