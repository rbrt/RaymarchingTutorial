Shader "Custom/Translate"
{
	Properties
	{
		_Centre("Centre", Vector) = (0,0,0,0)
		_Radius("Radius", Float) = 0
		_Color ("Color", Color) = (0,0,0,0)
		_MinDistance ("MinDistance", Float) = 0.01
		_SpecularPower ("SpecularPower", Float) = 0
		_Gloss ("Gloss", Float) = 0
		_FillColor ("FillColor", Color) = (0,0,0,0)
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
			#define STEP_SIZE 0.001

			float4 _Centre;
			float _Radius;
			fixed4 _Color;
			fixed4 _FillColor;
			float _MinDistance;
			float _SpecularPower;
			float _Gloss;

			float sphereDistance (float3 p)
			{
			    return distance(p, _Centre) - _Radius;
			}

			float sdfBox (half3 p, half3 s)
			{
			    float x = max
			    (   p.x - _Centre.x - half3(s.x / 2., 0, 0),
			        _Centre.x - p.x - half3(s.x / 2., 0, 0)
			    );

			    float y = max
			    (   p.y - _Centre.y - half3(s.y / 2., 0, 0),
			        _Centre.y - p.y - half3(s.y / 2., 0, 0)
			    );

			    float z = max
			    (   p.z - _Centre.z - half3(s.z / 2., 0, 0),
			        _Centre.z - p.z - half3(s.z / 2., 0, 0)
			    );

			    float d = x;
			    d = max(d,y);
			    d = max(d,z);
			    return d;
			}

			float4x4 inverse(float4x4 input)
			 {
			     #define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
			     //determinant(float3x3(input._22_23_23, input._32_33_34, input._42_43_44))

			     float4x4 cofactors = float4x4(
			          minor(_22_23_24, _32_33_34, _42_43_44),
			         -minor(_21_23_24, _31_33_34, _41_43_44),
			          minor(_21_22_24, _31_32_34, _41_42_44),
			         -minor(_21_22_23, _31_32_33, _41_42_43),

			         -minor(_12_13_14, _32_33_34, _42_43_44),
			          minor(_11_13_14, _31_33_34, _41_43_44),
			         -minor(_11_12_14, _31_32_34, _41_42_44),
			          minor(_11_12_13, _31_32_33, _41_42_43),

			          minor(_12_13_14, _22_23_24, _42_43_44),
			         -minor(_11_13_14, _21_23_24, _41_43_44),
			          minor(_11_12_14, _21_22_24, _41_42_44),
			         -minor(_11_12_13, _21_22_23, _41_42_43),

			         -minor(_12_13_14, _22_23_24, _32_33_34),
			          minor(_11_13_14, _21_23_24, _31_33_34),
			         -minor(_11_12_14, _21_22_24, _31_32_34),
			          minor(_11_12_13, _21_22_23, _31_32_33)
			     );
			     #undef minor
			     return transpose(cofactors) / determinant(input);
			 }

			float3 opApplyMatrix( float3 p, float4x4 m )
			{
			    float4 q = mul(inverse(m), float4(p,1));
			    return sdfBox(q.xyz, float3(10,10,10));
			}

			float4x4 translationMatrix(float3 coords)
			{
				float4x4 mat = float4x4(1.0,0.0,0.0,coords.x,
										0.0,1.0,0.0,coords.y,
										0.0,0.0,1.0,coords.z,
										0.0,0.0,0.0,1.0);
				return mat;
			}

			float4x4 rotationMatrix(float3 rotationTheta)
			{
				float4x4 matX = float4x4(1.0,0.0,0.0,0.0,
										 0.0,cos(rotationTheta.x),-sin(rotationTheta.x),0.0,
										 0.0,sin(rotationTheta.x),cos(rotationTheta.x),0.0,
										 0.0,0.0,0.0,1.0);

				float4x4 matY = float4x4(cos(rotationTheta.y),0.0,sin(rotationTheta.y),0.0,
										 0.0,1.0,0.0,0.0,
										 -sin(rotationTheta.y),0.0,cos(rotationTheta.y),0.0,
										 0.0,0.0,0.0,1.0);

				float4x4 matZ = float4x4(cos(rotationTheta.z),-sin(rotationTheta.z),0.0,0.0,
										 sin(rotationTheta.z),cos(rotationTheta.z),0.0,0.0,
										 0.0,0.0,1.0,0.0,
										 0.0,0.0,0.0,1.0);

				return mul(matX, mul(matY, matZ));

			}

			float4x4 scalingMatrix(float scale)
			{
				float4x4 mat = float4x4(scale,0.0,0.0,0.0,
										0.0,scale,0.0,0.0,
										0.0,0.0,scale,0.0,
										0.0,0.0,0.0,1.0);

				return mat;
			}

			float3 opTranslate(float3 p, float4 coords)
			{
				float4x4 mat = float4x4(1.0,0.0,0.0,coords.x,
										0.0,1.0,0.0,coords.y,
										0.0,0.0,1.0,coords.z,
										0.0,0.0,0.0,1.0);
				return opApplyMatrix(float4(p, 1), mat);
			}

			float3 opRotateX(float3 p)
			{
				float theta = _Time.y * 5;
				float4x4 mat = float4x4(1.0,0.0,0.0,0.0,
										0.0,cos(theta),-sin(theta),0.0,
										0.0,sin(theta),cos(theta),0.0,
										0.0,0.0,0.0,1.0);
				return opApplyMatrix(float4(p, 1), mat);
			}

			float rotatePoint(float3 p, float3 rotationAngles)
			{
				return opApplyMatrix(p, rotationMatrix(rotationAngles));
			}

			float translatePoint(float3 p, float3 translation)
			{
				return opApplyMatrix(p, translationMatrix(translation));
			}

			float sdf1(float3 p)
			{
				return opApplyMatrix(p, scalingMatrix(1));
			}

			float map(float3 p)
			{
				return sdf1(p);
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
				fixed4 fill = fixed4(_FillColor.xyz, 1);
				fill.xyz *= abs(direction.x * (sin(_Time.y * 2) + 2) / 2) * 5 * abs(direction.y * 3);
				return fill;
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
