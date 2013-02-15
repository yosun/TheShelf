using UnityEngine;
using System.Collections;

public class SelectableObject : MonoBehaviour {
	
	IntelPerC ipc;
	TheShelfManager tsm;
	
	void Start(){
		ipc = GameObject.Find ("ReflectiveTexture").GetComponent<IntelPerC>();
		tsm = GameObject.Find ("GameObject").GetComponent<TheShelfManager>();
	}
	
	void OnTriggerStay(Collider col){//print (col.name);
		if(col.name=="SelectorCollider"){
			//if(ipc.GetConfidence()>50){
				if(ipc.GetClosedCertain()){
					SelectThisObject ();
				}else if(ipc.GetOpenCertain()){
					tsm.PutBack();
					return;
				}
			//}
		}
	}
	
	void Update(){
			if(tsm.GetCurrentObj()==this.gameObject){
				
				//transform.position = col.transform.position;
				if(ipc.GetOpenCertain()){
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
