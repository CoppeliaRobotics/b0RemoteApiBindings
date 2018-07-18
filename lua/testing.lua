require 'b0RemoteApi'

local client=b0RemoteApi('b0RemoteApi_luaClient','b0RemoteApi')

function callb(msg)
    print(msg)
end


--[[        
client.simxAddStatusbarMessage('Hello',client.simxDefaultPublisher())
local res=client.simxAuxiliaryConsoleOpen('theTitle',50,4,{10,400},{1024,100},{1,1,0},{0,0,0},client.simxServiceCall())
client.simxAuxiliaryConsolePrint(res[2],'Hello World!!!\n',client.simxServiceCall())
client.simxSleep(1000)
client.simxAuxiliaryConsoleShow(res[2],false,client.simxServiceCall())
client.simxSleep(1000)
client.simxAuxiliaryConsoleShow(res[2],true,client.simxServiceCall())
client.simxSleep(1000)
client.simxAuxiliaryConsoleClose(res[2],client.simxServiceCall())
client.simxStartSimulation(client.simxServiceCall())
client.simxStopSimulation(client.simxServiceCall())
local res=client.simxGetObjectHandle('shape1',client.simxServiceCall())
client.simxGetObjectPosition(res[2],-1,client.simxDefaultSubscriber(callb))
for i=1,100,1 do
    client.simxSpinOnce()
    client.simxSleep(100)
end


res=client.simxAddDrawingObject_points(8,{255,0,255},{0,0,0,1,0,0,0,0,1},client.simxServiceCall())
client.simxSleep(1000)
client.simxRemoveDrawingObject(res[2],client.simxServiceCall())
res=client.simxAddDrawingObject_spheres(0.05,{255,0,0},{0,0,0,1,0,0,0,0,1},client.simxServiceCall())
client.simxSleep(1000)
client.simxRemoveDrawingObject(res[2],client.simxServiceCall())
res=client.simxAddDrawingObject_cubes(0.05,{255,0,0},{0,0,0,1,0,0,0,0,1},client.simxServiceCall())
client.simxSleep(1000)
client.simxRemoveDrawingObject(res[2],client.simxServiceCall())
res=client.simxAddDrawingObject_segments(4,{0,255,0},{0,0,0,1,0,0, 1,0,0,0,0,1, 0,0,1,0,0,0},client.simxServiceCall())
client.simxSleep(1000)
client.simxRemoveDrawingObject(res[2],client.simxServiceCall())
res=client.simxAddDrawingObject_triangles({255,128,0},{0,0,0, 1,0,0, 0,0,1},client.simxServiceCall())
client.simxSleep(1000)
client.simxRemoveDrawingObject(res[2],client.simxServiceCall())
--]]

--res=client.simxCallScriptFunction('myFunction@DefaultCamera',"sim.scripttype_customizationscript","Hello World :)",{255,0,255},nil,nil,client.simxServiceCall())
--[[
s1=client.simxGetObjectHandle('shape1',client.simxServiceCall())
s2=client.simxGetObjectHandle('shape2',client.simxServiceCall())
prox=client.simxGetObjectHandle('prox',client.simxServiceCall())
vis=client.simxGetObjectHandle('vis',client.simxServiceCall())
fs=client.simxGetObjectHandle('fs',client.simxServiceCall())
print(client.simxCheckCollision(s1[2],s2[2],client.simxServiceCall()))
print(client.simxCheckDistance(s1[2],s2[2],0,client.simxServiceCall()))
print(client.simxCheckProximitySensor(prox[2],s2[2],client.simxServiceCall()))
print(client.simxCheckVisionSensor(vis[2],s2[2],client.simxServiceCall()))
coll=client.simxGetCollisionHandle('coll',client.simxServiceCall())
dist=client.simxGetDistanceHandle('dist',client.simxServiceCall())
print(client.simxReadCollision(coll[2],client.simxServiceCall()))
print(client.simxReadDistance(dist[2],client.simxServiceCall()))
print(client.simxReadProximitySensor(prox[2],client.simxServiceCall()))
print(client.simxReadVisionSensor(vis[2],client.simxServiceCall()))
print(client.simxReadForceSensor(fs[2],client.simxServiceCall()))
print(client.simxBreakForceSensor(fs[2],client.simxServiceCall()))
--]]
--[[    

client.simxSetFloatSignal('floatSignal',123.456,client.simxServiceCall())
client.simxSetIntegerSignal('integerSignal',59,client.simxServiceCall())
client.simxSetStringSignal('stringSignal','Hello World',client.simxServiceCall())
print(client.simxGetFloatSignal('floatSignal',client.simxServiceCall()))
print(client.simxGetIntegerSignal('integerSignal',client.simxServiceCall()))
print(client.simxGetStringSignal('stringSignal',client.simxServiceCall()))
client.simxSleep(1000)
client.simxClearFloatSignal('floatSignal',client.simxServiceCall())
client.simxClearIntegerSignal('integerSignal',client.simxServiceCall())
client.simxClearStringSignal('stringSignal',client.simxServiceCall())
client.simxSleep(1000)
print(client.simxGetFloatSignal('floatSignal',client.simxServiceCall()))
print(client.simxGetIntegerSignal('integerSignal',client.simxServiceCall()))
print(client.simxGetStringSignal('stringSignal',client.simxServiceCall()))

client.simxCheckProximitySensor(prox[2],s2[2],client.simxDefaultSubscriber(callb))
startTime=os.time()
while os.time()<startTime+5 do 
    client.simxSpinOnce()
end
--]]

client.delete()