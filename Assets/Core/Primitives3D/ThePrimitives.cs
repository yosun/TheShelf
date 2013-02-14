using UnityEngine;
using System.Collections;

public class ThePrimitives : MonoBehaviour {
	
	IntelPerC ipc;
	TheShelfManager tsm;
	
	public GameObject goParent;
		
	void Start(){
		ipc = GetComponent<IntelPerC>();
		tsm = GameObject.Find ("GameObject").GetComponent<TheShelfManager>();
	}
	
	void Update(){
		string s = PrimitivesDictionary.SanitizeDictation(ipc.GetDictation ());
		if(s!="DUNNO"){
			GameObject go = goParent.transform.Find (s).gameObject;	
			tsm.SetCurrent(go);
		}
	}
	
}
