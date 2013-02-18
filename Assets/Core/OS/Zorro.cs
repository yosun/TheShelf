using UnityEngine;
using System.Collections;

public class Zorro : MonoBehaviour {
	
	public bool hit1=false; public bool hit1again=false;
	public bool hit2=false; public bool hit2again=false;
	
	bool zorroActive=false;
	
	float timeElapsed;
	int hitFirst=-1;
	
	public bool ZorroActive(){
		if(zorroActive)print ("ZORRO");
		bool f = zorroActive;
		zorroActive=false;
		return f;
	}
	
	void Update(){
		if((hit1==true&&hit2==false)||(hit2==true&&hit1==false)){
			timeElapsed=0f;
			if(hit1)hitFirst=1;
			else hitFirst=2;
		}else if((hit2again&&hitFirst==2)||(hit1again&&hitFirst==1)){
				
			print (timeElapsed);
			if(timeElapsed<0.5f)
				zorroActive=true;
			ZorroActive();
			
			ResetAllHit();
		}
		timeElapsed+=Time.deltaTime;
	}
	
	void ResetAllHit(){
		timeElapsed=10f;
		hitFirst=-1;
		hit1=false;hit1again=false;
		hit2=false;hit2again=false;
	}
	
}
