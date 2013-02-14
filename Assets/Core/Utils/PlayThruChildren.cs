using UnityEngine;
using System.Collections;

public class PlayThruChildren : MonoBehaviour {
	
	// put in parent with serialized mesh to play through *Init(totalTime). 
	//		change *childbasename* from "Cylinder" to whatever each child is named. eg "Cylinder"+XYZ
	// *PlayMe() plays me
	// *sPlayStatus() returns true when finished playing
	
	 string childBaseName="Cylinder";
	 int totalPieces=60;
	 float timePerPiece=0.5f; private  float timeElapsed=0f; private  int currentPiece=1; private  bool finished=false;
	
	 bool playing=true;

	void Start () {
		AllPiecesOff();
	}
	
	void Update(){
		if(!playing)
			return;
		timeElapsed+=Time.deltaTime;
		if(timeElapsed>timePerPiece){
			timeElapsed=0f;
			NextPiece ();
		}
	}
	
	public string GetPieceNumber(){
		if(currentPiece<totalPieces)
		return currentPiece.ToString();
		else return "Done!";
	}
	
	public bool PlayStatus(){
		return finished;
	}
	
	private void NextPiece(){
		if(currentPiece<=totalPieces){
			AllPiecesOff();	
			PieceOn (currentPiece);
			currentPiece++;
		}else{
			finished=true;
			playing=false;
		}
	}
	
	private  void AllPiecesOff(){
		for(int i=0;i<totalPieces;i++){
			transform.GetChild(i).gameObject.SetActiveRecursively(false);	
		}
	}
	
	private void PieceOn(int n){
		string s = childBaseName+ThreePad(n);
		transform.Find (s).gameObject.SetActiveRecursively(true);
	}
	
	private string ThreePad(int n){
		if(n<10)return "00"+n.ToString();
		else if(n<100)return "0"+n.ToString ();
		else return n.ToString();
	}
	
	public void Init(float totalTime){
		totalPieces = transform.childCount;
		timePerPiece = totalTime/totalPieces;
	}
	
	public  void PlayMe(){
		timeElapsed=0f;
		currentPiece=1;
		finished=false;
		AllPiecesOff ();
		playing=true;		
	}
}
