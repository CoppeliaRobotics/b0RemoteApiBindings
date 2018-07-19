// -------------------------------------------------------
// Add your custom functions at the bottom of the file
// and the server counterpart to lua/b0RemoteApiServer.lua
// -------------------------------------------------------

package coppelia;

import org.msgpack.core.MessagePack;
import org.msgpack.core.MessageBufferPacker;
import org.msgpack.core.MessageUnpacker;
import org.msgpack.value.*;

import java.util.Random;
import java.util.HashMap;
import java.util.Map;
import java.util.function.*;

import java.io.IOException;

public class b0RemoteApi
{
    class SHandleAndCb
    {
        long handle;
        boolean dropMessages;
        Consumer<MessageUnpacker> cb;
    }
    class SHandle
    {
        long handle;
    }

    static{
        System.loadLibrary("b0");
    }
    public static void print(final MessageUnpacker msg) throws IOException 
    {
        int cnt=0;
        while (msg.hasNext())
        {
            if (cnt>0)
                System.out.printf(", ");
            System.out.print(msg.unpackValue());
            cnt=cnt+1;
        }
        if (cnt>0)
            System.out.printf("\n");
    }
    
    public static boolean hasValue(final MessageUnpacker msg) throws IOException 
    {
        return msg.hasNext();
    }
    public static Value readValue(final MessageUnpacker msg) throws IOException
    {
        return readValue(msg,0);
    }
    public static Value readValue(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        while (valuesToDiscard>0)
        {
            msg.unpackValue();
            valuesToDiscard=valuesToDiscard-1;
        }
        return msg.unpackValue();
    }
    public static boolean readBool(final MessageUnpacker msg) throws IOException
    {
        return readBool(msg,0);
    }
    public static boolean readBool(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        Value val=readValue(msg,valuesToDiscard);
        return val.asBooleanValue().getBoolean();
    }
    public static int readInt(final MessageUnpacker msg) throws IOException
    {
        return readInt(msg,0);
    }
    public static int readInt(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        Value val=readValue(msg,valuesToDiscard);
        if (val.isIntegerValue())
            return val.asNumberValue().toInt();
        throw new IOException("not an int");
    }
    public static float readFloat(final MessageUnpacker msg) throws IOException
    {
        return readFloat(msg,0);
    }
    public static float readFloat(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        return (float)readDouble(msg,valuesToDiscard);
    }
    public static double readDouble(final MessageUnpacker msg) throws IOException
    {
        return readDouble(msg,0);
    }
    public static double readDouble(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        Value val=readValue(msg,valuesToDiscard);
        return val.asNumberValue().toDouble();
    }
    public static String readString(final MessageUnpacker msg) throws IOException
    {
        return readString(msg,0);
    }
    public static String readString(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        Value val=readValue(msg,valuesToDiscard);
        return val.asStringValue().asString();
    }
    public static byte[] readByteArray(final MessageUnpacker msg) throws IOException
    {
        return readByteArray(msg,0);
    }
    public static byte[] readByteArray(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        Value val=readValue(msg,valuesToDiscard);
        if (val.isRawValue())
            return val.asRawValue().asByteArray();
        throw new IOException("not a byte array");
    }
    public static int[] readIntArray(final MessageUnpacker msg) throws IOException
    {
        return readIntArray(msg,0);
    }
    public static int[] readIntArray(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        Value val=readValue(msg,valuesToDiscard);
        if (val.isArrayValue())
        {
            ArrayValue arr=val.asArrayValue();
            int s=arr.size();
            int[] retVal=new int[s];
            for (int i=0;i<s;i=i+1)
            {
                Value v=arr.get(i);
                if (v.isNumberValue())
                    retVal[i]=v.asNumberValue().toInt();
                else
                    retVal[i]=0;
            }
            return retVal;
        }
        throw new IOException("not an array");
    }
    public static float[] readFloatArray(final MessageUnpacker msg) throws IOException
    {
        return readFloatArray(msg,0);
    }
    public static float[] readFloatArray(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        Value val=readValue(msg,valuesToDiscard);
        if (val.isArrayValue())
        {
            ArrayValue arr=val.asArrayValue();
            int s=arr.size();
            float[] retVal=new float[s];
            for (int i=0;i<s;i=i+1)
            {
                Value v=arr.get(i);
                if (v.isNumberValue())
                    retVal[i]=v.asNumberValue().toFloat();
                else
                    retVal[i]=0.0f;
            }
            return retVal;
        }
        throw new IOException("not an array");
    }
    public static double[] readDoubleArray(final MessageUnpacker msg) throws IOException
    {
        return readDoubleArray(msg,0);
    }
    public static double[] readDoubleArray(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        Value val=readValue(msg,valuesToDiscard);
        if (val.isArrayValue())
        {
            ArrayValue arr=val.asArrayValue();
            int s=arr.size();
            double[] retVal=new double[s];
            for (int i=0;i<s;i=i+1)
            {
                Value v=arr.get(i);
                if (v.isNumberValue())
                    retVal[i]=v.asNumberValue().toDouble();
                else
                    retVal[i]=0.0;
            }
            return retVal;
        }
        throw new IOException("not an array");
    }
    public static String[] readStringArray(final MessageUnpacker msg) throws IOException
    {
        return readStringArray(msg,0);
    }
    public static String[] readStringArray(final MessageUnpacker msg,int valuesToDiscard) throws IOException
    {
        Value val=readValue(msg,valuesToDiscard);
        if (val.isArrayValue())
        {
            ArrayValue arr=val.asArrayValue();
            int s=arr.size();
            String[] retVal=new String[s];
            for (int i=0;i<s;i=i+1)
            {
                Value v=arr.get(i);
                if (v.isStringValue())
                    retVal[i]=v.asStringValue().asString();
                else
                    retVal[i]=new String("");
            }
            return retVal;
        }
        throw new IOException("not an array");
    }
    
