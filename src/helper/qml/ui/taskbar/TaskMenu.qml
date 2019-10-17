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

import QtQml 2.2
import QtQuick 2.0
import QtQuick.Controls 2.1
import "../../components" as Components

Components.PopupBehavior {
    id: menu

    sourceComponent: Components.PopupMenu {
        id: menuWindow

        property var application: model.application

        //x: 0
        //y: -height

        //transformOrigin: Menu.BottomLeft

        onCloseRequested: {
            menu.close();
        }

        Instantiator {
            id: actionsInstantiator

            model: application ? application.actionsModel : undefined
            delegate: MenuItem {
                text: model.name
                onTriggered: {
                    if (model.command) {
                        model.action.execute();
                        menuWindow.closeRequested();
                    }
                }
            }
            onObjectAdded: menu.insertItem(0, object)
            onObjectRemoved: menu.removeItem(index)
        }

        Instantiator {
            model: actionsInstantiator.count > 0 ? 1 : 0
            delegate: MenuSeparator {}
            onObjectAdded: menu.insertItem(actionsInstantiator.count, object)
            onObjectRemoved: menu.removeItem(index)
        }

        MenuItem {
            text: qsTr("New Window")
            enabled: model.running
        }

        MenuSeparator {}

        MenuItem {
            text: model.pinned ? qsTr("Unpin") : qsTr("Pin")
            enabled: model.name
            onTriggered: {
                model.application.pinned = !model.application.pinned;
                menuWindow.closeRequested();
            }
        }

        MenuSeparator {}

        MenuItem {
            id: quit

            text: qsTr("Quit")
            enabled: model.running
            onTriggered: {
                if (!model.application.quit())
                    console.warn("Failed to quit:", model.appId);
                menuWindow.closeRequested();
            }
        }
    }
}
