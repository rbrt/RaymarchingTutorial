Shader "Custom/SphereShader"
{
	Properties
	{
		_Centre("Centre", Vector) = (0,0,0,0)
		_Radius("Radius", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;	// Clip space
				float3 wPos : TEXCOORD1;	// World position
			};
			
			#define STEPS 64
			#define STEP_SIZE 0.01

			float4 _Centre;
			float _Radius;

			bool sphereHit(float3 p)
			{
				return distance(p, _Centre.xyz) < _Radius;
			}

			bool raymarchHit(float3 position, float3 direction)
			{
				for (int i = 0; i < STEPS; i++)
				{
					if (sphereHit(position))
						return true;

					position += direction * STEP_SIZE;
				}

				return false;
			}

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.wPos = mul(_Object2World, v.vertex).xyz;
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
				float3 worldPosition = i.wPos;
				float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
				if (raymarchHit(worldPosition, viewDirection))
					return fixed4(1,0,0,1); // Red if hit the ball
				else
					return fixed4(1,1,1,1); // White otherwise
			}
			ENDCG
		}
	}
}
