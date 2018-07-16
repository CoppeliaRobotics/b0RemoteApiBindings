require 'b0Lua'
b0.messagePack=require('messagePack-lua/MessagePack')
--b0.messagePack.set_string('binary')
--b0.messagePack.set_string('string')

function b0RemoteApi(nodeName,channelName,inactivityToleranceInSec,setupSubscribersAsynchronously)
    local self={}
    
    if nodeName==nil then nodeName='b0RemoteApi_luaClient' end
    if channelName==nil then channelName='b0RemoteApi' end
    if inactivityToleranceInSec==nil then inactivityToleranceInSec=60 end
    if setupSubscribersAsynchronously==nil then setupSubscribersAsynchronously=false end
    
    local _channelName=channelName
    local _serviceCallTopic=channelName..'SerX'
    local _defaultPublisherTopic=channelName..'SubX'
    local _defaultSubscriberTopic=channelName..'PubX'
    local _nextDefaultSubscriberHandle=2
    local _nextDedicatedPublisherHandle=500
    local _nextDedicatedSubscriberHandle=1000
    local _node=b0.node_new(nodeName)
    math.randomseed(b0.node_hardware_time_usec(_node))
    local _clientId=''
    for i=1,10,1 do
        local r=math.random(62)
        _clientId=_clientId..string.sub('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',r,r)
    end
    local _serviceClient=b0.service_client_new_ex(_node,_serviceCallTopic,1,1)
    local _defaultPublisher=b0.publisher_new_ex(_node,_defaultPublisherTopic,1,1)
    local _defaultSubscriber=b0.subscriber_new_ex(_node,_defaultSubscriberTopic,1,1) -- we will poll the socket
    local _allSubscribers={}
    local _allDedicatedPublishers={}
    local _setupSubscribersAsynchronously=setupSubscribersAsynchronously
    local _pongReceived=false

    function self._pingCallback(msg)
        _pongReceived=true
    end
        
    function self.destroy()
        _pongReceived=false
        self._handleFunction('Ping',{0},self.simxDefaultSubscriber(self._pingCallback))
        while not _pongReceived do
            self.simxSpinOnce()
        end
        self._handleFunction('DisconnectClient',{_clientId},_serviceCallTopic)
        for key,value in pairs(_allSubscribers) do 
            if value.handle~=_defaultSubscriber then
                b0.subscriber_delete(value.handle)
            end
        end
        for key,value in pairs(_allDedicatedPublishers) do
            b0.publisher_delete(value)
        end
        b0.node_delete(_node)
    end
    
    function self._handleFunction(funcName,reqArgs,topic)
        if topic==_serviceCallTopic then
            local packedData=b0.messagePack.pack({{funcName,_clientId,topic,0},reqArgs})
            local repl=b0.messagePack.unpack(b0.service_client_call(_serviceClient,packedData))
            return repl
        elseif topic==_defaultPublisherTopic then
            local packedData=b0.messagePack.pack({{funcName,_clientId,topic,1},reqArgs})
            b0.publisher_publish(_defaultPublisher,packedData)
        elseif _allSubscribers[topic] then
            if _allSubscribers[topic].handle==_defaultSubscriber then
                local packedData=b0.messagePack.pack({{funcName,_clientId,topic,2},reqArgs})
                if _setupSubscribersAsynchronously then
                    b0.publisher_publisher(_defaultPublisher,packedData)
                else
                    b0.service_client_call(_serviceClient,packedData)
                end
            else
                local packedData=b0.messagePack.pack({{funcName,_clientId,topic,4},reqArgs})
                if _setupSubscribersAsynchronously then
                    b0.publisher_publish(_defaultPublisher,packedData)
                else
                    b0.service_client_call(_serviceClient,packedData)
                end
            end
        elseif _allDedicatedPublishers[topic] then
            local packedData=b0.messagePack.pack({{funcName,_clientId,topic,3},reqArgs})
            b0.publisher_publish(_allDedicatedPublishers[topic],packedData)
        else
            print('B0 Remote API error: invalid topic')
        end
    end
    
    function self.simxDefaultPublisher()
        return _defaultPublisherTopic
    end

    function self.simxCreatePublisher(dropMessages)
        if dropMessages==nil then dropMessages=false end
        local topic=_channelName..'Sub'..tostring(_nextDedicatedPublisherHandle).._clientId
        _nextDedicatedPublisherHandle=_nextDedicatedPublisherHandle+1
        local pub=b0.publisher_new_ex(_node,topic,0,1)
        b0.publisher_init(pub)
        _allDedicatedPublishers[topic]=pub
        self._handleFunction('createSubscriber',{topic,dropMessages},_serviceCallTopic)
        return topic
    end

    function self.simxDefaultSubscriber(cb,publishInterval)
        if publishInterval==nil then publishInterval=1 end
        local topic=_channelName..'Pub'..tostring(_nextDefaultSubscriberHandle).._clientId
        _nextDefaultSubscriberHandle=_nextDefaultSubscriberHandle+1
        _allSubscribers[topic]={}
        _allSubscribers[topic].handle=_defaultSubscriber
        _allSubscribers[topic].cb=cb
        _allSubscribers[topic].dropMessages=false
        local channel=_serviceCallTopic
        if _setupSubscribersAsynchronously then
            channel=_defaultPublisherTopic
        end
        self._handleFunction('setDefaultPublisherPubInterval',{topic,publishInterval},channel)
        return topic
    end
        
    function self.simxCreateSubscriber(cb,publishInterval,dropMessages)
        if publishInterval==nil then publishInterval=1 end
        if dropMessages==nil then dropMessages=false end
        local topic=_channelName..'Pub'..tostring(_nextDedicatedSubscriberHandle).._clientId
        _nextDedicatedSubscriberHandle=_nextDedicatedSubscriberHandle+1
        local subb=b0.subscriber_new_ex(_node,topic,0,1)
        b0.subscriber_init(subb)
        _allSubscribers[topic]={}
        _allSubscribers[topic].handle=subb
        _allSubscribers[topic].cb=cb
        _allSubscribers[topic].dropMessages=dropMessages
        local channel=_serviceCallTopic
        if _setupSubscribersAsynchronously then
            channel=_defaultPublisherTopic
        end
        self._handleFunction('createPublisher',{topic,publishInterval},channel)
        return topic
    end
  
    function self.simxServiceCall()
        return _serviceCallTopic
    end

    function self._handleReceivedMessage(msg)
        msg=b0.messagePack.unpack(msg)
        if _allSubscribers[msg[1]] then
            local cbMsg=msg[2]
            _allSubscribers[msg[1]].cb(cbMsg)
        end
    end
        
    function self.simxSpinOnce()
        local defaultSubscriberAlreadyProcessed=false
        for key,value in pairs(_allSubscribers) do
            local readData=nil
            if (value.handle~=_defaultSubscriber) or (not defaultSubscriberAlreadyProcessed) then
                defaultSubscriberAlreadyProcessed=defaultSubscriberAlreadyProcessed or (value.handle==_defaultSubscriber)
                while b0.subscriber_poll(value.handle,0)>0 do
                    readData=b0.subscriber_read(value.handle)
                    if not value.dropMessages then
                        self._handleReceivedMessage(readData)
                    end
                end
                if value.dropMessages and readData then
                    self._handleReceivedMessage(readData)
                end
            end
        end
    end
                    
    function self.simxSpin()
        while true do
            self.simxSpinOnce()
        end
    end

    function self.simxSynchronous(enable)
        local reqArgs = {enable}
        local funcName = 'Synchronous'
        self._handleFunction(funcName,reqArgs,_serviceCallTopic)
    end
        
    function self.simxSynchronousTrigger()
        local reqArgs = {0}
        local funcName = 'SynchronousTrigger'
        self._handleFunction(funcName,reqArgs,_defaultPublisherTopic)
    end
        
    function self.simxGetSimulationStepDone(topic)
        if _allSubscribers[topic] then
            local reqArgs = {0}
            local funcName = 'GetSimulationStepDone'
            self._handleFunction(funcName,reqArgs,topic)
        else
            print('B0 Remote API error: invalid topic')
        end
    end
        
    function self.simxGetSimulationStepStarted(topic)
        if _allSubscribers[topic] then
            local reqArgs = {0}
            local funcName = 'GetSimulationStepStarted'
            self._handleFunction(funcName,reqArgs,topic)
        else
            print('B0 Remote API error: invalid topic')
        end
    end
    
    function self.simxGetTimeInMs()
        return b0.node_hardware_time_usec(_node)/1000    
    end
    
    function self.simxSleep(durationInMs)
        local st=self.simxGetTimeInMs()
        while self.simxGetTimeInMs()-st<durationInMs do end
    end
    
    print('\n  Running B0 Remote API client with channel name ['..channelName..']')
    print('  make sure that: 1) the B0 resolver is running')
    print('                  2) V-REP is running the B0 Remote API server with the same channel name')
    print('  Initializing...\n')
    b0.node_init(_node)
    
    self._handleFunction('inactivityTolerance',{inactivityToleranceInSec},_serviceCallTopic)
    print('\n  Connected!\n')
    
    -- ------------------------------
    -- Add your custom function here:
    -- ------------------------------
        
    function self.simxGetObjectHandle(objectName,topic)
        local reqArgs = {objectName}
        local funcName = 'GetObjectHandle'
        return self._handleFunction(funcName,reqArgs,topic)
    end

    function self.simxAddStatusbarMessage(txt,topic)
        local reqArgs = {txt}
        local funcName = 'AddStatusbarMessage'
        return self._handleFunction(funcName,reqArgs,topic)
    end
        
    function self.simxStartSimulation(topic)
        local reqArgs = {}
        local funcName = 'StartSimulation'
        return self._handleFunction(funcName,reqArgs,topic)
    end
        
    function self.simxStopSimulation(topic)
        local reqArgs = {}
        local funcName = 'StopSimulation'
        return self._handleFunction(funcName,reqArgs,topic)
    end

    function self.simxGetVisionSensorImage(objectHandle,greyscale,topic)
        local reqArgs = {objectHandle,greyscale}
        local funcName = 'GetVisionSensorImage'
        return self._handleFunction(funcName,reqArgs,topic)
    end

    function self.simxSetVisionSensorImage(objectHandle,greyscale,img,topic)
        local reqArgs = {objectHandle,greyscale,img}
        local funcName = 'SetVisionSensorImage'
        return self._handleFunction(funcName,reqArgs,topic)
    end

