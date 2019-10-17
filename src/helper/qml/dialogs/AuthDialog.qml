// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.10
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.10
import QtQuick.Controls.Material 2.10
import Fluid.Controls 1.0 as FluidControls
import "../components" as Components

Components.PopupBehavior {
    id: modalDialog

    property string message
    property string realName
    property string iconName
    property string prompt
    property bool echo: false
    property string information
    property string error

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

            modal: true

            title: qsTr("Authentication required")

            onOpened: {
                passwordInput.forceActiveFocus();
            }

            onAccepted: {
                policyKitAgent.authenticate(passwordInput.text);
            }
            onRejected: {
                policyKitAgent.abortAuthentication();
            }

            ColumnLayout {
                spacing: FluidControls.Units.smallSpacing

                RowLayout {
                    spacing: FluidControls.Units.smallSpacing

                    FluidControls.Icon {
                        source: FluidControls.Utils.iconUrl("action/lock")
                        size: FluidControls.Units.iconSizes.medium

                        Layout.alignment: Qt.AlignTop
                    }

                    ColumnLayout {
                        spacing: FluidControls.Units.smallSpacing

                        FluidControls.DialogLabel {
                            id: messageLabel

                            wrapMode: Text.WordWrap
                            text: message

                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: FluidControls.Units.smallSpacing

                            FluidControls.Icon {
                                id: avatarImage

                                size: FluidControls.Units.iconSizes.large
                                name: iconName
                                source: name ? "" : FluidControls.Utils.iconUrl("action/verified_user")
                            }

                            Label {
                                id: avatarName

                                text: realName

                                Layout.alignment: Qt.AlignVCenter
                            }

                            Layout.alignment: Qt.AlignCenter
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: FluidControls.Units.smallSpacing

                            Label {
                                id: promptLabel

                                text: prompt
                            }

                            TextField {
                                id: passwordInput

                                echoMode: echo ? TextInput.Normal : TextInput.Password
                                focus: true
                                onAccepted: {
                                    dialog.accepted();
                                }

                                Layout.fillWidth: true
                            }
                        }

                        Label {
                            id: infoLabel

                            color: "green"
                            font.bold: true
                            wrapMode: Text.WordWrap
                            text: information
                            visible: text != ""

                            Layout.fillWidth: true
                        }

                        Label {
                            id: errorLabel

                            color: "red"
                            font.bold: true
                            wrapMode: Text.WordWrap
                            text: error
                            visible: text != ""

                            onTextChanged: {
                                if (text) {
                                    // Give focus to the password field and clear
                                    passwordInput.text = "";
                                    passwordInput.forceActiveFocus();
                                }
                            }

                            Layout.fillWidth: true
                        }
                    }

                    Layout.fillHeight: true
                }
            }

            footer: DialogButtonBox {
                Button {
                    text: qsTr("Authenticate")
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
