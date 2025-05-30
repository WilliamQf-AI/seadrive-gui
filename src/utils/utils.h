#ifndef SEAFILE_CLIENT_UTILS_H_
#define SEAFILE_CLIENT_UTILS_H_

#include <jansson.h>
#include <QString>
#include <QStringList>
#include <QDir>
#include <QMap>
#include <QHash>
#include <QMultiHash>
#include <QUrl>
#include <QSslError>

const QString EMPTY_DOMAIN_ID = "00000000000000000000000000000000";

class QSslCipher;
class QSslCertificate;

#define toCStr(_s)   ((_s).isNull() ? NULL : (_s).toUtf8().data())

#if defined(XCODE_APP)
#define RESOURCE_PATH(_name)  (QDir(QCoreApplication::applicationDirPath()).filePath(QString("../Resources/")+(_name)))
#else
#define RESOURCE_PATH(_name)  (_name)
#endif

struct sqlite3;
struct sqlite3_stmt;

typedef bool (*SqliteRowFunc) (sqlite3_stmt *stmt, void *data);

sqlite3_stmt *sqlite_query_prepare (sqlite3 *db, const char *sql);

int sqlite_query_exec (sqlite3 *db, const char *sql);

int sqlite_foreach_selected_row (sqlite3 *db, const char *sql,
                                 SqliteRowFunc callback, void *data);

int checkdir_with_mkdir (const char *dir);

int get_seafile_auto_start();

int set_seafile_auto_start(bool on);

int set_seafile_dock_icon_style(bool hidden);

typedef bool (*KeyValueFunc) (void *data, const char *key,
                              const char *value);

bool parse_key_value_pairs (char *string, KeyValueFunc func, void *data);

QString getBrand();

QString translateCommitTime(qint64 timestamp);

QString readableFileSize(qint64 size);

QString readableFileSizeV2(qint64 size);

QMap<QString, QVariant> mapFromJSON(json_t *json, json_error_t *error);
QString mapToJson(QMap<QString, QVariant> map);

QString seadriveWorkDir();

QString seadriveInternalDir();

QString seadriveDataDir();

QString seadriveLogDir();

QString defaultDownloadDir();

// open file use native default file handler, return false if failed
bool openInNativeExtension(const QString &path);

// open file and select it in native file browser, return false if failed
bool showInGraphicalShell(const QString& path);

QString md5(const QString& s);

QUrl urlJoin(const QUrl& url, const QString& tail);

void removeDirRecursively(const QString &path);

bool copyDirRecursively(const QString &src_path, const QString &dst_path);

QString dumpHexPresentation(const QByteArray &bytes);

QString dumpSslErrors(const QList<QSslError>&);

QString dumpCipher(const QSslCipher &cipher);

QString dumpCertificate(const QSslCertificate &cert);

QString dumpCertificateFingerprint(const QSslCertificate &cert,
                                   const QCryptographicHash::Algorithm &algorithm = QCryptographicHash::Md5);

void msleep(int mseconds);


QUrl includeQueryParams(const QUrl& url,
                        const QMultiHash<QString, QString>& params);

QByteArray buildFormData(const QHash<QString, QString>& params);

QString translateTransferRate(int rate);

int runAsCommand(const QString &binary, const QStringList &arguments, QString *output = nullptr);

QString trimNULL(QString& s);

#ifdef Q_OS_MAC
bool checkOSVersion144();
void stopDaemon();
#endif

bool openUrl(QUrl url);

#endif
