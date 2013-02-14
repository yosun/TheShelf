/*******************************************************************************

INTEL CORPORATION PROPRIETARY INFORMATION
This software is supplied under the terms of a license agreement or nondisclosure
agreement with Intel Corporation and may not be copied or disclosed except in
accordance with the terms of that agreement
Copyright(c) 2012 Intel Corporation. All Rights Reserved.

*******************************************************************************/
using UnityEngine;
using System;
using System.Runtime.InteropServices;
using System.Linq;
using System.Text;

public class PXCUPipeline: IDisposable {
	[Flags] public enum Mode {
	    GESTURE       		=	0x00000002,
	    FACE_LOCATION 		=	0x00000004,
	    FACE_LANDMARK 		=	0x00000008,
		COLOR_VGA			=	0x00000001,
		COLOR_WXGA			=	0x00000010,
		DEPTH_QVGA			=	0x00000020,
		VOICE_RECOGNITION	=	0x00000040,
	};
	
	private IntPtr 	instance;
	private bool 	initialized;
	private bool 	disposed=false;
	
	public PXCUPipeline() {
		instance=CreateC();
		initialized=false;
	}

	~PXCUPipeline() {
		Dispose(false);
	}

	public void Dispose() {
		Dispose(true);
		GC.SuppressFinalize(this);
	}
	
