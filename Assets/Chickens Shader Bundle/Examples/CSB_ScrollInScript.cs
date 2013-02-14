using UnityEngine;
using System.Collections;

public class CSB_ScrollInScript : MonoBehaviour 
{

	public float MinDist = 1.3f;
	public float MaxDist = 8.0f;
    public Transform target;
    public float distance = 10.0f;

    public float xSpeed = 250.0f;
    public float ySpeed = 120.0f;

    public float yMinLimit = -20;
    public float yMaxLimit = 80;

    private float x = 0.0f;
    private float y = 0.0f;
    private bool started = false;
	public Vector3 OnKeyRotation;
    public bool rotateMe = false;

    void Start () {
        var angles = transform.eulerAngles;
        x = angles.y;
        y = angles.x;

	    // Make the rigid body not change rotation
   	    if (rigidbody)
		    rigidbody.freezeRotation = true;
    }

    void Update()
    {
        if (Input.GetAxis("Mouse ScrollWheel") != 0)
        {
            this.distance = Mathf.Min(Mathf.Max(this.distance - Input.GetAxis("Mouse ScrollWheel"), MinDist), MaxDist);
        }
        if (Input.GetKeyDown(KeyCode.Space))
        {
            rotateMe = !rotateMe;
        }
        if(rotateMe)
        {
            this.transform.RotateAround(target.transform.position, new Vector3(1, 0, 0), OnKeyRotation.x*Time.deltaTime);
            this.transform.RotateAround(target.transform.position, new Vector3(0, 1, 0), OnKeyRotation.y*Time.deltaTime);
            Vector3 eulers = this.transform.rotation.eulerAngles;
            eulers.z = 0;
            this.transform.rotation = Quaternion.Euler(eulers);
        }
    }

    void LateUpdate () {
        if (target) {
            if (Input.GetMouseButton(0) || !started || (Input.GetAxis("Mouse ScrollWheel") != 0))
            {
                if (Input.mousePosition.y<Screen.height-70)
                {
                    x += Input.GetAxis("Mouse X") * xSpeed * 0.02f;
                    y -= Input.GetAxis("Mouse Y") * ySpeed * 0.02f;

                    y = ClampAngle(y, yMinLimit, yMaxLimit);

                    var rotation = Quaternion.Euler(y, x, 0);
                    var position = rotation * new Vector3(0.0f, 0.0f, -distance) + target.position;

                    transform.rotation = rotation;
                    transform.position = position;
                    started = true;
                }
            }
        }
    }

    static float ClampAngle (float angle,float min,float max) {
	    if (angle < -360)
		    angle += 360;
	    if (angle > 360)
		    angle -= 360;
	    return Mathf.Clamp (angle, min, max);
    }
}


