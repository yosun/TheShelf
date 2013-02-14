/*******************************************************************************

INTEL CORPORATION PROPRIETARY INFORMATION
This software is supplied under the terms of a license agreement or nondisclosure
agreement with Intel Corporation and may not be copied or disclosed except in
accordance with the terms of that agreement
Copyright(c) 2012 Intel Corporation. All Rights Reserved.

*******************************************************************************/
using System;
using System.Runtime.InteropServices;

public struct PXCMRectU32
{
    public UInt32 x, y, w, h;
};

public struct PXCMPoint3DF32
{
	public float x, y, z;
};
	
public class PXCMFaceAnalysis
{
    public class Detection
    {
        [Flags]
        public enum ViewAngle : int
        {
            VIEW_ANGLE_0 			=	0x00000001,
            VIEW_ANGLE_45 			=	0x00000002,
            VIEW_ANGLE_FRONTAL 		=	0x00000004,
            VIEW_ANGLE_135 			=	0x00000008,
            VIEW_ANGLE_180 			=	0x00000010,
			
            VIEW_ROLL_30          	= 0x00000020,
            VIEW_ROLL_30N         	= 0x00000040,
            VIEW_ROLL_60          	= 0x00000080,
            VIEW_ROLL_60N         	= 0x00000100,

            VIEW_ANGLE_HALF_MULTI 	= VIEW_ANGLE_FRONTAL | VIEW_ANGLE_45 | VIEW_ANGLE_135,
            VIEW_ANGLE_MULTI      	= VIEW_ANGLE_HALF_MULTI | VIEW_ANGLE_0 | VIEW_ANGLE_180,
            VIEW_ANGLE_FRONTALROLL	= VIEW_ANGLE_FRONTAL | VIEW_ROLL_30| VIEW_ROLL_30N | VIEW_ROLL_60 | VIEW_ROLL_60N,
            VIEW_ANGLE_OMNI       	= -1,
        };

        public struct Data
        {
            public PXCMRectU32 	rectangle;
            public Int32		fid;
            public UInt32 		confidence;
            public ViewAngle 	viewAngle;
            private Int32	 	reserved1, reserved2, reserved3, reserved4;
        };
    };
	
	public class Landmark
	{
        [Flags] public enum Label: int {
            LABEL_LEFT_EYE_OUTER_CORNER = 0x0001000,
            LABEL_LEFT_EYE_INNER_CORNER = 0x0002000,
            LABEL_RIGHT_EYE_OUTER_CORNER = 0x0004000,
            LABEL_RIGHT_EYE_INNER_CORNER = 0x0008000,
            LABEL_MOUTH_LEFT_CORNER = 0x0010000,
            LABEL_MOUTH_RIGHT_CORNER = 0x0020000,
            LABEL_NOSE_TIP = 0x0040000,

            LABEL_6POINTS = 0x003F006,
            LABEL_7POINTS = 0x007F007,
            LABEL_SIZE_MASK = 0x0000FFF,
        };
		
	    public struct PoseData {
            public Int32	fid;
            public float	yaw;
			public float	roll;
			public float    pitch;
            private Int32   reserved1, reserved2, reserved3, reserved4;
        };
		
        public struct LandmarkData {
            public PXCMPoint3DF32 position;
            public Int32    fid;
            public Label    label;
            public UInt32   lidx;
            private Int32   rsv1, rsv2, rsv3, rsv4, rsv5, rsv6;
        };
	};
};

public class PXCMGesture
{
	public struct Gesture
	{
		[Flags]
		public enum Label: int {
            LABEL_ANY=0,
            LABEL_MASK_SET          =   unchecked((int)0xffff0000),
            LABEL_MASK_DETAILS      =   0x0000ffff,

            LABEL_SET_HAND          = 0x00010000,     /* Common hand gestures */
            LABEL_SET_NAVIGATION    = 0x00020000,     /* Navigation gestures */
            LABEL_SET_POSE          = 0x00040000,     /* Common hand poses */
            LABEL_SET_CUSTOMIZED    = 0x00080000,

            /* predefined nativation gestures */
            LABEL_NAV_SWIPE_LEFT = LABEL_SET_NAVIGATION+1,
            LABEL_NAV_SWIPE_RIGHT,
			LABEL_NAV_SWIPE_UP,
			LABEL_NAV_SWIPE_DOWN,

            /* predefined common hand gestures */
            LABEL_HAND_WAVE = LABEL_SET_HAND+1,
			LABEL_HAND_CIRCLE,

            /* predefined common hand poses */
            LABEL_POSE_THUMB_UP = LABEL_SET_POSE+1,
            LABEL_POSE_THUMB_DOWN,
            LABEL_POSE_PEACE,
            LABEL_POSE_BIG5,
        };

        public UInt64         	timeStamp;
        public Int32 	        user;
        public GeoNode.Label  	body;
        public Label            label;
        public UInt32           confidence;
        public Boolean          active;
        private UInt32          r1, r2, r3, r4, r5, r6, r7, r8, r9;
	};

	[StructLayout(LayoutKind.Explicit,Size=128)]
	public struct GeoNode 
	{
		[Flags] 
		public enum Label: int {
            LABEL_ANY=0,
            LABEL_MASK_BODY             =unchecked((int)0xffffff00),
            LABEL_MASK_DETAILS          =0x000000ff,