    public b0RemoteApi() throws IOException
    {
        _b0RemoteApi("b0RemoteApi_c++Client","b0RemoteApi",60,false);
    }
    public b0RemoteApi(final String nodeName) throws IOException
    {
        _b0RemoteApi(nodeName,"b0RemoteApi",60,false);
    }
    public b0RemoteApi(final String nodeName,final String channelName) throws IOException
    {
        _b0RemoteApi(nodeName,channelName,60,false);
    }
    public b0RemoteApi(final String nodeName,final String channelName,int inactivityToleranceInSec) throws IOException
    {
        _b0RemoteApi(nodeName,channelName,inactivityToleranceInSec,false);
    }
    public b0RemoteApi(final String nodeName,final String channelName,int inactivityToleranceInSec,boolean setupSubscribersAsynchronously) throws IOException
    {
        _b0RemoteApi(nodeName,channelName,inactivityToleranceInSec,setupSubscribersAsynchronously);
    }

    private void _b0RemoteApi(final String nodeName,final String channelName,int inactivityToleranceInSec,boolean setupSubscribersAsynchronously) throws IOException
    {
        _channelName=channelName;
        _serviceCallTopic=_channelName.concat("SerX");
        _defaultPublisherTopic=_channelName.concat("SubX");
        _defaultSubscriberTopic=_channelName.concat("PubX");
        _nextDefaultSubscriberHandle=2;
        _nextDedicatedPublisherHandle=500;
        _nextDedicatedSubscriberHandle=1000;
        _node=b0NodeNew(nodeName);
        Random rand = new Random(System.currentTimeMillis());
        String alp=new String("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz");
        _clientId="";
        for (int i=0;i<10;i=i+1)
        {
            char c=alp.charAt(rand.nextInt(62));
            _clientId=_clientId.concat(String.valueOf(c));
        }
        _serviceClient=b0ServiceClientNewEx(_node,_serviceCallTopic,1,1);
        _defaultPublisher=b0PublisherNewEx(_node,_defaultPublisherTopic,1,1);
        _defaultSubscriber=b0SubscriberNewEx(_node,_defaultSubscriberTopic,1,1);
        System.out.println("");
        System.out.println("Running B0 Remote API client with channel name ["+_channelName+"]");
        System.out.println("  make sure that: 1) the B0 resolver is running");
        System.out.println("                  2) V-REP is running the B0 Remote API server with the same channel name");
        System.out.println("  Initializing...");
        System.out.println("");
        b0NodeInit(_node);
        
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(inactivityToleranceInSec);
        _handleFunction("inactivityTolerance",args,_serviceCallTopic);
        _setupSubscribersAsynchronously=setupSubscribersAsynchronously;
        _allSubscribers=new HashMap<String,SHandleAndCb>();
        _allDedicatedPublishers=new HashMap<String,SHandle>();

        System.out.println("");
        System.out.println("  Connected!");
        System.out.println("");
    }
    
