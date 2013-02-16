using UnityEngine;
using System.Collections;

public class ObjectManipulateDictionary : MonoBehaviour {
	
	public static string SanitizeDictation(string s){
		s = s.ToLower();
	
		if(s=="rotate hex"||s=="road take hex"||s=="rotate x"||s=="road take x"||s=="rotate text"||s=="road take text"||s=="rotate axe"||s=="road take axe"||s=="rotate act"||s=="road take act"||s=="rotate ask"||s=="road take ask"){
			s="ROTATE|X";
		}else if(s=="rotate y"||s=="road take y"||s=="rotate why"||s=="road take why"){
			s="ROTATE|Y";
		}else if(s=="rotate z"||s=="road take z"||s=="rotate busy"||s=="road take busy"){
			s="ROTATE|Z";
		}else if(s=="rotate"||s=="road take"){
			s="ROTATE";
		}else if(s=="freeze"||s=="free"||s=="please"||s=="trees"||s=="breeze"||s=="busy"||s=="stop"||s=="stock"||s=="stalk"){
			s="FREEZE";
		}else if(s=="properties"||s=="property"||s=="prop ritty"){
			s="PROPERTIES";
		}else 
			s="UNKNOWN";
		
		return s;
	}
}
