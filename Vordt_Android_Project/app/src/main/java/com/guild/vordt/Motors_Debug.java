package com.guild.vordt;

import android.annotation.SuppressLint;
import android.app.FragmentManager;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.MainThread;
import android.support.annotation.RequiresApi;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import kotlin.Unit;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.functions.Function1;

import com.ramotion.fluidslider.FluidSlider;

import static java.lang.Thread.currentThread;
import static java.lang.Thread.sleep;


@RequiresApi(api = Build.VERSION_CODES.HONEYCOMB)
public class Motors_Debug extends FragmentActivity implements client.TaskCallbacks{

    private static final String TAG = Interface_Main.class.getSimpleName();
    private static final boolean DEBUG = true; // Set this to false to disable logs.

    private static final String KEY_TURN_SEEK_1 = "turn_seekbar_1";
    private static final String KEY_TURN_TXT_1 = "turn_text_1";
    private static final String KEY_POSITION_TEXT_1 = "position_text_1";
    private static final String KEY_POSITION_BAR_1 = "position_bar_1";
    private static final String KEY_POSITION_SEEK_1 = "position_seekbar_1";
    private static final String KEY_POSITION_REVERSED_BAR_1="position_reversed_bar_1";
    private static final String KEY_VELOCITY_SEEK_1 = "velocity_seekbar_1";
    private static final String KEY_VELOCITY_TEXT_1 = "velocity_text_1";
    private static final String KEY_VELOCITY_BAR_1= "velocity_bar_1";
    private static final String KEY_VELOCITY_REVERSED_BAR_1= "velocity_reversed_bar_1";
    private static final String KEY_DESIRED_VELOCITY_INPUT_TEXT_1="desired_velocity_input_1";
    private static final String KEY_DESIRED_POSITION_INPUT_TEXT_1="desired_position_input_1";
    private static final String KEY_DESIRED_TURN_INPUT_TEXT_1="desired_turn_input_1";

    private static final String KEY_TURN_SEEK_2 = "turn_seekbar_2";
    private static final String KEY_TURN_TXT_2 = "turn_text_2";
    private static final String KEY_POSITION_TEXT_2 = "position_text_2";
    private static final String KEY_POSITION_BAR_2 = "position_bar_2";
    private static final String KEY_POSITION_SEEK_2 = "position_seekbar_2";
    private static final String KEY_POSITION_REVERSED_BAR_2="position_reversed_bar_2";
    private static final String KEY_VELOCITY_SEEK_2 = "velocity_seekbar_2";
    private static final String KEY_VELOCITY_TEXT_2 = "velocity_text_2";
    private static final String KEY_VELOCITY_BAR_2= "velocity_bar_2";
    private static final String KEY_VELOCITY_REVERSED_BAR_2= "velocity_reversed_bar_2";
    private static final String KEY_DESIRED_VELOCITY_INPUT_TEXT_2="desired_velocity_input_2";
    private static final String KEY_DESIRED_POSITION_INPUT_TEXT_2="desired_position_input_2";
    private static final String KEY_DESIRED_TURN_INPUT_TEXT_2="desired_turn_input_2";

    private static final String TAG_CLIENT_FRAGMENT = "task_fragment";

    protected ProgressBar velocity_bar_1, velocity_bar_reversed_1, position_bar_1,position_bar_reversed_1;
    protected ProgressBar velocity_bar_2, velocity_bar_reversed_2, position_bar_2,position_bar_reversed_2;

    protected TextView velocity_txt_1, position_txt_1,turn_count_txt_1, voltage_txt_1;
    protected TextView velocity_txt_2, position_txt_2,turn_count_txt_2, voltage_txt_2;

    protected TextView desired_velocity_txt_1,desired_position_txt_1,desired_turn_txt_1;
    protected TextView desired_velocity_txt_2,desired_position_txt_2,desired_turn_txt_2;

    protected TextView desired_velocity_input_txt_1,desired_position_input_txt_1,desired_turn_input_txt_1;
    protected TextView desired_velocity_input_txt_2,desired_position_input_txt_2,desired_turn_input_txt_2;


    protected TextView response;

    protected FluidSlider position_slider_1,turn_slider_1, velocity_slider_1;
    protected FluidSlider position_slider_2,turn_slider_2, velocity_slider_2;

    private SeekBar desired_position_1, desired_velocity_1, desired_turn_1;
    private SeekBar desired_position_2, desired_velocity_2, desired_turn_2;

    private int velocity_status = 0;
    private int position_status = 0;
    private int Port;
    private int current_Turn_1,position_total_1,position_max_1,position_min_1;
    private int current_Turn_2,position_total_2,position_max_2,position_min_2;

