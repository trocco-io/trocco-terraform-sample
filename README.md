# TROCCOの転送設定をTerraformで別アカウントに移行するサンプル

このドキュメントでは、TROCCOで作成した既存の転送設定（SalesforceからSnowflakeへのデータ転送）とそのために必要な接続情報をTROCCOの画面上から作成したうえで、それらをTerraformに取り込み、別のTROCCOアカウントに対してTerraform経由で同じ転送設定と接続情報を作成する方法を説明します。
こうした手順を使うことで、貴社のパートナー検証用環境で作成した設定を、お客様のTROCCO環境にコピーすることができます。

## 前提条件

- Terraform（バージョン1.5.0以上）がインストールされていること
- コピー元とコピー先、両方のTROCCOアカウントのAPIキーを取得していること
- コピー元のTROCCOアカウントに、SalesforceからSnowflakeへの転送設定と必要な接続情報が作成済みであること

## 手順

### 1. コピー元のTROCCOアカウント用のTerraform設定

コピー元のTROCCOアカウントのAPIキーを使用してTerraform providerを設定します。

`source/provider.tf`ファイルを作成します：

```hcl
terraform {
  required_providers {
    trocco = {
      source  = "registry.terraform.io/trocco-io/trocco"
      version = ">= 0.13.0"
    }
  }
}

variable "trocco_api_key" {
  type      = string
  sensitive = true
}

provider "trocco" {
  api_key = var.trocco_api_key
  region  = "japan"
}
```

### 2. 既存の転送設定と接続情報のIDを確認

TROCCOの管理画面から、コピーしたい転送設定と接続情報のIDを確認します。

- 転送設定のID: 転送設定の詳細画面のURLから確認できます。例えば、URLが `https://trocco.io/job-definitions/123` の場合、IDは `123` です。
- Salesforce接続情報のID: 接続情報の詳細画面のURLから確認できます。例えば、URLが `https://trocco.io/connections/1` の場合、IDは `1` です。
- Snowflake接続情報のID: 接続情報の詳細画面のURLから確認できます。例えば、URLが `https://trocco.io/connections/2` の場合、IDは `2` です。

### 3. インポート用の設定ファイルの作成

`source/import.tf`ファイルを作成します：

```hcl
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
```

### 4. Terraformの初期化

```bash
cd source
terraform init
```

### 5. 環境変数の設定

コピー元のTROCCOアカウントのAPIキーを環境変数として設定します。

```bash
export TF_VAR_trocco_api_key="your-source-api-key"
```

### 6. 既存の転送設定と接続情報をTerraformに取り込む

```bash
terraform plan -generate-config-out=resources.tf
```

このコマンドを実行すると、`resources.tf`ファイルが生成されます。このファイルには、既存の転送設定と接続情報のTerraformコードが含まれています。

生成されたファイルを確認し、必要に応じて以下のように分割することもできます：

```bash
# 転送設定と接続情報を別々のファイルに分割する場合
grep -A 100 "trocco_job_definition" resources.tf > job_definition.tf
grep -A 100 "trocco_connection.*salesforce" resources.tf > salesforce_connection.tf
grep -A 100 "trocco_connection.*snowflake" resources.tf > snowflake_connection.tf
```

### 7. コピー先のTROCCOアカウント用のディレクトリを作成

```bash
cd ..
mkdir destination
cp source/provider.tf destination/
cp source/*.tf destination/
```

### 8. コピー先のTROCCOアカウント用に設定を調整

コピー先のTROCCOアカウントでは、接続情報も新たに作成されるため、転送設定内の接続情報IDの参照を更新する必要はありません。ただし、以下の点に注意してください：

1. Salesforceの接続情報に含まれるパスワードやセキュリティトークンなどの機密情報は、セキュリティ上の理由からTerraformのインポート時に空になっている可能性があります。その場合は、コピー先のアカウント用に正しい値を設定してください。

2. Snowflakeの接続情報についても同様に、パスワードなどの機密情報を適切に設定してください。

3. リソースグループIDやラベルなど、アカウント固有の設定がある場合は、コピー先のアカウントに合わせて調整してください。

### 9. コピー先のTROCCOアカウントでTerraformを実行

```bash
cd destination
export TF_VAR_trocco_api_key="your-destination-api-key"
terraform init
terraform plan
terraform apply
```

`terraform apply`コマンドを実行すると、コピー先のTROCCOアカウントに転送設定が作成されます。

## サンプルコード

### 生成される接続情報のサンプル

以下は、`terraform plan -generate-config-out=resources.tf`コマンドで生成される可能性のあるSalesforceとSnowflakeの接続情報のサンプルです。
実際の出力は、既存の接続情報の内容によって異なります。

#### Salesforce接続情報のサンプル

```hcl
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
```

#### Snowflake接続情報のサンプル

```hcl
resource "trocco_connection" "snowflake" {
  connection_type = "snowflake"

  name        = "Snowflake Data Warehouse"
  description = "Main Snowflake data warehouse connection"

  host        = "example.snowflakecomputing.com"
  auth_method = "user_password"
  user_name   = "snowflake_user"
  password    = "" # セキュリティ上の理由から空になっている可能性があります
}
```

### 生成される転送設定のサンプル

以下は、`terraform plan -generate-config-out=resources.tf`コマンドで生成される可能性のあるSalesforceからSnowflakeへの転送設定のサンプルです。
実際の出力は、既存の転送設定の内容によって異なります。

```hcl
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
```

### コピー先のTROCCOアカウント用に編集したファイル

コピー先のTROCCOアカウントで使用するために、接続情報IDを更新したファイルの例：

```hcl
resource "trocco_job_definition" "salesforce_to_snowflake" {
  # 他の設定は同じ
  
  input_option = {
    salesforce_input_option = {
      # 他の設定は同じ
      salesforce_connection_id = 5 # コピー先のSalesforce接続情報ID
    }
  }
  
  output_option = {
    snowflake_output_option = {
      # 他の設定は同じ
      snowflake_connection_id = 6 # コピー先のSnowflake接続情報ID
    }
  }
}
```

## 注意事項

1. 接続情報に含まれるパスワードやセキュリティトークンなどの機密情報は、セキュリティ上の理由からTerraformのインポート時に空になっている可能性があります。コピー先のアカウントで使用する前に、これらの値を適切に設定してください。
2. 接続情報のIDは、Terraform管理下では自動的に生成されるため、コピー先のアカウントでは新しいIDが割り当てられます。転送設定内の接続情報IDの参照は、Terraformによって自動的に解決されます。
3. リソースグループIDやラベルなど、アカウント固有の設定も適宜更新する必要があります。
4. 転送設定に関連する他のリソース（スケジュール、通知設定など）も必要に応じて更新してください。
5. 大量のリソースを移行する場合は、依存関係に注意してください。接続情報を先に作成し、その後で転送設定を作成するという順序で行うと良いでしょう。
