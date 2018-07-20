% -------------------------------------------------------
% Add your custom functions at the bottom of the file
% and the server counterpart to lua/b0RemoteApiServer.lua
% -------------------------------------------------------

classdef b0RemoteApi < handle

    properties
        libName;
        hFile;
        pongReceived;
        channelName;
        serviceCallTopic;
        defaultPublisherTopic;
        defaultSubscriberTopic;
        nextDefaultSubscriberHandle;
        nextDedicatedPublisherHandle;
        nextDedicatedSubscriberHandle;
        node;
        clientId;
        serviceClient;
        defaultPublisher;
        defaultSubscriber;
        allSubscribers;
        allDedicatedPublishers;
        nodeName;
        inactivityToleranceInSec;
        setupSubscribersAsynchronously;
    end
    
    methods
        function cleanUp(obj)
            obj.pongReceived=false;
            obj.handleFunction('Ping',{0},obj.simxDefaultSubscriber(@obj.pingCallback));
            while not(obj.pongReceived)
                obj.simxSpinOnce();
            end
            obj.handleFunction('DisconnectClient',{obj.clientId},obj.serviceCallTopic);
            
            allKeys=keys(obj.allSubscribers);
            for key=allKeys
                value=obj.allSubscribers(key{1});
                if value('handle')~=obj.defaultSubscriber
                    calllib(obj.libName,'b0_subscriber_delete',value('handle'));
                end
            end
            allKeys=keys(obj.allDedicatedPublishers);
            for key=allKeys
                value=obj.allDedicatedPublishers(key{1});
                calllib(obj.libName,'b0_publisher_delete',value);
            end
