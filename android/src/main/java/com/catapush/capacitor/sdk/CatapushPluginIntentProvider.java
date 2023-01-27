package com.catapush.capacitor.sdk;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;

import androidx.annotation.NonNull;

import com.catapush.library.interfaces.ICatapushNotificationIntentProvider;
import com.catapush.library.messages.CatapushMessage;
import com.catapush.library.util.Strings;

public class CatapushPluginIntentProvider implements ICatapushNotificationIntentProvider {

    Class<? extends Activity> targetActivityClass;

    public CatapushPluginIntentProvider(@NonNull Class<? extends Activity> targetActivityClass) {
        this.targetActivityClass = targetActivityClass;
    }

    public static void handleIntent(Intent intent) {
        if (intent == null || intent.getData() == null || intent.getScheme() == null) {
            return;
        }
        String entity = intent.getData().getAuthority();
        String id = intent.getData().getLastPathSegment();
        String scheme = intent.getScheme();
        if (scheme.equals("catapush") && entity.equals("messages")
                && !Strings.isEmptyOrWhitespace(id)) {
            CatapushMessage message = intent.getParcelableExtra("message");
            if (message != null) {
                CatapushPlugin.Companion.handleNotificationTapped(message);
            }
        }
    }

    @Override
    public PendingIntent getIntentForMessage(
            CatapushMessage message,
            Context context
    ) {
        Intent intent = new Intent(context, targetActivityClass);
        intent.setData(Uri.parse("catapush://messages/${message.id()}"));
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        intent.putExtra("message", message);

        int piFlags;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            piFlags = PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_IMMUTABLE;
        } else {
            piFlags = PendingIntent.FLAG_ONE_SHOT;
        }

        return PendingIntent.getActivity(context, 0, intent, piFlags);
    }

}
