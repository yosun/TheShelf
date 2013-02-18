using UnityEngine;
using System.Collections;

public class TheShelfManager : MonoBehaviour {
	
	MoveSelector ms;

	public GameObject[] goShelfObjects = new GameObject[5];
	public Vector3[] vShelfLocations = new Vector3[5];
	public Vector3[] vShelfRotations=new Vector3[5];
	
	bool newlyselected=false;
	

	
	GameObject goCurrent=null;
	
	void Start(){
		ms = GameObject.Find ("SelectorCollider").GetComponent<MoveSelector>();	

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
		
		ms.Activate (true);
		
	}
	
	public GameObject GetCurrentObj(){
		return goCurrent;
	}
}
