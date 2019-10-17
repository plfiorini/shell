/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini
 *
 * Author(s):
 *    Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
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

#include <QCoreApplication>
#include <QDir>
#include <QDBusConnection>
#include <QDBusError>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlExtensionPlugin>
#include <QStandardPaths>
#include <QTimer>
#include <QtPlugin>
#include <QtWaylandCompositor/QWaylandCompositor>

#include "application.h"

#include <unistd.h>
#include <sys/types.h>

#ifdef HAVE_SYSTEMD
#  include <systemd/sd-daemon.h>
#endif

Q_IMPORT_PLUGIN(ShellPrivatePlugin)

static const QEvent::Type StartupEventType = static_cast<QEvent::Type>(QEvent::registerEventType());

static int convertPermission(const QFileInfo &fileInfo)
{
    int p = 0;

    if (fileInfo.permission(QFile::ReadUser))
        p += 400;
    if (fileInfo.permission(QFile::WriteUser))
        p += 200;
    if (fileInfo.permission(QFile::ExeUser))
        p += 100;
    if (fileInfo.permission(QFile::ReadGroup))
        p += 40;
    if (fileInfo.permission(QFile::WriteGroup))
        p += 20;
    if (fileInfo.permission(QFile::ExeGroup))
        p += 10;
    if (fileInfo.permission(QFile::ReadOther))
        p += 4;
    if (fileInfo.permission(QFile::WriteOther))
        p += 2;
    if (fileInfo.permission(QFile::ExeOther))
        p += 1;

    return p;
}

Application::Application(QObject *parent)
    : QObject(parent)
    , m_failSafe(false)
    , m_started(false)
{
    // Register the static QML plugin
    qobject_cast<QQmlExtensionPlugin*>(qt_static_plugin_ShellPrivatePlugin().instance())->registerTypes("Liri.private.shell");

    // Application engine
    m_appEngine = new QQmlApplicationEngine(this);
    connect(m_appEngine, &QQmlApplicationEngine::objectCreated,
            this, &Application::objectCreated);

    // Invoke shutdown sequence when quitting
    connect(QCoreApplication::instance(), &QCoreApplication::aboutToQuit,
            this, &Application::shutdown);
}

QString Application::screenConfigurationFileName() const
{
    return m_screenConfigFileName;
}

void Application::setScreenConfigurationFileName(const QString &fileName)
{
    m_screenConfigFileName = fileName;
}

void Application::setUrl(const QUrl &url)
{
    m_url = url;
}

void Application::registerService()
{
    // Register the service
    if (!QDBusConnection::sessionBus().registerService(QStringLiteral("io.liri.Shell"))) {
        qWarning("Failed to register D-Bus service io.liri.Shell");
        return;
    }

    // Notify systemd that the compositor is ready
#ifdef HAVE_SYSTEMD
    sd_notify(0, "READY=1");
#endif
}

void Application::customEvent(QEvent *event)
{
    if (event->type() == StartupEventType)
        startup();
}

void Application::verifyXdgRuntimeDir()
{
    QString dirName = QString::fromLocal8Bit(qgetenv("XDG_RUNTIME_DIR"));

    if (dirName.isEmpty()) {
        QString msg = QObject::tr(
                    "The XDG_RUNTIME_DIR environment variable is not set.\n"
                    "Refer to your distribution on how to get it, or read\n"
                    "http://www.freedesktop.org/wiki/Specifications/basedir-spec\n"
                    "on how to implement it.\n");
        qFatal("%s", qPrintable(msg));
    }

    QFileInfo fileInfo(dirName);

    if (!fileInfo.exists()) {
        QString msg = QObject::tr(
                    "The XDG_RUNTIME_DIR environment variable is set to "
                    "\"%1\", which doesn't exist.\n").arg(dirName.constData());
        qFatal("%s", qPrintable(msg));
    }

    if (convertPermission(fileInfo) != 700 || fileInfo.ownerId() != getuid()) {
        QString msg = QObject::tr(
                    "XDG_RUNTIME_DIR is set to \"%1\" and is not configured correctly.\n"
                    "Unix access mode must be 0700, but is 0%2.\n"
                    "It must also be owned by the current user (UID %3), "
                    "but is owned by UID %4 (\"%5\").\n")
                .arg(dirName.constData())
                .arg(convertPermission(fileInfo))
                .arg(getuid())
                .arg(fileInfo.ownerId())
                .arg(fileInfo.owner());
        qFatal("%s\n", qPrintable(msg));
    }
}

void Application::startup()
{
    // Can't do the startup sequence twice
    if (m_started)
        return;

    // Check whether XDG_RUNTIME_DIR is ok or not
    verifyXdgRuntimeDir();

#ifdef HAVE_SYSTEMD
    uint64_t interval = 0;
    if (sd_watchdog_enabled(0, &interval) > 0) {
        if (interval > 0) {
            // Start a keep-alive timer every half of the watchdog interval,
            // and convert it from microseconds to milliseconds
            std::chrono::microseconds us(interval / 2);
            auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(us);
            auto *timer = new QTimer(this);
            timer->setInterval(ms);
            connect(timer, &QTimer::timeout, this, [] {
                sd_notify(0, "WATCHDOG=1");
            });
            timer->start();
        }
    }
#endif

    // Register this object
    m_appEngine->rootContext()->setContextProperty(QStringLiteral("ShellCpp"), this);

    // Set screen configuration file name
    m_appEngine->rootContext()->setContextProperty(QStringLiteral("screenConfigurationFileName"),
                                                   m_screenConfigFileName);

    // Load the compositor
    m_appEngine->load(m_url);

    m_started = true;
}

void Application::shutdown()
{
    // Notify systemd that we are quitting
#ifdef HAVE_SYSTEMD
    sd_notify(0, "STOPPING=1");
#endif

    // Unregister D-Bus service
    QDBusConnection::sessionBus().unregisterService(QStringLiteral("io.liri.Shell"));

    // Unload the engine
    m_appEngine->deleteLater();
    m_appEngine = nullptr;
}

void Application::objectCreated(QObject *object, const QUrl &)
{
    // All went fine
    if (object)
        return;

    // Compositor failed to load
    if (m_failSafe) {
        // We give up because even the error screen has an error
        qWarning("A fatal error has occurred while running Liri Shell, but the error "
                 "screen has errors too. Giving up.");
        QCoreApplication::exit(1);
    } else {
        // Load the error screen in case of error
        m_failSafe = true;
        m_appEngine->load(QUrl(QStringLiteral("qrc:/qml/error/ErrorCompositor.qml")));
    }
}

StartupEvent::StartupEvent()
    : QEvent(StartupEventType)
{
}

#include "moc_application.cpp"
