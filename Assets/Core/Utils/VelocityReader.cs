using UnityEngine;
using System.Collections;

public class VelocityReader : MonoBehaviour {
	
	// exposes velocity property for non-rigidbody things
	
	public Vector3 velocity = Vector3.zero;
	Vector3 lastPos = Vector3.zero;
	
	void Update(){
		velocity = (transform.position - lastPos)/Time.deltaTime;
		lastPos = transform.position;	
	}
	
}
