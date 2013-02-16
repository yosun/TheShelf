using UnityEngine;
using System.Collections;

public class ThePrimitives : MonoBehaviour {
	
	IntelPerC ipc;
	TheShelfManager tsm;
	
	public Material matGraphite;
	public Material matToon;
	
	public Camera cam;
	
	public GameObject goParent; 
	
	float voiceOverride=0f;
		
	void Start(){
		ipc = GetComponent<IntelPerC>();
		tsm = GameObject.Find ("GameObject").GetComponent<TheShelfManager>();
	}
	
	void Update(){
		if(tsm.GetCurrentObj()!=null){
			voiceOverride-=Time.deltaTime;
			if(voiceOverride>0)
				tsm.GetCurrentObj().GetComponent<SelectableObject>().delayReturn=true;
			else 
				tsm.GetCurrentObj().GetComponent<SelectableObject>().delayReturn=false;
			return;
		}
		
		string s = PrimitivesDictionary.SanitizeDictation(ipc.GetDictation ());
		ipc.ResetDictation();
		if(s=="GRAPHITE")
			ApplyShader(matGraphite);
		else if(s=="CARTOON")
			ApplyShader(matToon);
		else{
			if(s!="DUNNO"){
				print ("Finding "+s);
				GameObject go = goParent.transform.Find (s).gameObject;	
				if(go!=null){print ("Found "+s);
					tsm.SetCurrent(go);
					voiceOverride=5f;
				}else print ("Cannot find "+s);
			}
		}
	}
	
	void ApplyShader(Material m){
		for(int i=0;i<goParent.transform.childCount;i++){
			GameObject go = goParent.transform.GetChild (i).gameObject;	
			go.renderer.material = m;
		}
			if(m==matToon){
				cam.gameObject.GetComponent<EdgeDetectFXNormals>().activated=true;
				cam.transform.rotation = Quaternion.Euler(270,180,180);
			}else {
				cam.gameObject.GetComponent<EdgeDetectFXNormals>().activated=false;
				cam.transform.rotation = Quaternion.Euler(270,180,0);
			}		
	}
	
}
