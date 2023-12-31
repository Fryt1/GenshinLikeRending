Shader "CustShader/GenshinLike"
{
    Properties
    {
        //着色器的输入，注意Unity所规定的类型不变
        _MainTex("颜色贴图",2D) = "white" {}
        _LightMap("LightMap",2D) = "white"{}
        _MetalMap("_MetalMap",2D) = "white" {}
        _ShadowRampMap("_ShadowRampMap",2D) = "white"{}

        _BodyShadowSmooth("lambert阴影映射",Range(0,1)) = 1 

        _InNight("从白天到黑夜",Range(0,0.2))=0

        _StrokeRange("衣服花纹边非金属高光上界",Range(0.25,0.32)) = 0.3
        _StrokeRangeIntensity("花纹边高光强度",Range(1,5)) =1
        _PatternRange("衣服图案兼非金属高光上界",Range(0.32,1)) = 0.9
        _PatternRangeIntensity("图案高光强度",Range(1,5)) =1

        _MetalIntensity("金属高光强度",Range(0,5)) =1

        _EmissionIntensity("自发光强度",Range(0,5)) =1

        _RimWidth("光圈宽度",Range(0,5)) = 1

         _RimThreshold("深度差判定是否有rim",Range(0,100000)) = 1

         _RimColor("边缘光颜色",Color) = (1,1,1,1)


         _HairDarkShadowSmooth("黑阴影上界*",Range(-1,-0.5)) = -0.5

        _HairDarkShadowArea("亮阴影上界*",Range(-0.5,-0.065)) = -0.065

        _HairShadowSmooth("亮阴影平滑上界*",Range(-0.065,0)) = 0

        _HairSmoothShadowIntensity("亮阴影平滑强度*",Range(0,3)) = 1

        _HairRange("漫反射高光分界*",Range(0.01,0.19)) = 0.13


        _HairViewSpecularThreshold("头发视角遮罩*",Range(0,1)) = 0.05

        _HairSpecAreaBaseline("Baseline高光遮罩",Range(0.01,0.02)) = 0.5

        _HairAccGroveBaseline("非金属和金属的分界",Range(0.6,0.8)) =0.6

        _HairViewSpecularIntensity("头发整体高光强度*",Range(0,5))=0

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

                #pragma shader_feature _Body _Hair _Face

                //引用
                CBUFFER_START(UnityPerMaterial)
                    /*输入变量的声明要包在CBUFFER_START(UnityPerMaterial)和CBUFFER_END中*/
                float4 _MainTex_ST;

                half _BodyShadowSmooth;

                half _InNight;

                half _StrokeRange;

                half _PatternRange;

                half _MetalIntensity;

                half _StrokeRangeIntensity;

                half  _PatternRangeIntensity;

                half _EmissionIntensity;

                half _RimWidth;

                half  _RimThreshold;

                vector _RimColor;

                half _HairDarkShadowSmooth;

                half _HairDarkShadowArea;

                half _HairSmoothShadowIntensity;

                half _HairRange;

                half _HairShadowSmooth;

                half _HairViewSpecularThreshold;

                half _HairSpecAreaBaseline;

                half _HairAccGroveBaseline;

                half _HairViewSpecularIntensity;

                 half _range;

                CBUFFER_END

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);

                TEXTURE2D(_LightMap);
                SAMPLER(sampler_LightMap);
                
                TEXTURE2D(_ShadowRampMap);
                SAMPLER(sampler_ShadowRampMap);

                TEXTURE2D(_MetalMap);
                SAMPLER(sampler_MetalMap);


                struct VertexInput{
                    //顶点着色器的输入，我们需要顶点位置和法线，语义和CG中一样

                    float4 vertex:POSITION;
                    half3 normal:NORMAL;
                    float2 uv : TEXCOORD0;
                    half4 vertColor : COLOR;
                    
                };

                struct VertexOutput{
                    //顶点着色器的输出

                    float4 pos:SV_POSITION;
                    float2 uv : TEXCOORD1;
                    half4 vertColor : COLOR;
                    half3 vDirWS : TEXCOORD2;
                    half3 nDirWS: TEXCOORD3;
                    float4 posDNC: TEXCOORD4;
                    float4 posVS : TEXCOORD5;
                    float4 nDirVS: TEXCOORD6;
                    half3 worldNormal:TEXCOORD0;
                };
                  //获得高光指数p
                float RoughnessToSpecularExponent(float roughness){
                   return  sqrt(2 / (roughness + 2));
                }

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
                    #if defined(_Body)||defined(_Hair)
                    o.pos = TransformObjectToHClip(v.vertex.rgb);

                    float4 ndc = o.pos *0.5f;

                    o.posDNC.xy = float2(ndc.x, ndc.y*_ProjectionParams.x)+ ndc.w;

                    o.posDNC.zw = o.pos.zw;   
                                           
                    o.nDirWS = normalize(TransformObjectToWorldNormal(v.normal)); 

                    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).rgb;

                    o.posVS  = mul(UNITY_MATRIX_MV, v.vertex);

                    o.nDirVS = normalize(mul(UNITY_MATRIX_IT_MV, v.normal));

                    o.uv = TRANSFORM_TEX(v.uv,_MainTex);  
                    o.vertColor = v.vertColor;

                    o.vDirWS  = -normalize (worldPos - GetCameraPositionWS().xyz); 
                    #endif

                    #if defined(_Face)
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
                    #endif
                    return o;
                }

                half4 Pixel(VertexOutput IN):SV_TARGET{
                    /* 片元着色器 */
                    #if defined(_Body)||defined(_Hair)
                    //主光源
                    Light mainLight = GetMainLight(); 
                    float4 mainLightColor = float4(mainLight.color, 1); //获取主光源颜色
                    float3 lDir = normalize(mainLight.direction); //主光源方向

                    //基础色
                    half4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv); 
                    half4 vertexColor = IN.vertColor; //顶点色

                    //通道图
                    float4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, IN.uv); 
                    float4 metalMap = SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, IN.vDirWS.xy * 0.5 + 0.5);
                    float4 faceShadowMap = SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, IN.uv);

                    //方向点积
                    float ndotLRaw = dot(IN.nDirWS, lDir);
                    float ndotL = max(0.0, ndotLRaw);
                    float ndotH = max(0, dot(IN.nDirWS, normalize(IN.vDirWS + lDir)));
                    float ndotV = max(0, dot(IN.nDirWS, IN.vDirWS));

                    
                    //lambert系数(光照): 光照面积, 光照面积AO, 平滑光照面积AO
                    float lambert = ndotL;
                    half lambertAO = lambert * saturate(lightMap.g * 2);
                    half lambertRampAO = smoothstep(0, _BodyShadowSmooth, lambertAO);

                     //日夜状态
                    half dayOrNight = (1 - step(0.1, _InNight)) * 0.5 + 0.03;
                    
                    //lambert系数(采样): 半lambert采样, 偏移半lambert采样
                    half halfSampler = saturate(lambertRampAO * 0.5 + 0.5);
                    half rampOffset = step(0.5, vertexColor.g) == 1 ? vertexColor.g : vertexColor.g - 1;
                    half adjustedHalfSampler = saturate(halfSampler + rampOffset);
                    #endif
                   
                    #if defined(_Body)
                    //漫反射diffuse: Ramp+AO
                    float rampV = saturate(lightMap.a * 0.45 + dayOrNight);
                    float2 rampUV = float2(adjustedHalfSampler, rampV);
                    half4 rampShadow = SAMPLE_TEXTURE2D(_ShadowRampMap, sampler_ShadowRampMap, rampUV);
                    float4 diffuse = lerp(rampShadow, mainLightColor, lambertRampAO) * baseColor;
                    #endif
                    #if defined(_Hair)
                    //------漫反射diffuse: Double Shadow+Ramp------
                    float shadowUpperBound = step(ndotLRaw, _HairShadowSmooth) ;
                    float isHair = step(0.11, lightMap.r) - step(0.6, lightMap.r);
                    float litHair = step(0.0, ndotLRaw);

                    //1级暗阴影
                    float vDark = saturate(0.4 + dayOrNight);
                    float2 uvDark = float2(halfSampler, vDark);
                    float4 hairShadowD = SAMPLE_TEXTURE2D(_ShadowRampMap, sampler_ShadowRampMap, uvDark);

                    //2级亮阴影
                    float vLight = saturate(0.45 + dayOrNight);
                    float2 uvLight = float2(halfSampler, vLight);
                    float4 hairShadowL = SAMPLE_TEXTURE2D(_ShadowRampMap, sampler_ShadowRampMap, uvLight);

                    //计算1级深阴影，过度到2级浅阴影
                    float3 darkShadow = lerp(hairShadowD, hairShadowL, smoothstep(_HairDarkShadowSmooth, _HairDarkShadowArea, ndotLRaw)).rgb  * step(ndotLRaw, _HairDarkShadowArea);
                                        
                    //2级阴影平滑
                    float lightSmoothArea = step(_HairDarkShadowArea, ndotLRaw);
                    float3 lightShadowSmooth = 0.5 * _HairSmoothShadowIntensity * hairShadowL.rgb * lightSmoothArea* shadowUpperBound;

                    //计算头发和头饰颜色
                    float3 diffuseHair = (darkShadow + litHair) * baseColor.rgb * isHair +  lightShadowSmooth * isHair * baseColor.rgb  ;
                    float3 diffuseHairAccessory = baseColor.rgb * step(lightMap.r, _HairRange);

                    //结合diffuse和AO
                    half3 diffusergb = (diffuseHair + diffuseHairAccessory) * step(_HairRange, lightMap.g);
                    diffusergb += hairShadowD.rgb * (1 - step(_HairRange, lightMap.g)) * baseColor.rgb;
                    half4 diffuse = half4(diffusergb,1);
                    #endif

                    #if defined(_Body)||defined(_Hair)
                    //高光系数    
                    float specularPow = pow(ndotH, RoughnessToSpecularExponent(lightMap.b));
                    #endif

                    #if defined (_Body)
                    //衣服材质，高光区间
                    half strokeVMask = step(1 - _StrokeRange, ndotV);
                    half patternVMask = step(1 - _PatternRange, ndotV);

                    //高光specular: Metal+Non-metal

                    // ILM的R通道，视角高亮
                    half strokeMask = step(0.001, lightMap.r) - step(_StrokeRange, lightMap.r);
                    half3 strokeSpecular = lightMap.b  * strokeVMask  * strokeMask *_StrokeRangeIntensity;
                    half patternMask = step(_StrokeRange, lightMap.r) - step(_PatternRange, lightMap.r);
                    half3 patternSpecular = lightMap.b  * patternVMask  * patternMask *  _PatternRangeIntensity;

                    // 金属高光, Blinn-Phong
                    half metalMask = step(_PatternRange, lightMap.r);
                    half3 metalSpecular = _MetalIntensity * metalMap.rgb * metalMask;
                                        
                    //最终高光
                    half3 specularrgb = (strokeSpecular + patternSpecular  + metalSpecular) * baseColor.rgb;
                    half4 specular = half4(specularrgb,1);
                    #endif
                    #if defined(_Hair)
                    //头部，高光区间
                    half hairMask = step(_HairRange, lightMap.r);
                    half hairViewMask = step(_HairViewSpecularThreshold, ndotV);
                    half hairSpecAreaMask = step(_HairSpecAreaBaseline, lightMap.b);
                    half hairAccGroveMask = step(_HairAccGroveBaseline, lightMap.r);

                                        

                    //高光部分: 头发顶视角高亮


                    float3 specularrgb = _HairViewSpecularIntensity * specularPow * hairViewMask * hairMask *isHair;
                    specularrgb *= hairSpecAreaMask * baseColor * litHair;
                    specularrgb += metalMap.b * hairAccGroveMask * baseColor;
                    specularrgb += hairAccGroveMask * baseColor;
                    half4 specular = half4(specularrgb,1);
                    #endif


                    #if defined(_Body)
                    //自发光Emission: 周期函数
                    float bloomMask  = baseColor.a;
                    bloomMask *= step(0.95, 1 - lightMap.a);
                    //abs(_SinTime.w)
                    float3 emissionrgb = bloomMask * _EmissionIntensity * mainLightColor.rgb * abs((frac(_Time.y * 0.5) - 0.5) * 2);
                    emissionrgb *= baseColor.rgb;
                    half4 emission = half4(emissionrgb,1);
                    #endif

                    

                    #if defined(_Body)||defined(_Hair)
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

                    //float4 shadowColor = rampShadow;
                    half4 rim = rimMask * _RimColor * IN.vertColor * baseColor * step(0.1, lightMap.g);
                    #endif

                    //Face Frag
                    #if defined(_Face)
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
                    half3 diffusergb = lerp(faceShadowColor, mainLightColor, inShadow) * baseColor ;
                    half4 diffuse =half4(diffusergb,1);
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
                    #endif

                    #if defined(_Body)
                        half4 final = emission + diffuse +specular+rim ;
                    #endif
                    #if defined(_Hair)
                        half4 final = diffuse  + specular+rim ;

                    #endif

                    #if defined(_Face)
                        half4 final = diffuse + rim ;
                    #endif



                    return final  ;            //将表面颜色，漫反射强度和光源强度混合。
                }
            ENDHLSL
        }
            
        UsePass "Universal Render Pipeline/Lit/DepthNormals"
    }
    CustomEditor "GenshinLikeGui"
}