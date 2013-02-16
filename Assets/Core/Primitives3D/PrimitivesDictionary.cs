using UnityEngine;
using System.Collections;

public class PrimitivesDictionary : MonoBehaviour {

	public static string SanitizeDictation(string s){
		s = s.ToLower();
		if(s=="cylinder")return "Cylinder";
		else if(s=="pyramid"||s=="pyramid")return "Pyramid";
		else if(s=="kapok"||s=="teapot"||s=="utah teapot"||s=="you tag teapot")return "Teapot";
		else if(s=="tetrahedron"||s=="tetrahedral"||s=="tetrahedral on")return "Tetrahedron";
		else if(s=="icosahedron")return "Icosahedron";
		else if(s=="dodecahedron"||s=="doug decahedron")return "Dodecahedron";
		else if(s=="octahedron")return "Octahedron";
		else if(s=="'s near"||s=="sphere"||s=="here")return "Sphere";
		else if(s=="taurus"||s=="prius"||s=="dutchess"||s=="tires")return "Torus";
		else if(s=="cube"||s=="queued"||s=="cuba")return "Cube";
		else if(s=="cone"||s=="com")return "Cone";
		else if(s=="graphite")return "GRAPHITE";
		else if(s=="cartoon")return "CARTOON";
		else return "DUNNO";
	}
	
}