            /* full body labels */
            LABEL_BODY_ELBOW_PRIMARY = 0x00004000,
            LABEL_BODY_ELBOW_LEFT = 0x00004000,
            LABEL_BODY_ELBOW_SECONDARY = 0x00008000,
            LABEL_BODY_ELBOW_RIGHT = 0x00008000,
            LABEL_BODY_HAND_PRIMARY = 0x00040000,
            LABEL_BODY_HAND_LEFT = 0x00040000,
            LABEL_BODY_HAND_SECONDARY = 0x00080000,
            LABEL_BODY_HAND_RIGHT = 0x00080000,

            /* detailed labels: Hand */
            LABEL_FINGER_THUMB = 1,
            LABEL_FINGER_INDEX,
            LABEL_FINGER_MIDDLE,
            LABEL_FINGER_RING,
            LABEL_FINGER_PINKY,

            LABEL_HAND_FINGERTIP,
            LABEL_HAND_UPPER,
            LABEL_HAND_MIDDLE,
            LABEL_HAND_LOWER,
        };

        public enum Side : int
        {
            LABEL_SIDE_ANY=0,
            LABEL_LEFT,
            LABEL_RIGHT,
        };

        public enum Openness : int
        {
            LABEL_OPENNESS_ANY=0,
            LABEL_CLOSE,
            LABEL_OPEN,
        };

        [FieldOffset(0)]   public  UInt64           timeStamp;
        [FieldOffset(8)]   public  Int32            user;
        [FieldOffset(12)]  public  Label            body;
        [FieldOffset(16)]  public  Side             side;
		[FieldOffset(20)]  public  UInt32		    confidence;
        [FieldOffset(24)]  public  PXCMPoint3DF32   positionWorld;
        [FieldOffset(36)]  public  PXCMPoint3DF32   positionImage;
		[FieldOffset(64)]  public  float            radiusWorld;
		[FieldOffset(68)]  public  float      	   	radiusImage;
		[FieldOffset(64)]  public  PXCMPoint3DF32   massCenterWorld;
		[FieldOffset(76)]  public  PXCMPoint3DF32   massCenterImage;
		[FieldOffset(88)]  public  PXCMPoint3DF32   normal;
		[FieldOffset(100)] public  UInt32           openness;
		[FieldOffset(104)] public  Openness         opennessState;
	};

   	public struct Blob
	{
		[Flags] 
		public enum Label: int {
            LABEL_ANY=0,
            LABEL_SCENE=1,
        };

        public  UInt64  timeStamp;
        public  Label   name;
        public  UInt32  labelBackground;
        public  UInt32  labelLeftHand;
        public  UInt32  labelRightHand;
        private UInt32  r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24, r25, r26;
    };
};

public class PXCMCapture {
	public class Device {
        public enum Property: int {
            /* Single value properties */
            PROPERTY_COLOR_EXPOSURE             =   1,
            PROPERTY_COLOR_BRIGHTNESS           =   2,
            PROPERTY_COLOR_CONTRAST             =   3,
            PROPERTY_COLOR_SATURATION           =   4,
            PROPERTY_COLOR_HUE                  =   5,
            PROPERTY_COLOR_GAMMA                =   6,
            PROPERTY_COLOR_WHITE_BALANCE        =   7,
            PROPERTY_COLOR_SHARPNESS            =   8,
            PROPERTY_COLOR_BACK_LIGHT_COMPENSATION  =   9,
            PROPERTY_COLOR_GAIN                     =   10,
            PROPERTY_AUDIO_MIX_LEVEL            =   100,
			PROPERTY_DEPTH_SATURATION_VALUE		=   200,
			PROPERTY_DEPTH_LOW_CONFIDENCE_VALUE	=   201,
            PROPERTY_DEPTH_CONFIDENCE_THRESHOLD =   202,
            PROPERTY_DEPTH_SMOOTHING            =   203,

            /* Two value properties */
            PROPERTY_COLOR_FIELD_OF_VIEW        =   1000,
            PROPERTY_COLOR_SENSOR_RANGE         =   1002,
            PROPERTY_COLOR_FOCAL_LENGTH         =   1006,
            PROPERTY_COLOR_PRINCIPAL_POINT      =   1008,

            PROPERTY_DEPTH_FIELD_OF_VIEW        =   2000,
            PROPERTY_DEPTH_SENSOR_RANGE         =   2002,
            PROPERTY_DEPTH_FOCAL_LENGTH         =   2006,
            PROPERTY_DEPTH_PRINCIPAL_POINT      =   2008,

            /* Three value properties */
            PROPERTY_ACCELEROMETER_READING      =   3000,

            /* Customized properties */
            PROPERTY_CUSTOMIZED=0x04000000,
        };
	};
};

public class PXCMVoiceRecognition {
	public struct Recognition {
    	public struct NBest {
            public Int32	label;
            public Int32 	confidence;
        };

        public UInt64	timeStamp;
        public NBest[] 	nBest;
        public UInt32   duration;
        public String 	dictation;
		
		public Int32 label {
        	get	{
            	return nBest[0].label;
        	}
	        set {
            	nBest[0].label=value;
			}
        }
		
		public Int32 confidence {
        	get	{
            	return nBest[0].confidence;
        	}
	        set {
            	nBest[0].confidence=value;
			}
		}
    };
};
