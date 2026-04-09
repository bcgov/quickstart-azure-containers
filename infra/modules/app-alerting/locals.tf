locals {
  alerts_enabled = var.enable_alerts && length(var.alert_emails) > 0

  smart_detectors = {
    request-performance = {
      description = "Detect backend request latency regressions compared with historical baselines."
      detector    = "RequestPerformanceDegradationDetector"
      severity    = "Sev2"
      frequency   = "PT1H"
    }
    dependency-performance = {
      description = "Detect anomalous degradation in downstream dependency latency."
      detector    = "DependencyPerformanceDegradationDetector"
      severity    = "Sev2"
      frequency   = "PT1H"
    }
    exception-volume = {
      description = "Detect abnormal increases in backend exception volume."
      detector    = "ExceptionVolumeChangedDetector"
      severity    = "Sev2"
      frequency   = "PT1H"
    }
  }

  # Runtime Issues Query
  # ---------------------------------------------------------------------------
  # Scoped to: Log Analytics Workspace
  # Lookback:  10 minutes
  #
  # Searches six log tables (App Service + Container Apps, both custom and
  # built-in diagnostic settings) for known runtime failure patterns:
  #   - PrismaClientInitializationError  : ORM failed to connect at startup
  #   - Failed to initialize Azure Monitor OpenTelemetry : telemetry SDK error
  #   - Can't reach database server      : PostgreSQL unreachable
  #   - CrashLoopBackOff / Back-off restarting : container restart loops
  #   - probe failed                     : health-check failures
  #   - UnhandledPromiseRejection        : uncaught async errors in Node.js
  #   - EADDRINUSE                       : port conflict on startup
  #
  # Tables queried:
  #   AppServiceConsoleLogs, AppServicePlatformLogs          (App Service)
  #   ContainerAppConsoleLogs_CL, ContainerAppSystemLogs_CL  (Container Apps custom)
  #   ContainerAppConsoleLogs, ContainerAppSystemLogs        (Container Apps diagnostic)
  #
  # Returns: rows of (TimeGenerated, RuntimeMessage) unioned across all tables.
  # ---------------------------------------------------------------------------
  runtime_issues_query = <<-QUERY
    let lookback = ago(10m);
    let runtimeIssuePatterns = dynamic([
      "PrismaClientInitializationError",
      "Failed to initialize Azure Monitor OpenTelemetry",
      "Can't reach database server",
      "CrashLoopBackOff",
      "Back-off restarting",
      "probe failed",
      "UnhandledPromiseRejection",
      "EADDRINUSE"
    ]);
    let appServiceConsole = AppServiceConsoleLogs
    | where TimeGenerated > lookback
    | extend RuntimeMessage = tostring(ResultDescription)
    | where RuntimeMessage has_any(runtimeIssuePatterns)
    | project TimeGenerated, RuntimeMessage;
    let appServicePlatform = AppServicePlatformLogs
    | where TimeGenerated > lookback
    | extend RuntimeMessage = tostring(Message)
    | where RuntimeMessage has_any(runtimeIssuePatterns)
    | project TimeGenerated, RuntimeMessage;
    let containerConsole = ContainerAppConsoleLogs_CL
    | where TimeGenerated > lookback
    | extend RuntimeMessage = tostring(Log_s)
    | where RuntimeMessage has_any(runtimeIssuePatterns)
    | project TimeGenerated, RuntimeMessage;
    let containerSystem = ContainerAppSystemLogs_CL
    | where TimeGenerated > lookback
    | extend RuntimeMessage = tostring(Log_s)
    | where RuntimeMessage has_any(runtimeIssuePatterns)
    | project TimeGenerated, RuntimeMessage;
    let containerConsoleDiag = ContainerAppConsoleLogs
    | where TimeGenerated > lookback
    | extend RuntimeMessage = tostring(Log)
    | where RuntimeMessage has_any(runtimeIssuePatterns)
    | project TimeGenerated, RuntimeMessage;
    let containerSystemDiag = ContainerAppSystemLogs
    | where TimeGenerated > lookback
    | extend RuntimeMessage = tostring(Log)
    | where RuntimeMessage has_any(runtimeIssuePatterns)
    | project TimeGenerated, RuntimeMessage;
    union isfuzzy=true appServiceConsole, appServicePlatform, containerConsole, containerSystem, containerConsoleDiag, containerSystemDiag
  QUERY

  # Database Connectivity Query
  # ---------------------------------------------------------------------------
  # Scoped to: Application Insights
  # Lookback:  10 minutes
  #
  # Detects Prisma ORM and PostgreSQL connectivity failures by scanning
  # Application Insights exception and trace telemetry for known error patterns:
  #   - PrismaClientInitializationError  : ORM could not establish a connection
  #   - P1001                            : Prisma "can't reach database server"
  #   - P1002                            : Prisma "database server timed out"
  #   - Can't reach database server      : raw driver-level connection refusal
  #   - Connection terminated unexpectedly : TCP/TLS drop mid-session
  #   - timeout                          : generic query or connection timeout
  #
  # Tables queried:
  #   exceptions     — native Application Insights exception telemetry
  #                    (checks message, innermostMessage, outerMessage,
  #                    and problemId)
  #   traces         — native Application Insights trace telemetry
  #
  # Returns: rows of (TimeGenerated, Message) unioned across both tables.
  # ---------------------------------------------------------------------------
  database_connectivity_query = <<-QUERY
    let lookback = ago(10m);
    let databaseIssuePatterns = dynamic([
      "PrismaClientInitializationError",
      "P1001",
      "P1002",
      "Can't reach database server",
      "Connection terminated unexpectedly",
      "timeout"
    ]);
    let exceptionMatches = exceptions
    | where timestamp > lookback
    | extend MessageText = coalesce(message, innermostMessage, outerMessage, problemId)
    | where MessageText has_any(databaseIssuePatterns)
    | project TimeGenerated = timestamp, Message = MessageText;
    let traceMatches = traces
    | where timestamp > lookback
    | where message has_any(databaseIssuePatterns)
    | project TimeGenerated = timestamp, Message = message;
    union isfuzzy=true exceptionMatches, traceMatches
  QUERY
}
