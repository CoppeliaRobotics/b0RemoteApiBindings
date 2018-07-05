#include "b0RemoteApi.h"

b0RemoteApi::b0RemoteApi(const char* nodeName,const char* channelName,int inactivityToleranceInSec,bool setupSubscribersAsynchronously)
{
    _channelName=channelName;
    _serviceCallTopic=_channelName+"SerX";
    _defaultPublisherTopic=_channelName+"SubX";
    _defaultSubscriberTopic=_channelName+"PubX";
    _nextDefaultSubscriberHandle=2;
    _nextDedicatedPublisherHandle=500;
    _nextDedicatedSubscriberHandle=1000;
    _node=new b0::Node(nodeName);
    srand((unsigned int)_node->hardwareTimeUSec());
    const char* alp="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    for (size_t i=0;i<10;i++)
    {
        size_t p=size_t(61.9f*(float(rand())/RAND_MAX));
        _clientId+=alp[p];
    }
    _serviceClient=new b0::ServiceClient(_node,_serviceCallTopic);
    _defaultPublisher=new b0::Publisher(_node,_defaultPublisherTopic);
    _defaultSubscriber=new b0::Subscriber(_node,_defaultSubscriberTopic,NULL); // we will poll the socket
    std::cout << "\n  Running B0 Remote API client with channel name [" << channelName << "]" << std::endl;
    std::cout << "  make sure that: 1) the B0 resolver is running" << std::endl;
    std::cout << "                  2) V-REP is running the B0 Remote API server with the same channel name" << std::endl;
    std::cout << "  Initializing...\n" << std::endl;
    _node->init();

    std::tuple<int> args(inactivityToleranceInSec);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    _handleFunction("inactivityTolerance",packedArgs.str(),_serviceCallTopic,NULL);
    _setupSubscribersAsynchronously=setupSubscribersAsynchronously;

    std::cout << "\n  Connected!\n" << std::endl;
}

b0RemoteApi::~b0RemoteApi()
{
    _pongReceived=false;
    std::tuple<int> args1(0);
    std::stringstream packedArgs1;
    msgpack::pack(packedArgs1,args1);
    msgTopic pingTopic=simxDefaultSubscriber(boost::bind(&b0RemoteApi::_pingCallback,this,_1,_2));
    _handleFunction("Ping",packedArgs1.str(),pingTopic,NULL);
    while (!_pongReceived)
        simxSpinOnce();

    std::tuple<std::string> args2(_clientId);
    std::stringstream packedArgs2;
    msgpack::pack(packedArgs2,args2);
    _handleFunction("DisconnectClient",packedArgs2.str(),_serviceCallTopic,NULL);

    for (std::map<std::string,SHandleAndCb>::iterator it=_allSubscribers.begin();it!=_allSubscribers.end();it++)
    {
        if (it->second.handle!=_defaultSubscriber)
        {
            it->second.handle->cleanup();
            delete it->second.handle;
        }
    }

    for (std::map<std::string,b0::Publisher*>::iterator it=_allDedicatedPublishers.begin();it!=_allDedicatedPublishers.end();it++)
    {
        it->second->cleanup();
        delete it->second;
    }
    _tmpMsgPackObjects.clear();
    _node->cleanup();
    delete _defaultSubscriber;
    delete _defaultPublisher;
    delete _serviceClient;
    delete _node;
}

void b0RemoteApi::_pingCallback(std::vector<msgpack::object>* msg,const std::string* errorStr)
{
    _pongReceived=true;
}

void b0RemoteApi::simxSpin()
{
    while (true)
        simxSpinOnce();
}

void b0RemoteApi::simxSpinOnce()
{
    bool defaultSubscriberAlreadyProcessed=false;
    for (std::map<std::string,SHandleAndCb>::iterator it=_allSubscribers.begin();it!=_allSubscribers.end();it++)
    {
        std::string packedData;
        if ( (it->second.handle!=_defaultSubscriber)||(!defaultSubscriberAlreadyProcessed) )
        {
            defaultSubscriberAlreadyProcessed|=(it->second.handle==_defaultSubscriber);
            while (it->second.handle->poll(0))
            {
                packedData.clear();
                it->second.handle->readRaw(packedData);
                if (!it->second.dropMessages)
                    _handleReceivedMessage(packedData);
            }
            if ( it->second.dropMessages&&(packedData.size()>0) )
                _handleReceivedMessage(packedData);
        }
    }
}

