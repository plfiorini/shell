/****************************************************************************
 * This file is part of Liri.
 *
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

import QtQuick 2.0
import QtQml.Models 2.1
import Fluid.Controls 1.0 as FluidControls
import Liri.TaskManager 1.0 as TaskManager

Item {
    id: frequentApps

    readonly property alias count: repeater.count

    width: 130 * grid.columns
    height: 130 * grid.rows

    FluidControls.Placeholder {
        anchors.fill: parent

        icon.source: FluidControls.Utils.iconUrl("action/history")
        text: qsTr("Frequent Apps")
        subText: qsTr("The apps you use frequently will show here")
        visible: frequentApps.count === 0
    }

    Grid {
        id: grid

        anchors.fill: parent

        columns: 6
        rows: 2

        Repeater {
            id: repeater

            model: TaskManager.PageModel {
                limitCount: grid.rows * grid.columns
                sourceModel: TaskManager.FrequentAppsModel {
                    sourceModel: appsModel
                }
            }

            delegate: Item {

                width: 130
                height: width

                AppDelegate {
                    anchors {
                        fill: parent
                        margins: FluidControls.Units.smallSpacing
                    }
                }
            }
        }
    }
}