    private String current_position_1;
    private String current_position_2;
    private String IP;

    private boolean run_flag,fill_once,fill_once_old;

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
        setContentView(R.layout.motors_debug);
        final Button motor1_reset_button = findViewById(R.id.motor1_reset_button);
        final Button motor1_send_button = findViewById(R.id.motor1_send_button);

        final Button motor2_reset_button = findViewById(R.id.motor2_reset_button);
        final Button motor2_send_button = findViewById(R.id.motor2_send_button);

        final Button motors_send_button = findViewById(R.id.motors_send_button);

        velocity_status=0;
        velocity_bar_reversed_1 = findViewById(R.id.Velocity_Bar_Negative_1);
        velocity_bar_1 = findViewById(R.id.Velocity_Bar_1);
        position_bar_1 = findViewById(R.id.Position_Bar_1);
        position_bar_reversed_1 = findViewById(R.id.Position_Bar_Negative_1);
        velocity_txt_1 = findViewById(R.id.Velocity_Text_1);
        position_txt_1 = findViewById(R.id.Position_Text_1);
        turn_count_txt_1 = findViewById(R.id.Turn_Count_Text_1);
        voltage_txt_1 =findViewById(R.id.Voltage_Text_1);
        desired_velocity_input_txt_1 = findViewById(R.id.Desired_Velocity_Input_Text_1);
        desired_position_input_txt_1 = findViewById(R.id.Desired_Position_Input_Text_1);
        desired_turn_input_txt_1 = findViewById(R.id.Desired_Turn_Input_Text_1);


        velocity_bar_reversed_2 = findViewById(R.id.Velocity_Bar_Negative_2);
        velocity_bar_2 = findViewById(R.id.Velocity_Bar_2);
        position_bar_2 = findViewById(R.id.Position_Bar_2);
        position_bar_reversed_2 = findViewById(R.id.Position_Bar_Negative_2);
        velocity_txt_2 = findViewById(R.id.Velocity_Text_2);
        position_txt_2 = findViewById(R.id.Position_Text_2);
        turn_count_txt_2 = findViewById(R.id.Turn_Count_Text_2);
        voltage_txt_2 =findViewById(R.id.Voltage_Text_2);
        desired_velocity_input_txt_2 = findViewById(R.id.Desired_Velocity_Input_Text_2);
        desired_position_input_txt_2 = findViewById(R.id.Desired_Position_Input_Text_2);
        desired_turn_input_txt_2 = findViewById(R.id.Desired_Turn_Input_Text_2);
        // desired_velocity_txt_1=findViewById(R.id.desired_velocity_txt_1);
        // desired_position_txt_1=findViewById(R.id.desired_position_txt_1);
        // desired_turn_txt_1=findViewById(R.id.desired_turn_txt_1);

        //desired_position=findViewById(R.id.Position_Seek);
        // desired_turn=findViewById(R.id.Turn_Seek);
        // desired_velocity=findViewById(R.id.Velocity_Seek);

        TextView txt1 = findViewById(R.id.editText);
        TextView txt2 = findViewById(R.id.editText2);
        TextView txt3 = findViewById(R.id.editText3);
        TextView txt4 = findViewById(R.id.editText4);
        TextView txt5 = findViewById(R.id.editText5);
        TextView txt6 = findViewById(R.id.editText6);
        TextView txt7 = findViewById(R.id.editText7);
        TextView txt8 = findViewById(R.id.editText8);
        TextView txt9 = findViewById(R.id.editText9);
        TextView txt10 = findViewById(R.id.editText10);
        TextView txt11 = findViewById(R.id.editText11);
        TextView txt12 = findViewById(R.id.editText12);
        TextView txt13 = findViewById(R.id.editText13);
        TextView txt14 = findViewById(R.id.editText14);
        TextView txt15 = findViewById(R.id.editText15);

        velocity_txt_1.setEnabled(false);
        position_txt_1.setEnabled(false);
        turn_count_txt_1.setEnabled(false);
        voltage_txt_1.setEnabled(false);

        velocity_txt_2.setEnabled(false);
        position_txt_2.setEnabled(false);
        turn_count_txt_2.setEnabled(false);
        voltage_txt_2.setEnabled(false);

        desired_velocity_input_txt_1.setEnabled(true);
        desired_position_input_txt_1.setEnabled(true);
        desired_turn_input_txt_1.setEnabled(true);

        desired_velocity_input_txt_2.setEnabled(true);
        desired_position_input_txt_2.setEnabled(true);
        desired_turn_input_txt_2.setEnabled(true);

        //  desired_position_txt_1.setEnabled(false);
        //  desired_turn_txt_1.setEnabled(false);
        //  desired_velocity_txt_1.setEnabled(false);

