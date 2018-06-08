package com.guild.vordt;

import android.content.Intent;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.RequiresApi;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;



@RequiresApi(api = Build.VERSION_CODES.HONEYCOMB)
public class Interface_Main extends AppCompatActivity {

    private int Port;
    private String IP;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.interface_main);
        this.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN);
        final Button motor1 = findViewById(R.id.motor1_button);
        final Button motor2 = findViewById(R.id.motor2_button);
        final Button motors = findViewById(R.id.motors_button);
        final Button skid_steer = findViewById(R.id.skid_steer);

        //get values from MainActivity
        Intent intent = getIntent();
        Port = intent.getIntExtra("port", 1500);
        IP = intent.getStringExtra("ip");

        motor1.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                Intent myIntent = new Intent(Interface_Main.this, Motor1_Debug.class);
                myIntent.putExtra("ip", IP);
                myIntent.putExtra("port", Port);
                startActivity(myIntent);
            }
            // Code here executes on main thread after user presses button
        });
        motor2.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                Intent myIntent = new Intent(Interface_Main.this, Motor2_Debug.class);
                myIntent.putExtra("ip", IP);
                myIntent.putExtra("port", Port);
                startActivity(myIntent);
            }
            // Code here executes on main thread after user presses button
        });
        motors.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                Intent myIntent = new Intent(Interface_Main.this, Motors_Debug.class);
                myIntent.putExtra("ip",IP);
                myIntent.putExtra("port",Port);
                startActivity(myIntent);
            }
            // Code here executes on main thread after user presses button
        });

        skid_steer.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                /*Intent myIntent = new Intent(Interface_Main.this, Motor1_Debug.class);
                myIntent.putExtra("ip",IP);
                myIntent.putExtra("port",Port);
                startActivity(myIntent);*/

            }
            // Code here executes on main thread after user presses button
        });
    }

}