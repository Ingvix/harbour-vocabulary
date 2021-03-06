/*
 * Copyright 2016,2017 Marcus Soll
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#include "csvhandle.h"

#include <QTextStream>
#include <QtCore/QtMath>
#include <QTextCodec>
#include <QDate>

CSVHandle::CSVHandle(QObject *parent) : QObject(parent)
{
}

QStringList CSVHandle::loadCSV(QString path, CSVHandle::seperator sep, bool has_header, int column_word, int column_translation, int column_priority, bool import_priority, int language)
{
    QStringList errors;

    if(column_priority < 0 || column_translation < 0 || column_word < 0)
    {
        errors << tr("All column indices must be positive or zero");
        return errors;
    }

    QFile file(path);

    if(!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        QString error = QString(tr("Can not open file \"%1\": %2")).arg(path).arg(file.errorString());
        WARNING(error);
        errors << error;
        return errors;
    }

    QTextStream stream(&file);
    stream.setCodec(QTextCodec::codecForName("UTF-8"));

    database.transaction();
    QSqlQuery q(database);
    QString s;

    s = "INSERT INTO vocabulary (word, translation, priority, creation, modification, language) VALUES (:word, :translation, 100, :creation, :modification, :language)";


    int need_num_columns = qMax(column_word, column_translation);
    QChar sep_char = getSeperator(sep);

    if(import_priority)
    {
        need_num_columns = qMax(need_num_columns, column_priority);
        s = "INSERT INTO vocabulary (word, translation, priority, creation, modification, language) VALUES (:word, :translation, :priority, :creation, :modification, :language)";
    }

    if(has_header)
    {
        // Ignore header
        stream.readLine();
    }

    qint64 today = QDate::currentDate().toJulianDay();

    while(!stream.atEnd())
    {
        QString line = stream.readLine();
        if(line.isEmpty())
        {
            continue;
        }
        QStringList columns = line.split(sep_char, QString::KeepEmptyParts);
        if(columns.size() < need_num_columns + 1)
        {
            QString error = QString(tr("Error at \"%1\": Column to small")).arg(line);
            WARNING(error);
            errors << error;
            continue;
        }
        q.prepare(s);
        q.bindValue(":word", columns[column_word].simplified());
        q.bindValue(":translation", columns[column_translation].simplified());
        if(import_priority)
        {
            bool ok = true;
            int priority = qBound(1, columns[column_priority].toInt(&ok), 100);
            if(!ok)
            {
                priority = 100;
                QString error = QString(tr("Can not convert \"%1\" to priority")).arg(columns[column_priority]);
                WARNING(error);
                errors << error;
            }
            q.bindValue(":priority", priority);
        }
        q.bindValue(":creation", today);
        q.bindValue(":modification", today);
        q.bindValue(":language", language);

        if(!q.exec())
        {
            QString error = s;
            error.append(": ").append(q.lastError().text());
            WARNING(error);
            errors << error;
        }
    }

    if(!database.commit())
    {
        errors << database.lastError().text();
    }
    return errors;
}

QStringList CSVHandle::saveCSV(QString path, CSVHandle::seperator sep, bool write_header, int language)
{
    QStringList errors;

    QFile file(path);

    if(!file.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        QString error = QString(tr("Can not open file \"%1\": %2")).arg(path).arg(file.errorString());
        WARNING(error);
        errors << error;
        return errors;
    }

    QTextStream stream(&file);
    stream.setCodec(QTextCodec::codecForName("UTF-8"));

    QSqlQuery q(database);
    QString s;

    if(language == -1)
    {
        s = "SELECT word,translation,priority FROM vocabulary";

        q.prepare(s);
    }
    else
    {
        s = "SELECT word,translation,priority FROM vocabulary WHERE language=:l";

        q.prepare(s);
        q.bindValue(":l", language);
    }

    if(!q.exec())
    {
        QString error = s;
        error.append(": ").append(q.lastError().text());
        WARNING(error);
        errors << error;
        file.close();
        return errors;
    }
    if(!q.isSelect())
    {
        QString error = s;
        error.append(": No select");
        WARNING(error);
        errors << error;
        file.close();
        return errors;
    }

    QChar sep_char = getSeperator(sep);

    if(write_header)
    {
        stream << QString(tr("word%1translation%1priority\n")).arg(sep_char);
    }

    while(q.next())
    {
        QString line;
        line.append(q.value(0).toString());
        line.append(sep_char);
        line.append(q.value(1).toString());
        line.append(sep_char);
        line.append(q.value(2).toString());
        line.append('\n');
        stream << line;
    }

    file.close();
    return errors;
}

QChar CSVHandle::getSeperator(CSVHandle::seperator sep)
{
    switch(sep)
    {
    case TAB:
        return QChar('\t');
        break;
    case SPACE:
        return QChar(' ');
        break;
    case COMMA:
        return QChar(',');
        break;
    case SEMICOLON:
        return QChar(';');
        break;
    }
    Q_UNREACHABLE();
}


