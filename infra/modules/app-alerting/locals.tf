locals {
  alerts_enabled = var.enable_alerts && length(var.alert_emails) > 0
  scheduled_query_evaluation_frequency = "PT1M"
  scheduled_query_window_duration      = "PT5M"

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

  # Backend HTTP 5xx Query
  # ---------------------------------------------------------------------------
  # Scoped to: Log Analytics Workspace
  # Lookback:  10 minutes
  #
  # Detects backend HTTP 5xx responses across both hosting models:
  #   - App Service        : native AppServiceHTTPLogs access logs
  #   - Container Apps     : structured `http_request` access logs emitted by
  #                          the Nest middleware to stdout/stderr and ingested
  #                          into ContainerAppConsoleLogs tables
  #
  # Tables queried:
  #   AppServiceHTTPLogs                                   (App Service access logs)
  #   ContainerAppConsoleLogs_CL, ContainerAppConsoleLogs (Container Apps app logs)
  #
  # Returns: rows of (TimeGenerated, HttpStatusCode, RequestPath) across all
  # relevant request/access-log sources.
  # ---------------------------------------------------------------------------
  backend_http_5xx_query = <<-QUERY
    let lookback = ago(10m);
    let appServiceHttp = AppServiceHTTPLogs
    | where TimeGenerated > lookback
    | extend HttpStatusCode = toint(ScStatus), RequestPath = tostring(CsUriStem)
    | where HttpStatusCode >= 500 and HttpStatusCode < 600
    | project TimeGenerated, HttpStatusCode, RequestPath;
    let containerConsole = ContainerAppConsoleLogs_CL
    | where TimeGenerated > lookback
    | extend LogText = tostring(Log_s)
    | where LogText has '"event":"http_request"'
    | extend ParsedLog = parse_json(LogText)
    | extend HttpStatusCode = toint(ParsedLog.statusCode), RequestPath = tostring(ParsedLog.url)
    | where HttpStatusCode >= 500 and HttpStatusCode < 600
    | project TimeGenerated, HttpStatusCode, RequestPath;
    let containerConsoleDiag = ContainerAppConsoleLogs
    | where TimeGenerated > lookback
    | extend LogText = tostring(Log)
    | where LogText has '"event":"http_request"'
    | extend ParsedLog = parse_json(LogText)
    | extend HttpStatusCode = toint(ParsedLog.statusCode), RequestPath = tostring(ParsedLog.url)
    | where HttpStatusCode >= 500 and HttpStatusCode < 600
    | project TimeGenerated, HttpStatusCode, RequestPath;
    union isfuzzy=true appServiceHttp, containerConsole, containerConsoleDiag
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

  scheduled_query_alerts = {
    runtime_issues = {
      name_suffix           = "runtime-issues"
      display_name          = "${var.app_name} runtime issues"
      description           = "Detect repeated backend startup, crash-loop, or telemetry initialization failures from host runtime logs."
      scopes                = [var.log_analytics_workspace_id]
      severity              = 2
      skip_query_validation = true
      criteria = {
        query     = local.runtime_issues_query
        threshold = var.runtime_issue_log_threshold
      }
      action = {
        alert_scope = "runtime"
        signal_type = "log-query"
      }
    }
    database_connectivity = {
      name_suffix           = "db-connectivity"
      display_name          = "${var.app_name} database connectivity"
      description           = "Detect repeated Prisma and PostgreSQL connectivity failures from Application Insights telemetry."
      scopes                = [var.application_insights_id]
      severity              = 1
      skip_query_validation = false
      criteria = {
        query     = local.database_connectivity_query
        threshold = var.database_connectivity_issue_threshold
      }
      action = {
        alert_scope = "database"
        signal_type = "application-insights-query"
      }
    }
    backend_http_5xx = {
      name_suffix           = "backend-http5xx"
      display_name          = "${var.app_name} backend HTTP 5xx"
      description           = "Detect repeated backend HTTP 5xx responses from request and access logs across App Service and Container Apps."
      scopes                = [var.log_analytics_workspace_id]
      severity              = 2
      skip_query_validation = true
      criteria = {
        query     = local.backend_http_5xx_query
        threshold = var.backend_http_5xx_threshold
      }
      action = {
        alert_scope = "http-5xx"
        signal_type = "log-query"
      }
    }
  }
}
