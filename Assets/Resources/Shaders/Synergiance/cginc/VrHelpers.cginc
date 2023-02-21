// Some helper variables for VR

#if defined(USING_STEREO_MATRICES)
	#define _WorldSpaceCameraCenterPos ((unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) * 0.5)
	#define _ActualWorldSpaceCameraPos unity_StereoWorldSpaceCameraPos[unity_StereoEyeIndex]
#else
	#define _WorldSpaceCameraCenterPos _WorldSpaceCameraPos
	#define _ActualWorldSpaceCameraPos _WorldSpaceCameraPos
#endif
