using UnityEngine;
using System.Collections;

public class SelectableObject : MonoBehaviour {
	
	IntelPerC ipc;
	TheShelfManager tsm;
	
	public bool delayReturn=false;
	
	bool openedInside=false;
	float timeOpenCounter=-1f;
	
	void Start(){
		ipc = GameObject.Find ("ReflectiveTexture").GetComponent<IntelPerC>();
		tsm = GameObject.Find ("GameObject").GetComponent<TheShelfManager>();
	}
	
	void OnTriggerStay(Collider col){//print (col.name);
		if(col.name=="SelectorCollider"){
			//if(ipc.GetConfidence()>50){
				print (ipc.GetOpenness());
				if(ipc.GetClosedCertain()){//print ("Closed Certain "+gameObject.name);
					if(openedInside){
					//print ("opened inside select "+gameObject.name);
						openedInside=false;
						timeOpenCounter=-1f;
						SelectThisObject ();
					}
				}else if(ipc.GetConfidence()>70&&ipc.GetOpenness()>55) {
					openedInside=true;
					timeOpenCounter=0f;
					//print ("Open Certain "+gameObject.name);
				}/*else if(ipc.GetOpenCertain()){
					tsm.PutBack();
					return;
				}*/
			//}
			timeOpenCounter += Time.deltaTime;
		}
	}
	
	void OnTriggerExit(Collider col){
		openedInside=false;
		timeOpenCounter=-1f;
		print ("Reset "+gameObject.name);
	}
	
	void Update(){
			if(tsm.GetCurrentObj()==this.gameObject){
				
				//transform.position = col.transform.position;
				if(ipc.GetOpenCertain()){//print ("BOO");
					if(!delayReturn)
						tsm.PutBack();
					return;
				}
			}		
	}
	
	public void SelectThisObject(){
		tsm.SetCurrent(this.gameObject);
		ActivateFurtherActions();
	}
	
	void ActivateFurtherActions(){
		// activate child gameobject for further action	
		
	}
	
}