    public void delete() throws IOException
    {
        _pongReceived=false;
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(0);
        String pingTopic=simxDefaultSubscriber(this::_pingCallback);
        _handleFunction("Ping",args,pingTopic);
        
        while (!_pongReceived)
            simxSpinOnce();

        args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(_clientId);
        _handleFunction("DisconnectClient",args,_serviceCallTopic);

        for (String key:_allSubscribers.keySet())
        {
            SHandleAndCb val=_allSubscribers.get(key);
            if (val.handle!=_defaultSubscriber)
                b0SubscriberDelete(val.handle);
        }

        for (String key:_allDedicatedPublishers.keySet())
        {
            SHandle val=_allDedicatedPublishers.get(key);
            b0PublisherDelete(val.handle);
        }
        
//        b0NodeDelete(_node);
    }

    private void _pingCallback(final MessageUnpacker msg) 
    {
        _pongReceived=true;
    }

    
    private byte[] _concatPackers(final MessageBufferPacker header,final MessageBufferPacker data) throws IOException
    {
        MessageBufferPacker msg=MessagePack.newDefaultBufferPacker();
        msg.packArrayHeader(2);
        byte[] packedData=new byte[msg.toByteArray().length+header.toByteArray().length+data.toByteArray().length];
        System.arraycopy(msg.toByteArray(),0,packedData,0,msg.toByteArray().length);
        System.arraycopy(header.toByteArray(),0,packedData,msg.toByteArray().length,header.toByteArray().length);
        System.arraycopy(data.toByteArray(),0,packedData,msg.toByteArray().length+header.toByteArray().length,data.toByteArray().length);
        return packedData;
    }
    
    private MessageUnpacker _handleFunction(final String funcName,final MessageBufferPacker packedArgs,final String topic) throws IOException
    {
        if (topic.equals(_serviceCallTopic))
        {
            MessageBufferPacker header=MessagePack.newDefaultBufferPacker();
            header.packArrayHeader(4).packString(funcName).packString(_clientId).packString(topic).packInt(0);
            byte[] rep=b0ServiceClientCall(_serviceClient,_concatPackers(header,packedArgs));
            MessageUnpacker unpacker = MessagePack.newDefaultUnpacker(rep);
            int s=unpacker.unpackArrayHeader();
            if (s>=2)
//                return MessagePack.newDefaultUnpacker(rep);
                return unpacker;
            MessageBufferPacker tmp=MessagePack.newDefaultBufferPacker();
//            tmp.packArrayHeader(2).packBoolean(unpacker.unpackBoolean()).packNil();
            tmp.packBoolean(unpacker.unpackBoolean()).packNil();
            return MessagePack.newDefaultUnpacker(tmp.toByteArray());
        }
        else if (topic.equals(_defaultPublisherTopic))
        {
            MessageBufferPacker header=MessagePack.newDefaultBufferPacker();
            header.packArrayHeader(4).packString(funcName).packString(_clientId).packString(topic).packInt(1);
            b0PublisherPublish(_defaultPublisher,_concatPackers(header,packedArgs));
        }
        else
        {
            if (_allSubscribers.containsKey(topic))
            {
                SHandleAndCb val=_allSubscribers.get(topic);
                MessageBufferPacker header=MessagePack.newDefaultBufferPacker();
                if (val.handle==_defaultSubscriber)
                    header.packArrayHeader(4).packString(funcName).packString(_clientId).packString(topic).packInt(2);
                else
                    header.packArrayHeader(4).packString(funcName).packString(_clientId).packString(topic).packInt(4);
                if (_setupSubscribersAsynchronously)
                    b0PublisherPublish(_defaultPublisher,_concatPackers(header,packedArgs));
                else
                    b0ServiceClientCall(_serviceClient,_concatPackers(header,packedArgs));
            }
            else
            {
                if (_allDedicatedPublishers.containsKey(topic))
                {
                    SHandle val=_allDedicatedPublishers.get(topic);
                    MessageBufferPacker header=MessagePack.newDefaultBufferPacker();
                    header.packArrayHeader(4).packString(funcName).packString(_clientId).packString(topic).packInt(3);
                    b0PublisherPublish(val.handle,_concatPackers(header,packedArgs));
                }
            }
        }
        return null;
    }
    
