locals {
  alerts_enabled = var.enable_alerts && length(var.alert_emails) > 0

  # Application Insights smart detection remains available as a platform-managed
  # capability on the component itself. Custom alert-rule provisioning for these
  # detector types is not accepted by the Azure Monitor API in this environment,
  # so Terraform only manages the action group plus the explicit scheduled-query
  # and metric alerts below.
  smart_detectors = {}

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

  # SQL Injection Query
  # ---------------------------------------------------------------------------
  # Scoped to: Log Analytics Workspace
  # Lookback:  10 minutes
  #
  # Detects backend requests that were explicitly blocked as SQL injection
  # attempts. The backend middleware emits structured console logs with the
  # `SQLInjectionAttackDetected` indicator when it rejects a suspicious payload.
  #
  # Tables queried:
  #   AppServiceConsoleLogs, AppServicePlatformLogs          (App Service)
  #   ContainerAppConsoleLogs_CL, ContainerAppSystemLogs_CL  (Container Apps custom)
  #   ContainerAppConsoleLogs, ContainerAppSystemLogs        (Container Apps diagnostic)
  #
  # Returns: rows of (TimeGenerated, SecurityMessage) that contain the security
  # indicator used by the middleware.
  # ---------------------------------------------------------------------------
  sql_injection_query = <<-QUERY
    let lookback = ago(10m);
    let sqlInjectionIndicator = "SQLInjectionAttackDetected";
    let appServiceConsole = AppServiceConsoleLogs
    | where TimeGenerated > lookback
    | extend SecurityMessage = tostring(ResultDescription)
    | where SecurityMessage has sqlInjectionIndicator
    | project TimeGenerated, SecurityMessage;
    let appServicePlatform = AppServicePlatformLogs
    | where TimeGenerated > lookback
    | extend SecurityMessage = tostring(Message)
    | where SecurityMessage has sqlInjectionIndicator
    | project TimeGenerated, SecurityMessage;
    let containerConsole = ContainerAppConsoleLogs_CL
    | where TimeGenerated > lookback
    | extend SecurityMessage = tostring(Log_s)
    | where SecurityMessage has sqlInjectionIndicator
    | project TimeGenerated, SecurityMessage;
    let containerSystem = ContainerAppSystemLogs_CL
    | where TimeGenerated > lookback
    | extend SecurityMessage = tostring(Log_s)
    | where SecurityMessage has sqlInjectionIndicator
    | project TimeGenerated, SecurityMessage;
    let containerConsoleDiag = ContainerAppConsoleLogs
    | where TimeGenerated > lookback
    | extend SecurityMessage = tostring(Log)
    | where SecurityMessage has sqlInjectionIndicator
    | project TimeGenerated, SecurityMessage;
    let containerSystemDiag = ContainerAppSystemLogs
    | where TimeGenerated > lookback
    | extend SecurityMessage = tostring(Log)
    | where SecurityMessage has sqlInjectionIndicator
    | project TimeGenerated, SecurityMessage;
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
