Shader "URPNotes/Lambert"
{
    Properties
    {
        //着色器的输入，注意Unity所规定的类型不变
        _MainTex("颜色贴图",2D) = "white" {}
        _LightMap("LightMap",2D) = "white"{}
        _ShadowRampMap("_ShadowRampMap",2D) = "white"{}

        _InNight("从白天到黑夜",Range(0,0.2))=0
       // _EmissionIntensity("自发光强度",Range(0,5)) =1

        _RimWidth("光圈宽度",Range(0,0.1)) = 0.002

         _RimThreshold("深度差判定是否有rim",Range(0,100000)) = 500

         _RimColor("边缘光颜色",Color) = (1,1,1,1)
        
        _range("阴影色号",Range(0,0.5)) = 0

    }
    SubShader
    {
        Tags {"RenderType"="Opaque" "RenderPipeline" = "UniversalRenderPipeline"}
        //设定为URP
        
        pass{

            HLSLPROGRAM
                /* 主要的着色器内容 */

                #pragma vertex Vertex
                #pragma fragment Pixel

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

                //引用


                CBUFFER_START(UnityPerMaterial)
                    /*输入变量的声明要包在CBUFFER_START(UnityPerMaterial)和CBUFFER_END中*/
                float4 _MainTex_ST;

                half _InNight;

               // half _EmissionIntensity;

                half _RimWidth;

                half  _RimThreshold;

                vector _RimColor;

                half _range;

                CBUFFER_END

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);

                TEXTURE2D(_LightMap);
                SAMPLER(sampler_LightMap);
                
                TEXTURE2D(_ShadowRampMap);
                SAMPLER(sampler_ShadowRampMap);

                struct VertexInput{
                    //顶点着色器的输入，我们需要顶点位置和法线，语义和CG中一样

                    float4 vertex:POSITION;
                    half3 normal:NORMAL;
                    float2 uv : TEXCOORD1;
                    half4 vertColor : COLOR;
                };

                struct VertexOutput{
                    //顶点着色器的输出

                    float4 pos:SV_POSITION;
                    half3 worldNormal:TEXCOORD0;
                    float2 uv : TEXCOORD1;
                    float4 posDNC :TEXCOORD2;
                    float4 posVS: TEXCOORD3;
                    float4 nDirVS:TEXCOORD4;
                    half4 vertColor : COLOR;
                };

                float4 TransformHClipToViewPortPos(float4 offsetPosCS)
                {
                    float4 ndc = offsetPosCS * 0.5f;

                    float4 positionndc;

                    positionndc.xy = float2(ndc.x,ndc.y *_ProjectionParams.x) + ndc.w;
                    positionndc.zw = offsetPosCS.zw;
                    return positionndc/offsetPosCS.w;

                }

                VertexOutput Vertex(VertexInput v){
                    /* 顶点着色器 */

                    VertexOutput o;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);           //将顶点转换到裁剪空间，这步是顶点着色器必做的事情，否则
                                                                            //渲染后模型会错位。
                    o.worldNormal = TransformObjectToWorldNormal(v.normal); //将法线切换到世界空间下，注意normal是方向

                    o.uv = TRANSFORM_TEX(v.uv,_MainTex);  

                    float4 ndc = o.pos *0.5f;

                    o.posDNC.xy = float2(ndc.x, ndc.y*_ProjectionParams.x)+ ndc.w;

                    o.posDNC.zw = o.pos.zw;

                    o.posVS  = mul(UNITY_MATRIX_MV, v.vertex);

                    o.nDirVS = normalize(mul(UNITY_MATRIX_IT_MV, v.normal));

                    o.vertColor = v.vertColor;

                    return o;
                }

                half4 Pixel(VertexOutput IN):SV_TARGET{
                    /* 片元着色器 */

                    Light mlight = GetMainLight();                                  //获取主光源的数据 
                    float3 LDir = normalize(mlight.direction); 

                    float3 mainLightColor = mlight.color.rgb;

                    float4 baseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,IN.uv);

                    float4 lightMap = SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,IN.uv);


                    half dayOrNight = (1 - step(0.1, _InNight)) * 0.5 + 0.03;
                    //漫反射diffuse: SDF阴影
                    //人物朝向 Get character orientation
                    float3 up = float3(0,1,0);  
                    float3 front = TransformObjectToWorldDir(float4(0.0,0.0,1.0,1.0)).rgb;
                    float3 right = cross(up, front);

                    //左右阴影图 Sample flipped face light map
                    float2 rightFaceUV = float2(-IN.uv.x, IN.uv.y);
                    float4 faceShadowR = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, rightFaceUV);
                    float4 faceShadowL = lightMap;

                    //灯光朝向和灯光vector不一致，逆时针转90，投影后要归一化，不然长度会小于1
                    float s = sin(90 * (PI/180.0f));
                    float c = cos(90 * (PI/180.0f));
                    float2x2 rMatrix = float2x2(c, -s, s, c);    
                    float2 realLDir = normalize(mul(rMatrix,LDir.xz));

                    float realFDotL = dot(normalize(front.xz), realLDir);
                    
                    float realRDotL =  dot(normalize(right.xz), realLDir);
                    realRDotL = -(acos(realRDotL)/3.14159265 - 0.5)*2;

                    //通过RdotL决定用哪张阴影图
                    float shadowTex = realRDotL < 0? faceShadowL: faceShadowR;
                    //获取当前像素的阴影阈值
                    float shadowMargin = shadowTex.r;
                    //判断是否在阴影中
                    float inShadow =  -0.5 * realFDotL + 0.5 < shadowMargin;

                    //采样阴影ramp颜色图
                    float2 shadowUV = float2(inShadow * mlight.shadowAttenuation - 0.06, _range + dayOrNight);
                    half3 faceShadowColor = SAMPLE_TEXTURE2D(_ShadowRampMap, sampler_ShadowRampMap, shadowUV);
                    half3 diffuse = lerp(faceShadowColor, mainLightColor, inShadow) * baseColor ;

                    float Lambert = max(0,dot(LDir,IN.worldNormal));

                    //边缘光Rim: 屏幕空间深度边缘光
                    float3 nonHomogeneousCoord = IN.posDNC.xyz / IN.posDNC.w;
                    float2 screenUV = nonHomogeneousCoord.xy;
                    // 保持z不变即可
                    float3 offsetPosVS = float3(IN.posVS.xy + IN.nDirVS.xy * _RimWidth, IN.posVS.z);
                    float4 offsetPosCS = TransformWViewToHClip(offsetPosVS);
                    float4 offsetPosVP = TransformHClipToViewPortPos(offsetPosCS);

                    float depth = SampleSceneDepth(screenUV); 
                    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams); // 离相机越近越大

                    float offsetDepth = SampleSceneDepth(offsetPosVP);
                    float linearEyeOffsetDepth = LinearEyeDepth(offsetDepth, _ZBufferParams);

                    float depthDiff = linearEyeOffsetDepth - linearEyeDepth;

                    float rimMask = smoothstep(0, _RimThreshold, depthDiff);


                    half4 rim = rimMask * _RimColor * IN.vertColor * baseColor * step(0.1, lightMap.g);


                    half4 final = half4(diffuse,1) + rim ;



                    return final;              //将表面颜色，漫反射强度和光源强度混合。
                }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/DepthNormals"

    }
}