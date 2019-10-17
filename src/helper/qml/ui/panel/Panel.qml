// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import QtQuick.Controls.Material 2.0
import Fluid.Controls 1.0 as FluidControls
import "../taskbar" as TaskBar

Rectangle {
    id: panel

    readonly property bool showing: !taskBar.hasFullscreenWindow
    readonly property bool maximized: taskBar.hasMaximizedWindow

    Material.theme: Material.Dark
    Material.accent: Material.Blue

    color: maximized ? Material.dialogColor : "transparent"
    height: 56

    Behavior on color {
        ColorAnimation {
            duration: FluidControls.Units.shortDuration
        }
    }

    Item {
        id: appsButtonContainer

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        implicitWidth: height

        Tray {
            anchors.fill: parent

            TaskBar.LauncherButton {
                width: height
            }
        }
    }

    TaskBar.TaskBar {
        id: taskBar

        anchors.left: appsButtonContainer.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        implicitWidth: parent.width - indicatorsWindow.width
    }
}
