// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.10
import QtQuick.Controls 2.10
import QtQuick.Controls.Material 2.10
import "../../components" as Components

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
            Material.background: "#eee"

            anchors.centerIn: parent

            modal: true

            width: launcher.implicitWidth
            height: launcher.implicitHeight

            padding: 0
            topPadding: 0

            header: Item {}
            footer: Item {}

            onOpened: {
                launcher.takeFocus();
            }
            onClosed: {
                modalWindow.close();
            }

            Launcher {
                id: launcher

                onAppLaunched: {
                    dialog.close();
                }
            }
        }
    }
}
