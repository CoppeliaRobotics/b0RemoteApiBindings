// -------------------------------------------------------
// Add your custom functions at the bottom of the file
// and the server counterpart to lua/b0RemoteApiServer.lua
// -------------------------------------------------------

#pragma once

#include <string>
#include <vector>
#include <map>
#include <b0/node.h>
#include <b0/publisher.h>
#include <b0/subscriber.h>
#include <b0/service_client.h>
#include "msgpack.hpp"

#ifndef _WIN32
    #define __cdecl
#endif

typedef boost::function<void(std::vector<msgpack::object>*)> CB_FUNC;
typedef std::string msgTopic;

struct SHandleAndCb
{
    b0::Subscriber* handle;
    bool dropMessages;
    CB_FUNC cb;
};


class b0RemoteApi
{
public:
    b0RemoteApi(const char* nodeName="b0RemoteApi_c++Client",const char* channelName="b0RemoteApi",int inactivityToleranceInSec=60,bool setupSubscribersAsynchronously=false);
    virtual ~b0RemoteApi();

    msgTopic simxServiceCall();
    msgTopic simxDefaultPublisher();
    msgTopic simxDefaultSubscriber(CB_FUNC cb,int publishInterval=1);
    msgTopic simxCreatePublisher(bool dropMessages=false);
    msgTopic simxCreateSubscriber(CB_FUNC cb,int publishInterval=1,bool dropMessages=false);

    unsigned int simxGetTimeInMs();
    void simxSleep(int durationInMs);
    void simxSpin();
    void simxSpinOnce();

    void simxSynchronous(bool enable);
    void simxSynchronousTrigger();
    void simxGetSimulationStepDone(msgTopic topic);
    void simxGetSimulationStepStarted(msgTopic topic);

    static void print(const std::vector<msgpack::object>* msg);
    static bool hasValue(const std::vector<msgpack::object>* msg);
    static const msgpack::object* readValue(std::vector<msgpack::object>* msg,int valuesToDiscard=0,bool* success=NULL);
    static bool readBool(std::vector<msgpack::object>* msg,int valuesToDiscard=0,bool* success=NULL);
    static int readInt(std::vector<msgpack::object>* msg,int valuesToDiscard=0,bool* success=NULL);
    static float readFloat(std::vector<msgpack::object>* msg,int valuesToDiscard=0,bool* success=NULL);
    static double readDouble(std::vector<msgpack::object>* msg,int valuesToDiscard=0,bool* success=NULL);
    static std::string readString(std::vector<msgpack::object>* msg,int valuesToDiscard=0,bool* success=NULL);
    static std::string readByteArray(std::vector<msgpack::object>* msg,int valuesToDiscard=0,bool* success=NULL);
    static bool readIntArray(std::vector<msgpack::object>* msg,std::vector<int>& array,int valuesToDiscard=0);
    static bool readFloatArray(std::vector<msgpack::object>* msg,std::vector<float>& array,int valuesToDiscard=0);
    static bool readDoubleArray(std::vector<msgpack::object>* msg,std::vector<double>& array,int valuesToDiscard=0);
    static bool readStringArray(std::vector<msgpack::object>* msg,std::vector<std::string>& array,int valuesToDiscard=0);

protected:
    std::vector<msgpack::object>* _handleFunction(const char* funcName,const std::string& packedArgs,msgTopic topic);
    void _handleReceivedMessage(const std::string packedData);
    void _pingCallback(std::vector<msgpack::object>* msg);

    msgTopic _serviceCallTopic;
    msgTopic _defaultPublisherTopic;
    msgTopic _defaultSubscriberTopic;
    int _nextDefaultSubscriberHandle;
    int _nextDedicatedPublisherHandle;
    int _nextDedicatedSubscriberHandle;
    bool _pongReceived;
    bool _setupSubscribersAsynchronously;
    msgpack::unpacked _tmpUnpackedMsg;
    std::vector<msgpack::object> _tmpMsgPackObjects;
    std::string _channelName;
    b0::Node* _node;
    std::string _clientId;
    b0::ServiceClient* _serviceClient;
    b0::Publisher* _defaultPublisher;
    b0::Subscriber* _defaultSubscriber;
    std::map<msgTopic,SHandleAndCb> _allSubscribers;
    std::map<msgTopic,b0::Publisher*> _allDedicatedPublishers;

public:
    std::vector<msgpack::object>* simxGetObjectHandle(const char* objectName,msgTopic topic);
    std::vector<msgpack::object>* simxAddStatusbarMessage(const char* msg,msgTopic topic);
    std::vector<msgpack::object>* simxGetObjectPosition(int objectHandle,int relObjHandle,msgTopic topic);
    std::vector<msgpack::object>* simxStartSimulation(msgTopic topic);
    std::vector<msgpack::object>* simxStopSimulation(msgTopic topic);
    std::vector<msgpack::object>* simxGetVisionSensorImage(int objectHandle,bool greyScale,msgTopic topic);
    std::vector<msgpack::object>* simxSetVisionSensorImage(int objectHandle,bool greyScale,const char* img,size_t imgSize,msgTopic topic);

    std::vector<msgpack::object>* simxAuxiliaryConsoleClose(int consoleHandle,msgTopic topic);
    std::vector<msgpack::object>* simxAuxiliaryConsolePrint(int consoleHandle,const char* text,msgTopic topic);
    std::vector<msgpack::object>* simxAuxiliaryConsoleOpen(const char* title,int maxLines,int mode,const int position[2],const int size[2],const float textColor[3],const float backgroundColor[3],msgTopic topic);
    std::vector<msgpack::object>* simxAuxiliaryConsoleShow(int consoleHandle,bool showState,msgTopic topic);

