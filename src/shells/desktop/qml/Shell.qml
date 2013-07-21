/****************************************************************************
 * This file is part of Hawaii Shell.
 *
 * Copyright (C) 2012-2013 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 *
 * Author(s):
 *    Pier Luigi Fiorini
 *
 * $BEGIN_LICENSE:LGPL2.1+$
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * $END_LICENSE$
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Window 1.0
import Hawaii.Shell.Desktop 0.1

QtObject {
    id: root

    // Available screen geometry
    property rect availableGeometry

    property var appChooser: AppChooserWindow {
        objectName: "appChooser"
    }

    property var launcher: LauncherWindow {
        objectName: "launcher"
        onAlignmentChanged: {
            moveAppChooser();
            recalculateAvailableGeometry();
        }

        Component.onCompleted: recalculateAvailableGeometry()
    }

    property var panel: PanelWindow {
        objectName: "panel"

        Component.onCompleted: recalculateAvailableGeometry()
    }

    property var background: BackgroundWindow {
        objectName: "background"
    }

    function moveAppChooser() {
        switch (launcher.alignment) {
        case LauncherSettings.LeftAlignment:
            appChooser.x = launcher.width;
            appChooser.y = panel.height;
            break;
        case LauncherSettings.RightAlignment:
            appChooser.x = launcher.x - appChooser.width;
            appChooser.y = panel.height;
            break;
        case LauncherSettings.BottomAlignment:
            appChooser.x = launcher.x;
            appChooser.y = launcher.y - appChooser.height;
            break;
        }
    }

    function recalculateAvailableGeometry() {
        root.availableGeometry = Qt.rect(0, 0, background.width, background.height);

        root.availableGeometry.y = panel.height;

        switch (launcher.alignment) {
        case LauncherSettings.LeftAlignment:
            root.availableGeometry.x = launcher.width;
            break;
        case LauncherSettings.RightAlignment:
            root.availableGeometry.width -= launcher.width;
            break;
        case LauncherSettings.BottomAlignment:
            root.availableGeometry.height -= launcher.height;
            break;
        }
    }

    Component.onCompleted: moveAppChooser()

    /*
    // Notifications panel
    NotificationsPanel {
        id: notificationsPanel
        x: root.width
        y: panelComponent.height
        z: 3
        width: root.width / 4
        height: root.height
        visible: false

        // Animation
        Behavior on x {
            NumberAnimation { duration: 200 }
        }

        function show() {
            visible = true;
            x = root.width - width;
        }

        function hide() {
            x = root.width;
        }
    }
*/
}
