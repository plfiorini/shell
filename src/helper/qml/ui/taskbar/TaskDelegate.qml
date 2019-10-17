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

import QtQuick 2.0
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import Fluid.Controls 1.0 as FluidControls
import Liri.Shell 1.0 as LiriShell
import "../../components" as Components

LiriShell.PanelItem {
    id: taskBarDelegate

    property int indexOfThisDelegate: index

    highlightColor: model.starting ? Material.color(Material.Orange) : "white"
    highlightOpacity: model.active || model.starting ? 1 : model.running ? 0.4 : 0
    active: model.active

    ToolTip.text: model.name || model.appId
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
    ToolTip.visible: containsMouse && !menu.visible

    onActiveChanged: {
        if (active)
            taskBar.currentIndex = index;
    }
    onClicked: {
        if (model.running) {
            // Set rectangle
            var pt = panel.mapFromItem(taskBarDelegate, taskBarDelegate.width * 0.5, taskBarDelegate.height * 0.5);
            var rect = Qt.rect(pt.x, pt.y, taskBarDelegate.width, taskBarDelegate.height);
            model.application.setRectangle(panelWindow, rect);

            // Minimize or unminimize all windows of this app
            model.application.toggleMinimized();
        } else {
            if (!tasksModel.get(index).launch())
                console.warn("Failed to run:", model.appId);
        }
    }
    onRightClicked: {
        menu.open();
    }

    SequentialAnimation on y {
        loops: Animation.Infinite
        running: model.starting
        alwaysRunToEnd: true

        NumberAnimation {
            from: 0; to: -taskBarDelegate.height/2
            easing.type: Easing.OutExpo; duration: 300
        }

        NumberAnimation {
            from: -taskBarDelegate.height/2; to: 0
            easing.type: Easing.OutBounce; duration: 1000
        }

        PauseAnimation { duration: 500 }
    }

    FluidControls.Icon {
        id: icon
        anchors.centerIn: parent
        name: model.iconName || "application-x-executable"
        size: parent.height * 0.55
    }

    Rectangle {
        id: badge
        anchors {
            top: parent.top
            right: parent.right
            topMargin: -(FluidControls.Units.smallSpacing * 0.35)
            rightMargin: -(FluidControls.Units.largeSpacing * 0.35)
        }
        width: FluidControls.Units.iconSizes.smallMedium
        height: width
        radius: width * 0.5
        color: "orangered"
        opacity: model.hasCount > 0 ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                easing.type: Easing.OutQuad
                duration: FluidControls.Units.shortDuration
            }
        }

        Label {
            anchors.centerIn: parent
            font.pixelSize: parent.width - FluidControls.Units.smallSpacing
            color: "white"
            text: model.count
        }
    }

    TaskMenu {
        id: menu
    }

    Component.onDestruction: {
        menu.close();
    }
}