        position_slider_1 = findViewById(R.id.Position_fluidSlider_1);
        turn_slider_1 = findViewById(R.id.Turn_fluidSlider_1);
        velocity_slider_1 = findViewById(R.id.Velocity_fluidSlider_1);

        position_slider_2 = findViewById(R.id.Position_fluidSlider_2);
        turn_slider_2 = findViewById(R.id.Turn_fluidSlider_2);
        velocity_slider_2 = findViewById(R.id.Velocity_fluidSlider_2);

        txt1.setEnabled(false);
        txt2.setEnabled(false);
        txt3.setEnabled(false);
        txt4.setEnabled(false);
        txt5.setEnabled(false);
        txt6.setEnabled(false);
        txt7.setEnabled(false);
        txt8.setEnabled(false);
        txt9.setEnabled(false);
        txt10.setEnabled(false);
        txt11.setEnabled(false);
        txt12.setEnabled(false);
        txt13.setEnabled(false);
        txt14.setEnabled(false);
        txt15.setEnabled(false);


        velocity_bar_1.setScaleY(15);
        velocity_bar_reversed_1.setScaleY(15);

        velocity_bar_2.setScaleY(15);
        velocity_bar_reversed_2.setScaleY(15);

        velocity_txt_1.setBackgroundResource(android.R.color.transparent);
        position_txt_1.setBackgroundResource(android.R.color.transparent);
        turn_count_txt_1.setBackgroundResource(android.R.color.transparent);
        voltage_txt_1.setBackgroundResource(android.R.color.transparent);
        desired_velocity_input_txt_1.setBackgroundResource(android.R.color.transparent);
        desired_position_input_txt_1.setBackgroundResource(android.R.color.transparent);
        desired_turn_input_txt_1.setBackgroundResource(android.R.color.transparent);

        velocity_txt_2.setBackgroundResource(android.R.color.transparent);
        position_txt_2.setBackgroundResource(android.R.color.transparent);
        turn_count_txt_2.setBackgroundResource(android.R.color.transparent);
        voltage_txt_2.setBackgroundResource(android.R.color.transparent);
        desired_velocity_input_txt_2.setBackgroundResource(android.R.color.transparent);
        desired_position_input_txt_2.setBackgroundResource(android.R.color.transparent);
        desired_turn_input_txt_2.setBackgroundResource(android.R.color.transparent);

        //get values from MainActivity
        Intent intent = getIntent();
        Port = intent.getIntExtra("port", 1500);
        IP = intent.getStringExtra("ip");