    public void simxSpin() throws IOException
    {
        while (true)
            simxSpinOnce();
    }

    public void simxSpinOnce() throws IOException
    {
        boolean defaultSubscriberAlreadyProcessed=false;
        for (String key:_allSubscribers.keySet())
        {
            byte[] packedData=null;
            SHandleAndCb val=_allSubscribers.get(key);
            if ( (val.handle!=_defaultSubscriber)||(!defaultSubscriberAlreadyProcessed) )
            {
                defaultSubscriberAlreadyProcessed=defaultSubscriberAlreadyProcessed|(val.handle==_defaultSubscriber);
                while (b0SubscriberPoll(val.handle,0)>0)
                {
                    packedData=b0SubscriberRead(val.handle);
                    if (!val.dropMessages)
                        _handleReceivedMessage(packedData);
                }
                if ( val.dropMessages&&(packedData!=null) )
                    _handleReceivedMessage(packedData);
            }
        }
    }

    private void _handleReceivedMessage(final byte[] packedData) throws IOException
    {
        if (packedData.length>0)
        {
            MessageUnpacker unpacker = MessagePack.newDefaultUnpacker(packedData);
            int s=unpacker.unpackArrayHeader();
            if (s==2)
            {
                String topic=unpacker.unpackString();
                if (_allSubscribers.containsKey(topic))
                {
                    unpacker.unpackArrayHeader();
                    SHandleAndCb val=_allSubscribers.get(topic);
                    val.cb.accept(unpacker);
                    
                    
 /*                   
                    MessageUnpacker msg=null;
                    s=unpacker.unpackArrayHeader();
                    if (s>=2)
                    {
                        msg=MessagePack.newDefaultUnpacker(packedData);
                        msg.unpackArrayHeader();
                        msg.unpackString();
                    }
                    else
                    {
                        MessageBufferPacker tmp=MessagePack.newDefaultBufferPacker();
                        tmp.packArrayHeader(2).packBoolean(unpacker.unpackBoolean()).packNil();                        
                        msg=MessagePack.newDefaultUnpacker(tmp.toByteArray());
                    }
                    SHandleAndCb val=_allSubscribers.get(topic);
                    val.cb.accept(msg);
                    */
                }
            }
        }
    }

    public long simxGetTimeInMs()
    {
        return b0NodeHardwareTimeUsec(_node)/1000;
    }

    public void simxSleep(int durationInMs) throws InterruptedException
    {
        Thread.sleep(durationInMs);
    }
    
    public String simxDefaultPublisher()
    {
        return _defaultPublisherTopic;
    }

    public String simxCreatePublisher() throws IOException
    {
        return simxCreatePublisher(false);
    }
    
    public String simxCreatePublisher(boolean dropMessages) throws IOException
    {
        String topic=_channelName+"Sub"+_nextDedicatedPublisherHandle+_clientId;
        _nextDedicatedPublisherHandle=_nextDedicatedPublisherHandle+1;
        long pub=b0PublisherNewEx(_node,topic,0,1);
        b0PublisherInit(pub);
        SHandle dat=new SHandle();
        dat.handle=pub;
        _allDedicatedPublishers.put(topic,dat);
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packString(topic).packBoolean(dropMessages);
        _handleFunction("createSubscriber",args,_serviceCallTopic);
        return topic;
    }

    public String simxDefaultSubscriber(final Consumer<MessageUnpacker> cb) throws IOException
    {
        return simxDefaultSubscriber(cb,1);
    }
    public String simxDefaultSubscriber(final Consumer<MessageUnpacker> cb,int publishInterval) throws IOException
    {
        String topic=_channelName+"Pub"+_nextDefaultSubscriberHandle+_clientId;
        _nextDefaultSubscriberHandle=_nextDefaultSubscriberHandle+1;
        SHandleAndCb dat=new SHandleAndCb();
        dat.handle=_defaultSubscriber;
        dat.cb=cb;
        dat.dropMessages=false;
        _allSubscribers.put(topic,dat);
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packString(topic).packInt(publishInterval);
        String channel=_serviceCallTopic;
        if (_setupSubscribersAsynchronously)
            channel=_defaultPublisherTopic;
        _handleFunction("setDefaultPublisherPubInterval",args,channel);
        return topic;
    }

