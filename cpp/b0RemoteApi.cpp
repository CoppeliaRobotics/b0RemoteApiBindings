// -------------------------------------------------------
// Add your custom functions at the bottom of the file
// and the server counterpart to lua/b0RemoteApiServer.lua
// -------------------------------------------------------

#include "b0RemoteApi.h"

b0RemoteApi::b0RemoteApi(const char* nodeName,const char* channelName,int inactivityToleranceInSec,bool setupSubscribersAsynchronously)
{
    _channelName=channelName;
    _serviceCallTopic=_channelName+"SerX";
    _defaultPublisherTopic=_channelName+"SubX";
    _defaultSubscriberTopic=_channelName+"PubX";
    _allTopics.push_back(_serviceCallTopic);
    _allTopics.push_back(_defaultPublisherTopic);
    _allTopics.push_back(_defaultSubscriberTopic);
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
    _handleFunction("inactivityTolerance",packedArgs.str(),_serviceCallTopic.c_str());
    _setupSubscribersAsynchronously=setupSubscribersAsynchronously;

    std::cout << "\n  Connected!\n" << std::endl;
}

b0RemoteApi::~b0RemoteApi()
{
    _pongReceived=false;
    std::tuple<int> args1(0);
    std::stringstream packedArgs1;
    msgpack::pack(packedArgs1,args1);
    const char* pingTopic=simxDefaultSubscriber(boost::bind(&b0RemoteApi::_pingCallback,this,_1));
    _handleFunction("Ping",packedArgs1.str(),pingTopic);
    while (!_pongReceived)
        simxSpinOnce();

    std::tuple<std::string> args2(_clientId);
    std::stringstream packedArgs2;
    msgpack::pack(packedArgs2,args2);
    _handleFunction("DisconnectClient",packedArgs2.str(),_serviceCallTopic.c_str());

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

void b0RemoteApi::_pingCallback(std::vector<msgpack::object>* msg)
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
                    if (vals.size()<2)
                        vals.push_back(msgpack::object());
                    it->second.cb(&vals);
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

const char* b0RemoteApi::simxDefaultPublisher()
{
    return(_defaultPublisherTopic.c_str());
}

const char* b0RemoteApi::simxCreatePublisher(bool dropMessages)
{
    std::string topic=_channelName+"Sub"+std::to_string(_nextDedicatedPublisherHandle++)+_clientId;
    _allTopics.push_back(topic);
    b0::Publisher* pub=new b0::Publisher(_node,topic,false,true);
    //    pub->setConflate(true);
    pub->init();
    _allDedicatedPublishers[topic]=pub;
    std::tuple<std::string,bool> args(topic,dropMessages);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    _handleFunction("createSubscriber",packedArgs.str(),_serviceCallTopic.c_str());
    return(_allTopics[_allTopics.size()-1].c_str());
}

const char* b0RemoteApi::simxDefaultSubscriber(CB_FUNC cb,int publishInterval)
{
    std::string topic=_channelName+"Pub"+std::to_string(_nextDefaultSubscriberHandle++)+_clientId;
    _allTopics.push_back(topic);
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
    _handleFunction("setDefaultPublisherPubInterval",packedArgs.str(),channel.c_str());
    return(_allTopics[_allTopics.size()-1].c_str());
}

const char* b0RemoteApi::simxCreateSubscriber(CB_FUNC cb,int publishInterval,bool dropMessages)
{
    std::string topic=_channelName+"Pub"+std::to_string(_nextDedicatedSubscriberHandle++)+_clientId;
    _allTopics.push_back(topic);
    b0::Subscriber* sub=new b0::Subscriber(_node,topic,NULL,false,true);
    //sub->setConflate(true);
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
    _handleFunction("createPublisher",packedArgs.str(),channel.c_str());
    return(_allTopics[_allTopics.size()-1].c_str());
}

const char* b0RemoteApi::simxServiceCall()
{
    return(_serviceCallTopic.c_str());
}

std::vector<msgpack::object>* b0RemoteApi::_handleFunction(const char* funcName,const std::string& packedArgs,const char* topic)
{
    _tmpMsgPackObjects.clear();

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
            if (_tmpMsgPackObjects.size()<2)
                _tmpMsgPackObjects.push_back(msgpack::object());
            return(&_tmpMsgPackObjects);
        }
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

void b0RemoteApi::print(const std::vector<msgpack::object>* msg)
{
    if (msg->size()>0)
    {
        for (size_t i=0;i<msg->size();i++)
        {
            if (i>0)
                std::cout << ", ";
            std::cout << msg->at(i);
        }
        std::cout << std::endl;
    }
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
    _handleFunction("Synchronous",packedArgs.str(),_serviceCallTopic.c_str());
}

void b0RemoteApi::simxSynchronousTrigger()
{
    std::tuple<int> args(0);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    _handleFunction("SynchronousTrigger",packedArgs.str(),_defaultPublisherTopic.c_str());
}

void b0RemoteApi::simxGetSimulationStepDone(const char* topic)
{
    std::map<std::string,SHandleAndCb>::iterator it=_allSubscribers.find(topic);
    if (it!=_allSubscribers.end())
    {
        std::tuple<int> args(0);
        std::stringstream packedArgs;
        msgpack::pack(packedArgs,args);
        _handleFunction("GetSimulationStepDone",packedArgs.str(),topic);
    }
    else
        std::cout << "B0 Remote API error: invalid topic" << std::endl;
}

void b0RemoteApi::simxGetSimulationStepStarted(const char* topic)
{
    std::map<std::string,SHandleAndCb>::iterator it=_allSubscribers.find(topic);
    if (it!=_allSubscribers.end())
    {
        std::tuple<int> args(0);
        std::stringstream packedArgs;
        msgpack::pack(packedArgs,args);
        _handleFunction("GetSimulationStepStarted",packedArgs.str(),topic);
    }
    else
        std::cout << "B0 Remote API error: invalid topic" << std::endl;
}

std::vector<msgpack::object>* b0RemoteApi::simxGetObjectHandle(const char* objectName,const char* topic)
{
    std::tuple<std::string> args(objectName);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetObjectHandle",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxAddStatusbarMessage(const char* msg,const char* topic)
{
    std::tuple<std::string> args(msg);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AddStatusbarMessage",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetObjectPosition(int objectHandle,int relObjHandle,const char* topic)
{
    std::tuple<int,int> args(objectHandle,relObjHandle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetObjectPosition",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxStartSimulation(const char* topic)
{
    std::tuple<int> args(0);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("StartSimulation",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxStopSimulation(const char* topic)
{
    std::tuple<int> args(0);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("StopSimulation",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetVisionSensorImage(int objectHandle,bool greyScale,const char* topic)
{
    std::tuple<int,bool> args(objectHandle,greyScale);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetVisionSensorImage",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxSetVisionSensorImage(int objectHandle,bool greyScale,const char* img,size_t imgSize,const char* topic)
{
    std::tuple<int,bool,std::string> args(objectHandle,greyScale,std::string(img,img+imgSize));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("SetVisionSensorImage",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxAuxiliaryConsoleClose(int consoleHandle,const char* topic)
{
    std::tuple<int> args(consoleHandle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AuxiliaryConsoleClose",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxAuxiliaryConsolePrint(int consoleHandle,const char* text,const char* topic)
{
    std::tuple<int,std::string> args(consoleHandle,text);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AuxiliaryConsolePrint",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxAuxiliaryConsoleOpen(const char* title,int maxLines,int mode,const int position[2],const int size[2],const float textColor[3],const float backgroundColor[3],const char* topic)
{
    std::tuple<std::string,int,int,std::vector<int>,std::vector<int>,std::vector<float>,std::vector<float> > args(
                title,
                maxLines,
                mode,
                std::vector<int>(position,position+2),
                std::vector<int>(size,size+2),
                std::vector<float>(textColor,textColor+3),
                std::vector<float>(backgroundColor,backgroundColor+3));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AuxiliaryConsoleOpen",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxAuxiliaryConsoleShow(int consoleHandle,bool showState,const char* topic)
{
    std::tuple<int,bool> args(consoleHandle,showState);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AuxiliaryConsoleShow",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxAddDrawingObject_points(int size,const int color[3],const float coords[3],int pointCnt,const char* topic)
{
    std::tuple<int,std::vector<int>,std::vector<float> > args(
                size,
                std::vector<int>(color,color+3),
                std::vector<float>(coords,coords+3*pointCnt));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AddDrawingObject_points",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxAddDrawingObject_spheres(float size,const int color[3],const float coords[3],int sphereCnt,const char* topic)
{
    std::tuple<float,std::vector<int>,std::vector<float> > args(
                size,
                std::vector<int>(color,color+3),
                std::vector<float>(coords,coords+3*sphereCnt));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AddDrawingObject_spheres",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxAddDrawingObject_cubes(float size,const int color[3],const float coords[3],int cubeCnt,const char* topic)
{
    std::tuple<float,std::vector<int>,std::vector<float> > args(
                size,
                std::vector<int>(color,color+3),
                std::vector<float>(coords,coords+3*cubeCnt));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AddDrawingObject_cubes",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxAddDrawingObject_segments(int lineSize,const int color[3],const float* segments,int segmentCnt,const char* topic)
{
    std::tuple<int,std::vector<int>,std::vector<float> > args(
                lineSize,
                std::vector<int>(color,color+3),
                std::vector<float>(segments,segments+6*segmentCnt));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AddDrawingObject_segments",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxAddDrawingObject_triangles(const int color[3],const float* triangles,int triangleCnt,const char* topic)
{
    std::tuple<std::vector<int>,std::vector<float> > args(
                std::vector<int>(color,color+3),
                std::vector<float>(triangles,triangles+9*triangleCnt));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("AddDrawingObject_triangles",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxRemoveDrawingObject(int handle,const char* topic)
{
    std::tuple<int> args(handle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("RemoveDrawingObject",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxCallScriptFunction(const char* funcAtObjName,int scriptType,const char* packedData,size_t packedDataSize,const char* topic)
{
    std::tuple<std::string,int,std::string> args(funcAtObjName,scriptType,std::string(packedData,packedData+packedDataSize));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("CallScriptFunction",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxCallScriptFunction(const char* funcAtObjName,const char* scriptType,const char* packedData,size_t packedDataSize,const char* topic)
{
    std::tuple<std::string,std::string,std::string> args(funcAtObjName,scriptType,std::string(packedData,packedData+packedDataSize));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("CallScriptFunction",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxCheckCollision(int entity1,int entity2,const char* topic)
{
    std::tuple<int,int> args(entity1,entity2);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("CheckCollision",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxCheckCollision(int entity1,const char* entity2,const char* topic)
{
    std::tuple<int,std::string> args(entity1,entity2);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("CheckCollision",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetCollisionHandle(const char* name,const char* topic)
{
    std::tuple<std::string> args(name);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetCollisionHandle",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxReadCollision(int handle,const char* topic)
{
    std::tuple<int> args(handle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("ReadCollision",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxCheckDistance(int entity1,int entity2,float threshold,const char* topic)
{
    std::tuple<int,int,float> args(entity1,entity2,threshold);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("CheckDistance",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxCheckDistance(int entity1,const char* entity2,float threshold,const char* topic)
{
    std::tuple<int,std::string,float> args(entity1,entity2,threshold);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("CheckDistance",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetDistanceHandle(const char* name,const char* topic)
{
    std::tuple<std::string> args(name);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetDistanceHandle",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxReadDistance(int handle,const char* topic)
{
    std::tuple<int> args(handle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("ReadDistance",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxCheckProximitySensor(int sensor,int entity,const char* topic)
{
    std::tuple<int,int> args(sensor,entity);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("CheckProximitySensor",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxCheckProximitySensor(int sensor,const char* entity,const char* topic)
{
    std::tuple<int,std::string> args(sensor,entity);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("CheckProximitySensor",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxReadProximitySensor(int handle,const char* topic)
{
    std::tuple<int> args(handle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("ReadProximitySensor",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxCheckVisionSensor(int sensor,int entity,const char* topic)
{
    std::tuple<int,int> args(sensor,entity);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("CheckVisionSensor",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxCheckVisionSensor(int sensor,const char* entity,const char* topic)
{
    std::tuple<int,std::string> args(sensor,entity);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("CheckVisionSensor",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxReadVisionSensor(int handle,const char* topic)
{
    std::tuple<int> args(handle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("ReadVisionSensor",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxReadForceSensor(int handle,const char* topic)
{
    std::tuple<int> args(handle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("ReadForceSensor",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxBreakForceSensor(int handle,const char* topic)
{
    std::tuple<int> args(handle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("BreakForceSensor",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxClearFloatSignal(const char* sig,const char* topic)
{
    std::tuple<std::string> args(sig);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("ClearFloatSignal",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxClearIntegerSignal(const char* sig,const char* topic)
{
    std::tuple<std::string> args(sig);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("ClearIntegerSignal",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxClearStringSignal(const char* sig,const char* topic)
{
    std::tuple<std::string> args(sig);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("ClearStringSignal",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxSetFloatSignal(const char* sig,float val,const char* topic)
{
    std::tuple<std::string,float> args(sig,val);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("SetFloatSignal",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxSetIntegerSignal(const char* sig,int val,const char* topic)
{
    std::tuple<std::string,int> args(sig,val);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("SetIntegerSignal",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxSetStringSignal(const char* sig,const char* val,size_t valSize,const char* topic)
{
    std::tuple<std::string,std::string> args(sig,std::string(val,val+valSize));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("SetStringSignal",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetFloatSignal(const char* sig,const char* topic)
{
    std::tuple<std::string> args(sig);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetFloatSignal",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetIntegerSignal(const char* sig,const char* topic)
{
    std::tuple<std::string> args(sig);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetIntegerSignal",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetStringSignal(const char* sig,const char* topic)
{
    std::tuple<std::string> args(sig);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetStringSignal",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxSetObjectPosition(int objectHandle,int refObjectHandle,const float pos[3],const char* topic)
{
    std::tuple<int,int,std::vector<float> > args(objectHandle,refObjectHandle,std::vector<float>(pos,pos+3));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("SetObjectPosition",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetObjectOrientation(int objectHandle,int refObjectHandle,const char* topic)
{
    std::tuple<int,int> args(objectHandle,refObjectHandle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetObjectOrientation",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxSetObjectOrientation(int objectHandle,int refObjectHandle,const float euler[3],const char* topic)
{
    std::tuple<int,int,std::vector<float> > args(objectHandle,refObjectHandle,std::vector<float>(euler,euler+3));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("SetObjectOrientation",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetObjectQuaternion(int objectHandle,int refObjectHandle,const char* topic)
{
    std::tuple<int,int> args(objectHandle,refObjectHandle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetObjectQuaternion",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxSetObjectQuaternion(int objectHandle,int refObjectHandle,const float quat[4],const char* topic)
{
    std::tuple<int,int,std::vector<float> > args(objectHandle,refObjectHandle,std::vector<float>(quat,quat+4));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("SetObjectQuaternion",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetObjectPose(int objectHandle,int refObjectHandle,const char* topic)
{
    std::tuple<int,int> args(objectHandle,refObjectHandle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetObjectPose",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxSetObjectPose(int objectHandle,int refObjectHandle,const float pose[7],const char* topic)
{
    std::tuple<int,int,std::vector<float> > args(objectHandle,refObjectHandle,std::vector<float>(pose,pose+7));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("SetObjectPose",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxGetObjectMatrix(int objectHandle,int refObjectHandle,const char* topic)
{
    std::tuple<int,int> args(objectHandle,refObjectHandle);
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("GetObjectMatrix",packedArgs.str(),topic));
}

std::vector<msgpack::object>* b0RemoteApi::simxSetObjectMatrix(int objectHandle,int refObjectHandle,const float matr[12],const char* topic)
{
    std::tuple<int,int,std::vector<float> > args(objectHandle,refObjectHandle,std::vector<float>(matr,matr+12));
    std::stringstream packedArgs;
    msgpack::pack(packedArgs,args);
    return(_handleFunction("SetObjectMatrix",packedArgs.str(),topic));
}

// -------------------------------
// Add your custom functions here:
// -------------------------------
