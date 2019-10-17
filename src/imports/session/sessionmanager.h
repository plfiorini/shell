// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

#ifndef SESSIONMANAGER_H
#define SESSIONMANAGER_H

#include <QObject>
#include <QLoggingCategory>

Q_DECLARE_LOGGING_CATEGORY(lcSessionManager)

class SessionManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool idle READ isIdle WRITE setIdle NOTIFY idleChanged)
public:
    explicit SessionManager(QObject *parent = nullptr);

    bool isIdle() const;
    void setIdle(bool value);

    Q_INVOKABLE void lock();
    Q_INVOKABLE void unlock();
    Q_INVOKABLE void setEnvironment(const QString &key, const QString &value);

Q_SIGNALS:
    void idleChanged(bool value);
    void sessionLocked();
    void sessionUnlocked();

private:
    bool m_idle = false;
};

#endif // SESSIONMANAGER_H