    public String simxCreateSubscriber(final Consumer<MessageUnpacker> cb) throws IOException
    {
        return simxCreateSubscriber(cb,1);
    }
    public String simxCreateSubscriber(final Consumer<MessageUnpacker> cb,int publishInterval) throws IOException
    {
        return simxCreateSubscriber(cb,publishInterval,false);
    }
    
    public String simxCreateSubscriber(final Consumer<MessageUnpacker> cb,int publishInterval,boolean dropMessages) throws IOException
    {
        String topic=_channelName+"Pub"+_nextDedicatedSubscriberHandle+_clientId;
        _nextDedicatedSubscriberHandle=_nextDedicatedSubscriberHandle+1;
        long sub=b0SubscriberNewEx(_node,topic,0,1);
        b0SubscriberInit(sub);
        SHandleAndCb dat=new SHandleAndCb();
        dat.handle=sub;
        dat.cb=cb;
        dat.dropMessages=dropMessages;
        _allSubscribers.put(topic,dat);
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packString(topic).packInt(publishInterval);
        String channel=_serviceCallTopic;
        if (_setupSubscribersAsynchronously)
            channel=_defaultPublisherTopic;
        _handleFunction("createPublisher",args,channel);
        return topic;
    }
    
    public String simxServiceCall()
    {
        return _serviceCallTopic;
    }
    

    private native long b0NodeNew(final String name);
    private native void b0NodeDelete(long node);
    private native void b0NodeInit(long node);
    private native long b0NodeTimeUsec(long node);
    private native long b0NodeHardwareTimeUsec(long node);

    private native long b0PublisherNewEx(long node,final String topicName,int managed,int notifyGraph);
    private native void b0PublisherDelete(long pub);
    private native void b0PublisherInit(long pub);
    private native void b0PublisherPublish(long pub,byte[] data);
    
    private native long b0SubscriberNewEx(long node,final String topicName,int managed,int notifyGraph);
    private native void b0SubscriberDelete(long sub);
    private native void b0SubscriberInit(long sub);
    private native int b0SubscriberPoll(long sub,long timeout);
    private native byte[] b0SubscriberRead(long sub);
    
    private native long b0ServiceClientNewEx(long node,final String serviceName,int managed,int notifyGraph);
    private native void b0ServiceClientDelete(long cli);
    private native byte[] b0ServiceClientCall(long cli,byte[] data);
    
    String _serviceCallTopic;
    String _defaultPublisherTopic;
    String _defaultSubscriberTopic;
    int _nextDefaultSubscriberHandle;
    int _nextDedicatedPublisherHandle;
    int _nextDedicatedSubscriberHandle;
    boolean _pongReceived;
    boolean _setupSubscribersAsynchronously;
    String _channelName;
    long _node;
    String _clientId;
    long _serviceClient;
    long _defaultPublisher;
    long _defaultSubscriber;
    HashMap<String,SHandleAndCb> _allSubscribers;
    HashMap<String,SHandle> _allDedicatedPublishers;
    
