/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 * Copyright (C) 2017 Michael Spencer <sonrisesoftware@gmail.com>
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

import QtQml.Models 2.1
import QtQuick 2.10
import QtQuick.Window 2.10
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0
import QtWayland.Compositor 1.0
import Liri.Session 1.0 as Session
import Liri.WaylandServer 1.0 as WS
import Liri.Shell 1.0 as LiriShell
import Liri.private.shell 1.0 as P
import Fluid.Controls 1.0 as FluidControls
import "components" as Components
import "desktop" as Desktop
import "screens" as Screens

P.WaylandOutput {
    id: output

    readonly property bool primary: liriCompositor.defaultOutput === this

    property var screen: null

    property var viewsBySurface: ({})

    property int idleInhibit: 0

    readonly property alias splash: splash
    readonly property alias hotCorners: hotCorners
    readonly property alias desktop: desktop
    readonly property alias surfacesArea: desktop.currentWorkspace
    //readonly property alias idleDimmer: idleDimmer
    readonly property alias cursor: cursor

    readonly property var layers: QtObject {
        readonly property alias background: desktop.backgroundLayer
        readonly property alias bottom: bottomLayer
        readonly property alias top: topLayer
        readonly property alias lockScreen: lockScreenLayer
        readonly property alias overlay: overlayLayer
        readonly property alias modalOverlay: modalOverlayLayer
        readonly property alias notifications: notificationsLayer
        readonly property alias fullScreen: fullScreenLayer
    }

    property bool locked: false

    readonly property alias showFps: fpsIndicator.visible
    readonly property alias showInformation: outputInfo.visible

    property var exportDmabufFrame: null

    property bool __idle: false

    sizeFollowsWindow: false
    automaticFrameCallback: screen && screen.enabled && screen.powerState === P.ScreenItem.PowerStateOn

    Connections {
        target: output.screen

        function onCurrentModeChanged(resolution, refreshRate) {
            output.setCurrentOutputMode(resolution, refreshRate);
        }
    }

    Connections {
        target: Session.SessionManager

        function onSessionLocked() {
            // FIXME: Before suspend we lock the screen, but turning the output off has a side effect:
            // when the system is resumed it won't flip so we comment this out but unfortunately
            // it means that the lock screen will not turn off the screen
            //output.idle();
        }
    }

    Component.onCompleted: {
        if (output.screen) {
            for (var i = 0; i < output.screen.modes.length; i++) {
                var screenMode = output.screen.modes[i];
                var isPreferred = output.screen.preferredMode.resolution === screenMode.resolution &&
                        output.screen.preferredMode.refreshRateRate === screenMode.refreshRate;
                var isCurrent = output.screen.currentMode.resolution === screenMode.resolution &&
                        output.screen.currentMode.refreshRate === screenMode.refreshRate;
                output.addOutputMode(screenMode.resolution, screenMode.refreshRate, isPreferred, isCurrent);
            }
        }
    }

    window: Window {
        id: outputWindow

        Material.theme: Material.Dark
        Material.primary: Material.Blue
        Material.accent: Material.Blue

        x: output.position.x
        y: output.position.y
        width: output.geometry.width
        height: output.geometry.height
        flags: Qt.Window | Qt.FramelessWindowHint
        screen: output.screen ? Qt.application.screens[output.screen.screenIndex] : null
        color: Material.color(Material.Grey, Material.Shade700)
        visible: output.screen.enabled

        // Keyboard handling
        P.KeyEventFilter {
            Keys.onPressed: {
                // Input wakes the output
                liriCompositor.wake();

                // Power off and suspend
                switch (event.key) {
                case Qt.Key_PowerOff:
                case Qt.Key_PowerDown:
                case Qt.Key_Suspend:
                case Qt.Key_Hibernate:
                    shellHelper.requestShutdown();
                    event.accepted = true;
                    return;
                default:
                    break;
                }

                desktop.handleKeyPressed(event);
            }

            Keys.onReleased: {
                // Input wakes the output
                liriCompositor.wake();

                desktop.handleKeyReleased(event);
            }
        }

        // Mouse tracker
        WaylandMouseTracker {
            id: mouseTracker

            anchors.fill: parent

            windowSystemCursorEnabled: cursor.visible

            onMouseXChanged: {
                // Wake up
                liriCompositor.wake();

                // Update global mouse position
                liriCompositor.mousePos.x = output.position.x + mouseX;
            }
            onMouseYChanged: {
                // Wake up
                liriCompositor.wake();

                // Update global mouse position
                liriCompositor.mousePos.y = output.position.y + mouseY;
            }
            // TODO: Need to wake up with mouse button pressed, released and wheel

            // This is needed so the grab surface will receive pointer events
            WaylandQuickItem {
                surface: shellHelper.grabSurface
                focusOnClick: false
                touchEventsEnabled: false
                sizeFollowsSurface: true

                onSurfaceDestroyed: {
                    destroy();
                }
            }

            // Grab cursor when the pointer is over the window background
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                onPositionChanged: {
                    shellHelper.grabCursor(WS.LiriShell.ArrowGrabCursor);
                }
            }

            // Bottom
            Item {
                id: bottomLayer

                anchors.fill: parent
            }

            // Workspace
            Item {
                anchors.fill: parent

                Desktop.Desktop {
                    id: desktop

                    anchors.fill: parent
                    objectName: "desktop"

                    transform: Scale {
                        id: screenScaler

                        origin.x: zoomArea.x2
                        origin.y: zoomArea.y2
                        xScale: zoomArea.zoom2
                        yScale: zoomArea.zoom2
                    }

                    Desktop.ScreenZoom {
                        id: zoomArea

                        anchors.fill: parent
                        scaler: screenScaler
                        enabled: false
                    }
                }
            }

            // Virtual Keyboard
            Loader {
                active: liriCompositor.settings.ui.inputMethod === "qtvirtualkeyboard"
                source: Qt.resolvedUrl("base/Keyboard.qml")
                x: (parent.width - width) / 2
                y: parent.height - height
                width: Math.max(parent.width / 2, 768)
            }

            // Top
            Item {
                id: topLayer

                anchors.fill: parent

                // Lock screen
                Item {
                    id: lockScreenLayer

                    anchors.fill: parent
                    z: 1
                }

                // Hot corners
                Item {
                    id: hotCorners

                    anchors.fill: parent
                    z: 10

                    // Top-left corner
                    Components.HotCorner {
                        corner: Qt.TopLeftCorner
                    }

                    // Top-right corner
                    Components.HotCorner {
                        corner: Qt.TopRightCorner
                    }

                    // Bottom-left corner
                    Components.HotCorner {
                        corner: Qt.BottomLeftCorner
                        onTriggered: {
                            if (desktop.currentWorkspace.state == "normal")
                                desktop.currentWorkspace.state = "present";
                            else
                                desktop.currentWorkspace.state = "normal";
                        }
                    }

                    // Bottom-right corner
                    Components.HotCorner {
                        corner: Qt.BottomRightCorner
                    }
                }
            }

            // Notifications
            Item {
                id: notificationsLayer

                readonly property real spacing: FluidControls.Units.smallSpacing
                readonly property real padding: FluidControls.Units.smallSpacing * 3

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.topMargin: output.availableGeometry.y
                anchors.bottomMargin: output.geometry.height - output.availableGeometry.height
                anchors.rightMargin: output.geometry.width - output.availableGeometry.width
                width: FluidControls.Units.gu(24) + (padding * 2)
            }

            // Full screen windows can cover application windows and panels
            Rectangle {
                id: fullScreenLayer

                anchors.fill: parent
                color: "black"
                opacity: children.length > 0 ? 1.0 : 0.0
                visible: opacity > 0.0

                Behavior on opacity {
                    NumberAnimation {
                        easing.type: Easing.InSine
                        duration: FluidControls.Units.mediumDuration
                    }
                }
            }

            // Modal overlay
            Item {
                id: modalOverlayLayer

                anchors.fill: parent
            }

            // Overlays
            Item {
                id: overlayLayer

                anchors.fill: parent
            }

            // Splash screen
            Screens.SplashScreen {
                id: splash

                anchors.fill: parent

                // Hide anyway after a while, in case shell helper died before
                // emitting the "ready" signal
                Timer {
                    running: true
                    interval: 15000
                    onTriggered: {
                        splash.hide();
                    }
                }
            }

            // Flash for screenshots
            Rectangle {
                id: flash

                anchors.fill: parent

                color: "white"
                opacity: 0.0

                SequentialAnimation {
                    id: flashAnimation

                    OpacityAnimator {
                        easing.type: Easing.OutQuad
                        target: flash
                        from: 0.0
                        to: 1.0
                        duration: 250
                    }
                    OpacityAnimator {
                        easing.type: Easing.OutQuad
                        target: flash
                        from: 1.0
                        to: 0.0
                        duration: 250
                    }
                }
            }

            // FPS indicator
            Text {
                id: fpsIndicator

                anchors {
                    top: parent.top
                    right: parent.right
                }
                text: fpsCounter.framesPerSecond.toFixed(2)
                font.pointSize: 36
                style: Text.Raised
                styleColor: "#222"
                color: "white"
                visible: false

                P.FpsCounter {
                    id: fpsCounter
                }
            }

            // Output information
            Screens.OutputInfo {
                id: outputInfo

                anchors {
                    left: parent.left
                    top: parent.top
                }
                visible: false
            }

            // Idle dimmer
            Desktop.IdleDimmer {
                id: idleDimmer

                anchors.fill: parent

                output: output
            }
        }

        // Pointer cursor
        WaylandCursorItem {
            id: cursor

            seat: output.compositor.defaultSeat

            x: mouseTracker.mouseX
            y: mouseTracker.mouseY

            visible: surface !== null && mouseTracker.containsMouse
        }
    }

    /*
     * Methods
     */

    function wake() {
        if (!__idle)
            return;

        console.debug("Power on output", manufacturer, model);
        idleDimmer.fadeOut();
        screen.powerState = P.ScreenItem.PowerStateOn;
        __idle = false;
    }

    function idle() {
        if (__idle)
            return;

        console.debug("Standby output", manufacturer, model);
        idleDimmer.fadeIn();
        __idle = true;
    }

    function flash() {
        flashAnimation.start();
    }
}
