#include "crashpad.h"

#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>
#include <QFileInfo>

#include <filesystem>
#include <map>

// These platform-specific defines and includes are needed for chromium.

#if defined(Q_OS_WINDOWS)
#define NOMINMAX
#include <windows.h>
#endif

#if defined(Q_OS_MAC)
#include <mach-o/dyld.h>
#endif

#if defined(Q_OS_LINUX)
#include <unistd.h>
#define MIN(x, y) (((x) < (y)) ? (x) : (y))
#endif

#include <client/crash_report_database.h>
#include <client/crashpad_client.h>
#include <client/settings.h>
#include <base/files/file_path.h>

#if defined(Q_OS_WINDOWS)
constexpr const char* CRASHPAD_HANDLER = "crashpad_handler.exe";
#else
constexpr const char* CRASHPAD_HANDLER = "crashpad_handler";
#endif

inline std::filesystem::path StdPath(const QString& path) {
#if defined(Q_OS_WINDOWS)
    return std::filesystem::path(path.toStdWString());
#else
    return std::filesystem::path(path.toStdString());
#endif
}

bool initializeCrashpad(
    const QString& appDataDir,
    const char* dbName,
    const char* appName,
    const char* appVersion)
{
	static crashpad::CrashpadClient* client = nullptr;
    if (client != nullptr) {
		LOG_WARN("Crashpad has already been initialized");
        return false;
    };
	LOG_INFO("Initializing Crashpad");

    const QDir dataDir(appDataDir);
    if (!dataDir.exists()) {
		LOG_ERROR("Crashpad: app data director does not exist: {}", appDataDir);
        return false;
    };

    // Make sure the executable exists.
    const QString crashpadHandler = QCoreApplication::applicationDirPath() + "/" + CRASHPAD_HANDLER;
    const QFileInfo appInfo(crashpadHandler);
    if (!appInfo.exists()) {
		LOG_ERROR("Crashpad: the handler does not exist: {}", crashpadHandler);
        return false;
    };

	LOG_DEBUG("Crashpad: app data = {}", appDataDir);
	LOG_DEBUG("Crashpad: database = {}", dbName);
	LOG_DEBUG("Crashpad: application = {}", appName);
	LOG_DEBUG("Crashpad: version = {}", appVersion);
	LOG_DEBUG("Crashpad: handler = {}", crashpadHandler);

    // Convert paths to base::FilePath
	const base::FilePath handlerPath(StdPath(crashpadHandler));
	const base::FilePath crashpadDirPath(StdPath(appDataDir + "/crashpad"));
	const base::FilePath& reportsDirPath = crashpadDirPath;
	const base::FilePath& metricsDirPath = crashpadDirPath;

    // Configure url with your BugSplat database
    const std::string url = "https://" + std::string(dbName) + ".bugsplat.com/post/bp/crash/crashpad.php";

    // Metadata that will be posted to BugSplat
    const std::map<std::string, std::string> annotations = {
        { "format", "minidump" }, // Required: Crashpad setting to save crash as a minidump
        { "database", dbName },   // Required: BugSplat database
        { "product", appName },   // Required: BugSplat appName
        { "version", appVersion } // Required: BugSplat appVersion
    };

    // Disable crashpad rate limiting so that all crashes have dmp files
    const std::vector<std::string> arguments = {
        "--no-rate-limit"
    };
    const bool restartable = true;
    const bool asynchronous_start = true;


    // Attachments to be uploaded alongside the crash - default bundle size limit is 20MB
    const QString buyoutData = appDataDir + "/export/buyouts.tgz";
    QFile buyoutDataFile(buyoutData);
    if (buyoutDataFile.exists()) {
        buyoutDataFile.remove();
    };
	const std::vector<base::FilePath> attachments = {
		base::FilePath(StdPath(buyoutData))
    };

    // Log the crashpad initialization settings 
	LOG_DEBUG("Crashpad: starting the crashpad client");
	LOG_TRACE("Crashpad: handler = {}", QString(handlerPath.value()));
	LOG_TRACE("Crashpad: reportsDir = {}", QString(reportsDirPath.value()));
	LOG_TRACE("Crashpad: metricsDir = {}", QString(metricsDirPath.value()));
	LOG_TRACE("Crashpad: url = ", url);
	for (const auto& pair : annotations) {
		LOG_TRACE("Crashpad: annotations[{}] = {}", pair.first, pair.second);
    };
    for (size_t i = 0; i < arguments.size(); ++i) {
		LOG_TRACE("Crashpad: arguments[{}] = {}", i, arguments[i]);
    };
	LOG_TRACE("Crashpad: restartable = {}", restartable);
	LOG_TRACE("Crashpad: asynchronous_start = {}", asynchronous_start);
    for (size_t i = 0; i < attachments.size(); ++i) {
		LOG_TRACE("Crashpad: attachments[{}] = {}", i, QString(attachments[i].value()));
    };

    // Initialize crashpad database
	auto database = crashpad::CrashReportDatabase::Initialize(reportsDirPath);
    if (database == NULL) {
		LOG_ERROR("Crashpad: failed to initialize the crash report database.");
        return false;
    };
	LOG_TRACE("Crashpad: database initialized");

    // Enable automated crash uploads
    auto settings = database->GetSettings();
    if (settings == NULL) {
		LOG_ERROR("Crashpad: failed to get database settings.");
        return false;
    };
    settings->SetUploadsEnabled(true);
	LOG_TRACE("Crashpad: upload enabled");

    // Create the client and start the handler
	client = new crashpad::CrashpadClient();
    const bool started = client->StartHandler(handlerPath,
        reportsDirPath, metricsDirPath, url, annotations,
        arguments, restartable, asynchronous_start, attachments);
    if (!started) {
		LOG_ERROR("Crashpad: unable to start the handler");
        delete(client);
        client = nullptr;
        return false;
    };
	LOG_DEBUG("Crashpad: handler started");
    return true;
}
