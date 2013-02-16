function Update() {
	if (Input.GetKeyDown("space")) {
		var overdraw : ShowOverdraw = GetComponent(ShowOverdraw);
		overdraw.fullOverdraw = !overdraw.fullOverdraw;
	}
}
