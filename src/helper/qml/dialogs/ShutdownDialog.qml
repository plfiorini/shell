// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.10
import QtQuick.Controls 2.10
import QtQuick.Controls.Material 2.10
import QtQuick.Layouts 1.0
import Fluid.Controls 1.0 as FluidControls
import Liri.Device 1.0 as LiriDevice
import "../components" as Components

Components.PopupBehavior {
    id: popupBehavior

    sourceComponent: Components.ModalWindow {
        id: modalWindow

        property var startTime: new Date()
        property int remainingSeconds: totalSeconds - (new Date() - startTime) / 1000
        property int totalSeconds: 60

        onVisibleChanged: {
            if (visible)
                dialog.open();
            else
                popupBehavior.close();
        }
        onCloseRequested: {
            dialog.rejected();
            dialog.close();
        }

        Timer {
            running: true
            interval: 1000
            repeat: true
            onTriggered: {
                remainingSeconds = totalSeconds - (new Date() - startTime) / 1000;
            }
        }

        Timer {
            running: true
            interval: totalSeconds * 1000
            onTriggered: {
                LiriDevice.LocalDevice.powerOff();
                dialog.close();
            }
        }

        Dialog {
            id: dialog

            Material.primary: Material.Blue
            Material.accent: Material.Blue

            anchors.centerIn: parent

            width: 300
            height: implicitHeight

            modal: true

            padding: 0
            topPadding: 0

            onClosed: {
                modalWindow.close();
            }

            header: Rectangle {
                Material.theme: Material.Dark
                Material.primary: Material.Blue
                Material.accent: Material.Blue

                implicitWidth: dialog.width
                implicitHeight: (width * 3) / 5

                color: Material.color(Material.Red)

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    FluidControls.Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: FluidControls.Utils.iconUrl("action/power_settings_new")
                        size: 36
                    }

                    FluidControls.TitleLabel {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Material.primaryTextColor
                        text: qsTr("Power Off")
                    }

                    FluidControls.SubheadingLabel {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Material.secondaryTextColor
                        horizontalAlignment: Qt.AlignHCenter
                        text: ("The system will power off\n" +
                               "automatically in %1 seconds.").arg(remainingSeconds)
                    }
                }
            }

            ColumnLayout {
                id: column

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                FluidControls.ListItem {
                    icon.source: Qt.resolvedUrl("../images/sleep.svg")
                    text: qsTr("Sleep")
                    visible: LiriDevice.LocalDevice.canSuspend
                    onClicked: {
                        LiriDevice.LocalDevice.suspend();
                        dialog.close();
                    }
                }

                FluidControls.ListItem {
                    icon.source: Qt.resolvedUrl("../images/hibernate.svg")
                    text: qsTr("Suspend to disk")
                    visible: LiriDevice.LocalDevice.canHibernate
                    onClicked: {
                        LiriDevice.LocalDevice.hibernate();
                        dialog.close();
                    }
                }

                FluidControls.ListItem {
                    icon.source: FluidControls.Utils.iconUrl("action/power_settings_new")
                    text: qsTr("Power off")
                    visible: LiriDevice.LocalDevice.canPowerOff
                    onClicked: {
                        LiriDevice.LocalDevice.powerOff();
                        dialog.close();
                    }
                }

                FluidControls.ListItem {
                    icon.source: Qt.resolvedUrl("../images/reload.svg")
                    text: qsTr("Restart")
                    visible: LiriDevice.LocalDevice.canRestart
                    onClicked: {
                        LiriDevice.LocalDevice.restart();
                        dialog.close();
                    }
                }
            }
        }
    }
}
