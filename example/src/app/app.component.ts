import { Component } from '@angular/core';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Router } from '@angular/router';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { Platform } from '@ionic/angular';
import { CatapushPlugin } from "catapush-capacitor"
import { AndroidPermissions } from '@awesome-cordova-plugins/android-permissions/ngx';


@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
})
export class AppComponent {

  constructor(
    public router: Router,
    public platform: Platform,
    private androidPermissions: AndroidPermissions) {
    this.platform.ready().then(async (readySource) => {
      console.log('Platform ready from', readySource);

      this.androidPermissions.checkPermission(this.androidPermissions.PERMISSION.POST_NOTIFICATIONS).then(
        result => {
          console.log('Has post notifications permission?', result.hasPermission)
          if (!result.hasPermission)
            this.androidPermissions.requestPermission(this.androidPermissions.PERMISSION.POST_NOTIFICATIONS);
        },
        err => this.androidPermissions.requestPermission(this.androidPermissions.PERMISSION.POST_NOTIFICATIONS)
      );

      // Init native SDK
      await CatapushPlugin.enableLog({ enabled: true })
        .then(() => console.log('Catapush enableLog success'))
        .catch((reason) => console.log('Catapush enableLog failed: ' + reason))

      await CatapushPlugin.init({ appId: 'SET_YOUR_CATAPUSH_APP_KEY' })
        .then(() => console.log('Catapush init success'))
        .catch((reason) => console.log('Catapush init failed: ' + reason))

      await CatapushPlugin.setUser({ identifier: 'test', password: 'test' })
        .then(() => console.log('Catapush setUser success'))
        .catch((reason) => console.log('Catapush setUser failed: ' + reason))

      await CatapushPlugin.start()
        .then(() => {
          console.log('Catapush start success')
          this.router.navigate(['messages']);
        })
        .catch((reason) => console.log('Catapush start failed: ' + reason))

    });
  }

}
