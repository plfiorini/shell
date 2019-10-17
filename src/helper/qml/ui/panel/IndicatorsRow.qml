// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import QtQuick.Controls.Material 2.0
import Fluid.Controls 1.0 as FluidControls
import Liri.Shell 1.0 as Shell
import Liri.ShellHelper 1.0 as ShellHelper
import "../../components" as Components

Item {
    signal indicatorTriggered(Shell.Indicator indicator)

    width: row.implicitWidth + tray.elevation * 4
    height: 56

    Shell.DateTime {
        id: dateTime
    }

    Tray {
        id: tray

        Material.theme: Material.Dark

        anchors.fill: parent

        Row {
            id: row

            anchors.centerIn: parent

            height: parent.height

            Shell.DateTimeIndicator {
                onClicked: indicatorTriggered(this)
            }

            StorageIndicator {
                onClicked: indicatorTriggered(caller)
            }

            Repeater {
                model: ShellHelper.IndicatorsModel {}

                Loader {
                    source: url
                    width: 32
                    height: parent.height

                    Connections {
                        target: item

                        function onClicked() {
                            indicatorTriggered(item);
                        }
                    }
                }
            }
        }
    }
}
