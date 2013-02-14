using UnityEngine;
using UnityEditor;
using System.Collections;


[CustomEditor(typeof(MobileSkinLookupTexture))]
public class MobileSkinLookupInspector : Editor {


    private static string[] texSizes = { "16", "32", "64", "128", "256" };
    private static int[] texSizeVals = { 16, 32, 64, 128, 256 };
    bool changed = false;


    private void SaveTex()
    {
        MobileSkinLookupTexture tex = target as MobileSkinLookupTexture;
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
        MobileSkinLookupTexture tex = target as MobileSkinLookupTexture;
        EditorGUILayout.LabelField("Diffuse", EditorStyles.boldLabel);
        EditorGUI.indentLevel++;
        
        tex.DiffuseStrength = EditorGUILayout.Slider("Diff Main Intensity", tex.DiffuseStrength, 0f, 2f);
        tex.KeyColor = EditorGUILayout.ColorField("Main Color", tex.KeyColor);
        tex.FillColor = EditorGUILayout.ColorField("Fill Color", tex.FillColor);
        tex.BackColorStrength = EditorGUILayout.Slider("Diff Back Light Intensity", tex.BackColorStrength, 0f, 2f);
        tex.BackColor = EditorGUILayout.ColorField("Back Color", tex.BackColor);
        EditorGUI.indentLevel--;
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Skin", EditorStyles.boldLabel);
        EditorGUI.indentLevel++;
        tex.SkinColor = EditorGUILayout.ColorField("Skin Color", tex.SkinColor);
        tex.SkinPreMul = EditorGUILayout.Slider("Skin Pre Multiplier", tex.SkinPreMul, 0f, 1f);
        tex.SkinPow = EditorGUILayout.Slider("Skin Power", tex.SkinPow, 0f, 25f);
        tex.SkinMul = EditorGUILayout.Slider("Skin Intensity", tex.SkinMul, 0f, 2f);
        tex.SkinFrontKill = EditorGUILayout.Slider("Skin Diffuse Bleed", tex.SkinFrontKill, 0f, 5f);
        tex.SkinBackKill = EditorGUILayout.Slider("Skin Back Bleed", tex.SkinBackKill, 0f, 5f);
		tex.ReplaceFill = EditorGUILayout.Toggle("Replace Fill Light",tex.ReplaceFill);
        tex.SkinOffset = EditorGUILayout.Slider("Skin Offset", tex.SkinOffset, 0f, 1f);
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
