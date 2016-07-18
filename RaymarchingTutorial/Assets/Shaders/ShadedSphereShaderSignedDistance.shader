Shader "Custom/ShadedSphereShaderSignedDistance"
{
	Properties
	{
		_Centre("Centre", Vector) = (0,0,0,0)
		_Radius("Radius", Float) = 0
		_Color ("Color", Color) = (0,0,0,0)
		_MinDistance ("MinDistance", Float) = 0.01
		_SpecularPower ("SpecularPower", Float) = 0
		_Gloss ("Gloss", Float) = 0
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

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct v2f {
				float4 pos : SV_POSITION;	// Clip space
				float3 wPos : TEXCOORD0;	// World position
			};

			#define STEPS 200
			#define STEP_SIZE 0.01

			float4 _Centre;
			float _Radius;
			fixed4 _Color;
			float _MinDistance;
			float _SpecularPower;
			float _Gloss;

			float sphereDistance (float3 p)
			{
			    return distance(p, _Centre) - _Radius;
			}

			float map(float3 p)
			{
				return sphereDistance(p);
			}

			float3 normal (float3 p)
			{
				const float eps = 0.01;

				return normalize
				(	float3
					(	map(p + float3(eps, 0, 0)	) - map(p - float3(eps, 0, 0)),
						map(p + float3(0, eps, 0)	) - map(p - float3(0, eps, 0)),
						map(p + float3(0, 0, eps)	) - map(p - float3(0, 0, eps))
					)
				);
			}

			fixed4 simpleLambert (fixed3 normal, fixed3 position, float3 viewDirection) {
				fixed3 lightDir = _WorldSpaceLightPos0.xyz; // Light direction
				fixed3 lightCol = _LightColor0.rgb;		// Light color

				// Specular
				fixed NdotL = max(dot(normal, lightDir),0);
				fixed4 c;

				fixed3 h = (lightDir - viewDirection) / 2.;
				fixed s = pow( dot(normal, h), _SpecularPower) * _Gloss;
				c.rgb = _Color * lightCol * NdotL + s;
				c.a = 1;

				return c;
			}

			fixed4 renderSurface(float3 p, float3 direction)
			{
				float3 n = normal(p);
				return simpleLambert(n, p, direction);
			}

			fixed4 raymarch(float3 position, float3 direction)
			{
				for (int i = 0; i < STEPS; i++)
				{
					float distance = map(position);
					if (distance < _MinDistance)
					{
						return renderSurface(position, direction);
					}

					position += distance * direction;
				}
				return fixed4(1,1,1,1);
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
				return raymarch(worldPosition, viewDirection);
			}
			ENDCG
		}
	}
}
