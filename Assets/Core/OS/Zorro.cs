using UnityEngine;
using System.Collections;

public class Zorro : MonoBehaviour {
	
	public bool hit1=false; public bool hit1again=false;
	public bool hit2=false; public bool hit2again=false;
	
	bool zorroActive=false;
	
	float timeElapsed;
	public int hitFirst=-1;
	
	bool lookingForHits=false;
	
	public bool ZorroActive(){
		if(zorroActive)print (Time.timeSinceLevelLoad+" ZORRO");
		bool f = zorroActive;
		zorroActive=false;
		return f;
	}
	
	void Update(){ 
		if(!hit1again&&!hit2again){
			if((hit1&&!hit2)||(!hit1&&hit2)){
				timeElapsed = 0;	
				lookingForHits=true;
				if(hit1)hitFirst=1;
				else hitFirst=2;
			}
		}else if (lookingForHits){
			timeElapsed+=Time.deltaTime;
			if(timeElapsed>0.5f)ResetAllHit ();	
			else{
				if((hit1&&!hit2&&hit1again&&!hit2again)||(!hit1&&hit2&&!hit1again&&hit2again)){
					ResetAllHit();
				}else{
					if(hit1&&hit2&&hit1again&&hit2again){
						print (timeElapsed);
						zorroActive=true;
						ResetAllHit();
					}
				}
			}
		}
	}
	
	void ResetAllHit(){
		lookingForHits=false;
		print ("ResetAllHit");
		timeElapsed=10f;
		hitFirst=-1;
		hit1=false;hit1again=false;
		hit2=false;hit2again=false;
	}
	
}
