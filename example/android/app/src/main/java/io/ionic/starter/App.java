package io.ionic.starter;

import android.app.Application;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.graphics.Color;
import android.media.AudioAttributes;
import android.media.RingtoneManager;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;

import com.catapush.capacitor.sdk.CatapushPlugin;
import com.catapush.capacitor.sdk.CatapushPluginIntentProvider;
import com.catapush.library.Catapush;
import com.catapush.library.gms.CatapushGms;
import com.catapush.library.interfaces.Callback;
import com.catapush.library.interfaces.ICatapushInitializer;
import com.catapush.library.notifications.NotificationTemplate;

import java.util.Collections;

public class App extends Application implements ICatapushInitializer {

  @Override
  public void onCreate() {
    super.onCreate();
    initCatapush();
  }

  @Override
  public void initCatapush() {
    NotificationTemplate notificationTemplate = new NotificationTemplate.Builder("CATAPUSH_MESSAGES")
      .swipeToDismissEnabled(true)
      .vibrationEnabled(true)
      .vibrationPattern(new long[]{100, 200, 100, 300})
      .soundEnabled(true)
      .soundResourceUri(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
      .circleColor(Color.BLUE)
      .iconId(R.drawable.ic_stat_notify_default)
      .useAttachmentPreviewAsLargeIcon(true)
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
      .init(
        this,
        this,
        CatapushPlugin.Companion.getEventDelegate(),
        Collections.singletonList(CatapushGms.INSTANCE),
        new CatapushPluginIntentProvider(MainActivity.class),
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
