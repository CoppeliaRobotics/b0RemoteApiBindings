import b0RemoteApi
import time

with b0RemoteApi.RemoteApiClient('b0RemoteApi_pythonClient','b0RemoteApi') as client:    
    doNextStep=True

    def simulationStepStarted(msg):
        simTime=msg[1]['simulationTime'];
        print('Simulation step started. Simulation time: ',simTime)
        
    def simulationStepDone(msg):
        simTime=msg[1]['simulationTime'];
        print('Simulation step done. Simulation time: ',simTime);
        global doNextStep
        doNextStep=True
        
    def imageCallback(msg):
        print('Received image.',msg[1])
        client.simxSetVisionSensorImage(passiveVisionSensorHandle[1],False,msg[2],client.simxDefaultPublisher())
    
    client.simxAddStatusbarMessage('Hello world!',client.simxDefaultPublisher())
    visionSensorHandle=client.simxGetObjectHandle('VisionSensor',client.simxServiceCall())
    passiveVisionSensorHandle=client.simxGetObjectHandle('PassiveVisionSensor',client.simxServiceCall())
    client.simxSynchronous(True)
    
#    dedicatedSub=client.simxCreateSubscriber(imageCallback)
#    client.simxGetVisionSensorImage(visionSensorHandle[1],False,dedicatedSub)
    client.simxGetVisionSensorImage(visionSensorHandle[1],False,client.simxDefaultSubscriber(imageCallback))

    client.simxGetSimulationStepStarted(client.simxDefaultSubscriber(simulationStepStarted));
    client.simxGetSimulationStepDone(client.simxDefaultSubscriber(simulationStepDone));
    client.simxStartSimulation(client.simxDefaultPublisher())
    
    startTime=time.time()
    while time.time()<startTime+5: 
        if doNextStep:
            doNextStep=False
            client.simxSynchronousTrigger()
        client.simxSpinOnce()
    client.simxStopSimulation(client.simxDefaultPublisher())
