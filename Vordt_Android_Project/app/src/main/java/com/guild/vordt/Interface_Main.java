package com.guild.vordt;

import android.app.FragmentManager;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.MainThread;
import android.support.annotation.RequiresApi;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.widget.ProgressBar;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import kotlin.Unit;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.functions.Function1;

import com.ramotion.fluidslider.FluidSlider;


@RequiresApi(api = Build.VERSION_CODES.HONEYCOMB)
public class Interface_Main extends FragmentActivity implements client.TaskCallbacks{

    private static final String TAG = Interface_Main.class.getSimpleName();
    private static final boolean DEBUG = true; // Set this to false to disable logs.

    private static final String KEY_TURN_SEEK = "turn_seekbar";
    private static final String KEY_TURN_TXT = "turn_text";
    private static final String KEY_POSITION_TEXT = "position_text";
    private static final String KEY_POSITION_BAR = "position_bar";
    private static final String KEY_POSITION_SEEK = "position_seekbar";
    private static final String KEY_POSITION_REVERSED_BAR="position_reversed_bar";
    private static final String KEY_VELOCITY_SEEK = "velocity_seekbar";
    private static final String KEY_VELOCITY_TEXT = "velocity_text";
    private static final String KEY_VELOCITY_BAR= "velocity_bar";
    private static final String KEY_VELOCITY_REVERSED_BAR= "velocity_reversed_bar";

    private static final String TAG_CLIENT_FRAGMENT = "task_fragment";

    protected ProgressBar velocity_bar, velocity_bar_reversed, position_bar,position_bar_reversed;
    protected TextView velocity_txt, position_txt,turn_count_txt, voltage_txt;
    protected TextView desired_velocity_txt,desired_position_txt,desired_turn_txt;
    protected TextView response;

    protected FluidSlider position_slider,turn_slider, velocity_slider;

    private SeekBar desired_position, desired_velocity, desired_turn;
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
        position_bar_reversed = findViewById(R.id.Position_Bar_Negative);
        velocity_txt = findViewById(R.id.Velocity_Text);
        position_txt = findViewById(R.id.Position_Text);
        turn_count_txt = findViewById(R.id.Turn_Count_Text);
        voltage_txt=findViewById(R.id.Voltage_Text);
       // desired_velocity_txt=findViewById(R.id.Desired_Velocity_txt);
       // desired_position_txt=findViewById(R.id.Desired_Position_txt);
       // desired_turn_txt=findViewById(R.id.Desired_Turn_txt);

        //desired_position=findViewById(R.id.Position_Seek);
       // desired_turn=findViewById(R.id.Turn_Seek);
       // desired_velocity=findViewById(R.id.Velocity_Seek);

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

      //  desired_position_txt.setEnabled(false);
      //  desired_turn_txt.setEnabled(false);
      //  desired_velocity_txt.setEnabled(false);

         position_slider = findViewById(R.id.Position_fluidSlider);
        turn_slider = findViewById(R.id.Turn_fluidSlider);
        velocity_slider = findViewById(R.id.Velocity_fluidSlider);

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
        voltage_txt.setBackgroundResource(android.R.color.transparent);

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

            //desired_velocity.setProgress(savedInstanceState.getInt(KEY_VELOCITY_SEEK));
            //desired_turn.setProgress(savedInstanceState.getInt(KEY_TURN_SEEK));
            //desired_position.setProgress(savedInstanceState.getInt(KEY_POSITION_SEEK));

            position_bar.setProgress(savedInstanceState.getInt(KEY_POSITION_BAR));
            position_bar_reversed.setProgress(savedInstanceState.getInt(KEY_POSITION_REVERSED_BAR));

            velocity_bar.setProgress(savedInstanceState.getInt(KEY_VELOCITY_BAR));
            velocity_bar_reversed.setProgress(savedInstanceState.getInt(KEY_VELOCITY_REVERSED_BAR));
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

        /** Desired Position Seek Bar **/
        final float start_position = 0.5f;
        final int position_max = 32767;
        final int position_min = -32767;
        final int position_total = position_max - position_min;
        final String position_start_value = String.valueOf(((int)(start_position * position_total)-32767));

        position_slider.setPosition(start_position);
        position_slider.setBubbleText(position_start_value);
        position_slider.setTextSize(33f);
        position_slider.setColorBubbleText(0xffFFF8E1);
        position_slider.setColorBubble(0xFF000000);
        position_slider.setColorBar(0xFF006064);
        //position_slider.setStartText(String.valueOf(min));
        //position_slider.setEndText(String.valueOf(max));

        position_slider.setStartText("");
        position_slider.setEndText("");

        position_slider.setPositionListener(new Function1<Float, Unit>() {
            @Override
            public Unit invoke(Float aFloat) {
                /** ARGB
                 ** Aplha-Red-Green-Blue **
                 **/
                int negative_bar_color = 0xffB71C1C;
                int positive_bar_color = 0xff558B2F;

                int prog = (int) (aFloat*position_total)-32767;
                final String value = String.valueOf(prog);
                if(prog <0) {
                    position_slider.setColorBubble(negative_bar_color);
                }
                else{
                    position_slider.setColorBubble(positive_bar_color);

                }
                position_slider.setBubbleText(value);

                return null;
            }
        });

