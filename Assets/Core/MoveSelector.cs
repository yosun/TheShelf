using UnityEngine;
using System.Collections;

public class MoveSelector : MonoBehaviour {
	
	IntelPerC ipc;
	TheShelfManager tsm;
	
	void Start(){
		ipc = GameObject.Find ("ReflectiveTexture").GetComponent<IntelPerC>();
		tsm = GameObject.Find ("GameObject").GetComponent<TheShelfManager>();
	}
	
	public void Activate(bool flip){
		if(flip)renderer.enabled=true;
		else renderer.enabled=false;
	}
	
	void Update () {
		transform.position = ipc.GetWorldPosition() * 10;
		if(tsm.GetCurrentObj()!=null)
			tsm.GetCurrentObj().transform.position = transform.position;
	}
}
