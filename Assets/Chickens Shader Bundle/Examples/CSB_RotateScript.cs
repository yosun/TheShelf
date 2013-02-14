using UnityEngine;
using System.Collections;

public class CSB_RotateScript : MonoBehaviour {

	public GameObject Rotator;
	public Vector3 axis;
	public float angle;
    bool rotate = true;
	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.R))
        {
            rotate = !rotate;
        }
        if (rotate)
        {
            this.transform.RotateAround(Rotator.transform.position, axis, angle * Time.deltaTime);
        }
    }
}
