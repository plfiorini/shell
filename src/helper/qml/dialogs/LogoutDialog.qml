// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.10
import QtQuick.Controls 2.10
import QtQuick.Controls.Material 2.10
import Fluid.Controls 1.0 as FluidControls
import "../components" as Components

Components.PopupBehavior {
    id: popupBehavior

    sourceComponent: Components.ModalWindow {
        id: modalWindow

        property var startTime: new Date()
        property int remainingSeconds: totalSeconds - (new Date() - startTime) / 1000
        readonly property int totalSeconds: 60

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
                dialog.close();
                liriShell.terminateCompositor();
            }
        }

        Dialog {
            id: dialog

            Material.primary: Material.Blue
            Material.accent: Material.Blue

            title: qsTr("Log out")

            anchors.centerIn: parent

            modal: true

            onClosed: {
                modalWindow.close();
            }

            onAccepted: {
                liriShell.terminateCompositor();
                dialog.close();
            }
            onRejected: {
                dialog.close();
            }

            FluidControls.DialogLabel {
                wrapMode: Text.Wrap
                width: parent.width
                text: qsTr("You will be logged out in %1 seconds").arg(remainingSeconds)
            }

            footer: DialogButtonBox {
                Button {
                    text: qsTr("Log out")
                    flat: true

                    DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                }

                Button {
                    text: qsTr("Cancel")
                    flat: true

                    DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                }
            }
        }
    }
}