%            calllib(obj.libName,'b0_node_delete',obj.node);
            unloadlibrary(obj.libName);
        end
        
        function pingCallback(obj,msg)
            obj.pongReceived=true;
        end
        
        function obj = b0RemoteApi(nodeName,channelName,inactivityToleranceInSec,setupSubscribersAsynchronously,hfile)
            addpath('./msgpack-matlab/');
            obj.libName = 'b0';
            obj.nodeName='b0RemoteApi_matlabClient';
            obj.channelName='b0RemoteApi';
            obj.inactivityToleranceInSec=60;
            obj.setupSubscribersAsynchronously=false;
            if nargin>=1
                obj.nodeName=nodeName;
            end
            if nargin>=2
                obj.channelName=channelName;
            end
            if nargin>=3
                obj.inactivityToleranceInSec=inactivityToleranceInSec;
            end
            if nargin>=4
                obj.setupSubscribersAsynchronously=setupSubscribersAsynchronously;
            end
            obj.serviceCallTopic=strcat(obj.channelName,'SerX');
            obj.defaultPublisherTopic=strcat(obj.channelName,'SubX');
            obj.defaultSubscriberTopic=strcat(obj.channelName,'PubX');
            obj.nextDefaultSubscriberHandle=2;
            obj.nextDedicatedPublisherHandle=500;
            obj.nextDedicatedSubscriberHandle=1000;
            if ~libisloaded(obj.libName)
                if nargin>=5
                    obj.hFile = hfile;
                    loadlibrary(obj.libName,obj.hFile);
                else
                    loadlibrary(obj.libName,@b0RemoteApiProto);
                end
            end
            obj.node = calllib(obj.libName,'b0_node_new',libpointer('int8Ptr',[uint8(obj.nodeName) 0]));
            chars = ['a':'z' 'A':'Z' '0':'9'];
            n = randi(numel(chars),[1 10]);
            obj.clientId= chars(n);
            

            tmp = libpointer('int8Ptr',[uint8(obj.serviceCallTopic) 0]);
            obj.serviceClient = calllib(obj.libName,'b0_service_client_new_ex',obj.node,tmp,1,1);

            tmp = libpointer('int8Ptr',[uint8(obj.defaultPublisherTopic) 0]);
            obj.defaultPublisher = calllib(obj.libName,'b0_publisher_new_ex',obj.node,tmp,1,1);

            tmp = libpointer('int8Ptr',[uint8(obj.defaultSubscriberTopic) 0]);
            obj.defaultSubscriber = calllib(obj.libName,'b0_subscriber_new_ex',obj.node,tmp,[],1,1); % We will poll the socket
            
            
            disp(char(10));
            disp(strcat('  Running B0 Remote API client with channel name [',obj.channelName,']'));
            disp('  make sure that: 1) the B0 resolver is running');
            disp('                  2) V-REP is running the B0 Remote API server with the same channel name');
            disp('  Initializing...');
            disp(char(10));
            try
                calllib(obj.libName,'b0_node_init',obj.node);
            catch me
                obj.cleanUp();
                rethrow(me);
            end
            obj.handleFunction('inactivityTolerance',{obj.inactivityToleranceInSec},obj.serviceCallTopic);
            disp(char(10));
            disp('  Connected!');
            disp(char(10));
            obj.allSubscribers=containers.Map;
            obj.allDedicatedPublishers=containers.Map;
        end

        function delete(obj)
            obj.cleanUp();
        end

        function topic = simxDefaultPublisher(obj)
            topic = obj.defaultPublisherTopic;
        end

        function topic = simxCreatePublisher(obj,dropMessages)
            if not(exist('dropMessages'))
                dropMessages=false;
            end
            topic=strcat(obj.channelName,'Sub',num2str(obj.nextDedicatedPublisherHandle),obj.clientId);
            obj.nextDedicatedPublisherHandle=obj.nextDedicatedPublisherHandle+1;
            tmp = libpointer('int8Ptr',[uint8(topic) 0]);
            pub = calllib(obj.libName,'b0_publisher_new_ex',obj.node,tmp,0,1);
            calllib(obj.libName,'b0_publisher_init',pub);
            obj.allDedicatedPublishers(topic)=pub;
            obj.handleFunction('createSubscriber',{topic,dropMessages},obj.serviceCallTopic);
        end

        function topic = simxDefaultSubscriber(obj,cb,publishInterval)
            if not(exist('publishInterval'))
                publishInterval=1;
            end
            topic=strcat(obj.channelName,'Pub',num2str(obj.nextDefaultSubscriberHandle),obj.clientId);
            obj.nextDefaultSubscriberHandle=obj.nextDefaultSubscriberHandle+1;
            theMap=containers.Map;
            theMap('handle')=obj.defaultSubscriber;
            theMap('cb')=cb;
            theMap('dropMessages')=false;
            obj.allSubscribers(topic)=theMap;
            channel=obj.serviceCallTopic;
            if obj.setupSubscribersAsynchronously
                channel=obj.defaultPublisherTopic;
            end
            obj.handleFunction('setDefaultPublisherPubInterval',{topic,publishInterval},channel);
        end
            
        function topic = simxCreateSubscriber(obj,cb,publishInterval,dropMessages)
            if not(exist('publishInterval'))
                publishInterval=1;
            end
            if not(exist('dropMessages'))
                dropMessages=false;
            end
            topic=strcat(obj.channelName,'Pub',num2str(obj.nextDedicatedSubscriberHandle),obj.clientId);
            obj.nextDedicatedSubscriberHandle=obj.nextDedicatedSubscriberHandle+1;
            tmp = libpointer('int8Ptr',[uint8(topic) 0]);
            sub = calllib(obj.libName,'b0_subscriber_new_ex',obj.node,tmp,[],0,1); % We will poll the socket
            %calllib(obj.libName,'b0_subscriber_set_conflate',sub,1);
            calllib(obj.libName,'b0_subscriber_init',sub);
            theMap=containers.Map;
            theMap('handle')=sub;
            theMap('cb')=cb;
            theMap('dropMessages')=dropMessages;
            obj.allSubscribers(topic)=theMap;
            channel=obj.serviceCallTopic;
            if obj.setupSubscribersAsynchronously
                channel=obj.defaultPublisherTopic;
            end
            obj.handleFunction('createPublisher',{topic,publishInterval},channel);
        end
  
        function topic = simxServiceCall(obj)
            topic = obj.serviceCallTopic;
        end
        
        function simxSpin(obj)
            while true
                obj.simxSpinOnce();
            end
        end
        
        function simxSpinOnce(obj)
            defaultSubscriberAlreadyProcessed=false;
            allKeys=keys(obj.allSubscribers);
            for key=allKeys
                value=obj.allSubscribers(key{1});
                retData=[];
                if (value('handle')~=obj.defaultSubscriber) || not(defaultSubscriberAlreadyProcessed)
                    defaultSubscriberAlreadyProcessed=defaultSubscriberAlreadyProcessed || (value('handle')==obj.defaultSubscriber);
                    while calllib(obj.libName,'b0_subscriber_poll',value('handle'),0)>0
                        if not(isempty(retData))
                            calllib(obj.libName,'b0_buffer_delete',retData);
                            retData=[];
                        end
                        retData = libpointer('uint8PtrPtr');
                        retSize = libpointer('uint64Ptr',uint64(0));
                        [retData subClient retSize]=calllib(obj.libName,'b0_subscriber_read',value('handle'),retSize);
                        retData.setdatatype('uint8Ptr',1,retSize);
                        if not(value('dropMessages'))
                            obj.handleReceivedMessage(retData.value);
                            calllib(obj.libName,'b0_buffer_delete',retData);
                            retData=[];
                        end
                    end
                    if value('dropMessages') && not(isempty(retData))
                        obj.handleReceivedMessage(retData.value);
                        calllib(obj.libName,'b0_buffer_delete',retData);
                        retData=[];
                    end
                end
            end
        end
        
        function handleReceivedMessage(obj,data)
            msg = parsemsgpack(data);
            kk=msg(1);
            k=kk{1};
            if isKey(obj.allSubscribers,k)
                value=obj.allSubscribers(k);
                cbMsg=msg(2);
                if length(cbMsg)==1
                    cbMsg=[cbMsg,[]];
                end
                cb=value('cb');
                cb(cbMsg{1});
            end
        end
        
        function ret = handleFunction(obj,funcName,reqArgs,topic)
            if strcmp(topic,obj.serviceCallTopic)
                packedData = dumpmsgpack({{funcName,obj.clientId,topic,0},reqArgs});
            
                retData = libpointer('uint8PtrPtr');
                retSize = libpointer('uint64Ptr',uint64(0));
                [retData servClient packedData retSize]= calllib(obj.libName,'b0_service_client_call',obj.serviceClient,packedData,length(packedData),retSize);
                if retSize > 0
                    retData.setdatatype('uint8Ptr',1,retSize);
                    returnedData = retData.value;
                    ret = parsemsgpack(returnedData);
                    if length(ret)<2
                        ret=[ret,[]];
                    end
                else 
                    ret=[];
                end
            else 
                if strcmp(topic,obj.defaultPublisherTopic)
                    packedData = dumpmsgpack({{funcName,obj.clientId,topic,1},reqArgs});
                    calllib(obj.libName,'b0_publisher_publish',obj.defaultPublisher,packedData,length(packedData));
                    ret=[];
                else 
                    if isKey(obj.allSubscribers,topic)
                        val=obj.allSubscribers(topic);
                        packedData=[];
                        if val('handle')==obj.defaultSubscriber
                            packedData = dumpmsgpack({{funcName,obj.clientId,topic,2},reqArgs});
                        else
                            packedData = dumpmsgpack({{funcName,obj.clientId,topic,4},reqArgs});
                        end
                        if obj.setupSubscribersAsynchronously
                            calllib(obj.libName,'b0_publisher_publish',obj.defaultPublisher,packedData,length(packedData));
                        else
                            retData = libpointer('uint8PtrPtr');
                            retSize = libpointer('uint64Ptr',uint64(0));
                            [retData servClient packedData retSize]= calllib(obj.libName,'b0_service_client_call',obj.serviceClient,packedData,length(packedData),retSize);
                        end
                        ret=[];
                    else 
                        if isKey(obj.allDedicatedPublishers,topic)
                            packedData = dumpmsgpack({{funcName,obj.clientId,topic,3},reqArgs});
                            calllib(obj.libName,'b0_publisher_publish',obj.allDedicatedPublishers,packedData,length(packedData));
                        else
                            disp('B0 Remote API error: invalid topic');
                        end
                        ret=[];
                    end
                end
            end
        end

        function ret = simxGetTimeInMs(obj)
            ret = calllib(obj.libName,'b0_node_hardware_time_usec',obj.node)/1000;
        end
        
        function simxSleep(obj,durationInMs)
            startT=obj.simxGetTimeInMs();
            while obj.simxGetTimeInMs()<startT+durationInMs
            end
        end
        
        function simxSynchronous(obj,enable)
            args = {enable};
            obj.handleFunction('Synchronous',args,obj.serviceCallTopic);
        end
        
        function simxSynchronousTrigger(obj)
            args = {0};
            obj.handleFunction('SynchronousTrigger',args,obj.defaultPublisherTopic);
        end
        
        function simxGetSimulationStepDone(obj,topic)
            if isKey(obj.allSubscribers,topic)
                reqArgs = {0};
                obj.handleFunction('GetSimulationStepDone',reqArgs,topic);
            else
                disp('B0 Remote API error: invalid topic');
            end
        end
        
        function simxGetSimulationStepStarted(obj,topic)
            if isKey(obj.allSubscribers,topic)
                reqArgs = {0};
                obj.handleFunction('GetSimulationStepStarted',reqArgs,topic);
            else
                disp('B0 Remote API error: invalid topic');
            end
        end
    
        function ret = simxGetObjectHandle(obj,objectName,topic)
            args = {objectName};
            ret = obj.handleFunction('GetObjectHandle',args,topic);
        end
        
        function ret = simxGetVisionSensorImage(obj,objectHandle,greyScale,topic)
            args = {objectHandle,greyScale};
            ret = obj.handleFunction('GetVisionSensorImage',args,topic);
        end
        
        function ret = simxSetVisionSensorImage(obj,objectHandle,greyScale,img,topic)
            args = {objectHandle,greyScale,img};
            ret = obj.handleFunction('SetVisionSensorImage',args,topic);
        end
        
        function ret = simxAddStatusbarMessage(obj,msg,topic)
            args = {msg};
            ret = obj.handleFunction('AddStatusbarMessage',args,topic);
        end
        
        function ret = simxGetObjectPosition(obj,objHandle,relObjHandle,topic)
            args = {objHandle,relObjHandle};
            ret = obj.handleFunction('GetObjectPosition',args,topic);
        end
        
        function ret = simxStartSimulation(obj,topic)
            args = {0};
            ret = obj.handleFunction('StartSimulation',args,topic);
        end
        
        function ret = simxStopSimulation(obj,topic)
            args = {0};
            ret = obj.handleFunction('StopSimulation',args,topic);
        end

        function ret = simxAuxiliaryConsoleClose(obj,consoleHandle,topic)
            args = {consoleHandle};
            ret = obj.handleFunction('AuxiliaryConsoleClose',args,topic);
        end
            
        function ret = simxAuxiliaryConsolePrint(obj,consoleHandle,text,topic)
            args = {consoleHandle,text};
            ret = obj.handleFunction('AuxiliaryConsolePrint',args,topic);
        end
            
        function ret = simxAuxiliaryConsoleOpen(obj,title,maxLines,mode,position,size,textColor,backgroundColor,topic)
            args = {title,maxLines,mode,position,size,textColor,backgroundColor};
            ret = obj.handleFunction('AuxiliaryConsoleOpen',args,topic);
        end
            
        function ret = simxAuxiliaryConsoleShow(obj,consoleHandle,showState,topic)
            args = {consoleHandle,showState};
            ret = obj.handleFunction('AuxiliaryConsoleShow',args,topic);
        end
            
        function ret = simxAddDrawingObject_points(obj,size,color,coords,topic)
            args = {size,color,coords};
            ret = obj.handleFunction('AddDrawingObject_points',args,topic);
        end

        function ret = simxAddDrawingObject_spheres(obj,size,color,coords,topic)
            args = {size,color,coords};
            ret = obj.handleFunction('AddDrawingObject_spheres',args,topic);
        end

        function ret = simxAddDrawingObject_cubes(obj,size,color,coords,topic)
            args = {size,color,coords};
            ret = obj.handleFunction('AddDrawingObject_cubes',args,topic);
        end

        function ret = simxAddDrawingObject_segments(obj,lineSize,color,segments,topic)
            args = {lineSize,color,segments};
            ret = obj.handleFunction('AddDrawingObject_segments',args,topic);
        end

        function ret = simxAddDrawingObject_triangles(obj,color,triangles,topic)
            args = {color,triangles};
            ret = obj.handleFunction('AddDrawingObject_triangles',args,topic);
        end

        function ret = simxRemoveDrawingObject(obj,handle,topic)
            args = {handle};
            ret = obj.handleFunction('RemoveDrawingObject',args,topic);
        end
            
        function ret = simxCallScriptFunction(obj,funcAtObjName,scriptType,arg,topic)
            packedData = dumpmsgpack(arg);
            args = {funcAtObjName,scriptType,packedData};
            ret = obj.handleFunction('CallScriptFunction',args,topic);
        end
            
        function ret = simxCheckCollision(obj,entity1,entity2,topic)
            args = {entity1,entity2};
            ret = obj.handleFunction('CheckCollision',args,topic);
        end
            
        function ret = simxGetCollisionHandle(obj,name,topic)
            args = {name};
            ret = obj.handleFunction('GetCollisionHandle',args,topic);
        end
            
        function ret = simxReadCollision(obj,handle,topic)
            args = {handle};
            ret = obj.handleFunction('ReadCollision',args,topic);
        end
            
        function ret = simxCheckDistance(obj,entity1,entity2,threshold,topic)
            args = {entity1,entity2,threshold};
            ret = obj.handleFunction('CheckDistance',args,topic);
        end
            
        function ret = simxGetDistanceHandle(obj,name,topic)
            args = {name};
            ret = obj.handleFunction('GetDistanceHandle',args,topic);
        end
            
        function ret = simxReadDistance(obj,handle,topic)
            args = {handle};
            ret = obj.handleFunction('ReadDistance',args,topic);
        end
            
        function ret = simxCheckProximitySensor(obj,sensor,entity,topic)
            args = {sensor,entity};
            ret = obj.handleFunction('CheckProximitySensor',args,topic);
        end
            
        function ret = simxReadProximitySensor(obj,handle,topic)
            args = {handle};
            ret = obj.handleFunction('ReadProximitySensor',args,topic);
        end
            
        function ret = simxCheckVisionSensor(obj,sensor,entity,topic)
            args = {sensor,entity};
            ret = obj.handleFunction('CheckVisionSensor',args,topic);
        end
            
        function ret = simxReadVisionSensor(obj,handle,topic)
            args = {handle};
            ret = obj.handleFunction('ReadVisionSensor',args,topic);
        end
            
        function ret = simxReadForceSensor(obj,handle,topic)
            args = {handle};
            ret = obj.handleFunction('ReadForceSensor',args,topic);
        end
            
        function ret = simxBreakForceSensor(obj,handle,topic)
            args = {handle};
            ret = obj.handleFunction('BreakForceSensor',args,topic);
        end
            
        function ret = simxClearFloatSignal(obj,sig,topic)
            args = {sig};
            ret = obj.handleFunction('ClearFloatSignal',args,topic);
        end
            
        function ret = simxClearIntegerSignal(obj,sig,topic)
            args = {sig};
            ret = obj.handleFunction('ClearIntegerSignal',args,topic);
        end
            
        function ret = simxClearStringSignal(obj,sig,topic)
            args = {sig};
            ret = obj.handleFunction('ClearStringSignal',args,topic);
        end
            
        function ret = simxSetFloatSignal(obj,sig,val,topic)
            args = {sig,val};
            ret = obj.handleFunction('SetFloatSignal',args,topic);
        end
            
        function ret = simxSetIntegerSignal(obj,sig,val,topic)
            args = {sig,val};
            ret = obj.handleFunction('SetIntegerSignal',args,topic);
        end
            
        function ret = simxSetStringSignal(obj,sig,val,topic)
            args = {sig,val};
            ret = obj.handleFunction('SetStringSignal',args,topic);
        end
            
        function ret = simxGetFloatSignal(obj,sig,topic)
            args = {sig};
            ret = obj.handleFunction('GetFloatSignal',args,topic);
        end
            
        function ret = simxGetIntegerSignal(obj,sig,topic)
            args = {sig};
            ret = obj.handleFunction('GetIntegerSignal',args,topic);
        end
            
        function ret = simxGetStringSignal(obj,sig,topic)
            args = {sig};
            ret = obj.handleFunction('GetStringSignal',args,topic);
        end
            
        function ret = simxSetObjectPosition(obj,objectHandle,refObjectHandle,pos,topic)
            args = {objectHandle,refObjectHandle,pos};
            ret = obj.handleFunction('SetObjectPosition',args,topic);
        end
            
        function ret = simxGetObjectOrientation(obj,objectHandle,refObjectHandle,topic)
            args = {objectHandle,refObjectHandle};
            ret = obj.handleFunction('GetObjectOrientation',args,topic);
        end
            
        function ret = simxSetObjectOrientation(obj,objectHandle,refObjectHandle,euler,topic)
            args = {objectHandle,refObjectHandle,euler};
            ret = obj.handleFunction('SetObjectOrientation',args,topic);
        end
            
        function ret = simxGetObjectQuaternion(obj,objectHandle,refObjectHandle,topic)
            args = {objectHandle,refObjectHandle};
            ret = obj.handleFunction('GetObjectQuaternion',args,topic);
        end
            
        function ret = simxSetObjectQuaternion(obj,objectHandle,refObjectHandle,quat,topic)
            args = {objectHandle,refObjectHandle,quat};
            ret = obj.handleFunction('SetObjectQuaternion',args,topic);
        end
            
        function ret = simxGetObjectPose(obj,objectHandle,refObjectHandle,topic)
            args = {objectHandle,refObjectHandle};
            ret = obj.handleFunction('GetObjectPose',args,topic);
        end
            
        function ret = simxSetObjectPose(obj,objectHandle,refObjectHandle,pose,topic)
            args = {objectHandle,refObjectHandle,pose};
            ret = obj.handleFunction('SetObjectPose',args,topic);
        end
            
        function ret = simxGetObjectMatrix(obj,objectHandle,refObjectHandle,topic)
            args = {objectHandle,refObjectHandle};
            ret = obj.handleFunction('GetObjectMatrix',args,topic);
        end
            
        function ret = simxSetObjectMatrix(obj,objectHandle,refObjectHandle,matr,topic)
            args = {objectHandle,refObjectHandle,matr};
            ret = obj.handleFunction('SetObjectMatrix',args,topic);
        end
        
        % -------------------------------
        % Add your custom functions here:
        % -------------------------------
        
    end
end
