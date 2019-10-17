// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

#include <QDBusConnection>
#include <QDBusError>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>

#include "sessionmanager.h"

Q_LOGGING_CATEGORY(lcSessionManager, "liri.session.manager")

SessionManager::SessionManager(QObject *parent)
    : QObject(parent)
{
    // Emit when the session is locked or unlocked
    QDBusConnection::sessionBus().connect(
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("/io/liri/SessionManager"),
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("Locked"),
                this, SIGNAL(sessionLocked()));
    QDBusConnection::sessionBus().connect(
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("/io/liri/SessionManager"),
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("Unlocked"),
                this, SIGNAL(sessionUnlocked()));
}

bool SessionManager::isIdle() const
{
    return m_idle;
}

void SessionManager::setIdle(bool value)
{
    if (m_idle == value)
        return;

    auto msg = QDBusMessage::createMethodCall(
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("/io/liri/SessionManager"),
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("SetIdle"));
    msg.setArguments(QVariantList() << value);
    QDBusPendingCall call = QDBusConnection::sessionBus().asyncCall(msg);
    auto *watcher = new QDBusPendingCallWatcher(call, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [&](QDBusPendingCallWatcher *self) {
        QDBusPendingReply<> reply = *self;
        if (reply.isError()) {
            qCWarning(lcSessionManager, "Failed to toggle idle flag: %s",
                      qPrintable(reply.error().message()));
        } else {
            m_idle = value;
            Q_EMIT idleChanged(m_idle);
        }

        self->deleteLater();
    });
}

void SessionManager::lock()
{
    auto msg = QDBusMessage::createMethodCall(
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("/io/liri/SessionManager"),
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("Lock"));
    QDBusPendingCall call = QDBusConnection::sessionBus().asyncCall(msg);
    auto *watcher = new QDBusPendingCallWatcher(call, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [](QDBusPendingCallWatcher *self) {
        QDBusPendingReply<> reply = *self;
        if (reply.isError())
            qCWarning(lcSessionManager, "Failed to lock session: %s",
                      qPrintable(reply.error().message()));

        self->deleteLater();
    });
}

void SessionManager::unlock()
{
    auto msg = QDBusMessage::createMethodCall(
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("/io/liri/SessionManager"),
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("Unlock"));
    QDBusPendingCall call = QDBusConnection::sessionBus().asyncCall(msg);
    auto *watcher = new QDBusPendingCallWatcher(call, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [](QDBusPendingCallWatcher *self) {
        QDBusPendingReply<> reply = *self;
        if (reply.isError())
            qCWarning(lcSessionManager, "Failed to unlock the session: %s",
                      qPrintable(reply.error().message()));

        self->deleteLater();
    });
}

void SessionManager::setEnvironment(const QString &key, const QString &value)
{
    auto msg = QDBusMessage::createMethodCall(
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("/io/liri/SessionManager"),
                QStringLiteral("io.liri.SessionManager"),
                QStringLiteral("SetEnvironment"));
    QVariantList args;
    args.append(key);
    args.append(value);
    msg.setArguments(args);
    QDBusPendingCall call = QDBusConnection::sessionBus().asyncCall(msg);
    auto *watcher = new QDBusPendingCallWatcher(call, this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [](QDBusPendingCallWatcher *self) {
        QDBusPendingReply<> reply = *self;
        if (reply.isError())
            qCWarning(lcSessionManager, "Failed to set environment: %s",
                      qPrintable(reply.error().message()));

        self->deleteLater();
    });
}
