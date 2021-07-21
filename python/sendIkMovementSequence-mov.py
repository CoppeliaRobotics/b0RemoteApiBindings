# Make sure to have CoppeliaSim running, with followig scene loaded:
#
# scenes/messaging/ikMovementViaRemoteApi.ttt
#
# Do not launch simulation, then run this script
#
# The client side (i.e. this script) depends on:
#
# b0RemoteApi (Python script), which depends several libraries present
# in the CoppeliaSim folder

import b0RemoteApi
import math

with b0RemoteApi.RemoteApiClient('b0RemoteApi_pythonClient','b0RemoteApi',60) as client:    
    client.executedMovId='notReady'

    targetArm='/LBR4p'
    stringSignalName=targetArm+'_executedMovId'

    def waitForMovementExecuted(id):
        while client.executedMovId!=id:
            client.simxSpinOnce()

    def executedMovId_callback(msg):
        if type(msg[1])==bytes:
            msg[1]=msg[1].decode('ascii') # python2/python3 differences
        client.executedMovId=msg[1]

    # Subscribe to stringSignalName string signal:
    client.simxGetStringSignal(stringSignalName,client.simxDefaultSubscriber(executedMovId_callback));

    # Set-up some movement variables:
    maxVel=0.1
    maxAccel=0.01

    # Start simulation:
    client.simxStartSimulation(client.simxServiceCall())

    # Wait until ready:
    waitForMovementExecuted('ready') 

    # Get initial pose:
    r=client.simxCallScriptFunction('getPoseAndConfig@'+targetArm,'sim.scripttype_childscript',[],client.simxServiceCall())
    initialPose=r[1]
    
    # Send first movement sequence:
    targetPose=[0,0,0.85,0,0,0,1]
    movementData={"id":"movSeq1","type":"mov","targetPose":targetPose,"maxVel":maxVel,"maxAccel":maxAccel}
    client.simxCallScriptFunction('movementDataFunction@'+targetArm,'sim.scripttype_childscript',movementData,client.simxDefaultPublisher())

    # Execute first movement sequence:
    client.simxCallScriptFunction('executeMovement@'+targetArm,'sim.scripttype_childscript','movSeq1',client.simxDefaultPublisher())
    
    # Wait until above movement sequence finished executing:
    waitForMovementExecuted('movSeq1')

    # Send second and third movement sequence, where third one should execute immediately after the second one:
    targetPose=[0,0,0.85,-0.7071068883, -6.252754758e-08, -8.940695295e-08, -0.7071067691]
    movementData={"id":"movSeq2","type":"mov","targetPose":targetPose,"maxVel":maxVel,"maxAccel":maxAccel}
    client.simxCallScriptFunction('movementDataFunction@'+targetArm,'sim.scripttype_childscript',movementData,client.simxDefaultPublisher())
    movementData={"id":"movSeq3","type":"mov","targetPose":initialPose,"maxVel":maxVel,"maxAccel":maxAccel}
    client.simxCallScriptFunction('movementDataFunction@'+targetArm,'sim.scripttype_childscript',movementData,client.simxDefaultPublisher())

    # Execute second and third movement sequences:
    client.simxCallScriptFunction('executeMovement@'+targetArm,'sim.scripttype_childscript','movSeq2',client.simxDefaultPublisher())
    client.simxCallScriptFunction('executeMovement@'+targetArm,'sim.scripttype_childscript','movSeq3',client.simxDefaultPublisher())
    
    # Wait until above 2 movement sequences finished executing:
    waitForMovementExecuted('movSeq3')
    client.simxStopSimulation(client.simxServiceCall())