void b0RemoteApi::_handleReceivedMessage(const std::string packedData)
{
    if (packedData.size()>0)
    {
        msgpack::unpacked msg;
        msgpack::unpack(msg,packedData.data(),packedData.size());
        msgpack::object obj(msg.get());
        if ( (obj.type==msgpack::type::ARRAY)&&(obj.via.array.size==2)&&( (obj.via.array.ptr[0].type==msgpack::type::STR)||(obj.via.array.ptr[0].type==msgpack::type::BIN) ) )
        {
            std::string topic(obj.via.array.ptr[0].as<std::string>());
            std::map<std::string,SHandleAndCb >::iterator it=_allSubscribers.find(topic);
            if (it!=_allSubscribers.end())
            {
                msgpack::object obj2=obj.via.array.ptr[1].as<msgpack::object>();
                if ( (obj2.type==msgpack::type::ARRAY)&&(obj2.via.array.ptr[0].type==msgpack::type::BOOLEAN) )
                {
                    std::vector<msgpack::object> vals;
                    obj2.convert(vals);
                    if (obj2.via.array.ptr[0].as<bool>())
                    {
                        if (vals.size()<2)
                            vals.push_back(msgpack::object());
                        it->second.cb(&vals,NULL);
                    }
                    else
                    {
                        if ( (obj2.via.array.ptr[1].type==msgpack::type::STR)||(obj2.via.array.ptr[1].type==msgpack::type::BIN) )
                        { // remote error
                            std::string errorStr(obj2.via.array.ptr[1].as<std::string>());
                            it->second.cb(NULL,&errorStr);
                        }
                    }
                }
            }
        }
    }
}

unsigned int b0RemoteApi::simxGetTimeInMs()
{
    return((unsigned int)_node->hardwareTimeUSec()/1000);
}

void b0RemoteApi::simxSleep(int durationInMs)
{
#ifdef _WIN32
    Sleep(durationInMs);
#else
    usleep(durationInMs*1000);
#endif
}

msgTopic b0RemoteApi::simxDefaultPublisher()
{
    return(_defaultPublisherTopic);
}

msgTopic b0RemoteApi::simxCreatePublisher(bool dropMessages)
{
    msgTopic topic=_channelName+"Sub"+std::to_string(_nextDedicatedPublisherHandle++)+_clientId;
    b0::Publisher* pub=new b0::Publisher(_node,topic,false,true);
    //    pub->setConflate(true);
    pub->init();
    _allDedicatedPublishers[topic]=pub;
    std::tuple<std::string,bool> args(topic,dropMessages);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    _handleFunction("createSubscriber",packedArgs.str(),_serviceCallTopic,NULL);
    return(topic);
}

msgTopic b0RemoteApi::simxDefaultSubscriber(CB_FUNC cb,int publishInterval)
{
    msgTopic topic=_channelName+"Pub"+std::to_string(_nextDefaultSubscriberHandle++)+_clientId;
    SHandleAndCb dat;
    dat.handle=_defaultSubscriber;
    dat.cb=cb;
    dat.dropMessages=false;
    _allSubscribers[topic]=dat;
    std::tuple<std::string,int> args(topic,publishInterval);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    std::string channel=_serviceCallTopic;
    if (_setupSubscribersAsynchronously)
        channel=_defaultPublisherTopic;
    _handleFunction("setDefaultPublisherPubInterval",packedArgs.str(),channel,NULL);
    return(topic);
}

msgTopic b0RemoteApi::simxCreateSubscriber(CB_FUNC cb,int publishInterval,bool dropMessages)
{
    msgTopic topic=_channelName+"Pub"+std::to_string(_nextDedicatedSubscriberHandle++)+_clientId;
    b0::Subscriber* sub=new b0::Subscriber(_node,topic,NULL,false,true);
    //    sub->setConflate(true);
    sub->init();
    SHandleAndCb dat;
    dat.handle=sub;
    dat.cb=cb;
    dat.dropMessages=dropMessages;
    _allSubscribers[topic]=dat;
    std::tuple<std::string,int> args(topic,publishInterval);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    std::string channel=_serviceCallTopic;
    if (_setupSubscribersAsynchronously)
        channel=_defaultPublisherTopic;
    _handleFunction("createPublisher",packedArgs.str(),channel,NULL);
    return(topic);
}

msgTopic b0RemoteApi::simxServiceCall()
{
    return(_serviceCallTopic);
}