        // If the Fragment is non-null, then it is being retained
        // over a configuration change.
        if(savedInstanceState !=null){
            position_txt_1.setText(savedInstanceState.getString(KEY_POSITION_TEXT_1));
            velocity_txt_1.setText(savedInstanceState.getString(KEY_VELOCITY_TEXT_1));
            turn_count_txt_1.setText(savedInstanceState.getString(KEY_TURN_TXT_1));
            desired_velocity_input_txt_1.setText(savedInstanceState.getString(KEY_DESIRED_VELOCITY_INPUT_TEXT_1));
            desired_position_input_txt_1.setText(savedInstanceState.getString(KEY_DESIRED_POSITION_INPUT_TEXT_1));
            desired_turn_input_txt_1.setText(savedInstanceState.getString(KEY_DESIRED_TURN_INPUT_TEXT_1));
            position_bar_1.setProgress(savedInstanceState.getInt(KEY_POSITION_BAR_1));
            position_bar_reversed_1.setProgress(savedInstanceState.getInt(KEY_POSITION_REVERSED_BAR_1));
            velocity_bar_1.setProgress(savedInstanceState.getInt(KEY_VELOCITY_BAR_1));
            velocity_bar_reversed_1.setProgress(savedInstanceState.getInt(KEY_VELOCITY_REVERSED_BAR_1));

            position_txt_2.setText(savedInstanceState.getString(KEY_POSITION_TEXT_2));
            velocity_txt_2.setText(savedInstanceState.getString(KEY_VELOCITY_TEXT_2));
            turn_count_txt_2.setText(savedInstanceState.getString(KEY_TURN_TXT_2));
            desired_velocity_input_txt_2.setText(savedInstanceState.getString(KEY_DESIRED_VELOCITY_INPUT_TEXT_2));
            desired_position_input_txt_2.setText(savedInstanceState.getString(KEY_DESIRED_POSITION_INPUT_TEXT_2));
            desired_turn_input_txt_2.setText(savedInstanceState.getString(KEY_DESIRED_TURN_INPUT_TEXT_2));
            position_bar_2.setProgress(savedInstanceState.getInt(KEY_POSITION_BAR_2));
            position_bar_reversed_2.setProgress(savedInstanceState.getInt(KEY_POSITION_REVERSED_BAR_2));
            velocity_bar_2.setProgress(savedInstanceState.getInt(KEY_VELOCITY_BAR_2));
            velocity_bar_reversed_2.setProgress(savedInstanceState.getInt(KEY_VELOCITY_REVERSED_BAR_2));
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
        //mClient.send_flag(false);
        /** Desired Position Seek Bar 1 **/
        final float start_position_1 = 0.5f;
        final String position_start_value_1 = String.valueOf(((int)(start_position_1 * position_total_1)));
        //final String position_start_value_1 = String.valueOf(current_position_1);
        position_slider_1.setPosition(start_position_1);
        position_slider_1.setBubbleText(position_start_value_1);
        position_slider_1.setTextSize(33f);
        position_slider_1.setColorBubbleText(0xffFFF8E1);
        position_slider_1.setColorBubble(0xFF000000);
        position_slider_1.setColorBar(0xFF006064);
        //position_slider_1.setStartText(String.valueOf(min));
        //position_slider_1.setEndText(String.valueOf(max));

        position_slider_1.setStartText("");
        position_slider_1.setEndText("");

        position_slider_1.setPositionListener(new Function1<Float, Unit>() {
            @Override
            public Unit invoke(Float aFloat) {
                /** ARGB
                 ** Aplha-Red-Green-Blue **
                 **/
                int prog_1=0;

                if (current_Turn_1>0){
                    position_max_1=32767;
                    position_min_1=0;
                    position_total_1= position_max_1 - position_min_1;
                    prog_1= (int) (aFloat*position_total_1);

                }
                else if (current_Turn_1 <0) {
                    position_max_1=0;
                    position_min_1=-32767;
                    position_total_1= position_max_1 - position_min_1;
                    prog_1= (int) (aFloat*position_total_1)-32767;
                }
                else {
                    position_max_1= 32767;
                    position_min_1=-32767;
                    position_total_1= position_max_1 - position_min_1;
                    prog_1= (int) (aFloat*position_total_1)-32767;
                }
                int negative_bar_color_1 = 0xffB71C1C;
                int positive_bar_color_1 = 0xff558B2F;

                final String value_1 = String.valueOf(prog_1);
                if(prog_1 <0) {
                    position_slider_1.setColorBubble(negative_bar_color_1);
                }
                else{
                    position_slider_1.setColorBubble(positive_bar_color_1);

                }
                position_slider_1.setBubbleText(value_1);
                desired_position_input_txt_1.setText(value_1);

                return null;
            }
        });

        position_slider_1.setBeginTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setBeginTrackingListener");
                //mClient.send_flag(false);
                return Unit.INSTANCE;
            }
        });

        position_slider_1.setEndTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setEndTrackingListener");
                //mClient.send_flag(true);
               /* if (current_Turn_1>0) {
                    mClient.send_command(1,"position", (int) (position_slider_1.getPosition() * position_total_1));
                }
                else if (current_Turn_1<0){
                    mClient.send_command(1,"position", (int) (position_slider_1.getPosition() * position_total_1)-32767);

                }
                else{
                    mClient.send_command(1,"position", (int) (position_slider_1.getPosition() * position_total_1) - 32767);
                }*/

                return Unit.INSTANCE;
            }
        });

       /** Desired Position Seek Bar 2 **/
       final float start_position_2 = 0.5f;
       final String position_start_value_2 = String.valueOf(((int)(start_position_2 * position_total_2)));
       //final String position_start_value_2 = String.valueOf(current_position_2);
       position_slider_2.setPosition(start_position_2);
       position_slider_2.setBubbleText(position_start_value_2);
       position_slider_2.setTextSize(33f);
       position_slider_2.setColorBubbleText(0xffFFF8E1);
       position_slider_2.setColorBubble(0xFF000000);
       position_slider_2.setColorBar(0xFF006064);
       //position_slider_2.setStartText(String.valueOf(min));
       //position_slider_2.setEndText(String.valueOf(max));

       position_slider_2.setStartText("");
       position_slider_2.setEndText("");

       position_slider_2.setPositionListener(new Function1<Float, Unit>() {
           @Override
           public Unit invoke(Float aFloat) {
               /** ARGB
                ** Aplha-Red-Green-Blue **
                **/
               int prog_2=0;

               if (current_Turn_2>0){
                   position_max_2=32767;
                   position_min_2=0;
                   position_total_2= position_max_2 - position_min_2;
                   prog_2= (int) (aFloat*position_total_2);

               }
               else if (current_Turn_2 <0) {
                   position_max_2=0;
                   position_min_2=-32767;
                   position_total_2= position_max_2 - position_min_2;
                   prog_2= (int) (aFloat*position_total_2)-32767;
               }
               else {
                   position_max_2= 32767;
                   position_min_2=-32767;
                   position_total_2= position_max_2 - position_min_2;
                   prog_2= (int) (aFloat*position_total_2)-32767;
               }
               int negative_bar_color_2 = 0xffB71C1C;
               int positive_bar_color_2 = 0xff558B2F;

               final String value_2 = String.valueOf(prog_2);
               if(prog_2 <0) {
                   position_slider_2.setColorBubble(negative_bar_color_2);
               }
               else{
                   position_slider_2.setColorBubble(positive_bar_color_2);

               }
               position_slider_2.setBubbleText(value_2);
               desired_position_input_txt_2.setText(value_2);


               return null;
           }
       });

       position_slider_2.setBeginTrackingListener(new Function0<Unit>() {
           @Override
           public Unit invoke() {
               Log.e("E", "setBeginTrackingListener");
               //mClient.send_flag(false);
               return Unit.INSTANCE;
           }
       });

       position_slider_2.setEndTrackingListener(new Function0<Unit>() {
           @Override
           public Unit invoke() {
               Log.e("E", "setEndTrackingListener");
               /*mClient.send_flag(true);
               if (current_Turn_2>0) {
                   mClient.send_command(2,"position", (int) (position_slider_2.getPosition() * position_total_2));
               }
               else if (current_Turn_2<0){
                   mClient.send_command(2,"position", (int) (position_slider_2.getPosition() * position_total_2)-32767);

               }
               else{
                   mClient.send_command(2,"position", (int) (position_slider_2.getPosition() * position_total_2) - 32767);
               }*/

               return Unit.INSTANCE;
           }
       });
      

        /** Desired Turn Seek Bar 1**/
        final float start_turn_1 = 0.5f;
        final int turn_max_1 = 50;
        final int turn_min_1 = -50;
        final int turn_total_1 = turn_max_1 - turn_min_1;
        final String turn_start_value_1 = String.valueOf(((int)(start_turn_1 * turn_total_1)-50));

        turn_slider_1.setPosition(start_turn_1);
        turn_slider_1.setBubbleText(turn_start_value_1);
        turn_slider_1.setTextSize(33f);
        turn_slider_1.setColorBubbleText(0xffFFF8E1);
        turn_slider_1.setColorBubble(0xFF000000);
        turn_slider_1.setColorBar(0xFFE0E0E0 );
        //turn_slider_1.setStartText(String.valueOf(min));
        //turn_slider_1.setEndText(String.valueOf(max));
        turn_slider_1.setStartText("");
        turn_slider_1.setEndText("");

        turn_slider_1.setPositionListener(new Function1<Float, Unit>() {
            @Override
            public Unit invoke(Float aFloat) {
                /** ARGB
                 ** Aplha-Red-Green-Blue **
                 **/
                int negative_bar_color_1 = 0xffB71C1C;
                int positive_bar_color_1 = 0xff558B2F;

                int prog_1 = (int) (aFloat*turn_total_1)-50;
                current_Turn_1 = prog_1;
                final String value_1 = String.valueOf(prog_1);
                if(prog_1 <0) {
                    turn_slider_1.setColorBubble(negative_bar_color_1);
                }
                else{
                    turn_slider_1.setColorBubble(positive_bar_color_1);

                }
                turn_slider_1.setBubbleText(value_1);
                desired_turn_input_txt_1.setText(value_1);
                return null;
            }
        });

        turn_slider_1.setBeginTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setBeginTrackingListener");
                //mClient.send_flag(false);
                return Unit.INSTANCE;
            }
        });

        turn_slider_1.setEndTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setEndTrackingListener");
                //mClient.send_flag(true);
                //mClient.send_command(1,"turn", (int)(turn_slider_1.getPosition()*turn_total_1)-50 );
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
                desired_turn_txt_1.setText(progress + "");

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

        /** Desired Turn Seek Bar 2**/
        final float start_turn_2 = 0.5f;
        final int turn_max_2 = 50;
        final int turn_min_2 = -50;
        final int turn_total_2 = turn_max_2 - turn_min_2;
        final String turn_start_value_2 = String.valueOf(((int)(start_turn_2 * turn_total_2)-50));

        turn_slider_2.setPosition(start_turn_2);
        turn_slider_2.setBubbleText(turn_start_value_2);
        turn_slider_2.setTextSize(33f);
        turn_slider_2.setColorBubbleText(0xffFFF8E1);
        turn_slider_2.setColorBubble(0xFF000000);
        turn_slider_2.setColorBar(0xFFE0E0E0 );
        //turn_slider_2.setStartText(String.valueOf(min));
        //turn_slider_2.setEndText(String.valueOf(max));
        turn_slider_2.setStartText("");
        turn_slider_2.setEndText("");

        turn_slider_2.setPositionListener(new Function1<Float, Unit>() {
            @Override
            public Unit invoke(Float aFloat) {
                /** ARGB
                 ** Aplha-Red-Green-Blue **
                 **/
                int negative_bar_color_2 = 0xffB71C1C;
                int positive_bar_color_2 = 0xff558B2F;

                int prog_2 = (int) (aFloat*turn_total_2)-50;
                current_Turn_2 = prog_2;
                final String value_2 = String.valueOf(prog_2);
                if(prog_2 <0) {
                    turn_slider_2.setColorBubble(negative_bar_color_2);
                }
                else{
                    turn_slider_2.setColorBubble(positive_bar_color_2);

                }
                turn_slider_2.setBubbleText(value_2);
                desired_turn_input_txt_2.setText(value_2);
                return null;
            }
        });

        turn_slider_2.setBeginTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setBeginTrackingListener");
                //mClient.send_flag(false);
                return Unit.INSTANCE;
            }
        });

        turn_slider_2.setEndTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setEndTrackingListener");
                //mClient.send_flag(true);
                //mClient.send_command(2,"turn", (int)(turn_slider_2.getPosition()*turn_total_2)-50 );
                return Unit.INSTANCE;
            }
        });

        


        /** Desired Velocity Seek Bar 1 **/
        final float start_velocity_1 = 0.4f;
        final int velocity_max_1 = 150;
        final int velocity_min_1 = 0;
        final int velocity_total_1 = velocity_max_1 - velocity_min_1;
        final String velocity_start_value_1 = String.valueOf((int)(start_velocity_1 * velocity_total_1));

        velocity_slider_1.setPosition(start_velocity_1);
        velocity_slider_1.setBubbleText(velocity_start_value_1);
        desired_velocity_input_txt_1.setText(velocity_start_value_1);
        velocity_slider_1.setTextSize(33f);
        velocity_slider_1.setColorBubbleText(0xffFFF8E1);
        velocity_slider_1.setColorBubble(0xFF000000);
        //velocity_slider_1.setStartText(String.valueOf(min));
        //velocity_slider_1.setEndText(String.valueOf(max));
        velocity_slider_1.setStartText("");
        velocity_slider_1.setEndText("");

        velocity_slider_1.setPositionListener(new Function1<Float, Unit>() {
            @Override
            public Unit invoke(Float aFloat) {
                /** ARGB
                 ** Aplha-Red-Green-Blue **
                 **/
                int negative_bar_color_1 = 0xff0288D1;
                int positive_bar_color_1 = 0xff558B2F;

                int prog_1 = (int) (aFloat*velocity_total_1);
                final String value_1 = String.valueOf(prog_1+10);
                /*if(prog_1 <0) {
                    velocity_slider_1.setColorBar(negative_bar_color_1);
                }
                else{
                    velocity_slider_1.setColorBar(positive_bar_color_1);

                }*/
                velocity_slider_1.setBubbleText(value_1);
                desired_velocity_input_txt_1.setText(value_1);
                return null;
            }
        });

        velocity_slider_1.setBeginTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setBeginTrackingListener");
                //mClient.send_flag(false);
                return Unit.INSTANCE;
            }
        });

        velocity_slider_1.setEndTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setEndTrackingListener");
                //mClient.send_flag(true);
                //mClient.send_command(1,"velocity", (int)(velocity_slider_1.getPosition()*velocity_total_1)+10);
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
                desired_velocity_txt_1.setText(progress+ "");

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

        /** Desired Velocity Seek Bar 2**/
        final float start_velocity_2 = 0.4f;
        final int velocity_max_2 = 150;
        final int velocity_min_2 = 0;
        final int velocity_total_2 = velocity_max_2 - velocity_min_2;
        final String velocity_start_value_2 = String.valueOf((int)(start_velocity_2 * velocity_total_2));

        velocity_slider_2.setPosition(start_velocity_2);
        velocity_slider_2.setBubbleText(velocity_start_value_2);
        desired_velocity_input_txt_2.setText(velocity_start_value_2);
        velocity_slider_2.setTextSize(33f);
        velocity_slider_2.setColorBubbleText(0xffFFF8E1);
        velocity_slider_2.setColorBubble(0xFF000000);
        //velocity_slider_2.setStartText(String.valueOf(min));
        //velocity_slider_2.setEndText(String.valueOf(max));
        velocity_slider_2.setStartText("");
        velocity_slider_2.setEndText("");

        velocity_slider_2.setPositionListener(new Function1<Float, Unit>() {
            @Override
            public Unit invoke(Float aFloat) {
                /** ARGB
                 ** Aplha-Red-Green-Blue **
                 **/
                int negative_bar_color_2 = 0xff0288D1;
                int positive_bar_color_2 = 0xff558B2F;

                int prog_2 = (int) (aFloat*velocity_total_2);
                final String value_2 = String.valueOf(prog_2+10);
                /*if(prog_2 <0) {
                    velocity_slider_2.setColorBar(negative_bar_color_2);
                }
                else{
                    velocity_slider_2.setColorBar(positive_bar_color_2);

                }*/
                velocity_slider_2.setBubbleText(value_2);
                desired_velocity_input_txt_2.setText(value_2);

                return null;
            }
        });

        velocity_slider_2.setBeginTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setBeginTrackingListener");
                //mClient.send_flag(false);
                return Unit.INSTANCE;
            }
        });

        velocity_slider_2.setEndTrackingListener(new Function0<Unit>() {
            @Override
            public Unit invoke() {
                Log.e("E", "setEndTrackingListener");
                //mClient.send_flag(true);
                //mClient.send_command(2,"velocity", (int)(velocity_slider_2.getPosition()*velocity_total_2)+10);
                return Unit.INSTANCE;
            }
        });

        motor1_send_button.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                try {
                    mClient.send_command(1,"velocity", Integer.valueOf(desired_velocity_input_txt_1.getText().toString()));
                    sleep(5);
                    mClient.send_command(1,"turn", Integer.valueOf(desired_turn_input_txt_1.getText().toString()));
                    sleep(5);
                    mClient.send_command(1,"position", Integer.valueOf(desired_position_input_txt_1.getText().toString()));
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

            }
            // Code here executes on main thread after user presses button
        });
        motor2_send_button.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                try {
                    mClient.send_command(2,"velocity", Integer.valueOf(desired_velocity_input_txt_2.getText().toString()));
                    Thread.sleep(5);
                    mClient.send_command(2,"turn", Integer.valueOf(desired_turn_input_txt_2.getText().toString()));
                    Thread.sleep(5);
                    mClient.send_command(2,"position", Integer.valueOf(desired_position_input_txt_2.getText().toString()));
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

            }
            // Code here executes on main thread after user presses button
        });
        motor1_reset_button.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                try {
                    Thread.sleep(5);
                    mClient.send_command(1,"reset", 0);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

            }
            // Code here executes on main thread after user presses button
        });

        motor2_reset_button.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                try {
                    Thread.sleep(5);
                    mClient.send_command(2,"reset", 0);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

            }
            // Code here executes on main thread after user presses button
        });

        motors_send_button.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                try {
                    mClient.send_command(1,"velocity", Integer.valueOf(desired_velocity_input_txt_1.getText().toString()));
                    Thread.sleep(5);
                    mClient.send_command(1,"turn", Integer.valueOf(desired_turn_input_txt_1.getText().toString()));
                    Thread.sleep(5);
                    mClient.send_command(1,"position", Integer.valueOf(desired_position_input_txt_1.getText().toString()));
                    Thread.sleep(5);
                    mClient.send_command(2,"velocity", Integer.valueOf(desired_velocity_input_txt_2.getText().toString()));
                    Thread.sleep(5);
                    mClient.send_command(2,"turn", Integer.valueOf(desired_turn_input_txt_2.getText().toString()));
                    Thread.sleep(5);
                    mClient.send_command(2,"position", Integer.valueOf(desired_position_input_txt_2.getText().toString()));
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

            }
            // Code here executes on main thread after user presses button
        });
        //mClient.start();
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        if (DEBUG) Log.i(TAG, "onSaveInstanceState(Bundle)");
        super.onSaveInstanceState(outState);

        outState.putString(KEY_POSITION_TEXT_1, position_txt_1.getText().toString());
        outState.putString(KEY_VELOCITY_TEXT_1, velocity_txt_1.getText().toString());
        outState.putString(KEY_TURN_TXT_1, turn_count_txt_1.getText().toString());
        outState.putInt(KEY_POSITION_BAR_1, position_bar_1.getProgress());
        outState.putInt(KEY_POSITION_REVERSED_BAR_1, position_bar_reversed_1.getProgress());
        outState.putInt(KEY_VELOCITY_BAR_1, velocity_bar_1.getProgress());
        outState.putInt(KEY_VELOCITY_REVERSED_BAR_1, velocity_bar_reversed_1.getProgress());

        outState.putString(KEY_POSITION_TEXT_2, position_txt_2.getText().toString());
        outState.putString(KEY_VELOCITY_TEXT_2, velocity_txt_2.getText().toString());
        outState.putString(KEY_TURN_TXT_2, turn_count_txt_2.getText().toString());
        outState.putInt(KEY_POSITION_BAR_2, position_bar_2.getProgress());
        outState.putInt(KEY_POSITION_REVERSED_BAR_2, position_bar_reversed_2.getProgress());
        outState.putInt(KEY_VELOCITY_BAR_2, velocity_bar_2.getProgress());
        outState.putInt(KEY_VELOCITY_REVERSED_BAR_2, velocity_bar_reversed_2.getProgress());

        //      outState.putInt(KEY_POSITION_SEEK_1, desired_position.getProgress());
        //       outState.putInt(KEY_VELOCITY_SEEK_1, desired_velocity.getProgress());
        //       outState.putInt(KEY_TURN_SEEK_1, desired_turn.getProgress());

    }
    @Override
    public void onPreExecute() {
        if (DEBUG) Log.i(TAG, "onPreExecute()");
    }
    //(int Motor_Number,String Position, String Velocity, String Turn, int position, int position_reversed, int velocity, int velocity_reversed) 
    
    @Override
    public void PositionUpdate(int Motor_Number,String Position, int position, int position_reversed) {
        if (Motor_Number == 1) {
            position_txt_1.setText(Position);
            current_position_1 = Position;
            position_bar_1.setProgress(position);
            position_bar_reversed_1.setProgress(position_reversed); 
        }
        else if(Motor_Number == 2){
            position_txt_2.setText(Position);
            current_position_2 = Position;
            position_bar_2.setProgress(position);
            position_bar_reversed_2.setProgress(position_reversed); 
        }
        else{
            return;
        }
    }
    @Override
    public void VelocityUpdate(int Motor_Number,String Velocity, int velocity, int velocity_reversed) {
        if (Motor_Number == 1) {
            velocity_txt_1.setText(Velocity);
            velocity_bar_1.setProgress(velocity);
            velocity_bar_reversed_1.setProgress(velocity_reversed);
        }
        else if(Motor_Number == 2){
            velocity_txt_2.setText(Velocity);
            velocity_bar_2.setProgress(velocity);
            velocity_bar_reversed_2.setProgress(velocity_reversed);
        }
        else{
            return;
        }
    }
    @Override
    public void TurnUpdate(int Motor_Number,String Turn) {
        if (Motor_Number == 1) {
            turn_count_txt_1.setText(Turn);
        }
        else if(Motor_Number == 2){
            turn_count_txt_2.setText(Turn);
        }
        else{
            return;
        }
    }


    @SuppressLint("DefaultLocale")
    @Override
    public void UtilityUpdates(int Motor_Number,String voltage) {
        float volt=(float) 24/128 * Integer.valueOf(voltage);
        voltage = String.format("%.02f", volt);
        if (Motor_Number == 1) {
            voltage_txt_1.setText(voltage);
        }
        else if (Motor_Number ==2) {
            voltage_txt_2.setText(voltage);
        }
        else{
            return;
        }
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

        Toast toast= Toast.makeText(getApplicationContext(),
                "Connected to VORDT", Toast.LENGTH_SHORT);
        toast.setGravity(Gravity.TOP|Gravity.CENTER_HORIZONTAL, 0, 0);
        toast.show();
        //Toast.makeText(this, "Connected to VORDT", Toast.LENGTH_SHORT).show();
        //position_slider_1.setBubbleText(current_position_1);
    }

    @Override
    public void onLostConnection() {
        if (DEBUG) Log.i(TAG, "onLostConnection()");
        Toast toast= Toast.makeText(getApplicationContext(),
                "VORDT Connection Lost!", Toast.LENGTH_SHORT);
        toast.setGravity(Gravity.TOP|Gravity.CENTER_HORIZONTAL, 0, 0);
        toast.show();
    }

    @Override
    public void onDisconnected() {
        if (DEBUG) Log.i(TAG, "onDisconnected()");
        Toast toast= Toast.makeText(getApplicationContext(),
                "Disconnected from VORDT!", Toast.LENGTH_SHORT);
        toast.setGravity(Gravity.TOP|Gravity.CENTER_HORIZONTAL, 0, 0);
        toast.show();
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
        //myClient = new client("192.168.1.228", 1500, position_txt_1,velocity_txt_1,turn_count_txt_1,position_bar_1, velocity_bar_1,velocity_bar_reversed_1);
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