Shader "Custom/Silly"
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

			float sdfSmin(float a, float b, float k = 32)
			{
				float res = exp(-k*a) + exp(-k*b);
				return -log(max(0.0001,res)) / k;
			}

			float opRep(float3 p, float3 c)
			{
			    float3 q = fmod(p,c)-0.5*c;
			    return sphereDistance(q);
			}

			float opTwist( float3 p, float intensity)
			{
			    float c = cos(intensity*p.y);
			    float s = sin(intensity*p.y);
			    float2x2  m = float2x2(c,-s,s,c);
				float3 q = float3(mul(m, p.xz), p.y);
			    return sdfBox(q, float3(20,20,20));
			}

			float displacement(float3 p)
			{
				return sin(p.x)*cos(p.x)*sin(p.z + _Time.w) + p.x;
			}

			float displacement2(float3 p)
			{
				return sin(p.x)*cos(p.y)*sin(p.z + _Time.w);
			}

			float opCheapBend(float3 p, float intensity)
			{
			    float c = cos(intensity*p.y);
			    float s = sin(intensity*p.y);
			    float2x2  m = float2x2(c,-s,s,c);
			    float3  q = float3(mul(m,p.xy),p.z);
			    return sphereDistance(q);
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
			    float3 q = mul(inverse(m), p);
			    return sdfBox(q, float3(10,10,10));
			}

			float3 opTranslate(float3 p, float3 coords)
			{
				float4x4 mat = float4x4(1.0,0.0,0.0,coords.x,
										0.0,1.0,0.0,coords.y,
										0.0,0.0,1.0,coords.z,
										0.0,0.0,0.0,1.0);
				return opApplyMatrix(p, mat);
			}

			float opDisplace(float3 p)
			{
			    float d1 = sphereDistance(p);
			    float d2 = displacement(p);
			    return d1+d2;
			}

			float opDisplace2(float3 p)
			{
			    float d1 = sphereDistance(p);
			    float d2 = displacement2(p);
			    return d1+d2;
			}

			float sdf1(float3 p)
			{
				//p += sin(p.x - _Time.z * 4) * 2;
				return opTranslate(p, float3(3,3,0));
			}

			float sdf2(float3 p)
			{
				return opDisplace2(p);
			}

			float sdfBlend(float d1, float d2, float step)
			{
				return step * d1 + (1 - step) * d2;
			}

			float map(float3 p)
			{
				return sdfBlend(sdf1(p), sdf1(p), _SinTime.w + sin(p.x));
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