    public void simxSynchronous(boolean enable) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packBoolean(enable);
        _handleFunction("Synchronous",args,_serviceCallTopic);
    }
    
    public void simxSynchronousTrigger() throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(0);
        _handleFunction("SynchronousTrigger",args,_defaultPublisherTopic);
    }
    public void simxGetSimulationStepDone(final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(0);
        _handleFunction("GetSimulationStepDone",args,topic);
    }
    
    public void simxGetSimulationStepStarted(final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(0);
        _handleFunction("GetSimulationStepStarted",args,topic);
    }
    
    public MessageUnpacker simxGetObjectHandle(final String objectName,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(objectName);
        return _handleFunction("GetObjectHandle",args,topic);
    }
    
    public MessageUnpacker simxAddStatusbarMessage(final String msg,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(msg);
        return _handleFunction("AddStatusbarMessage",args,topic);
    }

    public MessageUnpacker simxGetObjectPosition(int objectHandle,int relObjHandle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(objectHandle).packInt(relObjHandle);
        return _handleFunction("GetObjectPosition",args,topic);
    }
    public MessageUnpacker simxStartSimulation(final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(0);
        return _handleFunction("StartSimulation",args,topic);
    }
    public MessageUnpacker simxStopSimulation(final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(0);
        return _handleFunction("StopSimulation",args,topic);
    }

    public MessageUnpacker simxGetVisionSensorImage(int objectHandle,boolean greyScale,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(objectHandle).packBoolean(greyScale);
        return _handleFunction("GetVisionSensorImage",args,topic);
    }

    public MessageUnpacker simxSetVisionSensorImage(int objectHandle,boolean greyScale,byte[] img,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3);
        args.packInt(objectHandle);
        args.packBoolean(greyScale);
        args.packBinaryHeader(img.length);
        args.writePayload(img);
        return _handleFunction("SetVisionSensorImage",args,topic);
    }
    
    public MessageUnpacker simxAuxiliaryConsoleClose(int consoleHandle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(consoleHandle);
        return _handleFunction("AuxiliaryConsoleClose",args,topic);
    }

    public MessageUnpacker simxAuxiliaryConsolePrint(int consoleHandle,final String text,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(consoleHandle).packString(text);
        return _handleFunction("AuxiliaryConsolePrint",args,topic);
    }

    public MessageUnpacker simxAuxiliaryConsoleOpen(final String title,int maxLines,int mode,int[] position,int[] size,float[] textColor,float[] backgroundColor,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(7);
        args.packString(title);
        args.packInt(maxLines);
        args.packInt(mode);
        args.packArrayHeader(2).packInt(position[0]).packInt(position[1]);
        args.packArrayHeader(2).packInt(size[0]).packInt(size[1]);
        args.packArrayHeader(3).packFloat(textColor[0]).packFloat(textColor[1]).packFloat(textColor[2]);
        args.packArrayHeader(3).packFloat(backgroundColor[0]).packFloat(backgroundColor[1]).packFloat(backgroundColor[2]);
        return _handleFunction("AuxiliaryConsoleOpen",args,topic);
    }

    public MessageUnpacker simxAuxiliaryConsoleShow(int consoleHandle,boolean showState,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(consoleHandle).packBoolean(showState);
        return _handleFunction("AuxiliaryConsoleShow",args,topic);
    }

    public MessageUnpacker simxAddDrawingObject_points(int size,int[] color,float[] coords,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3);
        args.packInt(size);
        args.packArrayHeader(3);
        args.packInt(color[0]);
        args.packInt(color[1]);
        args.packInt(color[2]);
        args.packArrayHeader(coords.length);
        for (int i=0;i<coords.length;i=i+1)
            args.packFloat(coords[i]);
        return _handleFunction("AddDrawingObject_points",args,topic);
    }

    public MessageUnpacker simxAddDrawingObject_spheres(float size,int[] color,float[] coords,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3);
        args.packFloat(size);
        args.packArrayHeader(3);
        args.packInt(color[0]);
        args.packInt(color[1]);
        args.packInt(color[2]);
        args.packArrayHeader(coords.length);
        for (int i=0;i<coords.length;i=i+1)
            args.packFloat(coords[i]);
        return _handleFunction("AddDrawingObject_spheres",args,topic);
    }

    public MessageUnpacker simxAddDrawingObject_cubes(float size,int[] color,float[] coords,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3);
        args.packFloat(size);
        args.packArrayHeader(3);
        args.packInt(color[0]);
        args.packInt(color[1]);
        args.packInt(color[2]);
        args.packArrayHeader(coords.length);
        for (int i=0;i<coords.length;i=i+1)
            args.packFloat(coords[i]);
        return _handleFunction("AddDrawingObject_cubes",args,topic);
    }

    public MessageUnpacker simxAddDrawingObject_segments(int lineSize,int[] color,float[] coords,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3);
        args.packInt(lineSize);
        args.packArrayHeader(3);
        args.packInt(color[0]);
        args.packInt(color[1]);
        args.packInt(color[2]);
        args.packArrayHeader(coords.length);
        for (int i=0;i<coords.length;i=i+1)
            args.packFloat(coords[i]);
        return _handleFunction("AddDrawingObject_segments",args,topic);
    }

    public MessageUnpacker simxAddDrawingObject_triangles(int[] color,float[] coords,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2);
        args.packArrayHeader(3);
        args.packInt(color[0]);
        args.packInt(color[1]);
        args.packInt(color[2]);
        args.packArrayHeader(coords.length);
        for (int i=0;i<coords.length;i=i+1)
            args.packFloat(coords[i]);
        return _handleFunction("AddDrawingObject_triangles",args,topic);
    }

    public MessageUnpacker simxRemoveDrawingObject(int handle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(handle);
        return _handleFunction("RemoveDrawingObject",args,topic);
    }

    public MessageUnpacker simxCallScriptFunction(MessageBufferPacker args,final String topic) throws IOException
    {
        return _handleFunction("CallScriptFunction",args,topic);
    }

    public MessageUnpacker simxCheckCollision(int entity1,int entity2,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(entity1).packInt(entity2);
        return _handleFunction("CheckCollision",args,topic);
    }

    public MessageUnpacker simxCheckCollision(int entity1,final String entity2,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(entity1).packString(entity2);
        return _handleFunction("CheckCollision",args,topic);
    }

    public MessageUnpacker simxGetCollisionHandle(final String name,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(name);
        return _handleFunction("GetCollisionHandle",args,topic);
    }

    public MessageUnpacker simxReadCollision(int handle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(handle);
        return _handleFunction("ReadCollision",args,topic);
    }

    public MessageUnpacker simxCheckDistance(int entity1,int entity2,float threshold,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3).packInt(entity1).packInt(entity2).packFloat(threshold);
        return _handleFunction("CheckDistance",args,topic);
    }

    public MessageUnpacker simxCheckDistance(int entity1,final String entity2,float threshold,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3).packInt(entity1).packString(entity2).packFloat(threshold);
        return _handleFunction("CheckDistance",args,topic);
    }

    public MessageUnpacker simxGetDistanceHandle(final String name,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(name);
        return _handleFunction("GetDistanceHandle",args,topic);
    }

    public MessageUnpacker simxReadDistance(int handle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(handle);
        return _handleFunction("ReadDistance",args,topic);
    }

    public MessageUnpacker simxCheckProximitySensor(int sensor,int entity,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(sensor).packInt(entity);
        return _handleFunction("CheckProximitySensor",args,topic);
    }

    public MessageUnpacker simxCheckProximitySensor(int sensor,final String entity,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(sensor).packString(entity);
        return _handleFunction("CheckProximitySensor",args,topic);
    }

    public MessageUnpacker simxReadProximitySensor(int handle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(handle);
        return _handleFunction("ReadProximitySensor",args,topic);
    }

    public MessageUnpacker simxCheckVisionSensor(int sensor,int entity,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(sensor).packInt(entity);
        return _handleFunction("CheckVisionSensor",args,topic);
    }

    public MessageUnpacker simxCheckVisionSensor(int sensor,final String entity,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(sensor).packString(entity);
        return _handleFunction("CheckVisionSensor",args,topic);
    }

    public MessageUnpacker simxReadVisionSensor(int handle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(handle);
        return _handleFunction("ReadVisionSensor",args,topic);
    }

    public MessageUnpacker simxReadForceSensor(int handle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(handle);
        return _handleFunction("ReadForceSensor",args,topic);
    }

    public MessageUnpacker simxBreakForceSensor(int handle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packInt(handle);
        return _handleFunction("BreakForceSensor",args,topic);
    }

    public MessageUnpacker simxClearFloatSignal(final String sig,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(sig);
        return _handleFunction("ClearFloatSignal",args,topic);
    }

    public MessageUnpacker simxClearIntegerSignal(final String sig,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(sig);
        return _handleFunction("ClearIntegerSignal",args,topic);
    }

    public MessageUnpacker simxClearStringSignal(final String sig,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(sig);
        return _handleFunction("ClearStringSignal",args,topic);
    }

    public MessageUnpacker simxSetFloatSignal(final String sig,float val,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packString(sig).packFloat(val);
        return _handleFunction("SetFloatSignal",args,topic);
    }

    public MessageUnpacker simxSetIntegerSignal(final String sig,int val,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packString(sig).packInt(val);
        return _handleFunction("SetIntegerSignal",args,topic);
    }

    public MessageUnpacker simxSetStringSignal(final String sig,byte[] val,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2);
        args.packString(sig);
        args.packBinaryHeader(val.length);
        args.writePayload(val);
        return _handleFunction("SetStringSignal",args,topic);
    }

    public MessageUnpacker simxGetFloatSignal(final String sig,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(sig);
        return _handleFunction("GetFloatSignal",args,topic);
    }

    public MessageUnpacker simxGetIntegerSignal(final String sig,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(sig);
        return _handleFunction("GetIntegerSignal",args,topic);
    }

    public MessageUnpacker simxGetStringSignal(final String sig,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(1).packString(sig);
        return _handleFunction("GetStringSignal",args,topic);
    }
    
    public MessageUnpacker simxSetObjectPosition(int objectHandle,int refObjectHandle,float[] pos,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3);
        args.packInt(objectHandle);
        args.packInt(refObjectHandle);
        args.packArrayHeader(3).packFloat(pos[0]).packFloat(pos[1]).packFloat(pos[2]);
        return _handleFunction("SetObjectPosition",args,topic);
    }

    public MessageUnpacker simxGetObjectOrientation(int objectHandle,int refObjectHandle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(objectHandle).packInt(refObjectHandle);
        return _handleFunction("GetObjectOrientation",args,topic);
    }

    public MessageUnpacker simxSetObjectOrientation(int objectHandle,int refObjectHandle,float[] euler,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3);
        args.packInt(objectHandle);
        args.packInt(refObjectHandle);
        args.packArrayHeader(3).packFloat(euler[0]).packFloat(euler[1]).packFloat(euler[2]);
        return _handleFunction("SetObjectOrientation",args,topic);
    }

    public MessageUnpacker simxGetObjectQuaternion(int objectHandle,int refObjectHandle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(objectHandle).packInt(refObjectHandle);
        return _handleFunction("GetObjectQuaternion",args,topic);
    }

    public MessageUnpacker simxSetObjectQuaternion(int objectHandle,int refObjectHandle,float[] quat,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3);
        args.packInt(objectHandle);
        args.packInt(refObjectHandle);
        args.packArrayHeader(4).packFloat(quat[0]).packFloat(quat[1]).packFloat(quat[2]).packFloat(quat[3]);
        return _handleFunction("SetObjectQuaternion",args,topic);
    }

    public MessageUnpacker simxGetObjectPose(int objectHandle,int refObjectHandle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(objectHandle).packInt(refObjectHandle);
        return _handleFunction("GetObjectPose",args,topic);
    }

    public MessageUnpacker simxSetObjectPose(int objectHandle,int refObjectHandle,float[] pose,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3);
        args.packInt(objectHandle);
        args.packInt(refObjectHandle);
        args.packArrayHeader(7).packFloat(pose[0]).packFloat(pose[1]).packFloat(pose[2]).packFloat(pose[3]).packFloat(pose[4]).packFloat(pose[5]).packFloat(pose[6]);
        return _handleFunction("SetObjectPose",args,topic);
    }

    public MessageUnpacker simxGetObjectMatrix(int objectHandle,int refObjectHandle,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(2).packInt(objectHandle).packInt(refObjectHandle);
        return _handleFunction("GetObjectMatrix",args,topic);
    }

    public MessageUnpacker simxSetObjectMatrix(int objectHandle,int refObjectHandle,float[] matr,final String topic) throws IOException
    {
        MessageBufferPacker args=MessagePack.newDefaultBufferPacker();
        args.packArrayHeader(3);
        args.packInt(objectHandle);
        args.packInt(refObjectHandle);
        args.packArrayHeader(12);
        args.packFloat(matr[0]).packFloat(matr[1]).packFloat(matr[2]).packFloat(matr[3]);
        args.packFloat(matr[4]).packFloat(matr[5]).packFloat(matr[6]).packFloat(matr[7]);
        args.packFloat(matr[8]).packFloat(matr[9]).packFloat(matr[10]).packFloat(matr[11]);
        return _handleFunction("SetObjectMatrix",args,topic);
    }
    
    // -------------------------------
    // Add your custom functions here:
    // -------------------------------
    
}
