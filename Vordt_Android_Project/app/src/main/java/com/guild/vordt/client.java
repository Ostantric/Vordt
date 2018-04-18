package com.guild.vordt;

/**
 * Created by Murat-Cosmos on 3/23/2018.
 */

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketTimeoutException;

import android.app.Activity;
import android.app.Fragment;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import eu.amirs.JSON;

public class client extends Fragment {

    private static final String TAG = client.class.getSimpleName();
    private static final boolean DEBUG = true; // Set this to false to disable logs.

    private boolean mRunning;
    private udp_task mTask;
    private TaskCallbacks mCallbacks;
    private boolean run, big_run = true;
    private boolean restart = true;
    private boolean show_disconnected,connection,isconnected,connection_old = false;
    private DatagramSocket ds = null;
    private DatagramPacket dp = null;
    private DatagramPacket dp_send = null;
    private boolean send_command_flag;
    private String json_buffer;

    private int port_from_activity;
    private String ip_from_activity;

    /**
     * Callback interface through which the fragment will report the
     * task's progress and results back to the Activity.
     */
    interface TaskCallbacks {
        //String onPreExecute_IP();
        //int onPreExecute_PORT();
        void onPreExecute();

        void MovementUpdates(String Position, String Velocity, String Turn, int position, int position_reversed, int velocity, int velocity_reversed );

        void UtilityUpdates(String voltage);


        void onCancelled();

        void onConnected();

        void onLostConnection();

        void onPostExecute();

        void onDisconnected();
    }

    @Override
    public void onAttach(Activity activity) {
        if (DEBUG) Log.i(TAG, "onAttach(Activity)");

        super.onAttach(activity);
        if (!(activity instanceof TaskCallbacks)) {
            throw new IllegalStateException("Activity must implement the TaskCallbacks interface. Otherwise AsyncTask won't work!");
        }

        // Hold a reference to the parent Activity so we can report back the task's
        // current progress and results.

        mCallbacks = (TaskCallbacks) activity;
    }

    /**
     * This method will only be called once when the retained
     * Fragment is first created.
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        if (DEBUG) Log.i(TAG, "onCreate(Bundle)");

        super.onCreate(savedInstanceState);

        Bundle bundle = getArguments();

        port_from_activity = bundle.getInt("Port");
        ip_from_activity = bundle.getString("IP");


        // Retain this fragment across configuration changes.
        setRetainInstance(true);

        // Create and execute the background task.
        //mTask = new udp_task();
        //mTask.execute();
    }

    /*****************************/
    /***** TASK FRAGMENT API *****/
    /*****************************/

    /**
     * Start the background task.
     */
    public void start() {
        //port_from_activity = bundle.getInt("Port");

        if (!mRunning) {
//            if (getArguments() != null) {
//            }
            if (DEBUG) Log.i(TAG, "start ASYNCTASK");

            mTask = new udp_task(ip_from_activity,port_from_activity);
            mTask.execute();
            mRunning = true;
        }
    }

    /**
     * Cancel the background task.
     */
    public void cancel() {
        if (mRunning) {
            if (DEBUG) Log.i(TAG, "kill ASYNCTASK");

            mTask.cancel(false);
            mTask = null;
            //ds.close();
            mRunning = false;
        }
    }

    public void send_flag(boolean flag) {
        send_command_flag=flag;
    }

