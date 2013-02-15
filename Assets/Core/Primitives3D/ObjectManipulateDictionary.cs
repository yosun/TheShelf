using UnityEngine;
using System.Collections;

public class ObjectManipulateDictionary : MonoBehaviour {
	
	public static string SanitizeDictation(string s){
		s = s.ToLower();
	
		if(s=="rotate x"||s=="road take x"||s=="rotate axe"||s=="road take axe"||s=="rotate act"||s=="road take act"||s=="rotate ask"||s=="road take ask"){
			s="ROTATE|X";
		}else if(s=="rotate y"||s=="road take y"||s=="rotate why"||s=="road take why"){
			s="ROTATE|Y";
		}else if(s=="rotate z"||s=="road take z"){
			s="ROTATE|Z";
		}else if(s=="rotate"||s=="road take"){
			s="ROTATE";
		}else if(s=="freeze"||s=="free"||s=="please"||s=="busy"||s=="stop"||s=="stock"||s=="stalk"){
			s="FREEZE";
		}else 
			s="UNKNOWN";
		
		return s;
	}
}
