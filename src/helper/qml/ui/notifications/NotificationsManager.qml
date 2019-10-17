// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Fluid.Core 1.0 as FluidCore
import Liri.Notifications 1.0 as Notifications

FluidCore.Object {
    Component {
        id: component

        NotificationWindow {}
    }

    Connections {
        target: Notifications.NotificationsService

        function onActiveChanged() {
            if (active)
                console.debug("Notifications manager activated");
            else
                console.debug("Notifications manager deactivated");
        }

        function onNotificationReceived(notificationId, appName, appIcon,
                                        hasIcon, summary, body, actions,
                                        isPersistent, expireTimeout, hints) {
            console.debug("Notification", notificationId, "received");
            var props = {
                "notificationId": notificationId,
                "appName": appName,
                "appIcon": appIcon,
                "iconUrl": "image://notifications/%1/%2".arg(notificationId).arg(Date.now() / 1000 | 0),
                "hasIcon": hasIcon,
                "summary": summary,
                "body": body,
                "actions": actions,
                "isPersistent": isPersistent,
                "expireTimeout": expireTimeout,
                "hints": hints
            };
            component.createObject(null, props);
        }

        function onNotificationClosed(notificationId, reason) {
            console.debug("Notification", notificationId, "closed for", reason);
        }

        function onActionInvoked(notificationId, actionKey) {
            console.debug("Notification", notificationId, "action:", actionKey);
        }
    }
}
