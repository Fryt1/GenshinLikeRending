using UnityEngine;
using UnityEditor;


public class GenshinLikeGui : ShaderGUI {

    enum CharacterPart {
		Body, Face, Hair
	}
    Material target;
    MaterialEditor editor;
	MaterialProperty[] properties;
    public override void OnGUI (
		MaterialEditor editor, MaterialProperty[] properties
	) {
        this.target = editor.target as Material;
        this.editor = editor;
		this.properties = properties;
        DoMain();
        
	}

    void SwitchKeword()
    {
        CharacterPart source = CharacterPart.Body;
        if (IsKeywordEnabled("_Body")) {
			source = CharacterPart.Body;
			
		}
        else if (IsKeywordEnabled("_Hair")) {
			source = CharacterPart.Hair;
		}
		else if (IsKeywordEnabled("_Face")) {
			source = CharacterPart.Face;
		}
        

        EditorGUI.BeginChangeCheck();

        source = (CharacterPart)EditorGUILayout.EnumPopup(
			MakeLabel("Source"), source
		);

        if (EditorGUI.EndChangeCheck()) {
            RecordAction("CharacterPart");

			SetKeyword("_Body", source == CharacterPart.Body);
            
			SetKeyword(
				"_Hair", source == CharacterPart.Hair
			);
            
            SetKeyword(
				"_Face", source == CharacterPart.Face
			);
		}
		switchpart();
		
    }

	void DoMain(){
		SwitchKeword();

		
	}

	void switchpart()
	{
		CharacterPart source = CharacterPart.Body;
        if (IsKeywordEnabled("_Body")) {
			source = CharacterPart.Body;
			DoBodyMain();	
		}
        else if (IsKeywordEnabled("_Hair")) {
			source = CharacterPart.Hair;
			DoHairMain();
		}
		else if (IsKeywordEnabled("_Face")) {
			source = CharacterPart.Face;
			DoFaceMain();
		}

	}

    void DoBodyMain() {
		GUILayout.Label("Texture", EditorStyles.boldLabel);
		//texture
        DoTexture("_MainTex");
        DoTexture("_LightMap");
        DoTexture("_MetalMap");
        DoTexture("_ShadowRampMap");
		//value
		GUILayout.Label("Value", EditorStyles.boldLabel);
        DOValue("_BodyShadowSmooth");
        DOValue("_InNight");
		DOValue("_StrokeRange");
		DOValue("_StrokeRangeIntensity");
        DOValue("_PatternRange");
		DOValue("_PatternRangeIntensity");
		DOValue("_MetalIntensity");
		DOValue("_EmissionIntensity");
        DOValue("_RimWidth");
		DOValue("_RimThreshold");
		DOValue("_RimColor");
		

	}
	void DoHairMain() {
		GUILayout.Label("Texture", EditorStyles.boldLabel);
		//texture
        DoTexture("_MainTex");
        DoTexture("_LightMap");
        DoTexture("_MetalMap");
        DoTexture("_ShadowRampMap");
		//value
		GUILayout.Label("Value", EditorStyles.boldLabel);
        DOValue("_BodyShadowSmooth");
        DOValue("_InNight");
		DOValue("_HairDarkShadowSmooth");
		DOValue("_HairDarkShadowArea");
        DOValue("_HairShadowSmooth");
		DOValue("_HairSmoothShadowIntensity");
		DOValue("_HairRange");
		DOValue("_HairViewSpecularThreshold");
        DOValue("_HairSpecAreaBaseline");
		DOValue("_HairAccGroveBaseline");
		DOValue("_HairViewSpecularIntensity");
        DOValue("_RimWidth");
		DOValue("_RimThreshold");
		DOValue("_RimColor");
		

	}
	void DoFaceMain()
	{
		GUILayout.Label("Texture", EditorStyles.boldLabel);
		//texture
        DoTexture("_MainTex");
        DoTexture("_LightMap");
        DoTexture("_ShadowRampMap");
		GUILayout.Label("Value", EditorStyles.boldLabel);
		DOValue("_InNight");
        DOValue("_RimWidth");
		DOValue("_RimThreshold");
		DOValue("_RimColor");
		DOValue("_range");
	}

void DoTexture(string name){
    MaterialProperty Map = FindProperty(name);

    // 使用TextureProperty方法显示默认的纹理选择框
    editor.TextureProperty(Map, MakeLabel(Map).text);
}



	void DOValue(string value)
	{
		MaterialProperty Value= FindProperty(value);

        editor.ShaderProperty(Value, MakeLabel(Value));

	}

    
    MaterialProperty FindProperty (string name) {
		return FindProperty(name, properties);
	}

    static GUIContent staticLabel = new GUIContent();
	
	static GUIContent MakeLabel (
		MaterialProperty property, string tooltip = null
	)
    {
		staticLabel.text = property.displayName;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}
    static GUIContent MakeLabel (
		string property, string tooltip = null
	)
    {
		staticLabel.text = property;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}

    void SetKeyword (string keyword, bool state) {
		if (state) {
			target.EnableKeyword(keyword);
		}
		else {
			target.DisableKeyword(keyword);
		}
	}
    bool IsKeywordEnabled (string keyword) {
		return target.IsKeywordEnabled(keyword);
	}
    void RecordAction (string label) {
		editor.RegisterPropertyChangeUndo(label);
	}

}