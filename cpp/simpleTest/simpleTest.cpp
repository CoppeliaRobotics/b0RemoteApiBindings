#include "b0RemoteApi.h"

bool doNextStep=true;
int sens1,sens2;
b0RemoteApi* cl=NULL;

void simulationStepStarted_CB(std::vector<msgpack::object>* msg,const std::string* errorStr)
{
    if (msg!=NULL)
    {
        float simTime=0.0;
        std::map<std::string,msgpack::object> data=msg->at(1).as<std::map<std::string,msgpack::object>>();
        std::map<std::string,msgpack::object>::iterator it=data.find("simulationTime");
        if (it!=data.end())
            simTime=it->second.as<float>();
        std::cout << "Simulation step started. Simulation time: " << simTime << std::endl;
    }
}

void simulationStepDone_CB(std::vector<msgpack::object>* msg,const std::string* errorStr)
{
    if (msg!=NULL)
    {
        float simTime=0.0;
        std::map<std::string,msgpack::object> data=msg->at(1).as<std::map<std::string,msgpack::object>>();
        std::map<std::string,msgpack::object>::iterator it=data.find("simulationTime");
        if (it!=data.end())
            simTime=it->second.as<float>();
        std::cout << "Simulation step done. Simulation time: " << simTime << std::endl;
    }
    doNextStep=true;
}

void image_CB(std::vector<msgpack::object>* msg,const std::string* errorStr)
{
    if (msg!=NULL)
    {
        std::cout << "Received image." << std::endl;
        cl->simxSetVisionSensorImage(sens2,false,cl->readByteArray(msg,2),cl->simxDefaultPublisher());
    }
    else
        std::cout << "Error in remote function execution: " << *errorStr << std::endl;
}

int main(int argc,char* argv[])
{
    b0RemoteApi client("b0RemoteApi_c++Client","b0RemoteApi");
    cl=&client;

    std::string errorStr;
    client.simxAddStatusbarMessage("Hello world!",client.simxDefaultPublisher(),&errorStr);
    std::vector<msgpack::object>* reply=client.simxGetObjectHandle("VisionSensor",client.simxServiceCall(),&errorStr);
    sens1=client.readInt(reply,1);
    reply=client.simxGetObjectHandle("PassiveVisionSensor",client.simxServiceCall(),&errorStr);
    sens2=client.readInt(reply,1);

    client.simxSynchronous(true);
    client.simxGetSimulationStepStarted(client.simxDefaultSubscriber(simulationStepStarted_CB));
    client.simxGetSimulationStepDone(client.simxDefaultSubscriber(simulationStepDone_CB));
    client.simxGetVisionSensorImage(sens1,false,client.simxDefaultSubscriber(image_CB,1));
    client.simxStartSimulation(client.simxDefaultPublisher());

    unsigned int st=client.simxGetTimeInMs();
    while (client.simxGetTimeInMs()<st+3000)
    {
        if (doNextStep)
        {
            doNextStep=false;
            client.simxSynchronousTrigger();
        }
        client.simxSpinOnce();
    }
    client.simxStopSimulation(client.simxDefaultPublisher());

    std::cout << "Ended!" << std::endl;
    return(0);
}

