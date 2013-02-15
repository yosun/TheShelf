using UnityEngine;
using System.Collections;

public class TheShelfManager : MonoBehaviour {
	
	MoveSelector ms;

	public GameObject[] goShelfObjects = new GameObject[5];
	public Vector3[] vShelfLocations = new Vector3[5];
	public Vector3[] vShelfRotations=new Vector3[5];
	
	bool newlyselected=false;
	
	VFontBehavior vfont; Vector3 posVFont;
	
	GameObject goCurrent=null;
	
	void Start(){
		ms = GameObject.Find ("SelectorCollider").GetComponent<MoveSelector>();	
		vfont = GameObject.Find ("VFont").GetComponent<VFontBehavior>();
		posVFont = vfont.transform.position;
	}
	
	public void CheckObjectCollision(){
		
	}
	
	public bool GetNewlySelectedBool(){
		bool x = newlyselected;
		newlyselected=false;
		return x;
	}
	
	public void SetCurrent(GameObject g){
		if(goCurrent!=null){
			PutBack();
		}
		goCurrent = g;
		vfont.text = g.name;
		ms.Activate(false);
		newlyselected=true;
	}
	
	public void PutBack(){
		for(int i=0;i<goShelfObjects.Length;i++){
			if(goShelfObjects[i]==goCurrent){
				goShelfObjects[i].transform.localPosition = vShelfLocations[i];
				goShelfObjects[i].transform.rotation = Quaternion.Euler (vShelfRotations[i]);
			}
		}
		goCurrent=null;
		vfont.text = "Select or Say a Name";
		ms.Activate (true);
		vfont.transform.position = posVFont;
	}
	
	public GameObject GetCurrentObj(){
		return goCurrent;
	}
}
