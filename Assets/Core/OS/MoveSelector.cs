using UnityEngine;
using System.Collections;

public class MoveSelector : MonoBehaviour {
	
	IntelPerC ipc;
	TheShelfManager tsm;
	
	GameObject currentImpact=null;
	
	Zorro zorro;
	
	void Start(){
		ipc = GameObject.Find ("ReflectiveTexture").GetComponent<IntelPerC>();
		tsm = GameObject.Find ("GameObject").GetComponent<TheShelfManager>();
		zorro = GetComponent<Zorro>();
	}
	
	public void Activate(bool flip){
		if(flip)renderer.enabled=true;
		else renderer.enabled=false;
	}
	
	void Update () {
		if(tsm.GetCurrentObj()!=null){
			if(Input.GetMouseButtonDown(0))tsm.PutBack();;
			return;
		}
		if(ipc.GetCameraStatus()){
			Vector3 v = ipc.GetWorldPosition() * 30;
			MoveMe(v);
		}else{
			if(Input.GetMouseButtonDown(0)){
				if(currentImpact!=null)	
					currentImpact.GetComponent<SelectableObject>().SelectThisObject();	
			}
			
			Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
			RaycastHit hit;
			if(Physics.Raycast(ray,out hit,1000f)){
				MoveMe(hit.point);
			}
		}
	}
	
	void OnTriggerEnter(Collider col){
		if(!ipc.GetCameraStatus()){
			currentImpact = col.gameObject;
		}else{
			if(col.name=="side1"){
				if(zorro.hit1)
					zorro.hit1again=true;
				else
					zorro.hit1=true;
			}else if(col.name=="side2"){
				if(zorro.hit2)
					zorro.hit2again=true;
				else
					zorro.hit2=true;
			}
		}
	}
	
	void OnTriggerExit(){
		currentImpact = null;	
	}
	
	void MoveMe(Vector3 v){
		if(v.y>-14)v = new Vector3(v.x,-14,v.z);
		transform.position=v;
		if(tsm.GetCurrentObj()!=null)
			tsm.GetCurrentObj().transform.position = transform.position;		
	}
}
