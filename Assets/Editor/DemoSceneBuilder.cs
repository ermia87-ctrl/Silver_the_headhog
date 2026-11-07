#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using PersianRunner;

public static class DemoSceneBuilder
{
    [MenuItem("Tools/Persian Runner/Create Demo Scene")]
    public static void Create()
    {
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        var ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
        ground.name = "Track";
        ground.transform.position = new Vector3(0, -0.35f, 45);
        ground.transform.localScale = new Vector3(8, .5f, 110);
        ground.GetComponent<Renderer>().sharedMaterial = MakeMaterial(new Color(.12f, .16f, .24f));

        var player = GameObject.CreatePrimitive(PrimitiveType.Capsule);
        player.name = "Runner Placeholder";
        Object.DestroyImmediate(player.GetComponent<CapsuleCollider>());
        player.transform.position = new Vector3(0, 1, 0);
        player.AddComponent<CharacterController>();
        player.AddComponent<RunnerController>();
        player.GetComponent<Renderer>().sharedMaterial = MakeMaterial(new Color(.15f, .55f, 1f));

        var camObj = new GameObject("Follow Camera");
        camObj.AddComponent<Camera>();
        camObj.tag = "MainCamera";
        camObj.transform.position = new Vector3(0, 5, -8);
        var follow = camObj.AddComponent<FollowCamera>();
        follow.SetTarget(player.transform);
        camObj.AddComponent<AudioListener>();

        var lightObj = new GameObject("Directional Light");
        var light = lightObj.AddComponent<Light>();
        light.type = LightType.Directional;
        light.intensity = 1.2f;
        lightObj.transform.rotation = Quaternion.Euler(50, -30, 0);

        var ui = new GameObject("Persian HUD", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        ui.GetComponent<Canvas>().renderMode = RenderMode.ScreenSpaceOverlay;
        var textObj = new GameObject("Score", typeof(Text));
        textObj.transform.SetParent(ui.transform, false);
        var text = textObj.GetComponent<Text>();
        text.text = "امتیاز: ۰";
        text.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
        text.fontSize = 30;
        text.alignment = TextAnchor.UpperRight;
        text.color = Color.white;
        var rect = text.rectTransform;
        rect.anchorMin = new Vector2(.55f, .88f);
        rect.anchorMax = new Vector2(.98f, .98f);
        rect.offsetMin = rect.offsetMax = Vector2.zero;
        var hud = ui.AddComponent<PersianHud>();
        var so = new SerializedObject(hud);
        so.FindProperty("scoreText").objectReferenceValue = text;
        so.ApplyModifiedProperties();

        var ring = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        ring.name = "Collectible Sample";
        ring.transform.position = new Vector3(0, 1.5f, 12);
        ring.transform.localScale = new Vector3(.9f, .08f, .9f);
        ring.GetComponent<Collider>().isTrigger = true;
        ring.AddComponent<Collectible>();
        ring.GetComponent<Renderer>().sharedMaterial = MakeMaterial(new Color(1f, .75f, .1f));

        System.IO.Directory.CreateDirectory("Assets/Scenes");
        EditorSceneManager.SaveScene(scene, "Assets/Scenes/Demo.unity");
        AssetDatabase.SaveAssets();
        Debug.Log("Persian Runner demo scene created. Replace placeholder art with licensed assets.");
    }

    static Material MakeMaterial(Color color)
    {
        var shader = Shader.Find("Universal Render Pipeline/Lit");
        if (!shader) shader = Shader.Find("Standard");
        var mat = new Material(shader);
        mat.color = color;
        return mat;
    }
}
#endif