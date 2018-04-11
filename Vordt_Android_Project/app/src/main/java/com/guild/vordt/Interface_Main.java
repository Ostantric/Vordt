package com.guild.vordt;

import android.app.FragmentManager;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;



public class Interface_Main extends FragmentActivity implements client.TaskCallbacks{

    private static final String TAG = Interface_Main.class.getSimpleName();
    private static final boolean DEBUG = true; // Set this to false to disable logs.

    private static final String KEY_TURN_TXT = "turn_text";
    private static final String KEY_POSITION_TEXT = "position_text";
    private static final String KEY_POSITION_BAR = "position_bar";
    private static final String KEY_VELOCITY_TEXT = "velocity_text";
    private static final String KEY_VELOCTY_BAR= "velocity_bar";
    private static final String KEY_VELOCTY_REVERSED_BAR= "velocity_reversed_bar";

    private static final String TAG_CLIENT_FRAGMENT = "task_fragment";

    protected ProgressBar velocity_bar, velocity_bar_reversed, position_bar;
    protected TextView velocity_txt, position_txt,turn_count_txt, voltage_txt;
    protected TextView response;
    private int velocity_status = 0;
    private int position_status = 0;
    private int Port;
    private String IP;
    private boolean run_flag;
    private client mClient;
    Bundle bundle = new Bundle();
    FragmentManager frgmn = getFragmentManager();



