// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.10
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.10
import QtQuick.Controls.Material 2.10
import Fluid.Controls 1.0 as FluidControls
import Liri.Session 1.0 as Session
import "../components" as Components

Components.PopupBehavior {
    id: popupBehavior

    modal: true
    sourceComponent: Components.ModalWindow {
        id: modalWindow

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

        Dialog {
            id: dialog

            Material.primary: Material.Blue
            Material.accent: Material.Blue

            anchors.centerIn: parent

            title: qsTr("Run")

            modal: true

            focus: true

            width: 350
            height: 200

            onOpened: {
                commandField.forceActiveFocus();
            }
            onClosed: {
                modalWindow.close();
            }

            onAccepted: {
                dialog.close();
            }
            onRejected: {
                dialog.close();
            }

            ColumnLayout {
                anchors.fill: parent

                FluidControls.DialogLabel {
                    text: qsTr("Enter a Command")
                }

                TextField {
                    id: commandField

                    focus: true
                    onAccepted: {
                        Session.Launcher.launchCommand(text);
                        text = "";
                        dialog.close();
                    }

                    Layout.fillWidth: true
                }
            }

            footer: DialogButtonBox {
                Button {
                    text: qsTr("Cancel")
                    flat: true

                    DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                }
            }
        }
    }
}
