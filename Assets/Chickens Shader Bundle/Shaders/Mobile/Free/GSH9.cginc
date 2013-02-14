		uniform float4 CSB_SHAr;
		uniform float4 CSB_SHAg;
		uniform float4 CSB_SHAb;
		
		uniform float4 CSB_SHBr;
		uniform float4 CSB_SHBg;
		uniform float4 CSB_SHBb;
		
		uniform float4 CSB_SHC;

		// normal should be normalized, w=1.0
		half3 CSBShadeSH9 (half4 normal)
		{
			half3 x1, x2, x3;
			
			// Linear + constant polynomial terms
			x1.r = dot(CSB_SHAr,normal);
			x1.g = dot(CSB_SHAg,normal);
			x1.b = dot(CSB_SHAb,normal);
			
			// 4 of the quadratic polynomials
			half4 vB = normal.xyzz * normal.yzzx;
			x2.r = dot(CSB_SHBr,vB);
			x2.g = dot(CSB_SHBg,vB);
			x2.b = dot(CSB_SHBb,vB);
			
			// Final quadratic polynomial
			float vC = normal.x*normal.x - normal.y*normal.y;
			x3 = CSB_SHC.rgb * vC;
			return x1 + x2 + x3;
		} 