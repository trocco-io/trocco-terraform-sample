# 転送設定のインポート
import {
  id = "123" # コピーしたい転送設定のID。実際に貴社環境に存在するIDに書き換えてください
  to = trocco_job_definition.salesforce_to_snowflake
}

# Salesforce接続情報のインポート
import {
  id = "1" # コピーしたいSalesforce接続情報のID。実際に貴社環境に存在するIDに書き換えてください
  to = trocco_connection.salesforce
}

# Snowflake接続情報のインポート
import {
  id = "2" # コピーしたいSnowflake接続情報のID。実際に貴社環境に存在するIDに書き換えてください
  to = trocco_connection.snowflake
}