std::vector<msgpack::object>* b0RemoteApi::_handleFunction(const char* funcName,const std::string& packedArgs,msgTopic topic,std::string* errorString)
{
    _tmpMsgPackObjects.clear();
    if (errorString!=NULL)
        errorString->clear();

    if (topic==_serviceCallTopic)
    {
        std::tuple<std::string,std::string,std::string,int> header(funcName,_clientId,topic,0);
        std::stringstream packedHeader;
        msgpack::pack(packedHeader,header);
        std::string packedMsg;
        packedMsg+=char(-110); // array of 2
        packedMsg+=packedHeader.str();
        packedMsg+=packedArgs;
        std::string rep;
        _serviceClient->call(packedMsg,rep);
        msgpack::unpack(_tmpUnpackedMsg,rep.data(),rep.size());
        msgpack::object obj(_tmpUnpackedMsg.get());
        if ( (obj.type==msgpack::type::ARRAY)&&(obj.via.array.ptr[0].type==msgpack::type::BOOLEAN) )
        {
            obj.convert(_tmpMsgPackObjects);
            if (obj.via.array.ptr[0].as<bool>())
            {
                if (_tmpMsgPackObjects.size()<2)
                    _tmpMsgPackObjects.push_back(msgpack::object());
                return(&_tmpMsgPackObjects);
            }
            else
            { // error in remote function
                if (errorString!=NULL)
                {
                    if (obj.via.array.ptr[1].type==msgpack::type::STR)
                        errorString[0]=obj.via.array.ptr[1].as<std::string>();
                    else
                        errorString[0]="received bad data";
                }
            }
        }
        else
            errorString[0]="received bad data";
        return(NULL);
    }
    else if (topic==_defaultPublisherTopic)
    {
        std::tuple<std::string,std::string,std::string,int> header(funcName,_clientId,topic,1);
        std::stringstream packedHeader;
        msgpack::pack(packedHeader,header);
        std::string packedMsg;
        packedMsg+=char(-110); // array of 2
        packedMsg+=packedHeader.str();
        packedMsg+=packedArgs;
        _defaultPublisher->publish(packedMsg);
        return(NULL);
    }
    else
    {
        std::map<std::string,SHandleAndCb>::iterator it=_allSubscribers.find(topic);
        if (it!=_allSubscribers.end())
        {
            std::stringstream packedHeader;
            if (it->second.handle==_defaultSubscriber)
            {
                std::tuple<std::string,std::string,std::string,int> header(funcName,_clientId,topic,2);
                msgpack::pack(packedHeader,header);
            }
            else
            {
                std::tuple<std::string,std::string,std::string,int> header(funcName,_clientId,topic,4);
                msgpack::pack(packedHeader,header);
            }
            std::string packedMsg;
            packedMsg+=char(-110); // array of 2
            packedMsg+=packedHeader.str();
            packedMsg+=packedArgs;
            if (_setupSubscribersAsynchronously)
                _defaultPublisher->publish(packedMsg);
            else
            {
                std::string rep;
                _serviceClient->call(packedMsg,rep);
            }
            return(NULL);
        }
        else
        {
            std::map<std::string,b0::Publisher*>::iterator it=_allDedicatedPublishers.find(topic);
            if (it!=_allDedicatedPublishers.end())
            {
                std::stringstream packedHeader;
                std::tuple<std::string,std::string,std::string,int> header(funcName,_clientId,topic,3);
                msgpack::pack(packedHeader,header);
                std::string packedMsg;
                packedMsg+=char(-110); // array of 2
                packedMsg+=packedHeader.str();
                packedMsg+=packedArgs;
                it->second->publish(packedMsg);
                return(NULL);
            }
        }
    }
    return(NULL);
}

bool b0RemoteApi::hasValue(const std::vector<msgpack::object>* msg)
{
    return(msg->size()>0);
}

const msgpack::object* b0RemoteApi::readValue(std::vector<msgpack::object>* msg,int valuesToDiscard/*=0*/,bool* success/*=NULL*/)
{
    while ( (valuesToDiscard>0)&&(msg->size()>0) )
    {
        msg->erase(msg->begin());
        valuesToDiscard--;
    }
    if ( (valuesToDiscard==0)&&(msg->size()>0) )
    {
        const msgpack::object* ret=&msg->at(0);
        msg->erase(msg->begin());
        if (success!=NULL)
            success[0]=true;
        return(ret);
    }
    if (success!=NULL)
        success[0]=false;
    return(NULL);
}

bool b0RemoteApi::readBool(std::vector<msgpack::object>* msg,int valuesToDiscard/*=0*/,bool* success/*=NULL*/)
{
    const msgpack::object* val=readValue(msg,valuesToDiscard);
    if ( (val!=NULL)&&(val->type==msgpack::type::BOOLEAN) )
    {
        if (success!=NULL)
            success[0]=true;
        return(val->as<bool>());
    }
    if (success!=NULL)
        success[0]=false;
    return(false);
}

