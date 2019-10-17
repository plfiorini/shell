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
import Liri.TaskManager 1.0 as TaskManager

ListView {
    id: launcher

    readonly property alias hasMaximizedWindow: tasksModel.hasMaximizedWindow

    orientation: Qt.Horizontal
    interactive: contentWidth > width

    model: TaskManager.TasksModel {
        id: tasksModel

        sourceModel: appsModel
    }
    delegate: TaskDelegate {}

    remove: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 250 }
            NumberAnimation { properties: "y"; to: height; duration: 250 }
        }
    }

    removeDisplaced: Transition {
        SequentialAnimation {
            PauseAnimation { duration: 250 }
            NumberAnimation { properties: "x,y"; duration: 250 }
        }
    }

    move: Transition {
        SequentialAnimation {
            PauseAnimation { duration: 250 }
            NumberAnimation { properties: "x,y"; duration: 250 }
        }
    }

    moveDisplaced: Transition {
        SequentialAnimation {
            PauseAnimation { duration: 250 }
            NumberAnimation { properties: "x,y"; duration: 250 }
        }
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 1; from: 0; duration: 250 }
            NumberAnimation { properties: "y"; to: 0; from: height; duration: 250 }
        }
    }
}
