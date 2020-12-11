/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini
 *
 * Author(s):
 *    Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
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

import QtQuick 2.2
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0
import Fluid.Controls 1.0 as FluidControls
import Liri.WaylandServer 1.0 as WS
import "../components" as ShellComponents

Item {
    property Item view: null
    readonly property alias container: mouseArea
    readonly property int margin: 10

    signal selected(var view)
    signal closed(var view)

    id: chrome

    x: view.x + view.window.windowGeometry.x * view.scale
    y: view.y + view.window.windowGeometry.y * view.scale
    width: view.width * view.scale
    height: view.height * view.scale

    Material.theme: Material.Dark

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        z: 4
        onPositionChanged: {
            shellHelper.grabCursor(WS.LiriShell.ArrowGrabCursor);
        }
        onClicked: chrome.selected(view)
    }

    RectangularGlow {
        anchors.fill: parent
        glowRadius: margin
        spread: 0.2
        color: Material.accent
        cornerRadius: FluidControls.Units.gu(0.2)
        opacity: closeButton.opacity > 0.0 ? 0.5 : 0.0
        z: 3

        Behavior on opacity {
            NumberAnimation {
                easing.type: Easing.InCubic
                duration: FluidControls.Units.shortDuration
            }
        }
    }

    Rectangle {
        id: titleBadge
        anchors.centerIn: parent
        radius: 6
        color: Material.dialogColor
        width: Math.max(parent.width * 0.8, titleLabel.paintedWidth) + FluidControls.Units.smallSpacing * 2
        height: titleLabel.paintedHeight + FluidControls.Units.smallSpacing * 2
        z: 4

        Label {
            id: titleLabel
            anchors {
                centerIn: parent
                margins: FluidControls.Units.smallSpacing
            }
            text: view.window.title ? view.window.title : qsTr("Unknown")
            elide: Text.ElideRight
        }

        OpacityAnimator {
            id: titleBadgeOpacityAnimator
            target: titleBadge
            from: 0.0
            to: 1.0
            duration: FluidControls.Units.longDuration
            running: true
        }
    }

    Rectangle {
        id: iconBadge
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: FluidControls.Units.largeSpacing
            bottomMargin: FluidControls.Units.largeSpacing
        }
        radius: 6
        color: Material.dialogColor
        width: icon.width + FluidControls.Units.smallSpacing * 2
        height: width
        z: 4

        FluidControls.Icon {
            id: icon
            anchors {
                centerIn: parent
                margins: FluidControls.Units.smallSpacing
            }
            name: view.window.iconName
            width: FluidControls.Units.iconSizes.large
            height: width
        }

        OpacityAnimator {
            id: iconBadgeOpacityAnimator
            target: iconBadge
            from: 0.0
            to: 1.0
            duration: FluidControls.Units.longDuration
            running: true
        }
    }

    ShellComponents.CloseButton {
        id: closeButton
        anchors {
            top: mouseArea.top
            right: mouseArea.right
            margins: -FluidControls.Units.gu(1)
        }
        width: FluidControls.Units.iconSizes.medium
        z: 5
        opacity: mouseArea.containsMouse || hovered ? 1.0 : 0.0
        onClicked: chrome.closed(view)

        Behavior on opacity {
            NumberAnimation {
                easing.type: Easing.InCubic
                duration: FluidControls.Units.shortDuration
            }
        }
    }
}
