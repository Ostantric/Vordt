package com.guild.vordt;

import android.util.Log;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;

/**
 * Created by Murat-Cosmos on 3/24/2018.
 */

public class UDP_Listen implements Runnable {
    @Override
    public void run() {
        boolean run = true;
        while (run) {
            try {
                DatagramSocket udpSocket = new DatagramSocket(365);
                byte[] message = new byte[8000];
                DatagramPacket packet = new DatagramPacket(message,message.length);
                Log.i("UDP client: ", "about to wait to receive");
                udpSocket.receive(packet);
                String text = new String(message, 0, packet.getLength());
                Log.d("Received data", text);
            }catch (IOException e) {
                Log.e("UDP client IOException", "error: ", e);
                run = false;
            }
        }
    }

}
