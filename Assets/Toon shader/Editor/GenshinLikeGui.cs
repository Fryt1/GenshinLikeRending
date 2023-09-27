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
    }

    void DoMain() {
		GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        DoMainTex();
        DoLightMap();
        DoMetalMap();
        DoShadowRampMap();
        Dolambertshadow();
        DoDayorNight();
        SwitchKeword();
	}
    void DoLightMap() {
        MaterialProperty LightMap = FindProperty("_LightMap");

        //editor.TextureScaleOffsetProperty(LightMap);

		editor.TexturePropertySingleLine(MakeLabel(LightMap), LightMap);
        
	}
    void DoMainTex() {
        MaterialProperty mainTex = FindProperty("_MainTex");

		editor.TexturePropertySingleLine(MakeLabel(mainTex), mainTex);

        editor.TextureScaleOffsetProperty(mainTex);
	}
    void DoMetalMap() {
        MaterialProperty  MetalMap = FindProperty("_MetalMap");

		editor.TexturePropertySingleLine(MakeLabel( MetalMap),  MetalMap);

        //editor.TextureScaleOffsetProperty(mainTex);
	}
    void DoShadowRampMap() {
        MaterialProperty  ShadowRampMap = FindProperty("_ShadowRampMap");

		editor.TexturePropertySingleLine(MakeLabel(ShadowRampMap),  ShadowRampMap);
        

        //editor.TextureScaleOffsetProperty(mainTex);
	}

    void Dolambertshadow()
    {
        MaterialProperty lambert = FindProperty("_BodyShadowSmooth");

        editor.ShaderProperty(lambert, MakeLabel(lambert));
    }

        void DoDayorNight()
    {
        MaterialProperty DayorNight = FindProperty("_InNight");

        editor.ShaderProperty(DayorNight, MakeLabel(DayorNight));
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