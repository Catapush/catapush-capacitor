import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { BrowserModule } from '@angular/platform-browser';
import { RouteReuseStrategy } from '@angular/router';
import { IonicModule, IonicRouteStrategy } from '@ionic/angular';
import { AndroidPermissions } from '@awesome-cordova-plugins/android-permissions/ngx';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { HomeComponent } from './home/home.component';
import { MessageListComponent } from './message-list/message-list.component';

@NgModule({
    declarations: [
        AppComponent,
        HomeComponent,
        MessageListComponent
    ],
    imports: [BrowserModule, IonicModule.forRoot(), AppRoutingModule, FormsModule],
    providers: [{ provide: RouteReuseStrategy, useClass: IonicRouteStrategy }, AndroidPermissions],
    bootstrap: [AppComponent]
})
export class AppModule { }