--[==[        
        
        
        
    function self.simxAuxiliaryConsoleClose(self,consoleHandle,topic)
        local reqArgs = {consoleHandle}
        local funcName = 'AuxiliaryConsoleClose'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxAuxiliaryConsolePrint(self,consoleHandle,text,topic)
        local reqArgs = {consoleHandle,text}
        local funcName = 'AuxiliaryConsolePrint'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxAuxiliaryConsoleOpen(self,title,maxLines,mode,position,size,textColor,backgroundColor,topic)
        local reqArgs = {title,maxLines,mode,position,size,textColor,backgroundColor}
        local funcName = 'AuxiliaryConsoleOpen'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxAuxiliaryConsoleShow(self,consoleHandle,showState,topic)
        local reqArgs = {consoleHandle,showState}
        local funcName = 'AuxiliaryConsoleShow'
        return self._handleFunction(funcName,reqArgs,topic)
        

    function self.simxGetObjectPosition(self,objectHandle,refObjectHandle,topic)
        local reqArgs = {objectHandle,refObjectHandle}
        local funcName = 'GetObjectPosition'
        return self._handleFunction(funcName,reqArgs,topic)

    function self.simxAddDrawingObject_points(self,size,color,coords,topic)
        local reqArgs = {size,color,coords}
        local funcName = 'AddDrawingObject_points'
        return self._handleFunction(funcName,reqArgs,topic)

    function self.simxAddDrawingObject_spheres(self,size,color,coords,topic)
        local reqArgs = {size,color,coords}
        local funcName = 'AddDrawingObject_spheres'
        return self._handleFunction(funcName,reqArgs,topic)

    function self.simxAddDrawingObject_cubes(self,size,color,coords,topic)
        local reqArgs = {size,color,coords}
        local funcName = 'AddDrawingObject_cubes'
        return self._handleFunction(funcName,reqArgs,topic)

    function self.simxAddDrawingObject_lines(self,lineSize,color,segments,topic)
        local reqArgs = {lineSize,color,segments}
        local funcName = 'AddDrawingObject_lines'
        return self._handleFunction(funcName,reqArgs,topic)

    function self.simxAddDrawingObject_triangles(self,color,triangles,topic)
        local reqArgs = {color,triangles}
        local funcName = 'AddDrawingObject_triangles'
        return self._handleFunction(funcName,reqArgs,topic)

    function self.simxRemoveDrawingObject(self,handle,topic)
        local reqArgs = {handle}
        local funcName = 'RemoveDrawingObject'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxCallScriptFunction(self,funcAtObjName,scriptType,arg1,arg2,arg3,arg4,topic)
        local reqArgs = {funcAtObjName,scriptType,arg1,arg2,arg3,arg4}
        local funcName = 'CallScriptFunction'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxCheckCollision(self,entity1,entity2,topic)
        local reqArgs = {entity1,entity2}
        local funcName = 'CheckCollision'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxGetCollisionHandle(self,name,topic)
        local reqArgs = {name}
        local funcName = 'GetCollisionHandle'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxReadCollision(self,handle,topic)
        local reqArgs = {handle}
        local funcName = 'ReadCollision'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxCheckDistance(self,entity1,entity2,threshold,topic)
        local reqArgs = {entity1,entity2,threshold}
        local funcName = 'CheckDistance'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxGetDistanceHandle(self,name,topic)
        local reqArgs = {name}
        local funcName = 'GetDistanceHandle'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxReadDistance(self,handle,topic)
        local reqArgs = {handle}
        local funcName = 'ReadDistance'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxCheckProximitySensor(self,sensor,entity,topic)
        local reqArgs = {sensor,entity}
        local funcName = 'CheckProximitySensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxReadProximitySensor(self,handle,topic)
        local reqArgs = {handle}
        local funcName = 'ReadProximitySensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxCheckVisionSensor(self,sensor,entity,topic)
        local reqArgs = {sensor,entity}
        local funcName = 'CheckVisionSensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxReadVisionSensor(self,handle,topic)
        local reqArgs = {handle}
        local funcName = 'ReadVisionSensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxReadForceSensor(self,handle,topic)
        local reqArgs = {handle}
        local funcName = 'ReadForceSensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxBreakForceSensor(self,handle,topic)
        local reqArgs = {handle}
        local funcName = 'BreakForceSensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxClearFloatSignal(self,sig,topic)
        local reqArgs = {sig}
        local funcName = 'ClearFloatSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxClearIntegerSignal(self,sig,topic)
        local reqArgs = {sig}
        local funcName = 'ClearIntegerSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxClearStringSignal(self,sig,topic)
        local reqArgs = {sig}
        local funcName = 'ClearStringSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxSetFloatSignal(self,sig,val,topic)
        local reqArgs = {sig,val}
        local funcName = 'SetFloatSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxSetIntegerSignal(self,sig,val,topic)
        local reqArgs = {sig,val}
        local funcName = 'SetIntegerSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxSetStringSignal(self,sig,val,topic)
        local reqArgs = {sig,val}
        local funcName = 'SetStringSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxGetFloatSignal(self,sig,topic)
        local reqArgs = {sig}
        local funcName = 'GetFloatSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxGetIntegerSignal(self,sig,topic)
        local reqArgs = {sig}
        local funcName = 'GetIntegerSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    function self.simxGetStringSignal(self,sig,topic)
        local reqArgs = {sig}
        local funcName = 'GetStringSignal'
        return self._handleFunction(funcName,reqArgs,topic)
--]==]    
    
    return self
end
