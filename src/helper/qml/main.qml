/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2019 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 *
 * $BEGIN_LICENSE:GPL3+$
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * $END_LICENSE$
 ***************************************************************************/

import QtQml 2.1
import QtQuick 2.10
import QtQuick.Window 2.9
import QtGSettings 1.0 as Settings
import Liri.Session 1.0 as Session
import Liri.WaylandClient 1.0 as WaylandClient
import Liri.TaskManager 1.0 as TaskManager
import Liri.PolicyKit 1.0 as PolicyKit
import "components" as Components
import "dialogs" as Dialogs
import "ui/launcher" as Launcher
import "ui/notifications" as Notifications

Item {
    id: main

    property Screen primaryScreen: null
    property int refCount: 0

    /*
     * Primary screen
     */

    Settings.GSettings {
        id: screenSettings

        schema.id: "io.liri.hardware.screens"
        schema.path: "/io/liri/hardware/screens/"
    }

    Connections {
        target: screenSettings

        function onPrimaryChanged() {
            primaryScreen = determinePrimaryScreen();
        }
    }

    Component.onCompleted: {
        primaryScreen = determinePrimaryScreen();
    }

    /*
     * Key bindings
     */

    KeyBindings {}

    /*
     * Session
     */

    Connections {
        target: Session.SessionManager

        function onSessionLocked() {
            indicatorsWindow.contentItem.enabled = false;
            lockScreen.open();
        }

        function onSessionUnlocked() {
            indicatorsWindow.contentItem.enabled = true;
            lockScreen.close();
        }
    }

    /*
     * Shell
     */

    Components.BorderlessWindow {
        id: grabWindow

        width: 1
        height: 1
    }

    TaskManager.ApplicationsModel {
        id: appsModel
    }

    WaylandClient.LiriShell {
        id: liriShell

        property bool isReady: false

        onActiveChanged: {
            if (active) {
                registerGrabSurface(grabWindow);
                grabWindow.visible = true;
            }
        }
        onShutdownRequested: {
            if (!lockScreen.opened)
                shutdownDialog.open();
        }
    }

    onRefCountChanged: {
        if (liriShell.active && refCount == 0) {
            liriShell.sendReady();
            liriShell.isReady = true;
        }
    }

    /*
     * PolicyKit
     */

    PolicyKit.PolicyKitAgent {
        id: policyKitAgent

        onAuthenticationInitiated: {
            console.warn("Authentication initiated for", actionId);
            authDialog.message = message;
            authDialog.realName = realName;
        }
        onAuthenticationRequested: {
            console.warn("Authentication requested:", prompt);
            authDialog.prompt = prompt;
            authDialog.echo = echo;
            authDialog.open();
        }
        onInformation: {
            authDialog.information = message;
        }
        onError: {
            authDialog.error = message;
        }
        onAuthorizationFailed: {
            authDialog.error = qsTr("Sorry, that didn't work. Please try again.");
        }
        onAuthenticationCanceled: {
            authDialog.close();
        }
        onAuthenticationFinished: {
            authDialog.close();
        }
        onAuthorizationGained: {
            authDialog.close();
        }
        onAuthorizationCanceled: {
            authDialog.close();
        }

        Component.onCompleted: {
            registerAgent();
        }
    }

    /*
     * Layers
     */

    WaylandClient.WlrLayerShellV1 {
        id: layerShell
    }

    Instantiator {
        id: modalOverlayInstantiator

        active: liriShell.isReady
        asynchronous: true
        model: Qt.application.screens

        ModalOverlayWindow {
            screen: Qt.application.screens[index]
        }

        function setVisible(visible, ignoredScreen) {
            for (var i = 0; i < count; i++) {
                if (ignoredScreen && objectAt(i).screen.name === ignoredScreen.name)
                    continue;
                objectAt(i).visible = visible;
            }
        }
    }

    Osd {}

    BackgroundWindow {}

    PanelWindow {
        id: panelWindow
    }

    IndicatorsWindow {
        id: indicatorsWindow
    }

    Notifications.NotificationsManager {}

    LockScreenWindow {
        id: lockScreen
    }

    // Dialogs

    Dialogs.AuthDialog {
        id: authDialog
    }

    Launcher.AppsDialog {
        id: appsDialog
    }

    Dialogs.RunDialog {
        id: runDialog
    }

    Dialogs.LogoutDialog {
        id: logoutDialog
    }

    Dialogs.ShutdownDialog {
        id: shutdownDialog
    }

    /*
     * Methods
     */

    function determinePrimaryScreen() {
        for (var i = 0; i < Qt.application.screens.length; i++) {
            var screen = Qt.application.screens[i];
            if (screen.name === screenSettings.primary)
                return screen;
        }

        return null;
    }
}
