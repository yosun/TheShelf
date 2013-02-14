using UnityEngine;
using System.Collections;
using UnityEditor;

[CustomEditor(typeof(ToonPack))]
public class ToonPackInspector : Editor {
 
    bool changed = false;
    bool gradientReadable;

    public override void OnInspectorGUI()
    {

        ToonPack tex = target as ToonPack;
        EditorGUILayout.Space();
        Object o = EditorGUILayout.ObjectField("Original Gradient", tex.gradient, typeof(Texture2D));
        try
        {
            tex.gradient = (Texture2D)o;
        }
        catch
        {
        }

        EditorGUILayout.Space();
        tex.OLP = EditorGUILayout.Slider("Outline Thickness", tex.OLP, 2f, 32f);
        EditorGUILayout.Space();
        tex.Sharpness = EditorGUILayout.Slider("Outline Sharpness", tex.Sharpness, 1f, 32f);
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
            catch (System.Exception e)
            {
                Debug.Log(e);
            }
            EditorGUILayout.LabelField(path + "\\" + fileName, EditorStyles.objectFieldThumb);
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
        if (GUILayout.Button("Bake") || (changed && tex.Preview))
        {
            ChangeGradientSettings(tex);
            tex.BakeTex();
            SaveTex();
            ResetGradientSettings(tex);
        }
        GUILayout.EndHorizontal();
        changed = false;
    }

    private void ChangeGradientSettings(ToonPack t)
    {
        if(t.gradient)
        {
            string path = AssetDatabase.GetAssetPath(t.gradient);
            TextureImporter ti = AssetImporter.GetAtPath(path) as TextureImporter;
            gradientReadable = ti.isReadable;
            ti.isReadable = true;
            AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
            AssetDatabase.Refresh();
        }
    }

    private void ResetGradientSettings(ToonPack t)
    {
        if (t.gradient)
        {
            string path = AssetDatabase.GetAssetPath(t.gradient);
            TextureImporter ti = AssetImporter.GetAtPath(path) as TextureImporter;
            ti.isReadable = gradientReadable;
            AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
            AssetDatabase.Refresh();
        }
    }

    private void SaveTex()
    {
        ToonPack tex = target as ToonPack;
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
        catch (System.Exception e)
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
        catch (System.Exception e)
        {
            Debug.Log("Unable to change lookup texture sttings. Probably because it failed to get the relative path.\r\n" + e.Message);
        }
    }
}