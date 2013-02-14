using UnityEngine;
using System.Collections;

public class testpiechart : MonoBehaviour {

	PlayThruChildren ptc;
	public GUIText guitext;
	
	void Start () {
		ptc = GetComponent<PlayThruChildren>();
		ptc.Init (5f);
		ptc.PlayMe ();	
	}
	
	void Update () {
		guitext.text = ptc.GetPieceNumber();
	}
}
