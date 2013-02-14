using UnityEngine;
using UnityEditor;
using System.Collections;


[CustomEditor(typeof(MobileISpecLookupTexture))]
public class MobileISpecLookupInspector : Editor {


    private static string[] texSizes = { "16", "32", "64", "128", "256" };
    private static int[] texSizeVals = { 16, 32, 64, 128, 256 };
    bool changed = false;


    private void SaveTex()
    {
        MobileISpecLookupTexture tex = target as MobileISpecLookupTexture;
        if (tex.TargetPath == null || tex.TargetPath.Length == 0)
        {
            tex.TargetPath = Application.dataPath + "\\" + tex.gameObject.name + ".png";
        }
        try
        {
            System.IO.FileInfo fi = new System.IO.FileInfo(tex.TargetPath);
            if (!fi.Directory.Exists)
            {
                fi.Directory.Create();
            }
            byte[] texData = tex.lookupTexture.EncodeToPNG();
            System.IO.File.WriteAllBytes(fi.FullName, texData);
            AssetDatabase.ImportAsset(fi.FullName, ImportAssetOptions.ForceUpdate);
            AssetDatabase.Refresh();
        }
        catch(System.Exception e)
        {
            Debug.LogError("Error while saving MobileISpec lookup texture.\r\n" + e.Message);
        }
        try
        {
            //ugly way to get the relative path... but hey, it works.
            System.Uri uri1 = new System.Uri(tex.TargetPath.Replace("/", "" + System.IO.Path.DirectorySeparatorChar).Replace("\\", "" + System.IO.Path.DirectorySeparatorChar));
            System.Uri uri2 = new System.Uri(Application.dataPath.Replace("/", "" + System.IO.Path.DirectorySeparatorChar).Replace("\\", "" + System.IO.Path.DirectorySeparatorChar));
            uri1 = uri2.MakeRelativeUri(uri1);
            string relPath = uri1.ToString().Replace("%20", " ");
            AssetDatabase.ImportAsset(relPath, ImportAssetOptions.ForceUpdate);
            
            TextureImporter texSettings = AssetImporter.GetAtPath(relPath) as TextureImporter;
            if (!texSettings)
            {
                AssetDatabase.Refresh();
                AssetDatabase.ImportAsset(relPath, ImportAssetOptions.ForceUpdate);
                texSettings = AssetImporter.GetAtPath(relPath) as TextureImporter;
            }
            texSettings.textureFormat = TextureImporterFormat.AutomaticTruecolor;
            texSettings.wrapMode = TextureWrapMode.Clamp;

            AssetDatabase.Refresh();
        }
        catch(System.Exception e)
        {
            Debug.Log("Unable to change lookup texture sttings. Probably because it failed to get the relative path.\r\n"+e.Message);
        }
    }

    public override void OnInspectorGUI()
    {
        MobileISpecLookupTexture tex = target as MobileISpecLookupTexture;
        EditorGUILayout.LabelField("Diffuse", EditorStyles.boldLabel);
        EditorGUI.indentLevel++;
        
        tex.DiffuseStrength = EditorGUILayout.Slider("Diff Main Strength", tex.DiffuseStrength, 0f, 2f);
        tex.BackColorStrength = EditorGUILayout.Slider("Diff Back Light Strength", tex.BackColorStrength, 0f,2f);
        EditorGUI.indentLevel--;
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Rim Light", EditorStyles.boldLabel);
        EditorGUI.indentLevel++;
        tex.RimStrength = EditorGUILayout.Slider("Rim Light Strength", tex.RimStrength, 0f, 2f);
        tex.RimPower = EditorGUILayout.Slider("Rim Light Power", tex.RimPower, 1f, 9f);
        tex.RimBalance = EditorGUILayout.Slider("Rim Main<>Back Color", tex.RimBalance, 0f, 1f);
        EditorGUI.indentLevel--;
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Specular Hightlights", EditorStyles.boldLabel);
        EditorGUI.indentLevel++;
        tex.DirectSpec = EditorGUILayout.Slider("Direct Spec Intensity", tex.DirectSpec, 0f, 3f);
        tex.DirectShininess = EditorGUILayout.Slider("Direct Spec Power", tex.DirectShininess, 0.03f, 1f);
        tex.DirectSlope = EditorGUILayout.Slider("Direct Spec Slope", tex.DirectSlope, 0.004f, 1f);
        EditorGUILayout.Space();
        tex.IndirectFresnel = EditorGUILayout.Slider("Indir. Spec Fresnel", tex.IndirectFresnel, 0.03f, 1f);
        tex.IndirectView = EditorGUILayout.Slider("Indir. Spec View", tex.IndirectView, 0.03f, 1f);
        tex.IndirectBalance = EditorGUILayout.Slider("Indir. Spec F<>V", tex.IndirectBalance, 0f, 1f);
        EditorGUI.indentLevel--;

        EditorGUILayout.Space();

        GUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Size", EditorStyles.boldLabel);
        tex.width = EditorGUILayout.IntPopup(tex.width, texSizes, texSizeVals);
        tex.height = tex.width;
        GUILayout.EndHorizontal();
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        string targetPath = tex.TargetPath;
        EditorGUILayout.LabelField("Target Texture", EditorStyles.boldLabel);
        EditorGUILayout.Space();
        string newTarget = "";
        if (targetPath != null && targetPath.Length != 0)
        {
            string path = Application.dataPath;
            string fileName = tex.gameObject.name;
            try
            {
                System.IO.FileInfo fi = new System.IO.FileInfo(targetPath);
                path = fi.Directory.FullName;
                fileName = fi.Name;
            }
            catch(System.Exception e)
            {
                Debug.Log(e);
            }
            EditorGUILayout.LabelField(path+"\\"+fileName, EditorStyles.objectFieldThumb);
            if (GUILayout.Button("SelectPath"))
            {
                newTarget = EditorUtility.SaveFilePanel("Lookup Texture Target", path, fileName, "png");
                if (newTarget != null && newTarget.Length != 0)
                {
                    tex.TargetPath = newTarget;
                }
            }
        }
        else
        {
            EditorGUILayout.LabelField("none", EditorStyles.objectFieldThumb);
            if (GUILayout.Button("SelectPath"))
            {
                newTarget = EditorUtility.SaveFilePanel("Lookup Texture Target", Application.dataPath, tex.gameObject.name, "png");
                if (newTarget != null && newTarget.Length != 0)
                {
                    tex.TargetPath = newTarget;
                }
            }
        }
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        GUILayout.BeginHorizontal();
        tex.Preview = EditorGUILayout.Toggle("Preview", tex.Preview);
        if (GUI.changed || !System.IO.File.Exists(tex.TargetPath) || !tex.lookupTexture)
        {
            changed = true;
        }
        if (GUILayout.Button("Bake"))
        {
            tex.BakeTex();
            SaveTex();
        }
        else if (changed && tex.Preview)
        {
            int prevVal = tex.width;
            tex.width = 16;
            tex.height = 16;
            tex.BakeTex();
            SaveTex();
            tex.width = prevVal;
            tex.height = prevVal;
        }
        GUILayout.EndHorizontal();
        changed = false;
    }
}
