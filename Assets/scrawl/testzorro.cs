using UnityEngine;
using System.Collections;

public class testzorro : MonoBehaviour {
	
	Zorro zorro;
	
	// Use this for initialization
	void Start () {
		zorro = GetComponent<Zorro>();
	}
	
	// Update is called once per frame
	void Update () {
		if(zorro.ZorroActive()){
			print ("Z!");	
		}
	}
}
