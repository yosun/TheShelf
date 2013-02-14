using UnityEngine;
using System.Collections;

public class SelectableObject : MonoBehaviour {
	
	IntelPerC ipc;
	TheShelfManager tsm;
	
	void Start(){
		ipc = GameObject.Find ("ReflectiveTexture").GetComponent<IntelPerC>();
		tsm = GameObject.Find ("GameObject").GetComponent<TheShelfManager>();
	}
	
	void OnTriggerStay(Collider col){
		if(col.name=="SelectorCollider"){
			if(ipc.GetConfidence()>50){
				if(ipc.GetOpenness()<5&&ipc.GetOpenness()>=0){
					tsm.SetCurrent(this.gameObject);
				}else if(ipc.GetOpenness()>85){
					tsm.PutBack();
					return;
				}
			}
			if(tsm.GetCurrentObj()==this.gameObject){
				transform.forward = ipc.GetNormal ();
				transform.position = col.transform.position;
			}
		}
	}
	
}
