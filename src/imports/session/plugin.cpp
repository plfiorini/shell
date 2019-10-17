// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

#include <QtQml>

#include "launcher.h"
#include "sessionmanager.h"

class SessionPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")
public:
    void registerTypes(const char *uri)
    {
        // @uri Liri.Session
        Q_ASSERT(QLatin1String(uri) == QLatin1String("Liri.Session"));

        const int versionMajor = 1;
        const int versionMinor = 0;

        qmlRegisterSingletonType<Launcher>(uri, versionMajor, versionMinor, "Launcher",
                                           [](QQmlEngine *, QJSEngine *) -> QObject * {
            return new Launcher();
        });
        qmlRegisterSingletonType<SessionManager>(uri, versionMajor, versionMinor, "SessionManager",
                                                 [](QQmlEngine *, QJSEngine *) -> QObject * {
            return new SessionManager();
        });
    }
};

#include "plugin.moc"