        position_slider.setBeginTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setBeginTrackingListener");
                mClient.send_flag(false);
                return Unit.INSTANCE;
            }
        });

        position_slider.setEndTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setEndTrackingListener");
                mClient.send_flag(true);
                mClient.send_command("position", (int)(position_slider.getPosition()*position_total)-32767);
                return Unit.INSTANCE;
            }
        });

        /** Desired Turn Seek Bar **/
        final float start_turn = 0.5f;
        final int turn_max = 50;
        final int turn_min = -50;
        final int turn_total = turn_max - turn_min;
        final String turn_start_value = String.valueOf(((int)(start_position * turn_total)-50));

        turn_slider.setPosition(start_turn);
        turn_slider.setBubbleText(turn_start_value);
        turn_slider.setTextSize(33f);
        turn_slider.setColorBubbleText(0xffFFF8E1);
        turn_slider.setColorBubble(0xFF000000);
        turn_slider.setColorBar(0xFFE0E0E0 );
        //turn_slider.setStartText(String.valueOf(min));
        //turn_slider.setEndText(String.valueOf(max));
        turn_slider.setStartText("");
        turn_slider.setEndText("");

        turn_slider.setPositionListener(new Function1<Float, Unit>() {
            @Override
            public Unit invoke(Float aFloat) {
                /** ARGB
                 ** Aplha-Red-Green-Blue **
                 **/
                int negative_bar_color = 0xffB71C1C;
                int positive_bar_color = 0xff558B2F;

                int prog = (int) (aFloat*turn_total)-50;
                final String value = String.valueOf(prog);
                if(prog <0) {
                    turn_slider.setColorBubble(negative_bar_color);
                }
                else{
                    turn_slider.setColorBubble(positive_bar_color);

                }
                turn_slider.setBubbleText(value);

                return null;
            }
        });

        turn_slider.setBeginTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setBeginTrackingListener");
                mClient.send_flag(false);
                return Unit.INSTANCE;
            }
        });

        turn_slider.setEndTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setEndTrackingListener");
                mClient.send_flag(true);
                mClient.send_command("turn", (int)(turn_slider.getPosition()*turn_total)-50 );
                return Unit.INSTANCE;
            }
        });

        /*
        desired_turn.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            int progress = 0;

            @Override
            public void onProgressChanged(SeekBar seekBar, int progresValue, boolean fromUser) {
                //Must be between -20 - 20. It should also start at 0.
                progress = progresValue-20;
                desired_turn_txt.setText(progress + "");

            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                mClient.send_flag(false);
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                mClient.send_flag(true);
                mClient.send_command("turn",progress);
            }
        });*/

        /** Desired Velocity Seek Bar **/
        final float start_velocity = 0.4f;
        final int velocity_max = 150;
        final int velocity_min = 0;
        final int velocity_total = velocity_max - velocity_min;
        final String velocity_start_value = String.valueOf((int)(start_velocity * velocity_total));

        velocity_slider.setPosition(start_velocity);
        velocity_slider.setBubbleText(velocity_start_value);
        velocity_slider.setTextSize(33f);
        velocity_slider.setColorBubbleText(0xffFFF8E1);
        velocity_slider.setColorBubble(0xFF000000);
        //velocity_slider.setStartText(String.valueOf(min));
        //velocity_slider.setEndText(String.valueOf(max));
        velocity_slider.setStartText("");
        velocity_slider.setEndText("");

        velocity_slider.setPositionListener(new Function1<Float, Unit>() {
            @Override
            public Unit invoke(Float aFloat) {
                /** ARGB
                 ** Aplha-Red-Green-Blue **
                 **/
                int negative_bar_color = 0xff0288D1;
                int positive_bar_color = 0xff558B2F;

                int prog = (int) (aFloat*velocity_total);
                final String value = String.valueOf(prog+10);
                /*if(prog <0) {
                    velocity_slider.setColorBar(negative_bar_color);
                }
                else{
                    velocity_slider.setColorBar(positive_bar_color);

                }*/
                velocity_slider.setBubbleText(value);

                return null;
            }
        });

        velocity_slider.setBeginTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setBeginTrackingListener");
                mClient.send_flag(false);
                return Unit.INSTANCE;
            }
        });

        velocity_slider.setEndTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setEndTrackingListener");
                mClient.send_flag(true);
                mClient.send_command("velocity", (int)(velocity_slider.getPosition()*velocity_total)+10);
                return Unit.INSTANCE;
            }
        });

        /*
        desired_velocity.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            int progress = 0;

            @Override
            public void onProgressChanged(SeekBar seekBar, int progresValue, boolean fromUser) {
                //Must be between 10-150. It should also start at 40.
                progress = progresValue;
                desired_velocity_txt.setText(progress+ "");

            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                mClient.send_flag(false);
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                mClient.send_flag(true);
                mClient.send_command("velocity",progress);
            }
        });
        */

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
        outState.putInt(KEY_POSITION_REVERSED_BAR, position_bar_reversed.getProgress());
        outState.putInt(KEY_VELOCITY_BAR, velocity_bar.getProgress());
        outState.putInt(KEY_VELOCITY_REVERSED_BAR, velocity_bar_reversed.getProgress());

  //      outState.putInt(KEY_POSITION_SEEK, desired_position.getProgress());
 //       outState.putInt(KEY_VELOCITY_SEEK, desired_velocity.getProgress());
 //       outState.putInt(KEY_TURN_SEEK, desired_turn.getProgress());

    }
    @Override
    public void onPreExecute() {
        if (DEBUG) Log.i(TAG, "onPreExecute()");
    }

    @Override
    public void MovementUpdates(String Position, String Velocity, String Turn, int position, int position_reversed, int velocity, int velocity_reversed) {
        //if (DEBUG) Log.i(TAG, "onProgressUpdate");
        position_txt.setText(Position);
        velocity_txt.setText(Velocity);
        turn_count_txt.setText(Turn);

        position_bar.setProgress(position);
        position_bar_reversed.setProgress(position_reversed);
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