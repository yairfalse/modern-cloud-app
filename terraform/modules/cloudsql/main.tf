# Cloud SQL PostgreSQL module for ModernBlog

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Random suffix for database instance name
resource "random_id" "db_suffix" {
  byte_length = 4
}

# Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "postgres" {
  name             = "${var.name_prefix}-db-${random_id.db_suffix.hex}"
  database_version = var.database_config.database_version
  region           = var.region
  
  # Delete protection
  deletion_protection = var.environment == "prod" ? true : false
  
  settings {
    tier              = var.database_config.tier
    disk_size         = var.database_config.disk_size
    disk_type         = var.database_config.disk_type
    disk_autoresize   = true
    disk_autoresize_limit = var.database_config.disk_size * 5
    
    # Availability configuration
    availability_type = var.database_config.availability_type
    
    # Backup configuration
    backup_configuration {
      enabled                        = var.database_config.backup_enabled
      start_time                     = var.database_config.backup_start_time
      point_in_time_recovery_enabled = var.database_config.point_in_time_recovery
      transaction_log_retention_days = 7
      
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }
    
    # IP configuration - Private IP only
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
      require_ssl     = true
      
      # Authorized networks (if public IP is enabled in the future)
      dynamic "authorized_networks" {
        for_each = []
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }
    
    # Database flags
    database_flags {
      name  = "log_connections"
      value = "on"
    }
    
    database_flags {
      name  = "log_disconnections"
      value = "on"
    }
    
    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }
    
    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }
    
    database_flags {
      name  = "log_temp_files"
      value = "0"
    }
    
    database_flags {
      name  = "log_min_duration_statement"
      value = "1000" # Log queries taking more than 1 second
    }
    
    database_flags {
      name  = "max_connections"
      value = var.environment == "prod" ? "500" : "100"
    }
    
    database_flags {
      name  = "shared_buffers"
      value = "256000" # In 8KB units
    }
    
    # Maintenance window
    maintenance_window {
      day          = 7 # Sunday
      hour         = 3
      update_track = "stable"
    }
    
    # Insights configuration
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
    
    # User labels
    user_labels = var.common_labels
  }
  
  project = var.project_id
}

# Database creation
resource "google_sql_database" "modernblog" {
  name     = "modernblog"
  instance = google_sql_database_instance.postgres.name
  
  project = var.project_id
}

# Database user with random password
resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "google_sql_user" "app_user" {
  name     = "modernblog"
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
  
  project = var.project_id
}

# Store database credentials in Secret Manager
resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "${var.name_prefix}-db-credentials"
  
  replication {
    auto {}
  }
  
  labels = var.common_labels
  
  project = var.project_id
}

resource "google_secret_manager_secret_version" "db_credentials" {
  secret = google_secret_manager_secret.db_credentials.id
  
  secret_data = jsonencode({
    username = google_sql_user.app_user.name
    password = google_sql_user.app_user.password
    database = google_sql_database.modernblog.name
    host     = google_sql_database_instance.postgres.private_ip_address
    port     = 5432
    connection_name = google_sql_database_instance.postgres.connection_name
  })
}

# Create read-only user for analytics
resource "random_password" "readonly_password" {
  length  = 32
  special = true
}

resource "google_sql_user" "readonly_user" {
  name     = "modernblog_readonly"
  instance = google_sql_database_instance.postgres.name
  password = random_password.readonly_password.result
  
  project = var.project_id
}

# Store read-only credentials
resource "google_secret_manager_secret" "readonly_credentials" {
  secret_id = "${var.name_prefix}-db-readonly-credentials"
  
  replication {
    auto {}
  }
  
  labels = var.common_labels
  
  project = var.project_id
}

resource "google_secret_manager_secret_version" "readonly_credentials" {
  secret = google_secret_manager_secret.readonly_credentials.id
  
  secret_data = jsonencode({
    username = google_sql_user.readonly_user.name
    password = google_sql_user.readonly_user.password
    database = google_sql_database.modernblog.name
    host     = google_sql_database_instance.postgres.private_ip_address
    port     = 5432
    connection_name = google_sql_database_instance.postgres.connection_name
  })
}

# High Availability configuration (for production)
resource "google_sql_database_instance" "read_replica" {
  count = var.database_config.high_availability && var.environment == "prod" ? 1 : 0
  
  name                 = "${var.name_prefix}-db-replica-${random_id.db_suffix.hex}"
  database_version     = var.database_config.database_version
  region               = var.region
  master_instance_name = google_sql_database_instance.postgres.name
  
  replica_configuration {
    failover_target = true
  }
  
  settings {
    tier              = var.database_config.tier
    disk_size         = var.database_config.disk_size
    disk_type         = var.database_config.disk_type
    disk_autoresize   = true
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
      require_ssl     = true
    }
    
    database_flags {
      name  = "max_connections"
      value = "500"
    }
    
    user_labels = merge(var.common_labels, {
      replica = "true"
    })
  }
  
  project = var.project_id
}