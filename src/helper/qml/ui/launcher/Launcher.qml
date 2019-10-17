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

import QtQuick 2.10
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import Fluid.Controls 1.0 as FluidControls
import Fluid.Effects 1.0 as FluidEffects

ColumnLayout {
    signal appLaunched(string appId)

    function takeFocus() {
        searchText.forceActiveFocus();
    }

    spacing: 0

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: topRow.implicitHeight + (2 * topRow.anchors.margins)

        color: Material.dialogColor

        Item {
            width: parent.width
            height: parent.height + 20

            clip: true

            Rectangle {
                x: -5
                y: -parent.y
                width: parent.width - 2 * x
                height: parent.parent.height

                layer.enabled: true
                layer.effect: FluidEffects.Elevation {
                    elevation: 2
                }
            }
        }

        RowLayout {
            id: topRow

            anchors {
                fill: parent
                margins: FluidControls.Units.smallSpacing
            }

            ToolButton {
                id: frequentAppsButton

                icon.source: FluidControls.Utils.iconUrl("action/history")
                checkable: true
                autoExclusive: true
                onClicked: {
                    categories.currentIndex = 0;
                    contentStack.currentIndex = 0;
                    searchText.forceActiveFocus();
                }
            }

            ToolButton {
                id: allAppsButton

                icon.source: FluidControls.Utils.iconUrl("navigation/apps")
                checkable: true
                autoExclusive: true
                onClicked: {
                    categories.currentIndex = 0;
                    contentStack.currentIndex = 1;
                    searchText.forceActiveFocus();
                }
            }

            ToolButton {
                id: categoriesButton

                icon.source: FluidControls.Utils.iconUrl("action/list")
                checkable: true
                autoExclusive: true
                onClicked: {
                    categories.currentIndex = 0;
                    contentStack.currentIndex = 1;
                    searchText.forceActiveFocus();
                }
            }

            Item {
                width: FluidControls.Units.smallSpacing
            }

            TextField {
                id: searchText

                placeholderText: qsTr("Type an application name...")
                focus: true
                onTextChanged: {
                    grid.query = text;

                    if (frequentAppsButton.checked)
                        allAppsButton.checked = true;
                }

                Layout.fillWidth: true
            }

            Item {
                Layout.fillWidth: true
            }

            ShutdownButtons {
                id: shutdownActions

                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    StackLayout {
        id: contentStack

        FrequentAppsView {
            id: frequentApps
        }

        RowLayout {
            Categories {
                id: categories

                Layout.preferredWidth: grid.width / 4
                Layout.fillHeight: true

                clip: true
                visible: categoriesButton.checked
                onSelected: {
                    grid.filterByCategory(category);
                }
            }

            ColumnLayout {
                AppsGridView {
                    id: grid
                }

                PageIndicator {
                    id: pageIndicator

                    // Set count to 1 when there are no pages so that the indicator
                    // is always properly sized and the indicator height is always
                    // accounted for, but we hide the indicator from the user
                    count: Math.max(1, grid.pages)
                    opacity: grid.pages > 0 ? 1.0 : 0.0

                    currentIndex: grid.currentPage
                    onCurrentIndexChanged: {
                        grid.currentPage = currentIndex;
                    }

                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Component.onCompleted: {
        if (frequentApps.count > 0)
            frequentAppsButton.checked = true;
        else
            allAppsButton.checked = true;
    }
}
