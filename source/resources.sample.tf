# このファイルはサンプルとして配置しています。README.mdの手順6を実施し、正常に取り込めたら適宜削除してください。

# Salesforce接続情報
resource "trocco_connection" "salesforce" {
  connection_type = "salesforce"

  name        = "Salesforce Production"
  description = "Salesforce production environment connection"

  auth_method    = "user_password"
  user_name      = "user@example.com"
  password       = "" # セキュリティ上の理由から空になっている可能性があります
  security_token = "" # セキュリティ上の理由から空になっている可能性があります
  auth_end_point = "https://login.salesforce.com/services/Soap/u/"
}

# Snowflake接続情報
resource "trocco_connection" "snowflake" {
  connection_type = "snowflake"

  name        = "Snowflake Data Warehouse"
  description = "Main Snowflake data warehouse connection"

  host        = "example.snowflakecomputing.com"
  auth_method = "user_password"
  user_name   = "snowflake_user"
  password    = "" # セキュリティ上の理由から空になっている可能性があります
}

# 転送設定
resource "trocco_job_definition" "salesforce_to_snowflake" {
  name                     = "Salesforce to Snowflake"
  description              = "Transfer data from Salesforce to Snowflake"
  is_runnable_concurrently = false
  retry_limit              = 3
  resource_group_id        = 1

  # 入力設定（Salesforce）
  input_option_type = "salesforce"
  input_option = {
    salesforce_input_option = {
      columns = [
        {
          name = "Id"
          type = "string"
        },
        {
          name = "Name"
          type = "string"
        },
        {
          name = "Email"
          type = "string"
        },
        {
          name = "CreatedDate"
          type = "timestamp"
        }
      ]
      include_deleted_or_archived_records = false
      is_convert_type_custom_columns      = false
      object                              = "Contact"
      object_acquisition_method           = "soql"
      soql                                = "SELECT Id, Name, Email, CreatedDate FROM Contact"
      salesforce_connection_id            = 1 # コピー元のSalesforce接続情報ID
    }
  }

  # 出力設定（Snowflake）
  output_option_type = "snowflake"
  output_option = {
    snowflake_output_option = {
      database                = "EXAMPLE_DB"
      schema                  = "PUBLIC"
      table                   = "CONTACTS"
      mode                    = "append"
      snowflake_connection_id = 2 # コピー元のSnowflake接続情報ID
    }
  }

  # フィルター列の設定
  filter_columns = [
    {
      name = "Id"
      src  = "Id"
      type = "string"
    },
    {
      name = "Name"
      src  = "Name"
      type = "string"
    },
    {
      name = "Email"
      src  = "Email"
      type = "string"
    },
    {
      name = "CreatedDate"
      src  = "CreatedDate"
      type = "timestamp"
    }
  ]

  # スケジュール設定（オプション）
  schedules = [
    {
      cron_expression = "0 0 * * *" # 毎日0時に実行
      timezone        = "Asia/Tokyo"
    }
  ]
}
