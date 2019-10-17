// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

#ifndef LIRI_SHELL_QMLAUTHENTICATOR_H
#define LIRI_SHELL_QMLAUTHENTICATOR_H

#include <QObject>
#include <QJSValue>

#include "authenticator.h"

class QmlAuthenticator : public QObject
{
    Q_OBJECT
public:
    explicit QmlAuthenticator(QObject *parent = nullptr);

    Q_INVOKABLE void authenticate(const QString &password, const QJSValue &callback);

private:
    Authenticator *m_authenticator = nullptr;
    QJSValue m_lastCallback;
    bool m_authRequested = false;
    bool m_succeded = false;

    void executeCallback();
};

#endif // LIRI_SHELL_QMLAUTHENTICATOR_H
