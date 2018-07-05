import coppelia.b0RemoteApi;

import org.msgpack.core.MessageUnpacker;
import org.msgpack.value.*;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.Map;

public class simpleTest
{
    public static boolean doNextStep=true;
    public static int visionSensorHandle;
    public static int passiveVisionSensorHandle;
    public static b0RemoteApi client;
    
    public static void simulationStepStarted(final MessageUnpacker msg)
    {
        try
        {
            Map<Value,Value> map=client.readValue(msg,1).asMapValue().map();
            float simTime=map.get(ValueFactory.newString("simulationTime")).asNumberValue().toFloat();
            System.out.println("Simulation step started. Simulation time: "+simTime);
        }
        catch(IOException e) { throw new UncheckedIOException(e); }
    }
        
    public static void simulationStepDone(final MessageUnpacker msg)
    {
        try
        {
            Map<Value,Value> map=client.readValue(msg,1).asMapValue().map();
            float simTime=map.get(ValueFactory.newString("simulationTime")).asNumberValue().toFloat();
            System.out.println("Simulation step done. Simulation time: "+simTime);
            doNextStep=true;
        }
        catch(IOException e) { throw new UncheckedIOException(e); }
    }
        
    public static void imageCallback(final MessageUnpacker msg)
    {
        try
        {
            byte[] img=client.readByteArray(msg,2);
            client.simxSetVisionSensorImage(passiveVisionSensorHandle,false,img,client.simxDefaultPublisher());
            System.out.println("Received image.");
        }
        catch(IOException e) { throw new UncheckedIOException(e); }
    }
        
    public static void main(String[] args) throws IOException
    {
        
        client = new b0RemoteApi();
        client.simxAddStatusbarMessage("Hello world!",client.simxDefaultPublisher());
        MessageUnpacker msg=client.simxGetObjectHandle("VisionSensor",client.simxServiceCall());
        visionSensorHandle=client.readInt(msg,1);
        msg=client.simxGetObjectHandle("PassiveVisionSensor",client.simxServiceCall());
        passiveVisionSensorHandle=client.readInt(msg,1);
        client.simxSynchronous(true);
        
        client.simxGetVisionSensorImage(visionSensorHandle,false,client.simxDefaultSubscriber(simpleTest::imageCallback));
        client.simxGetSimulationStepStarted(client.simxDefaultSubscriber(simpleTest::simulationStepStarted));
        client.simxGetSimulationStepDone(client.simxDefaultSubscriber(simpleTest::simulationStepDone));
        client.simxStartSimulation(client.simxDefaultPublisher());
        
        long startTime = System.currentTimeMillis();
        while (System.currentTimeMillis()<startTime+5000)
        {
            if (doNextStep)
            {
                doNextStep=false;
                client.simxSynchronousTrigger();
            }
            client.simxSpinOnce();
        }
        client.simxStopSimulation(client.simxDefaultPublisher());
        
        client.close();
        System.out.println("Program ended");
    }
}
