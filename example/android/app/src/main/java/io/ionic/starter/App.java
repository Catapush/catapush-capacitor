package io.ionic.starter;

import android.app.Application;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.media.AudioAttributes;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import com.catapush.capacitor.sdk.CatapushPlugin;
import com.catapush.library.Catapush;
import com.catapush.library.gms.CatapushGms;
import com.catapush.library.interfaces.Callback;
import com.catapush.library.notifications.NotificationTemplate;

import java.util.Collections;

public class App extends Application {

  @Override
  public void onCreate() {
    super.onCreate();

    NotificationTemplate notificationTemplate = new NotificationTemplate.Builder("CATAPUSH_MESSAGES")
      .swipeToDismissEnabled(true)
      .vibrationEnabled(true)
      .vibrationPattern(new long[]{100, 200, 100, 300})
      .soundEnabled(true)
      .soundResourceUri(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
      .circleColor(Color.BLUE)
      .iconId(R.drawable.ic_stat_notify_default)
      .useAttachmentPreviewAsLargeIcon(true)
      .modalIconId(R.mipmap.ic_launcher)
      .ledEnabled(true)
      .ledColor(Color.BLUE)
      .ledOnMS(2000)
      .ledOffMS(1000)
      .build();

    NotificationManager nm = ((NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE));
    if (nm != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      String channelName = "Catapush messages";
      NotificationChannel channel = nm.getNotificationChannel(notificationTemplate.getNotificationChannelId());
      if (channel == null) {
        channel = new NotificationChannel(notificationTemplate.getNotificationChannelId(), channelName, NotificationManager.IMPORTANCE_HIGH);
        channel.enableVibration(notificationTemplate.isVibrationEnabled());
        channel.setVibrationPattern(notificationTemplate.getVibrationPattern());
        channel.enableLights(notificationTemplate.isLedEnabled());
        channel.setLightColor(notificationTemplate.getLedColor());
        if (notificationTemplate.isSoundEnabled()) {
          AudioAttributes audioAttributes = new AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_COMMUNICATION_INSTANT)
            .build();
          channel.setSound(notificationTemplate.getSoundResourceUri(), audioAttributes);
        }
      }
      nm.createNotificationChannel(channel);
    }

    Catapush.getInstance()
      .setNotificationIntent((catapushMessage, context) -> {
        Intent intent = new Intent(context, MainActivity.class);
        intent.setData(Uri.parse("catapush://messages/" + catapushMessage.id()));
        intent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        intent.putExtra("message", catapushMessage);
        int requestCode = catapushMessage.id().hashCode();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
          return PendingIntent.getActivity(context, requestCode, intent, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_ONE_SHOT);
        } else {
          return PendingIntent.getActivity(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_ONE_SHOT);
        }
      })
      .init(this,
        CatapushPlugin.Companion.getEventDelegate(),
        Collections.singletonList(CatapushGms.INSTANCE),
        notificationTemplate,
        null,
        new Callback<Boolean>() {
          @Override
          public void success(Boolean response) {
            Log.d("APP", "Catapush has been successfully initialized");
          }

          @Override
          public void failure(@NonNull Throwable t) {
            Log.e("APP", "Can't initialize Catapush!", t);
          }
        });
  }
}
