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

import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0
import Fluid.Core 1.0 as FluidCore
import Fluid.Controls 1.0 as FluidControls
import "../panel"

Item {
    id: shell

    readonly property alias indicator: rightDrawer.indicator

        //onIndicatorTriggered: rightDrawer.indicator = indicator

    Drawer {
        id: rightDrawer

        property var indicator: null

        Material.theme: Material.Dark
        Material.primary: Material.Blue
        Material.accent: Material.Blue

        onIndicatorChanged: {
            if (indicator !== null)
                rightDrawer.open()
            else
                rightDrawer.close()
        }

        onClosed: indicator = null

        edge: Qt.RightEdge

//        width: Math.max(356, panel.rightWidth)
        height: shell.height

        Item {
            anchors.fill: parent

            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: titleLabel.implicitHeight + 2 * titleLabel.anchors.margins

                    FluidControls.HeadlineLabel {
                        id: titleLabel
                        text: rightDrawer.indicator ? rightDrawer.indicator.title : ""
                        verticalAlignment: Qt.AlignVCenter
                        anchors {
                            fill: parent
                            margins: 2 * FluidControls.Units.smallSpacing
                        }
                    }
                }

                Loader {
                    id: loader

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    sourceComponent: rightDrawer.indicator && rightDrawer.indicator.component
                }
            }

            Item {
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    rightMargin: FluidControls.Units.smallSpacing + (1 - rightDrawer.position) * rightDrawer.width
                }

                height: panel.height

                IndicatorsRow {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: FluidControls.Units.smallSpacing + 1
                    }

                    height: FluidCore.Utils.scale(rightDrawer.position, parent.height - 2 * FluidControls.Units.smallSpacing, parent.height)

                    onIndicatorTriggered: {
                        if (indicator.active)
                            rightDrawer.close()
                        else
                            rightDrawer.indicator = indicator
                    }
                }
            }
        }
    }
}
