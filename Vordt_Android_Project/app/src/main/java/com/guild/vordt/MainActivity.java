package com.guild.vordt;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {

    //public static final String Adress = "com.guild.vordt.Interface_Main";
    //public static final String Port = "com.guild.vordt.Interface_Main";
    private int ip1,ip2,ip3,ip4,port_number;
    TextView port_txt,ip1_txt,ip2_txt,ip3_txt,ip4_txt;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(R.layout.activity_main);
        final Button button = findViewById(R.id.button);

        button.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                port_txt = findViewById(R.id.PORT);
                ip1_txt = findViewById(R.id.IP_1);
                ip2_txt =findViewById(R.id.IP_2);
                ip3_txt = findViewById(R.id.IP_3);
                ip4_txt=findViewById(R.id.IP_4);
                String fixed_port = port_txt.getText().toString().replaceAll("[^0-9]-+","");
                String fixed_ip1 = ip1_txt.getText().toString().replaceAll("[^0-9]-+","");
                String fixed_ip2 = ip2_txt.getText().toString().replaceAll("[^0-9]-+","");
                String fixed_ip3 = ip3_txt.getText().toString().replaceAll("[^0-9]-+","");
                String fixed_ip4 = ip4_txt.getText().toString().replaceAll("[^0-9]-+","");
                port_number = Integer.valueOf(fixed_port);

                ip1= Integer.valueOf(fixed_ip1);
                ip2= Integer.valueOf(fixed_ip2);
                ip3= Integer.valueOf(fixed_ip3);
                ip4= Integer.valueOf(fixed_ip4);

                String ip_address = String.format ("%1$d.%2$d.%3$d.%4$d.", ip1,ip2,ip3,ip4);
                Intent myIntent = new Intent(MainActivity.this, Interface_Main.class);

                myIntent.putExtra("ip",ip_address);
                myIntent.putExtra("port",port_number);
                startActivity(myIntent);
            }
                // Code here executes on main thread after user presses button
            });

        }

}





