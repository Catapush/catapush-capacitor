package io.ionic.starter;

import android.content.Intent;
import android.os.Bundle;

import com.catapush.capacitor.sdk.CatapushPluginIntentProvider;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    CatapushPluginIntentProvider.handleIntent(getIntent());
  }

  @Override
  protected void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    CatapushPluginIntentProvider.handleIntent(intent);
  }

}