    std::vector<msgpack::object>* simxAddDrawingObject_points(int size,const int color[3],const float coords[3],int pointCnt,msgTopic topic);
    std::vector<msgpack::object>* simxAddDrawingObject_spheres(float size,const int color[3],const float coords[3],int sphereCnt,msgTopic topic);
    std::vector<msgpack::object>* simxAddDrawingObject_cubes(float size,const int color[3],const float coords[3],int cubeCnt,msgTopic topic);
    std::vector<msgpack::object>* simxAddDrawingObject_segments(int lineSize,const int color[3],const float* segments,int segmentCnt,msgTopic topic);
    std::vector<msgpack::object>* simxAddDrawingObject_triangles(const int color[3],const float* triangles,int triangleCnt,msgTopic topic);
    std::vector<msgpack::object>* simxRemoveDrawingObject(int handle,msgTopic topic);
    std::vector<msgpack::object>* simxCallScriptFunction(const char* funcAtObjName,int scriptType,const char* packedData,size_t packedDataSize,msgTopic topic);
    std::vector<msgpack::object>* simxCallScriptFunction(const char* funcAtObjName,const char* scriptType,const char* packedData,size_t packedDataSize,msgTopic topic);
    std::vector<msgpack::object>* simxCheckCollision(int entity1,int entity2,msgTopic topic);
    std::vector<msgpack::object>* simxCheckCollision(int entity1,const char* entity2,msgTopic topic);
    std::vector<msgpack::object>* simxGetCollisionHandle(const char* name,msgTopic topic);
    std::vector<msgpack::object>* simxReadCollision(int handle,msgTopic topic);
    std::vector<msgpack::object>* simxCheckDistance(int entity1,int entity2,float threshold,msgTopic topic);
    std::vector<msgpack::object>* simxCheckDistance(int entity1,const char* entity2,float threshold,msgTopic topic);
    std::vector<msgpack::object>* simxGetDistanceHandle(const char* name,msgTopic topic);
    std::vector<msgpack::object>* simxReadDistance(int handle,msgTopic topic);
    std::vector<msgpack::object>* simxCheckProximitySensor(int sensor,int entity,msgTopic topic);
    std::vector<msgpack::object>* simxCheckProximitySensor(int sensor,const char* entity,msgTopic topic);
    std::vector<msgpack::object>* simxReadProximitySensor(int handle,msgTopic topic);
    std::vector<msgpack::object>* simxCheckVisionSensor(int sensor,int entity,msgTopic topic);
    std::vector<msgpack::object>* simxCheckVisionSensor(int sensor,const char* entity,msgTopic topic);
    std::vector<msgpack::object>* simxReadVisionSensor(int handle,msgTopic topic);
    std::vector<msgpack::object>* simxReadForceSensor(int handle,msgTopic topic);
    std::vector<msgpack::object>* simxBreakForceSensor(int handle,msgTopic topic);
    std::vector<msgpack::object>* simxClearFloatSignal(const char* sig,msgTopic topic);
    std::vector<msgpack::object>* simxClearIntegerSignal(const char* sig,msgTopic topic);
    std::vector<msgpack::object>* simxClearStringSignal(const char* sig,msgTopic topic);
    std::vector<msgpack::object>* simxSetFloatSignal(const char* sig,float val,msgTopic topic);
    std::vector<msgpack::object>* simxSetIntegerSignal(const char* sig,int val,msgTopic topic);
    std::vector<msgpack::object>* simxSetStringSignal(const char* sig,const char* val,size_t valSize,msgTopic topic);
    std::vector<msgpack::object>* simxGetFloatSignal(const char* sig,msgTopic topic);
    std::vector<msgpack::object>* simxGetIntegerSignal(const char* sig,msgTopic topic);
    std::vector<msgpack::object>* simxGetStringSignal(const char* sig,msgTopic topic);

    std::vector<msgpack::object>* simxSetObjectPosition(int objectHandle,int refObjectHandle,const float pos[3],msgTopic topic);
    std::vector<msgpack::object>* simxGetObjectOrientation(int objectHandle,int refObjectHandle,msgTopic topic);
    std::vector<msgpack::object>* simxSetObjectOrientation(int objectHandle,int refObjectHandle,const float euler[3],msgTopic topic);
    std::vector<msgpack::object>* simxGetObjectQuaternion(int objectHandle,int refObjectHandle,msgTopic topic);
    std::vector<msgpack::object>* simxSetObjectQuaternion(int objectHandle,int refObjectHandle,const float quat[4],msgTopic topic);
    std::vector<msgpack::object>* simxGetObjectPose(int objectHandle,int refObjectHandle,msgTopic topic);
    std::vector<msgpack::object>* simxSetObjectPose(int objectHandle,int refObjectHandle,const float pose[7],msgTopic topic);
    std::vector<msgpack::object>* simxGetObjectMatrix(int objectHandle,int refObjectHandle,msgTopic topic);
    std::vector<msgpack::object>* simxSetObjectMatrix(int objectHandle,int refObjectHandle,const float matr[12],msgTopic topic);

    // -------------------------------
    // Add your custom functions here:
    // -------------------------------
    
};