    public void send_command(String type, int value){

        if (type.equals("velocity")) {
            JSONObject json = new JSONObject();
            try {
                json.put("dvel",value);
                json_buffer=json.toString();

            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        else if (type.equals("position")){
            JSONObject json = new JSONObject();
            try {
                json.put("dpos",value);
                json_buffer=json.toString();
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        else if (type.equals("turn"))
        {
            JSONObject json = new JSONObject();
            try {
                json.put("dturn",value);
                json_buffer=json.toString();
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        else{
            json_buffer="";
        }

    }

    public void disconnect() {
        //mCallbacks.onDisconnected();
        }

    /**
     * Returns the current state of the background task.
     */
    public boolean isRunning() {
        return mRunning;
    }

    //returns the current state of connection
    //public boolean isConnected() {
    //    return isconnected;
    //}

    //TODO: rearrange booleans and delete unnecessary states
    public class udp_task extends AsyncTask<Void, String, Void> {

        private String dstAddress="192.168.1.228";
        private int dstPort;
        private boolean send_command_flag_old=false;


        udp_task(String addr, int port_number) {
            this.dstAddress=addr;
            this.dstPort=port_number;
        }

        @Override
        protected void onPreExecute() {
             mRunning=true;
        }

        @Override
        protected Void doInBackground(Void... ignore) {
            String message1 = "1";
            //TODO:clean up while loops
            //stay in big run for continuous receives, connection checks and reconnection tries
            while (big_run) {
                //send  once then go to inner infinite loop for receive data
                if (restart) {
                    try {
                        InetAddress serverAddr = InetAddress.getByName(dstAddress);
                        dp = new DatagramPacket(message1.getBytes(), message1.length(), serverAddr, dstPort);
                        ds = new DatagramSocket();
                        ds.setSoTimeout(500);
                        ds.send(dp);
                        run = true;
                        restart = false;
                        Thread.sleep(50);
                    } catch (IOException e) {
                        //run = false;
                        //big_run = false;
                        publishProgress("lost");
                        Log.e("io error", "outter io error");
                        connection = false;
                        isconnected = false;
                        ds.close();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }

                //stay in this loop until timeout or IO exception
                while (run) {
                    try {
                        InetAddress serverAddr = InetAddress.getByName(dstAddress);
                        Thread.sleep(5);
                        byte[] buffer = new byte[256];
                        dp = new DatagramPacket(buffer, buffer.length);
                        ds.receive(dp);

                        String udp_msg = new String(buffer, 0, dp.getLength());
                        publishProgress(udp_msg);
                        Thread.sleep(5);
                        if (send_command_flag) {
                            if(!send_command_flag_old) {
                                dp_send = new DatagramPacket(json_buffer.getBytes(), json_buffer.length(), serverAddr, dstPort);
                                ds.send(dp_send);
                            }
                        }
                        connection = true;
                        isconnected = true;
                        send_command_flag_old=send_command_flag;
                        if (DEBUG) Log.i(TAG, "publishProgress(" + udp_msg + "%)");
                    } catch (SocketTimeoutException e) {
                        //TODO: leaks here. Check logic states
                        run = false;
                        restart = true;
                        connection = false;
                        isconnected = false;
                        ds.close();
                        publishProgress("lost");
                        Log.e("timeout ", "inner timeout");
                        break;
                    } catch (IOException e) {
                        run = false;
                        connection = false;
                        isconnected = false;
                        publishProgress("lost");
                        Log.e("io error", "inner io error");
                        ds.close();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }

                }
            }

            //ds.close();
            return null;

        }

        @Override
        protected void onPostExecute(Void ignore) {
            //super.onPostExecute(result);
            mCallbacks.onPostExecute();
            mRunning = false;
//            JSON json = new JSON(result);
//            String position = json.key("Position").stringValue();
//            String velocity = json.key("Velocity").stringValue();
//            String turn = json.key("Turn").stringValue();
//            int check = 0;
//            position_txt.setText(position);
//            velocity_txt.setText(velocity);
//            turn_txt.setText(turn);
//            //important if statment with replaceall function!
//
//
//            if (position != null) {
//                String fixed_text_1 = position.replaceAll("[^0-9]-+", "");
//                //position_bar.setProgress(Integer.valueOf(fixed_text_1));
//            }
//
//            if (velocity != null) {
//                String fixed_text_2 = velocity.replaceAll("[^0-9]-+", "");
//                check = Integer.valueOf(fixed_text_2);
//
//                if (check > 0) {
//                    velocity_bar.setProgress(check);
//                    velocity_bar_reversed.setProgress(0);
//                } else if (check == 0) {
//                    velocity_bar.setProgress(0);
//                    velocity_bar_reversed.setProgress(0);
//                } else {
//                    velocity_bar.setProgress(0);
//                    velocity_bar_reversed.setProgress(-check);
//                }
//            }
        }

        @Override
        protected void onProgressUpdate(String... value) {
            //super.onProgressUpdate(value);
            if(value[0]!=("lost")) { //check for status
                //json parsing
                JSON json = new JSON(value[0]);
                String type = json.key("Type").stringValue();

                int check2 = 0;
                int check1 = 0;
                int position_int = 0;
                int position_int_reversed = 0;
                int velocity_int = 0;
                double voltage_double =0.0;
                int velocity_int_reversed = 0;
                //position_txt.setText(position);
                //velocity_txt.setText(velocity);
                //turn_txt.setText(turn);
                //important if statement with replaceALL function!

//                if(voltage != null){
//                    String fixed_text = position.replaceAll("[^0-9]-+", "");
//                    voltage_double = Double.valueOf(fixed_text);
//                }
                if (type.equals("Movement")) {
                    String position = json.key("Position").stringValue();
                    String velocity = json.key("Velocity").stringValue();
                    String turn = json.key("Turn").stringValue();

                    if (position != null) {
                        String fixed_text = position.replaceAll("[^0-9]-+", "");
                        check1 = Integer.valueOf(fixed_text);
                        if (check1 > 0) {
                            position_int = check1;
                            position_int_reversed = 0;
                            //velocity_bar.setProgress(check);
                            //velocity_bar_reversed.setProgress(0);
                        } else if (check1 == 0) {
                            position_int = 0;
                            position_int_reversed = 0;
                            //velocity_bar.setProgress(0);
                            //velocity_bar_reversed.setProgress(0);
                        } else {
                            position_int = 0;
                            position_int_reversed = -check1;
                            //velocity_bar.setProgress(0);
                            //velocity_bar_reversed.setProgress(-check);
                        }
                        //position_bar.setProgress(Integer.valueOf(fixed_text_1));
                    }

                    if (velocity != null) {
                        String fixed_text = velocity.replaceAll("[^0-9]-+", "");
                        check2 = Integer.valueOf(fixed_text);

                        if (check2 > 0) {
                            velocity_int = check2;
                            velocity_int_reversed = 0;
                            //velocity_bar.setProgress(check);
                            //velocity_bar_reversed.setProgress(0);
                        } else if (check2 == 0) {
                            velocity_int = 0;
                            velocity_int_reversed = 0;
                            //velocity_bar.setProgress(0);
                            //velocity_bar_reversed.setProgress(0);
                        } else {
                            velocity_int = 0;
                            velocity_int_reversed = -check2;
                            //velocity_bar.setProgress(0);
                            //velocity_bar_reversed.setProgress(-check);
                        }
                    }
                    if(mRunning) {
                        if(velocity !=null & position != null & turn != null) {
                            mCallbacks.MovementUpdates(position, velocity, turn, position_int, position_int_reversed, velocity_int, velocity_int_reversed);
                        }
                    }
                }
                else if(type.equals("Utility"))
                {
                    String voltage = json.key("Voltage").stringValue();
                    if(mRunning) {
                        if(voltage != null) {
                            mCallbacks.UtilityUpdates(voltage);
                        }
                    }
                }
                //TODO:fix the temporary leak protection

            }

            //update this to onchange or listener
            //TODO:fix the temporary leak protection
            if(mRunning) {
                if (connection) {
                    if (!connection_old) {
                        mCallbacks.onConnected();
                    }
                } else {
                    if (connection_old) {
                        mCallbacks.onLostConnection();
                    }
                }
            }
            connection_old=connection;//store status

        }

        @Override
        protected void onCancelled() {

            //ds.close();
            //mCallbacks.onCancelled();
            mRunning = false;

            //ds.close();
            big_run=false;
            run=false;

            //super.onCancelled();
        }

    }

    /************************/
    /***** LOGS & STUFF *****/
    /************************/

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        if (DEBUG) Log.i(TAG, "onActivityCreated(Bundle)");
        super.onActivityCreated(savedInstanceState);
    }

    @Override
    public void onStart() {
        if (DEBUG) Log.i(TAG, "onStart()");
        run=true;
        big_run=true;
        restart=true;
        if(!mRunning){
            start();
        }

        super.onStart();

    }

    @Override
    public void onResume() {
        if (DEBUG) Log.i(TAG, "onResume()");
        //start();
        super.onResume();
    }

    @Override
    public void onPause() {
        if (DEBUG) Log.i(TAG, "onPause()");


        super.onPause();
    }

    @Override
    public void onStop() {
        if (DEBUG) Log.i(TAG, "onStop()");
        show_disconnected=false;
        super.onStop();
    }

    @Override
    public void onDestroy() {
        if (DEBUG) Log.i(TAG, "onDestroy()");
        super.onDestroy();

        ds.close(); // close socket before destroy everything
        cancel();

        run=false;
        big_run=false;

        if (isconnected) {
            mCallbacks.onDisconnected();
        }

        mCallbacks =null;

    }
    /**
     * Set the callback to null so we don't accidentally leak the
     * Activity instance.
     */
    @Override
    public void onDetach() {
        if (DEBUG) Log.i(TAG, "onDetach()");
        super.onDetach();
    }

}












//public class client extends AsyncTask<Void, Void, Void> {
//
//    String dstAddress;
//    int dstPort;
//    String response = "";
//    TextView textResponse;
//
//    client(String addr, int port,TextView textResponse) {
//        dstAddress = addr;
//        dstPort = port;
//        this.textResponse=textResponse;
//    }
//
//    @Override
//    protected Void doInBackground(Void... arg0) {
//
//        Socket socket = null;
//
//        try {
//            socket = new Socket(dstAddress, dstPort);
//
//            ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream(
//                    256);
//            byte[] buffer = new byte[256];
//
//            int bytesRead;
//            InputStream inputStream = socket.getInputStream();
//            OutputStream outputStream = socket.getOutputStream();
//
//            PrintWriter output = new PrintWriter(outputStream);
//
//            //output.print("1\r\n");
//            //outputStream.flush();
//            //outputStream.close();
//
//            /*
//			 * notice: inputStream.read() will block if no data return
//			 */
//            while ((bytesRead = inputStream.read(buffer)) != -1) {
//                byteArrayOutputStream.write(buffer, 0, bytesRead);
//                response += byteArrayOutputStream.toString("UTF-8");
//            }
//
//        } catch (UnknownHostException e) {
//            // TODO Auto-generated catch block
//            e.printStackTrace();
//            response = "UnknownHostException: " + e.toString();
//        } catch (IOException e) {
//            // TODO Auto-generated catch block
//            e.printStackTrace();
//            response = "IOException: " + e.toString();
//        } finally {
//            if (socket != null) {
//                try {
//                    socket.close();
//                } catch (IOException e) {
//                    // TODO Auto-generated catch block
//                    e.printStackTrace();
//                }
//            }
//        }
//        return null;
//    }
//
//    @Override
//    protected void onPostExecute(Void result) {
//        textResponse.setText(response);
//        super.onPostExecute(result);
//    }
//
//}

//public class client extends AsyncTask<Void,Void,Void> {
//    public static final String REQUEST_METHOD = "GET";
//    public static final int READ_TIMEOUT = 15000;
//    public static final int CONNECTION_TIMEOUT = 15000;
//    String dstAddress;
//    String response = "";
//    TextView textResponse;
//    client(String addr,TextView textResponse) {
//        dstAddress = addr;
//
//        this.textResponse=textResponse;
//    }
//
//
//    protected Void doInBackground(Void... arg0){
//        String stringUrl = dstAddress;
//
//        String inputLine;
//        try {
//            //Create a URL object holding our url
//            URL myUrl = new URL(stringUrl);
//            //Create a connection
//            HttpURLConnection connection =(HttpURLConnection)
//                    myUrl.openConnection();
//            //Set methods and timeouts
//            connection.setRequestMethod(REQUEST_METHOD);
//            connection.setReadTimeout(READ_TIMEOUT);
//            connection.setConnectTimeout(CONNECTION_TIMEOUT);
//
//            //Connect to our url
//            connection.connect();
//            //Create a new InputStreamReader
//            InputStreamReader streamReader = new
//                    InputStreamReader(connection.getInputStream());
//            //Create a new buffered reader and String Builder
//            BufferedReader reader = new BufferedReader(streamReader);
//            StringBuilder stringBuilder = new StringBuilder();
//            //Check if the line we are reading is not null
//            while((inputLine = reader.readLine()) != null){
//                stringBuilder.append(inputLine);
//            }
//            //Close our InputStream and Buffered reader
//            reader.close();
//            streamReader.close();
//            //Set our result equal to our stringBuilder
//            response = stringBuilder.toString();
//
//        }
//        catch (UnknownHostException e) {
//            // TODO Auto-generated catch block
//            e.printStackTrace();
//            response = "UnknownHostException: " + e.toString();
//        }
//        catch(IOException e){
//            e.printStackTrace();
//            response = "IOException: " + e.toString();
//        }
//
//        return null;
//    }
//    @Override
//    protected void onPostExecute(Void result){
//        textResponse.setText(response);
//        super.onPostExecute(result);
//
//
//    }
//}