    @Override
    protected void onCreate(Bundle savedInstanceState) {
        if (DEBUG) Log.i(TAG, "onCreate(Bundle)");
        super  .onCreate(savedInstanceState);
        this.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN);
        this.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.interface_main);
        velocity_status=0;
        velocity_bar_reversed = findViewById(R.id.Velocity_Bar_Negative);
        velocity_bar = findViewById(R.id.Velocity_Bar);
        position_bar = findViewById(R.id.Position_Bar);
        velocity_txt = findViewById(R.id.Velocity_Text);
        position_txt = findViewById(R.id.Position_Text);
        turn_count_txt = findViewById(R.id.Turn_Count_Text);
        voltage_txt=findViewById(R.id.Voltage_Text);

        TextView txt1 = findViewById(R.id.editText);
        TextView txt2 = findViewById(R.id.editText3);
        TextView txt3 = findViewById(R.id.editText5);
        TextView txt4 = findViewById(R.id.editText6);
        TextView txt5 = findViewById(R.id.editText2);
        TextView txt6 = findViewById(R.id.editText4);

        velocity_txt.setEnabled(false);
        position_txt.setEnabled(false);
        turn_count_txt.setEnabled(false);
        voltage_txt.setEnabled(false);

        txt1.setEnabled(false);
        txt2.setEnabled(false);
        txt3.setEnabled(false);
        txt4.setEnabled(false);
        txt5.setEnabled(false);
        txt6.setEnabled(false);


        velocity_bar.setScaleY(18);
        velocity_bar_reversed.setScaleY(18);
        velocity_txt.setBackgroundResource(android.R.color.transparent);
        position_txt.setBackgroundResource(android.R.color.transparent);
        turn_count_txt.setBackgroundResource(android.R.color.transparent);

        //get values from MainActivity
        Intent intent = getIntent();
        Port = intent.getIntExtra("port", 1500);
        IP = intent.getStringExtra("ip");


        // If the Fragment is non-null, then it is being retained
        // over a configuration change.

        if(savedInstanceState !=null){
            position_txt.setText(savedInstanceState.getString(KEY_POSITION_TEXT));
            velocity_txt.setText(savedInstanceState.getString(KEY_VELOCITY_TEXT));
            turn_count_txt.setText(savedInstanceState.getString(KEY_TURN_TXT));

            position_bar.setProgress(savedInstanceState.getInt(KEY_POSITION_BAR));
            velocity_bar.setProgress(savedInstanceState.getInt(KEY_VELOCTY_BAR));
            velocity_bar_reversed.setProgress(savedInstanceState.getInt(KEY_VELOCTY_REVERSED_BAR));
        }
        bundle.putInt("Port",Port);
        bundle.putString("IP",IP);

        mClient = (client) frgmn.findFragmentByTag(TAG_CLIENT_FRAGMENT);
        if (mClient == null) {

            mClient = new client();
            mClient.setArguments(bundle);
            frgmn.beginTransaction().add(mClient, TAG_CLIENT_FRAGMENT).commit();
            //frgmn.beginTransaction().add(mClient,TAG_CLIENT_FRAGMENT, arg).commit();
        }

        //mClient.start();

    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        if (DEBUG) Log.i(TAG, "onSaveInstanceState(Bundle)");
        super.onSaveInstanceState(outState);

        outState.putString(KEY_POSITION_TEXT, position_txt.getText().toString());
        outState.putString(KEY_VELOCITY_TEXT, velocity_txt.getText().toString());
        outState.putString(KEY_TURN_TXT, turn_count_txt.getText().toString());

        outState.putInt(KEY_POSITION_BAR, position_bar.getProgress());
        outState.putInt(KEY_VELOCTY_BAR, velocity_bar.getProgress());
        outState.putInt(KEY_VELOCTY_REVERSED_BAR, velocity_bar_reversed.getProgress());

    }


    @Override
    public void onPreExecute() {
        if (DEBUG) Log.i(TAG, "onPreExecute()");
    }

    @Override
    public void MovementUpdates(String Position, String Velocity, String Turn, int position, int velocity, int velocity_reversed) {
        //if (DEBUG) Log.i(TAG, "onProgressUpdate");
        position_txt.setText(Position);
        velocity_txt.setText(Velocity);
        turn_count_txt.setText(Turn);

        position_bar.setProgress(position);
        velocity_bar.setProgress(velocity);
        velocity_bar_reversed.setProgress(velocity_reversed);
    }

    @Override
    public void UtilityUpdates(String voltage) {
        voltage_txt.setText(voltage);
    }

    @Override
    public void onCancelled() {
        if (DEBUG) Log.i(TAG, "onCancelled()");
    }

    @Override
    public void onPostExecute() {
        if (DEBUG) Log.i(TAG, "onPostExecute()");
    }

    @Override
    public void onConnected() {
        if (DEBUG) Log.i(TAG, "onConnected()");
        Toast.makeText(this, "Connected to VORDT", Toast.LENGTH_SHORT).show();
    }

    @Override
    public void onLostConnection() {
        if (DEBUG) Log.i(TAG, "onLostConnection()");
        Toast.makeText(this, "VORDT Connection Lost!", Toast.LENGTH_LONG).show();


    }

    @Override
    public void onDisconnected() {
        if (DEBUG) Log.i(TAG, "onDisconnected()");
        Toast.makeText(this, "Disconnected from VORDT!", Toast.LENGTH_LONG).show();

    }

    @Override
    protected void onStart() {
        if (DEBUG) Log.i(TAG, "onStart()");

        super.onStart();

        //FragmentManager frgmn = getFragmentManager();
        mClient = (client) frgmn.findFragmentByTag(TAG_CLIENT_FRAGMENT);
        if (mClient == null) {

            mClient = new client();

            frgmn.beginTransaction().add(mClient, TAG_CLIENT_FRAGMENT).commit();
            //frgmn.beginTransaction().add(mClient,TAG_CLIENT_FRAGMENT, arg).commit();
        }
        //mClient.start();

        //mClient.setArguments(bundle);
        //mClient.start();
        //run_flag=true;

        //myClient.cancel(false);

        //myClient = new client("192.168.1.228", 1500, position_txt,velocity_txt,turn_count_txt,position_bar, velocity_bar,velocity_bar_reversed);


    }
    @Override
    protected void onResume() {
        if (DEBUG) Log.i(TAG, "onResume()");
        super.onResume();
    }
    @Override
    protected void onPause() {
        if (DEBUG) Log.i(TAG, "onPause()");
        super.onPause();
    }

    @Override
    protected void onStop() {
        if (DEBUG) Log.i(TAG, "onStop()");
        super.onStop();
    }


    @Override
    protected void onDestroy() {
        if (DEBUG) Log.i(TAG, "onDestroy()");
        super.onDestroy();
    }
}
