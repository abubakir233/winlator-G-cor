#include <jni.h>

JNIEXPORT jlong JNICALL
Java_com_winlator_winhandler_MIDIHandler_nativeAllocate(JNIEnv *env, jobject obj) { return 0; }
JNIEXPORT void JNICALL
Java_com_winlator_winhandler_MIDIHandler_destroy(JNIEnv *env, jobject obj, jlong nativePtr) {}
JNIEXPORT void JNICALL
Java_com_winlator_winhandler_MIDIHandler_noteOn(JNIEnv *env, jobject obj, jlong nativePtr, jint channel, jint note, jint velocity) {}
JNIEXPORT void JNICALL
Java_com_winlator_winhandler_MIDIHandler_noteOff(JNIEnv *env, jobject obj, jlong nativePtr, jint channel, jint note) {}
JNIEXPORT void JNICALL
Java_com_winlator_winhandler_MIDIHandler_loadSoundFont(JNIEnv *env, jobject obj, jlong nativePtr, jstring soundFontPath) {}
JNIEXPORT void JNICALL
Java_com_winlator_winhandler_MIDIHandler_programChange(JNIEnv *env, jobject obj, jlong nativePtr, jint channel, jint program) {}
JNIEXPORT void JNICALL
Java_com_winlator_winhandler_MIDIHandler_controlChange(JNIEnv *env, jobject obj, jlong nativePtr, jint channel, jint control, jint value) {}
JNIEXPORT void JNICALL
Java_com_winlator_winhandler_MIDIHandler_pitchBend(JNIEnv *env, jobject obj, jlong nativePtr, jint channel, jint value) {}
JNIEXPORT void JNICALL
Java_com_winlator_winhandler_MIDIHandler_keyPressure(JNIEnv *env, jobject obj, jlong nativePtr, jint channel, jint key, jint value) {}