int b0RemoteApi::readInt(std::vector<msgpack::object>* msg,int valuesToDiscard/*=0*/,bool* success/*=NULL*/)
{
    const msgpack::object* val=readValue(msg,valuesToDiscard);
    if ( (val!=NULL)&&( (val->type==msgpack::type::POSITIVE_INTEGER)||(val->type==msgpack::type::NEGATIVE_INTEGER)||(val->type==msgpack::type::FLOAT) ) )
    {
        if (success!=NULL)
            success[0]=true;
        return(val->as<int>());
    }
    if (success!=NULL)
        success[0]=false;
    return(false);
}

float b0RemoteApi::readFloat(std::vector<msgpack::object>* msg,int valuesToDiscard/*=0*/,bool* success/*=NULL*/)
{
    return((float)readDouble(msg,valuesToDiscard,success));
}

double b0RemoteApi::readDouble(std::vector<msgpack::object>* msg,int valuesToDiscard/*=0*/,bool* success/*=NULL*/)
{
    const msgpack::object* val=readValue(msg,valuesToDiscard);
    if ( (val!=NULL)&&( (val->type==msgpack::type::POSITIVE_INTEGER)||(val->type==msgpack::type::NEGATIVE_INTEGER)||(val->type==msgpack::type::FLOAT) ) )
    {
        if (success!=NULL)
            success[0]=true;
        return(val->as<double>());
    }
    if (success!=NULL)
        success[0]=false;
    return(false);
}

std::string b0RemoteApi::readString(std::vector<msgpack::object>* msg,int valuesToDiscard/*=0*/,bool* success/*=NULL*/)
{
    return(readByteArray(msg,valuesToDiscard,success));
}

std::string b0RemoteApi::readByteArray(std::vector<msgpack::object>* msg,int valuesToDiscard/*=0*/,bool* success/*=NULL*/)
{
    const msgpack::object* val=readValue(msg,valuesToDiscard);
    if ( (val!=NULL)&&( (val->type==msgpack::type::STR)||(val->type==msgpack::type::BIN) ) )
    {
        if (success!=NULL)
            success[0]=true;
        return(val->as<std::string>());
    }
    if (success!=NULL)
        success[0]=false;
    return(false);
}

bool b0RemoteApi::readIntArray(std::vector<msgpack::object>* msg,std::vector<int>& array,int valuesToDiscard/*=0*/)
{
    bool retVal=false;
    array.clear();
    const msgpack::object* val=readValue(msg,valuesToDiscard);
    if ( (val!=NULL)&&(val->type==msgpack::type::ARRAY) )
    {
        std::vector<msgpack::object> vals;
        val->convert(vals);
        for (size_t i=0;i<vals.size();i++)
        {
            if ( (vals[i].type==msgpack::type::POSITIVE_INTEGER)||(vals[i].type==msgpack::type::NEGATIVE_INTEGER)||(vals[i].type==msgpack::type::FLOAT) )
                array.push_back(vals[i].as<int>());
            else
                array.push_back(0);
        }
        retVal=true;
    }
    return(retVal);
}

bool b0RemoteApi::readFloatArray(std::vector<msgpack::object>* msg,std::vector<float>& array,int valuesToDiscard/*=0*/)
{
    bool retVal=false;
    array.clear();
    const msgpack::object* val=readValue(msg,valuesToDiscard);
    if ( (val!=NULL)&&(val->type==msgpack::type::ARRAY) )
    {
        std::vector<msgpack::object> vals;
        val->convert(vals);
        for (size_t i=0;i<vals.size();i++)
        {
            if ( (vals[i].type==msgpack::type::POSITIVE_INTEGER)||(vals[i].type==msgpack::type::NEGATIVE_INTEGER)||(vals[i].type==msgpack::type::FLOAT) )
                array.push_back(vals[i].as<float>());
            else
                array.push_back(0.0f);
        }
        retVal=true;
    }
    return(retVal);
}

