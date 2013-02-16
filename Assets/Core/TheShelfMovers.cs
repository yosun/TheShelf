using UnityEngine;
using System.Collections;

public class TheShelfMovers : MonoBehaviour {
	
	public GameObject theAppParent;
	
	float shelfHeight=3f;
	
	string[] theAppOrderPerShelf=new string[0] ;//"Cube|Sphere|Cylinder";
	float[] theAppSpacing=new float[0];
	
	public void PlaceApps(){
		for(int i=0;i<theAppOrderPerShelf.Length;i++){
			// create shelf
			
			// place apps on each shelf
			string[] str = theAppOrderPerShelf[i].Split ("|"[0]);	
			for(int j=0;j<str.Length;j++){
				GameObject g = theAppParent.transform.Find (str[j]).gameObject;	
				g.transform.position = new Vector3(j*theAppSpacing[i],0,i*shelfHeight);
			}
		}
	}
	
}
