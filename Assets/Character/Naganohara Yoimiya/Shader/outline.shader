Shader "Unlit/outline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }

        
    }
    SubShader
    {
        Tags {"RenderType"="Outline" "RenderPipeline" = "UniversalRenderPipeline"}
        LOD 100

        Pass
        {
         Tags { 
           "LightMode" = "Outline" //与ShaderTagId一致
            }
            Name "Outline"
            Cull Front
            //.....其他参数根据工程需要配置
                    
            HLSLPROGRAM
            #pragma vertex OutlinePassVert
            #pragma fragment OutlinePassFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            CBUFFER_START(UnityPerMaterial)
            half _OutlineWidth;

            vector _OutlineColor;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct Attributes 
            {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float2 uv : TEXCOORD0;
            float4 vertColor : COLOR;
            float4 tangent : TANGENT;
            };

            struct Varyings
            {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 vertColor : COLOR;
            };

            Varyings OutlinePassVert (Attributes v) 
            {
            Varyings o;
                        
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_TRANSFER_INSTANCE_ID(v, o);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
            //从tangent space取出平滑法线，进行外扩，处理硬边断裂
            v.vertex.xyz += v.tangent.xyz * 0.05 * 0.1 * v.vertColor.a;//顶点色a通道控制粗细
            o.pos = TransformObjectToHClip(v.vertex.xyz);
            o.uv = v.uv;
            o.vertColor = v.vertColor.rgb;
            return o;
            }

            float4 OutlinePassFrag(Varyings i) : SV_TARGET 
            { 
            return float4(i.vertColor, 1) * half4(0.1,0.1,0.1,0);//顶点色rgb混合描边颜色
            }

            ENDHLSL
        }
    }
}