	private void Dispose(bool dispose) {
		if(!this.disposed) {
			if (instance!=IntPtr.Zero) {
				if (initialized) {
					CloseC(instance);
					initialized=false;
				}
				DestroyC(instance);
				instance=IntPtr.Zero;
			}
		}
        disposed=true;
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_Create")]
    private static extern IntPtr CreateC();
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_Destroy")]
    private static extern void DestroyC(IntPtr pp);
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_Init")]
    private static extern bool InitC(IntPtr pp, Mode mode);
	
	public bool Init(Mode mode) {
		if (instance==IntPtr.Zero) return false;
		initialized=InitC(instance,mode);
		return initialized;
	}
	
    [DllImport("libpxcupipeline", EntryPoint="PXCUPipeline_Close")]
    private static extern void CloseC(IntPtr pp);
	
	public void Close() {
		if (instance==IntPtr.Zero) return;
		if (initialized) {
			CloseC(instance);
			initialized=false;
		}
		DestroyC(instance);
		instance=IntPtr.Zero;
	}
	
    [DllImport("libpxcupipeline", EntryPoint="PXCUPipeline_AcquireFrame")]
    private static extern bool AcquireFrameC(IntPtr pp, bool wait);
	
	public bool AcquireFrame(bool wait) {
		if (!initialized) return false;
		return AcquireFrameC(instance,wait);
	}
	
    [DllImport("libpxcupipeline", EntryPoint="PXCUPipeline_IsDisconnected")]
    private static extern bool IsDisconnectedC(IntPtr pp);
	
	public bool IsDisconnected() {
		if (!initialized) return false;
		return IsDisconnectedC(instance);
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryRGBSize")]
    private static extern bool QueryRGBSizeC(IntPtr pp, out int width, out int height);
	
	public bool QueryRGBSize(int[] size) {
		if (!initialized) return false;
		return QueryRGBSizeC(instance,out size[0],out size[1]);
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryRGB")]
    private static extern bool QueryRGBC(IntPtr pp, IntPtr data);

	public bool QueryRGB(Texture2D text2d) {
		if (!initialized || text2d==null) return false;
	    Color32[] pixels=text2d.GetPixels32(0);
        GCHandle pixelsHandle = GCHandle.Alloc(pixels, GCHandleType.Pinned);
		bool sts=QueryRGBC(instance,pixelsHandle.AddrOfPinnedObject());
        text2d.SetPixels32 (pixels, 0);
		pixelsHandle.Free();
		return sts;
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryUVMapSize")]
    private static extern bool QueryUVMapSizeC(IntPtr pp, out int width, out int height);

	public bool QueryUVMapSize(int[] size) {
		if (!initialized) return false;
		return QueryUVMapSizeC(instance,out size[0],out size[1]);
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryUVMap")]
    private static extern bool QueryUVMapC(IntPtr pp, IntPtr data);
	
	public bool QueryUVMap(float[] uvmap) {
		if (!initialized) return false;
        GCHandle uvmapHandle = GCHandle.Alloc(uvmap, GCHandleType.Pinned);
		bool sts=QueryUVMapC(instance,uvmapHandle.AddrOfPinnedObject());
		uvmapHandle.Free();
		return sts;
	}

    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryDepthMapSize")]
    private static extern bool QueryDepthMapSizeC(IntPtr pp, out int width, out int height);
	
	public bool QueryDepthMapSize(int[] size) {
		if (!initialized) return false;
		return QueryDepthMapSizeC(instance,out size[0],out size[1]);
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryDepthMap")]
    private static extern bool QueryDepthMapC(IntPtr pp, IntPtr data);

    public bool QueryDepthMap(short[] depthmap)
    {
		if (!initialized) return false;
        GCHandle depthmapHandle = GCHandle.Alloc(depthmap, GCHandleType.Pinned);
        bool sts = QueryDepthMapC(instance,depthmapHandle.AddrOfPinnedObject());
        depthmapHandle.Free();
        return sts;
    }

    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryIRMapSize")]
    private static extern bool QueryIRMapSizeC(IntPtr pp, out int width, out int height);
	
    public bool QueryIRMapSize(int[] size) {
		if (!initialized) return false;
		return QueryIRMapSizeC(instance,out size[0],out size[1]);
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryIRMap")]
    private static extern bool QueryIRMapC(IntPtr pp, IntPtr data);

    public bool QueryIRMap(short[] irmap)
    {
		if (!initialized) return false;
        GCHandle irmapHandle = GCHandle.Alloc(irmap, GCHandleType.Pinned);
        bool sts = QueryIRMapC(instance,irmapHandle.AddrOfPinnedObject());
        irmapHandle.Free();
        return sts;
    }

    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryLabelMapSize")]
    private static extern bool QueryLabelMapSizeC(IntPtr pp, out int width, out int height);
	
    public bool QueryLabelMapSize(int[] size) {
		if (!initialized) return false;
		return QueryLabelMapSizeC(instance,out size[0],out size[1]);
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryLabelMap")]
    private static extern bool QueryLabelMapC(IntPtr pp, IntPtr data, IntPtr labels);
	
	public bool QueryLabelMapAsImage(Texture2D text2d) {
		if (!initialized || text2d==null) return false;
		byte[] labelmap=new byte[text2d.width*text2d.height];
		int[] labels=new int[3];
		if (!QueryLabelMap(labelmap,labels)) return false; 
		
	    Color32[] pixels=text2d.GetPixels32(0);
		for (int i=0;i<text2d.width*text2d.height;i++)
			pixels[i]=new Color32(labelmap[i],labelmap[i],labelmap[i],0);
        text2d.SetPixels32 (pixels, 0);
		return true;
	}

	public bool QueryLabelMap(byte[] labelmap, int[] labels) {
		if (!initialized) return false;
        GCHandle lmapHandle = GCHandle.Alloc(labelmap, GCHandleType.Pinned);
        GCHandle labelsHandle = GCHandle.Alloc(labels, GCHandleType.Pinned);
        bool sts = QueryLabelMapC(instance,(IntPtr)lmapHandle.AddrOfPinnedObject(),(IntPtr)labelsHandle.AddrOfPinnedObject());
		lmapHandle.Free();
        labelsHandle.Free();
		return sts;
	}
	
    // gesture functions
    [DllImport("libpxcupipeline", EntryPoint="PXCUPipeline_QueryGeoNode")]
    private static extern bool QueryGeoNodeC(IntPtr pp, PXCMGesture.GeoNode.Label body, out PXCMGesture.GeoNode data);
	
	public bool QueryGeoNode(PXCMGesture.GeoNode.Label body, out PXCMGesture.GeoNode data) {
		if (initialized) return QueryGeoNodeC(instance, body,out data);
		data=new PXCMGesture.GeoNode();
		return false;		
	}
	
	public bool QueryGeoNode(PXCMGesture.GeoNode.Label body, PXCMGesture.GeoNode[] data) {
		bool found=false;
		for (int i=0;i<data.Length;i++,body++) {
			if (!QueryGeoNode(body,out data[i])) 
				data[i].body=PXCMGesture.GeoNode.Label.LABEL_ANY;
			else
				found=true;
		}
		return found;
	}
	
    [DllImport("libpxcupipeline", EntryPoint="PXCUPipeline_QueryGesture")]
    private static extern bool QueryGestureC(IntPtr pp, PXCMGesture.GeoNode.Label body, out PXCMGesture.Gesture data);

	public bool QueryGesture(PXCMGesture.GeoNode.Label body, out PXCMGesture.Gesture data) {
		if (initialized) return QueryGestureC(instance,body,out data);
		data=new PXCMGesture.Gesture();
		return false;
	}
	
    // face analysis functions
    [DllImport("libpxcupipeline", EntryPoint="PXCUPipeline_QueryFaceID")]
    private static extern bool QueryFaceIDC(IntPtr pp, int fidx, out Int32 face, out UInt64 timeStamp);
	
	public bool QueryFaceID(int fidx, out Int32 face, out UInt64 timeStamp) {
		face=0; timeStamp=0;
		if (!initialized) return false;
		return QueryFaceIDC(instance, fidx,out face,out timeStamp);
	}
	
    [DllImport("libpxcupipeline", EntryPoint="PXCUPipeline_QueryFaceLocationData")]
    private static extern bool QueryFaceLocationDataC(IntPtr pp, Int32 face, out PXCMFaceAnalysis.Detection.Data data);

    public bool QueryFaceLocationData(Int32 face, out PXCMFaceAnalysis.Detection.Data data) {
		if (initialized) return QueryFaceLocationDataC(instance,face,out data);
		data=new PXCMFaceAnalysis.Detection.Data();
		return false;
	}
	
    [DllImport("libpxcupipeline", EntryPoint="PXCUPipeline_QueryFaceLandmarkPose")]
    private static extern bool QueryFaceLandmarkPoseC(IntPtr pp, Int32 face, out PXCMFaceAnalysis.Landmark.PoseData data);
	
    public bool QueryFaceLandmarkPose(Int32 face, out PXCMFaceAnalysis.Landmark.PoseData data) {
		if (initialized) return QueryFaceLandmarkPoseC(instance,face,out data);
		data=new PXCMFaceAnalysis.Landmark.PoseData();
		return false;
	}
	
    [DllImport("libpxcupipeline", EntryPoint="PXCUPipeline_QueryFaceLandmarkData")]
    private static extern bool QueryFaceLandmarkDataC(IntPtr pp, Int32 face, PXCMFaceAnalysis.Landmark.Label label, int idx, out PXCMFaceAnalysis.Landmark.LandmarkData data);

    public bool QueryFaceLandmarkData(Int32 face, PXCMFaceAnalysis.Landmark.Label label, int idx, out PXCMFaceAnalysis.Landmark.LandmarkData data) {
		if (initialized) return QueryFaceLandmarkDataC(instance,face,label,idx,out data);
		data=new PXCMFaceAnalysis.Landmark.LandmarkData();
		return false;
	}
	
    public bool QueryFaceLandmarkData(Int32 face, PXCMFaceAnalysis.Landmark.Label label, PXCMFaceAnalysis.Landmark.LandmarkData[] data) {
        bool sts = false; 
        for (int i=0;i<data.Length;i++)
            if (QueryFaceLandmarkData(face,label,i,out data[i])) sts=true;
        return sts;
    }

    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_ReleaseFrame")]
    private static extern void ReleaseFrameC(IntPtr pp);
	
    public void ReleaseFrame() {
		if (!initialized) return;
		ReleaseFrameC(instance);
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryDeviceProperty")]
    private static extern bool QueryDevicePropertyC(IntPtr pp, PXCMCapture.Device.Property pty, int npty, IntPtr data);

    public bool QueryDeviceProperty(PXCMCapture.Device.Property pty, float[] data) {
		if (!initialized) return false;
        GCHandle dataHandle = GCHandle.Alloc(data, GCHandleType.Pinned);
        bool sts = QueryDevicePropertyC(instance, pty, data.Length, dataHandle.AddrOfPinnedObject());
        dataHandle.Free();
        return sts;
    }

    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_SetDeviceProperty")]
    private static extern bool SetDevicePropertyC(IntPtr pp, PXCMCapture.Device.Property pty, int npty, IntPtr data);

    public bool SetDeviceProperty(PXCMCapture.Device.Property pty, float[] data) {
		if (!initialized) return false;
        GCHandle dataHandle = GCHandle.Alloc(data, GCHandleType.Pinned);
        bool sts = SetDevicePropertyC(instance, pty, data.Length, dataHandle.AddrOfPinnedObject());
        dataHandle.Free();
        return sts;
    }
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_QueryVoiceRecognized")]
    private static extern bool QueryVoiceRecognizedC(IntPtr pp,IntPtr data);
	
	public bool QueryVoiceRecognized(out PXCMVoiceRecognition.Recognition data) {
		data=new PXCMVoiceRecognition.Recognition();
		data.nBest=new PXCMVoiceRecognition.Recognition.NBest[4];
		data.dictation="";
		if (!initialized) return false;
		
		IntPtr data1=Marshal.AllocHGlobal(2112);
		bool sts=QueryVoiceRecognizedC(instance,data1);
		if (sts) {
			data.timeStamp=(ulong)Marshal.ReadInt64(data1,0);
			for (int i=0;i<4;i++) {
				data.nBest[i].label=Marshal.ReadInt32(data1,8+i*8);
				data.nBest[i].confidence=Marshal.ReadInt32(data1,8+i*8+4);
			}
			data.duration=(uint)Marshal.ReadInt32(data1,60);
			data.dictation=Marshal.PtrToStringUni(new IntPtr(data1.ToInt64()+64),1024).Split(new Char[]{'\0'})[0];
		}
		Marshal.FreeHGlobal(data1);
		return sts;
	}

    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_SetVoiceCommand", CharSet=CharSet.Unicode)]
    private static extern bool SetVoiceCommandC(IntPtr pp, [MarshalAs(UnmanagedType.LPTStr)] String cmd);
	
	public bool SetVoiceCommands(String[] cmds) {
		if (instance==IntPtr.Zero) return false;
		for (int i=0;i<cmds.Length;i++)
			if (!SetVoiceCommandC(instance,cmds[i])) return false;
		return SetVoiceCommandC(instance,null);
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_SetVoiceDictation")]
    private static extern bool SetVoiceDictationC(IntPtr pp);
	
	public bool SetVoiceDictation() {
		if (instance==IntPtr.Zero) return false;
		return SetVoiceDictationC(instance);
	}
	
    [DllImport("libpxcupipeline", EntryPoint = "PXCUPipeline_PauseFrame")]
    private static extern void PauseFrameC(IntPtr pp, Mode mode, bool pause);
	
	public void PauseFrame(Mode mode, bool pause) {
		if (initialized) PauseFrameC(instance,mode,pause);
	}
};
