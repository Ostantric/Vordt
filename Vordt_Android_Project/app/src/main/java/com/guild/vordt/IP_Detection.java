package com.guild.vordt;

import android.app.Fragment;
import android.os.AsyncTask;

/**
 * Created by Murat-Cosmos on 6/7/2018.
 */

public class IP_Detection extends Fragment {

    private boolean mRunning;
    private udp_task mTask;
    private TaskCallbacks mCallbacks;

    interface TaskCallbacks {
        void onPreExecute();

        void PositionUpdate(int Motor_Number, String Position, int position, int position_reversed);

        void VelocityUpdate(int Motor_Number, String Velocity, int velocity, int velocity_bar_reversed);

        void UtilityUpdates(int Motor_Number,String voltage);

        void onCancelled();

        void onConnected();

        void onLostConnection();

        void onPostExecute();

        void onDisconnected();
    }

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
            return null;
        }

        @Override
        protected void onPostExecute(Void ignore) {

        }

        @Override
        protected void onProgressUpdate(String... value) {

        }

        @Override
        protected void onCancelled() {

        }
    }

}
