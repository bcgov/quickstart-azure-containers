locals {
  server_configuration = merge(
    {
      shared_preload_libraries = {
        name   = "shared_preload_libraries"
        config = "pg_stat_statements,pg_cron"
      }
      log_statement = {
        name   = "log_statement"
        config = var.enable_server_logs ? var.log_statement_mode : "none"
      }
      log_min_duration_statement = {
        name   = "log_min_duration_statement"
        config = tostring(var.log_min_duration_statement_ms)
      }
      track_io_timing = {
        name   = "track_io_timing"
        config = var.track_io_timing ? "ON" : "OFF"
      }
      pg_stat_statements_max = {
        name   = "pg_stat_statements.max"
        config = tostring(var.pg_stat_statements_max)
      }
    },
    var.enable_server_logs ? {
      log_connections = {
        name   = "log_connections"
        config = "ON"
      }
      log_disconnections = {
        name   = "log_disconnections"
        config = "ON"
      }
      log_duration = {
        name   = "log_duration"
        config = "ON"
      }
    } : {},
    var.enable_is_postgis ? {
      azure_extensions = {
        name   = "azure.extensions"
        config = "POSTGIS"
      }
    } : {}
  )

  diagnostic_settings = var.enable_diagnostic_insights ? {
    postgres = {
      name                  = "${var.app_name}-postgres-diagnostics"
      workspace_resource_id = var.log_analytics_workspace_id
      log_categories        = toset(var.diagnostic_log_categories)
      metric_categories     = toset(var.diagnostic_metric_categories)
    }
  } : {}
}
