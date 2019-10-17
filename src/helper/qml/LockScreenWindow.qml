// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.4
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0
import Fluid.Core 1.0 as FluidCore
import Fluid.Controls 1.0 as FluidControls
import Fluid.Effects 1.0 as FluidEffects
import QtGSettings 1.0 as Settings
import QtAccountsService 1.0 as Accounts
import Liri.Session 1.0 as Session
import Liri.Shell 1.0 as Shell
import Liri.ShellHelper 1.0 as Helper
import Liri.WaylandClient 1.0 as WC
import "components" as Components

FluidCore.Object {
    id: lockScreen

    readonly property alias opened: loader.active
    readonly property alias visible: loader.active

    Settings.GSettings {
        id: lockSettings

        schema.id: "io.liri.desktop.lockscreen"
        schema.path: "/io/liri/desktop/lockscreen/"
    }

    Loader {
        id: loader

        asynchronous: true
        active: false
        sourceComponent: Components.BorderlessWindow {
            id: lockScreenWindow

            screen: null

            WC.WlrLayerSurfaceV1 {
                shell: layerShell
                layer: WC.WlrLayerShellV1.TopLayer
                window: lockScreenWindow
                showOnAllScreens: true
                anchors: WC.WlrLayerSurfaceV1.TopAnchor |
                         WC.WlrLayerSurfaceV1.BottomAnchor |
                         WC.WlrLayerSurfaceV1.LeftAnchor |
                         WC.WlrLayerSurfaceV1.RightAnchor
                keyboardInteractivity: true
                nameSpace: "lockscreen"

                onConfigured: {
                    lockScreenWindow.width = width;
                    lockScreenWindow.height = height;
                    console.debug("Configuring lock screen to " + lockScreenWindow.width + "x" + lockScreenWindow.height);
                    ackConfigure(serial);
                    console.debug("Acked lock screen configure with serial", serial);
                    lockScreenWindow.visible = true;
                }
                onClosed: {
                    lockScreen.close();
                }
            }

            // Prevent mouse input from leaking through the lock screen
            MouseArea {
                Material.primary: Material.Blue
                Material.accent: Material.Blue

                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: {
                    usersListView.currentItem.field.forceActiveFocus();
                    mouse.accept = false;
                }

                Shell.Background {
                    id: background

                    anchors.fill: parent
                    mode: lockSettings.mode
                    pictureUrl: lockSettings.pictureUrl
                    primaryColor: lockSettings.primaryColor
                    secondaryColor: lockSettings.secondaryColor
                    fillMode: lockSettings.fillMode
                    blur: true
                    visible: !vignette.visible
                }

                FluidEffects.Vignette {
                    id: vignette

                    anchors.fill: parent
                    source: background
                    radius: 4
                    brightness: 0.4
                    visible: background.mode === "wallpaper" && background.imageLoaded
                }

                Shell.LoginGreeter {
                    id: usersListView

                    anchors.centerIn: parent

                    Accounts.UserAccount {
                        id: currentUser
                    }

                    Helper.Authenticator {
                        id: authenticator
                    }

                    model: ListModel {
                        id: usersModel

                        Component.onCompleted: {
                            var object = {
                                "realName": currentUser.realName,
                                "userName": currentUser.userName,
                                "iconFileName": currentUser.iconFileName
                            };
                            usersModel.append(object);
                        }
                    }
                    onLoginRequested: {
                        authenticator.authenticate(password, function(succeded) {
                            if (succeded) {
                                usersListView.currentItem.busyIndicator.opacity = 0.0;
                                usersListView.loginSucceeded();
                                Session.SessionManager.unlock();
                            } else {
                                usersListView.currentItem.busyIndicator.opacity = 0.0;
                                usersListView.currentItem.field.text = "";
                                usersListView.currentItem.field.forceActiveFocus();
                                usersListView.loginFailed(qsTr("Sorry, wrong password. Please try again."));
                            }
                        })
                    }
                    onLoginFailed: {
                        errorBar.open(message);
                    }
                }

                FluidControls.SnackBar {
                    id: errorBar
                }
            }
        }
    }

    function open() {
        loader.active = true;
    }

    function close() {
        loader.active = false;
    }
}
