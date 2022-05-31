#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(CatapushPlugin, "CatapushPlugin",
           CAP_PLUGIN_METHOD(init, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(start, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(enableLog, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(setUser, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(sendMessage, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(sendMessageReadNotificationWithId, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(subscribeMessageDelegate, CAPPluginReturnCallback);
           CAP_PLUGIN_METHOD(subscribeStateDelegate, CAPPluginReturnCallback);
           CAP_PLUGIN_METHOD(allMessages, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(pauseNotifications, CAPPluginReturnPromise);
)
