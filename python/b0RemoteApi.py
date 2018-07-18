# -------------------------------------------------------
# Add your custom functions at the bottom of the file
# and the server counterpart to lua/b0RemoteApiServer.lua
# -------------------------------------------------------

import b0
import msgpack
import random
import string
import time

class RemoteApiClient:
    def __init__(self,nodeName='b0RemoteApi_pythonClient',channelName='b0RemoteApi',inactivityToleranceInSec=60,setupSubscribersAsynchronously=False):
        self._channelName=channelName
        self._serviceCallTopic=channelName+'SerX'
        self._defaultPublisherTopic=channelName+'SubX'
        self._defaultSubscriberTopic=channelName+'PubX'
        self._nextDefaultSubscriberHandle=2
        self._nextDedicatedPublisherHandle=500
        self._nextDedicatedSubscriberHandle=1000
        self._node=b0.Node(nodeName)
        self._clientId=''.join(random.choice(string.ascii_uppercase+string.ascii_lowercase+string.digits) for _ in range(10))
        self._serviceClient=b0.ServiceClient(self._node,self._serviceCallTopic)
        self._defaultPublisher=b0.Publisher(self._node,self._defaultPublisherTopic)
        self._defaultSubscriber=b0.Subscriber(self._node,self._defaultSubscriberTopic,None) # we will poll the socket
        print('\n  Running B0 Remote API client with channel name ['+channelName+']')
        print('  make sure that: 1) the B0 resolver is running')
        print('                  2) V-REP is running the B0 Remote API server with the same channel name')
        print('  Initializing...\n')
        self._node.init()
        self._handleFunction('inactivityTolerance',[inactivityToleranceInSec],self._serviceCallTopic)
        print('\n  Connected!\n')
        self._allSubscribers={}
        self._allDedicatedPublishers={}
        self._setupSubscribersAsynchronously=setupSubscribersAsynchronously
  
    def __enter__(self):
        return self
    
    def __exit__(self,*err):
        self._pongReceived=False
        self._handleFunction('Ping',[0],self.simxDefaultSubscriber(self._pingCallback))
        while not self._pongReceived:
            self.simxSpinOnce();
        self._handleFunction('DisconnectClient',[self._clientId],self._serviceCallTopic)
        for key, value in self._allSubscribers.items():
            if value['handle']!=self._defaultSubscriber:
                value['handle'].cleanup()
        for key, value in self._allDedicatedPublishers.items():
            value.cleanup()
        self._node.cleanup()
        
    def _pingCallback(self,msg):
        self._pongReceived=True
        
    def _handleReceivedMessage(self,msg):
        msg=msgpack.unpackb(msg)
        msg[0]=msg[0].decode('ascii')
        if msg[0] in self._allSubscribers:
            cbMsg=msg[1]
            if len(cbMsg)==1:
                cbMsg.append(None)
            self._allSubscribers[msg[0]]['cb'](cbMsg)
            
    def _handleFunction(self,funcName,reqArgs,topic):
        if topic==self._serviceCallTopic:
            packedData=msgpack.packb([[funcName,self._clientId,topic,0],reqArgs])
            rep = msgpack.unpackb(self._serviceClient.call(packedData))
            if len(rep)==1:
                rep.append(None)
            return rep
        elif topic==self._defaultPublisherTopic:
            packedData=msgpack.packb([[funcName,self._clientId,topic,1],reqArgs])
            self._defaultPublisher.publish(packedData)
        elif topic in self._allSubscribers:
            if self._allSubscribers[topic]['handle']==self._defaultSubscriber:
                packedData=msgpack.packb([[funcName,self._clientId,topic,2],reqArgs])
                if self._setupSubscribersAsynchronously:
                    self._defaultPublisher.publish(packedData)
                else:
                    self._serviceClient.call(packedData)
            else:
                packedData=msgpack.packb([[funcName,self._clientId,topic,4],reqArgs])
                if self._setupSubscribersAsynchronously:
                    self._defaultPublisher.publish(packedData)
                else:
                    self._serviceClient.call(packedData)
        elif topic in self._allDedicatedPublishers:
            packedData=msgpack.packb([[funcName,self._clientId,topic,3],reqArgs])
            self._allDedicatedPublishers[topic].publish(packedData)
        else:
            print('B0 Remote API error: invalid topic')
        
    def simxDefaultPublisher(self):
        return self._defaultPublisherTopic

    def simxCreatePublisher(self,dropMessages=False):
        topic=self._channelName+'Sub'+str(self._nextDedicatedPublisherHandle)+self._clientId
        self._nextDedicatedPublisherHandle=self._nextDedicatedPublisherHandle+1
        pub=b0.Publisher(self._node,topic,0,1)
        pub.init()
        self._allDedicatedPublishers[topic]=pub
        self._handleFunction('createSubscriber',[topic,dropMessages],self._serviceCallTopic)
        return topic

    def simxDefaultSubscriber(self,cb,publishInterval=1):
        topic=self._channelName+'Pub'+str(self._nextDefaultSubscriberHandle)+self._clientId
        self._nextDefaultSubscriberHandle=self._nextDefaultSubscriberHandle+1
        self._allSubscribers[topic]={}
        self._allSubscribers[topic]['handle']=self._defaultSubscriber
        self._allSubscribers[topic]['cb']=cb
        self._allSubscribers[topic]['dropMessages']=False
        channel=self._serviceCallTopic
        if self._setupSubscribersAsynchronously:
            channel=self._defaultPublisherTopic
        self._handleFunction('setDefaultPublisherPubInterval',[topic,publishInterval],channel)
        return topic
        
    def simxCreateSubscriber(self,cb,publishInterval=1,dropMessages=False):
        topic=self._channelName+'Pub'+str(self._nextDedicatedSubscriberHandle)+self._clientId
        self._nextDedicatedSubscriberHandle=self._nextDedicatedSubscriberHandle+1
        sub=b0.Subscriber(self._node,topic,None,0,1)
        sub.init()
        self._allSubscribers[topic]={}
        self._allSubscribers[topic]['handle']=sub
        self._allSubscribers[topic]['cb']=cb
        self._allSubscribers[topic]['dropMessages']=dropMessages
        channel=self._serviceCallTopic
        if self._setupSubscribersAsynchronously:
            channel=self._defaultPublisherTopic
        self._handleFunction('createPublisher',[topic,publishInterval],channel)
        return topic
  
    def simxServiceCall(self):
        return self._serviceCallTopic
        
    def simxSpin(self):
        while True:
            self.simxSpinOnce()
        
    def simxSpinOnce(self):
        defaultSubscriberAlreadyProcessed=False
        for key, value in self._allSubscribers.items():
            readData=None
            if (value['handle']!=self._defaultSubscriber) or (not defaultSubscriberAlreadyProcessed):
                defaultSubscriberAlreadyProcessed=defaultSubscriberAlreadyProcessed or (value['handle']==self._defaultSubscriber)
                while value['handle'].poll(0):
                    readData=value['handle'].read()
                    if not value['dropMessages']:
                        self._handleReceivedMessage(readData)
                if value['dropMessages'] and (readData is not None):
                    self._handleReceivedMessage(readData)
                    
    def simxGetTimeInMs(self):
        return self._node.hardware_time_usec()/1000;    

    def simxSleep(self,durationInMs):
        time.sleep(durationInMs)
        
    def simxSynchronous(self,enable):
        reqArgs = [enable]
        funcName = 'Synchronous'
        self._handleFunction(funcName,reqArgs,self._serviceCallTopic)
        
    def simxSynchronousTrigger(self):
        reqArgs = [0]
        funcName = 'SynchronousTrigger'
        self._handleFunction(funcName,reqArgs,self._defaultPublisherTopic)
        
    def simxGetSimulationStepDone(self,topic):
        if topic in self._allSubscribers:
            reqArgs = [0]
            funcName = 'GetSimulationStepDone'
            self._handleFunction(funcName,reqArgs,topic)
        else:
            print('B0 Remote API error: invalid topic')
        
    def simxGetSimulationStepStarted(self,topic):
        if topic in self._allSubscribers:
            reqArgs = [0]
            funcName = 'GetSimulationStepStarted'
            self._handleFunction(funcName,reqArgs,topic)
        else:
            print('B0 Remote API error: invalid topic')
    
    def simxAuxiliaryConsoleClose(self,consoleHandle,topic):
        reqArgs = [consoleHandle]
        funcName = 'AuxiliaryConsoleClose'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxAuxiliaryConsolePrint(self,consoleHandle,text,topic):
        reqArgs = [consoleHandle,text]
        funcName = 'AuxiliaryConsolePrint'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxAuxiliaryConsoleOpen(self,title,maxLines,mode,position,size,textColor,backgroundColor,topic):
        reqArgs = [title,maxLines,mode,position,size,textColor,backgroundColor]
        funcName = 'AuxiliaryConsoleOpen'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxAuxiliaryConsoleShow(self,consoleHandle,showState,topic):
        reqArgs = [consoleHandle,showState]
        funcName = 'AuxiliaryConsoleShow'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxGetObjectHandle(self,objectName,topic):
        reqArgs = [objectName]
        funcName = 'GetObjectHandle'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxAddStatusbarMessage(self,txt,topic):
        reqArgs = [txt]
        funcName = 'AddStatusbarMessage'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxGetObjectPosition(self,objectHandle,refObjectHandle,topic):
        reqArgs = [objectHandle,refObjectHandle]
        funcName = 'GetObjectPosition'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxStartSimulation(self,topic):
        reqArgs = []
        funcName = 'StartSimulation'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxStopSimulation(self,topic):
        reqArgs = []
        funcName = 'StopSimulation'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxGetVisionSensorImage(self,objectHandle,greyscale,topic):
        reqArgs = [objectHandle,greyscale]
        funcName = 'GetVisionSensorImage'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxSetVisionSensorImage(self,objectHandle,greyscale,img,topic):
        reqArgs = [objectHandle,greyscale,img]
        funcName = 'SetVisionSensorImage'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxAddDrawingObject_points(self,size,color,coords,topic):
        reqArgs = [size,color,coords]
        funcName = 'AddDrawingObject_points'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxAddDrawingObject_spheres(self,size,color,coords,topic):
        reqArgs = [size,color,coords]
        funcName = 'AddDrawingObject_spheres'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxAddDrawingObject_cubes(self,size,color,coords,topic):
        reqArgs = [size,color,coords]
        funcName = 'AddDrawingObject_cubes'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxAddDrawingObject_segments(self,lineSize,color,segments,topic):
        reqArgs = [lineSize,color,segments]
        funcName = 'AddDrawingObject_segments'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxAddDrawingObject_triangles(self,color,triangles,topic):
        reqArgs = [color,triangles]
        funcName = 'AddDrawingObject_triangles'
        return self._handleFunction(funcName,reqArgs,topic)

    def simxRemoveDrawingObject(self,handle,topic):
        reqArgs = [handle]
        funcName = 'RemoveDrawingObject'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxCallScriptFunction(self,funcAtObjName,scriptType,arg1,arg2,arg3,arg4,topic):
        reqArgs = [funcAtObjName,scriptType,arg1,arg2,arg3,arg4]
        funcName = 'CallScriptFunction'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxCheckCollision(self,entity1,entity2,topic):
        reqArgs = [entity1,entity2]
        funcName = 'CheckCollision'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxGetCollisionHandle(self,name,topic):
        reqArgs = [name]
        funcName = 'GetCollisionHandle'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxReadCollision(self,handle,topic):
        reqArgs = [handle]
        funcName = 'ReadCollision'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxCheckDistance(self,entity1,entity2,threshold,topic):
        reqArgs = [entity1,entity2,threshold]
        funcName = 'CheckDistance'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxGetDistanceHandle(self,name,topic):
        reqArgs = [name]
        funcName = 'GetDistanceHandle'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxReadDistance(self,handle,topic):
        reqArgs = [handle]
        funcName = 'ReadDistance'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxCheckProximitySensor(self,sensor,entity,topic):
        reqArgs = [sensor,entity]
        funcName = 'CheckProximitySensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxReadProximitySensor(self,handle,topic):
        reqArgs = [handle]
        funcName = 'ReadProximitySensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxCheckVisionSensor(self,sensor,entity,topic):
        reqArgs = [sensor,entity]
        funcName = 'CheckVisionSensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxReadVisionSensor(self,handle,topic):
        reqArgs = [handle]
        funcName = 'ReadVisionSensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxReadForceSensor(self,handle,topic):
        reqArgs = [handle]
        funcName = 'ReadForceSensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxBreakForceSensor(self,handle,topic):
        reqArgs = [handle]
        funcName = 'BreakForceSensor'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxClearFloatSignal(self,sig,topic):
        reqArgs = [sig]
        funcName = 'ClearFloatSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxClearIntegerSignal(self,sig,topic):
        reqArgs = [sig]
        funcName = 'ClearIntegerSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxClearStringSignal(self,sig,topic):
        reqArgs = [sig]
        funcName = 'ClearStringSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxSetFloatSignal(self,sig,val,topic):
        reqArgs = [sig,val]
        funcName = 'SetFloatSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxSetIntegerSignal(self,sig,val,topic):
        reqArgs = [sig,val]
        funcName = 'SetIntegerSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxSetStringSignal(self,sig,val,topic):
        reqArgs = [sig,val]
        funcName = 'SetStringSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxGetFloatSignal(self,sig,topic):
        reqArgs = [sig]
        funcName = 'GetFloatSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxGetIntegerSignal(self,sig,topic):
        reqArgs = [sig]
        funcName = 'GetIntegerSignal'
        return self._handleFunction(funcName,reqArgs,topic)
        
    def simxGetStringSignal(self,sig,topic):
        reqArgs = [sig]
        funcName = 'GetStringSignal'
        return self._handleFunction(funcName,reqArgs,topic)

    # -------------------------------
    # Add your custom functions here:
    # -------------------------------
        