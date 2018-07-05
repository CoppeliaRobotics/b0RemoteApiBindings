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

typedef boost::function<void(std::vector<msgpack::object>*,const std::string*)> CB_FUNC;
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


    std::vector<msgpack::object>* simxGetObjectHandle(const char* objectName,msgTopic topic,std::string* errorString=NULL);
    std::vector<msgpack::object>* simxAddStatusbarMessage(const char* msg,msgTopic topic,std::string* errorString=NULL);
    std::vector<msgpack::object>* simxGetObjectPosition(int objectHandle,int relObjHandle,msgTopic topic,std::string* errorString=NULL);
    std::vector<msgpack::object>* simxStartSimulation(msgTopic topic,std::string* errorString=NULL);
    std::vector<msgpack::object>* simxStopSimulation(msgTopic topic,std::string* errorString=NULL);
    std::vector<msgpack::object>* simxGetVisionSensorImage(int objectHandle,bool greyScale,msgTopic topic,std::string* errorString=NULL);
    std::vector<msgpack::object>* simxSetVisionSensorImage(int objectHandle,bool greyScale,const std::string& img,msgTopic topic,std::string* errorString=NULL);

protected:
    std::vector<msgpack::object>* _handleFunction(const char* funcName,const std::string& packedArgs,msgTopic topic,std::string* errorString);
    void _handleReceivedMessage(const std::string packedData);
    void _pingCallback(std::vector<msgpack::object>* msg,const std::string* errorStr);

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
};