bool b0RemoteApi::readDoubleArray(std::vector<msgpack::object>* msg,std::vector<double>& array,int valuesToDiscard/*=0*/)
{
    bool retVal=false;
    array.clear();
    const msgpack::object* val=readValue(msg,valuesToDiscard);
    if ( (val!=NULL)&&(val->type==msgpack::type::ARRAY) )
    {
        std::vector<msgpack::object> vals;
        val->convert(vals);
        for (size_t i=0;i<vals.size();i++)
        {
            if ( (vals[i].type==msgpack::type::POSITIVE_INTEGER)||(vals[i].type==msgpack::type::NEGATIVE_INTEGER)||(vals[i].type==msgpack::type::FLOAT) )
                array.push_back(vals[i].as<double>());
            else
                array.push_back(0.0);
        }
        retVal=true;
    }
    return(retVal);
}

bool b0RemoteApi::readStringArray(std::vector<msgpack::object>* msg,std::vector<std::string>& array,int valuesToDiscard/*=0*/)
{
    bool retVal=false;
    array.clear();
    const msgpack::object* val=readValue(msg,valuesToDiscard);
    if ( (val!=NULL)&&(val->type==msgpack::type::ARRAY) )
    {
        std::vector<msgpack::object> vals;
        val->convert(vals);
        for (size_t i=0;i<vals.size();i++)
        {
            if ( (vals[i].type==msgpack::type::STR)||(vals[i].type==msgpack::type::BIN) )
                array.push_back(vals[i].as<std::string>());
            else
                array.push_back("");
        }
        retVal=true;
    }
    return(retVal);
}

void b0RemoteApi::simxSynchronous(bool enable)
{
    std::tuple<bool> args(enable);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    _handleFunction("Synchronous",packedArgs.str(),_serviceCallTopic,NULL);
}

void b0RemoteApi::simxSynchronousTrigger()
{
    std::tuple<int> args(0);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    _handleFunction("SynchronousTrigger",packedArgs.str(),_defaultPublisherTopic,NULL);
}

void b0RemoteApi::simxGetSimulationStepDone(msgTopic topic)
{
    std::map<std::string,SHandleAndCb>::iterator it=_allSubscribers.find(topic);
    if (it!=_allSubscribers.end())
    {
        std::tuple<int> args(0);
        std::stringstream packedArgs;
        msgpack::pack(packedArgs,args);
        _handleFunction("GetSimulationStepDone",packedArgs.str(),topic,NULL);
    }
    else
        std::cout << "B0 Remote API error: invalid topic" << std::endl;
}

void b0RemoteApi::simxGetSimulationStepStarted(msgTopic topic)
{
    std::map<std::string,SHandleAndCb>::iterator it=_allSubscribers.find(topic);
    if (it!=_allSubscribers.end())
    {
        std::tuple<int> args(0);
        std::stringstream packedArgs;
        msgpack::pack(packedArgs,args);
        _handleFunction("GetSimulationStepStarted",packedArgs.str(),topic,NULL);
    }
    else
        std::cout << "B0 Remote API error: invalid topic" << std::endl;
}

std::vector<msgpack::object>* b0RemoteApi::simxGetObjectHandle(const char* objectName,msgTopic topic,std::string* errorString)
{
    std::tuple<std::string> args(objectName);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetObjectHandle",packedArgs.str(),topic,errorString));
}
std::vector<msgpack::object>* b0RemoteApi::simxAddStatusbarMessage(const char* msg,msgTopic topic,std::string* errorString)
{
    std::tuple<std::string> args(msg);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AddStatusbarMessage",packedArgs.str(),topic,errorString));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetObjectPosition(int objectHandle,int relObjHandle,msgTopic topic,std::string* errorString)
{
    std::tuple<int,int> args(objectHandle,relObjHandle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetObjectPosition",packedArgs.str(),topic,errorString));
}
std::vector<msgpack::object>* b0RemoteApi::simxStartSimulation(msgTopic topic,std::string* errorString)
{
    std::tuple<int> args(0);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("StartSimulation",packedArgs.str(),topic,errorString));
}
std::vector<msgpack::object>* b0RemoteApi::simxStopSimulation(msgTopic topic,std::string* errorString)
{
    std::tuple<int> args(0);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("StopSimulation",packedArgs.str(),topic,errorString));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetVisionSensorImage(int objectHandle,bool greyScale,msgTopic topic,std::string* errorString)
{
    std::tuple<int,bool> args(objectHandle,greyScale);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetVisionSensorImage",packedArgs.str(),topic,errorString));
}

std::vector<msgpack::object>* b0RemoteApi::simxSetVisionSensorImage(int objectHandle,bool greyScale,const std::string& img,msgTopic topic,std::string* errorString)
{
    std::tuple<int,bool,std::string> args(objectHandle,greyScale,img);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("SetVisionSensorImage",packedArgs.str(),topic,errorString));
}

