Shader "Custom/SphereShaderSignedDistance"
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
			#define MIN_DISTANCE .001

			float4 _Centre;
			float _Radius;

			float sphereDistance (float3 p)
			{
			    return distance(p,_Centre) - _Radius;
			}

			fixed4 raymarch (float3 position, float3 direction)
			{
				for (int i = 0; i < STEPS; i++)
				{
					float distance = sphereDistance(position);
					if (distance < MIN_DISTANCE)
						return i / (float) STEPS;

					position += distance * direction;
				}
				return 0;
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
				fixed4 raymarchValue = raymarch(worldPosition, viewDirection) * fixed4(1,0,0,1);
				return raymarchValue;
			}
			ENDCG
		}
	}
}
