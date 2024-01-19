#!/bin/bash

send_request() {
      # 在函数内部获取参数值
      secret_id="$1"
      secret_key="$2"
      action="$3"
#      action="DescribeRecordList"
      payload="$4"
      service="dnspod"
      host="dnspod.tencentcloudapi.com"
      region="ap-guangzhou"  # 请根据实际情况设置区域

      version="2021-03-23"
      algorithm="TC3-HMAC-SHA256"
      timestamp=$(date +%s)
      date=$(date -u -d "@$timestamp" +"%Y-%m-%d")

      # 用户输入域名
#      read -p "请输入您要查询的域名: " input_domain
#      payload="{\"Domain\":\"$input_domain\"}"

      # ************* 步骤 1：拼接规范请求串 *************
      http_request_method="POST"
      canonical_uri="/"
      canonical_querystring=""
      canonical_headers="content-type:application/json; charset=utf-8\nhost:$host\nx-tc-action:$(echo $action | awk '{print tolower($0)}')\n"
      signed_headers="content-type;host;x-tc-action"
      hashed_request_payload=$(echo -n "$payload" | openssl sha256 -hex | awk '{print $2}')
      canonical_request="$http_request_method\n$canonical_uri\n$canonical_querystring\n$canonical_headers\n$signed_headers\n$hashed_request_payload"

      # ************* 步骤 2：拼接待签名字符串 *************
      credential_scope="$date/$service/tc3_request"
      hashed_canonical_request=$(printf "$canonical_request" | openssl sha256 -hex | awk '{print $2}')
      string_to_sign="$algorithm\n$timestamp\n$credential_scope\n$hashed_canonical_request"

      # ************* 步骤 3：计算签名 *************
      #secret_date=$(printf "$date" | openssl sha256 -hmac "TC3$secret_key" | awk '{print $2}')
      #secret_service=$(printf $service | openssl dgst -sha256 -mac hmac -macopt hexkey:"$secret_date" | awk '{print $2}')
      secret_date=$(printf "$date" | openssl dgst -sha256 -hmac "TC3$secret_key" | awk '{print $2}')

      # 使用新的openssl语法
      secret_service=$(printf "$service" | openssl dgst -sha256 -mac HMAC -macopt hexkey:"$secret_date" | awk '{print $2}')



      secret_signing=$(printf "tc3_request" | openssl dgst -sha256 -mac hmac -macopt hexkey:"$secret_service" | awk '{print $2}')
      signature=$(printf "$string_to_sign" | openssl dgst -sha256 -mac hmac -macopt hexkey:"$secret_signing" | awk '{print $2}')

      # ************* 步骤 4：拼接 Authorization *************
      authorization="$algorithm Credential=$secret_id/$credential_scope, SignedHeaders=$signed_headers, Signature=$signature"

      # ************* 步骤 5：构造并发起请求 *************
      #curl -XPOST "https://$host" -d "$payload" -H "Authorization: $authorization" -H "Content-Type: application/json; charset=utf-8" -H "Host: $host" -H "X-TC-Action: $action" -H "X-TC-Timestamp: $timestamp" -H "X-TC-Version: $version" -H "X-TC-Region: $region" -H "X-TC-Token: $token"


      response=$(curl -s -XPOST "https://$host" -d "$payload" -H "Authorization: $authorization" -H "Content-Type: application/json; charset=utf-8" -H "Host: $host" -H "X-TC-Action: $action" -H "X-TC-Timestamp: $timestamp" -H "X-TC-Version: $version" -H "X-TC-Region: $region" -H "X-TC-Token: $token")
      echo "$response"

}


get_domain_list() {
    secret_id="$1"
    secret_key="$2"
    action="DescribeDomainList"
    payload="{}"
    echo $(send_request "$secret_id" "$secret_key" $action $payload)
}

get_domain_record_list() {
      secret_id="$1"
      secret_key="$2"
      input_domain="$3"
      action="DescribeRecordList"
      payload="{\"Domain\":\"$input_domain\"}"
      echo $(send_request "$secret_id" "$secret_key" $action $payload)
}


update_domain_ip() {
  # 1. 用户输入秘钥和payload信息
#domain_list_json=$(update_domain_ip "$secret_id" "$secret_key" "$selected_domain" "$subdomain" "$record_type" "$record_line" "$curl_ip" "$record_id")
  secret_id="$1"
  secret_key="$2"
  selected_domain="$3"
  subdomain="$4"
  record_type="$5"
  record_line="$6"
  curl_ip="$7"
  record_id="$8"
  # 构建payload

  action="ModifyRecord"

  payload="{\"Domain\":\"$selected_domain\",\"SubDomain\":\"$subdomain\",\"RecordType\":\"$record_type\",\"RecordLine\":\"$record_line\",\"Value\":\"$curl_ip\",\"RecordId\":$record_id}"

# echo $payload
#  payload="{\"Domain\":\"$domain\",\"SubDomain\":\"$subdomain\",\"RecordType\":\"$record_type\",\"RecordLine\":\"默认\",\"Value\":\"$value\",\"RecordId\":54370757}"

  echo $(send_request "$secret_id" "$secret_key" $action $payload)


}

is_valid_ip() {
    local ip=$1
    local ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    if [[ $ip =~ $ip_regex ]]; then
        return 0  # 返回 0 表示是有效的 IP 地址
    else
        return 1  # 返回 1 表示不是有效的 IP 地址
    fi
}


# 初始化变量
secret_id=""
secret_key=""
domain=""

# 解析命令行参数
for arg in "$@"; do
    case $arg in
        secret_id=*)
            secret_id="${arg#*=}"
            ;;
        secret_key=*)
            secret_key="${arg#*=}"
            ;;
        domain=*)
            domain="${arg#*=}"
            ;;
        *)
            # 未知参数，你可以根据需要进行处理
            echo "未知参数: $arg"
            ;;
    esac
done

# 检查必要参数是否都已提供
if [ -z "$secret_id" ] || [ -z "$secret_key" ] || [ -z "$domain" ]; then
        echo "缺少参数， 正确的启动参数为:"
        echo "./ddns.sh secret_id=1231231232123 secret_key=aaaaaaa domain=123.baidu.com"
        echo "secret_id和secret_key需要去以下网址申请："
        echo "https://console.cloud.tencent.com/cam/capi"
        echo ""
        echo "进入手工更新模式"
        # 步骤 0：用户输入秘钥
        read -p "请输入您的secret_id: " secret_id
        read -p "请输入您的secret_key: " secret_key

        token=""

        echo "开始获取域名列表"

        domain_list_json=$(get_domain_list "$secret_id" "$secret_key" )

#        echo "$domain_list_json"

        # 解析JSON并提取域名信息
        domain_list=$(echo "$domain_list_json" | jq -r '.Response.DomainList[] | "\(.Name)"')

        # 输出数字序号和域名
        echo "域名列表："
        index=1
        while IFS= read -r line; do
          echo "$index.$line"
          ((index++))
        done <<< "$domain_list"

        # 用户输入域名的数字序号
        read -p "请输入域名的数字序号: " selected_index

        # 获取用户选择的域名
        selected_domain=$(echo "$domain_list" | sed -n "${selected_index}p")
        echo $selected_domain


        echo "您选择的域名是: $selected_domain"

        # 从选定的域名中提取 DomainId
        domain_id=$(echo "$domain_list_json" | jq -r --arg selected_domain "$selected_domain" '.Response.DomainList[] | select(.Name == $selected_domain) | .DomainId')

        echo "选定的域名的 DomainId 值为: $domain_id"


        # 获取子域名列表

        domain_record_list_json=$(get_domain_record_list "$secret_id" "$secret_key" $selected_domain)

        # 解析返回的json，按照序号:Name:Type:Value的格式输出
        echo "$domain_record_list_json" | jq -r '.Response.RecordList | keys[] as $i | "\($i + 1):\(.[$i].Name):\(.[$i].Type):\(.[$i].Value)"'


        # 用户输入对应序号
        read -p "请输入序号查看详细信息: " selected_index

        # 输出用户选择的记录详细信息
        selected_record=$(echo "$domain_record_list_json" | jq -r ".Response.RecordList[$selected_index - 1]")
        echo "您选择的记录详细信息："
        echo "$selected_record"

        subdomain=$(echo "$selected_record" | jq -r '.Name')
        record_line=$(echo "$selected_record" | jq -r '.Line')
        record_line_id=$(echo "$selected_record" | jq -r '.LineId')
        record_type=$(echo "$selected_record" | jq -r '.Type')
        record_id=$(echo "$selected_record" | jq -r '.RecordId')
        record_ip=$(echo "$selected_record" | jq -r '.Value')


        # 获取指定域名的IP地址
        curl_ip=$(curl -s ip.zhuikan.com)
                if is_valid_ip "$curl_ip"; then
                    echo "curl 获取的 IP 地址为: $curl_ip，是一个有效的 IP 地址。"
                else
                    echo "curl 获取的 IP 地址为: $curl_ip，不符合 IP 地址的格式。"
                    exit 1
                fi


        # 比较两个IP是否一致
        if [ "$curl_ip" == "$record_ip" ]; then
                echo "用户选择的域名的IP地址$record_ip,与curl获取的IP地址一致。无需更新ip"
                exit
            else
                echo "用户选择的域名的IP地址$record_ip,与curl获取的IP地址不一致。现在开始更新ip"
        fi

        update_domian_result=$(update_domain_ip "$secret_id" "$secret_key" "$selected_domain" "$subdomain" "$record_type" "$record_line" "$curl_ip" "$record_id")

        echo $update_domian_result
else

        # 移除可能的协议部分（例如，https://）
        domain="${domain#*://}"

        # 使用正则表达式提取二级域名和根域名
        if [[ $domain =~ ^([a-zA-Z0-9-]+)\.([a-zA-Z0-9.-]+)$ ]]; then
                subdomain="${BASH_REMATCH[1]}"
                selected_domain="${BASH_REMATCH[2]}"

                echo "二级域名: $subdomain"
                echo "根域名: $selected_domain"
        else
                echo "无法提取有效的域名信息。"
        fi



        domain_list_json=$(get_domain_list "$secret_id" "$secret_key" )
        domain_id=$(echo "$domain_list_json" | jq -r --arg selected_domain "$selected_domain" '.Response.DomainList[] | select(.Name == $selected_domain) | .DomainId')

        domain_record_list_json=$(get_domain_record_list "$secret_id" "$secret_key" $selected_domain)

        # 使用jq工具解析JSON数据
        record_info=$(echo "$domain_record_list_json" | jq -r --arg subdomain "$subdomain" '.Response.RecordList[] | select(.Name == $subdomain)')

        # 检查是否找到匹配的记录
        if [ -n "$record_info" ]; then
            # 提取相关信息并赋值给变量
            record_ip=$(echo "$record_info" | jq -r '.Value')
            record_line=$(echo "$record_info" | jq -r '.Line')
            record_line_id=$(echo "$record_info" | jq -r '.LineId')
            record_type=$(echo "$record_info" | jq -r '.Type')
            record_id=$(echo "$record_info" | jq -r '.RecordId')

            # 输出结果（可选）
#            echo "Record IP: $record_ip"
#            echo "Record Line: $record_line"
#            echo "Record Line ID: $record_line_id"
#            echo "Record Type: $record_type"
#            echo "Record ID: $record_id"
        else
            echo "未找到满足条件的记录。"
        fi


        # 获取指定域名的IP地址
        curl_ip=$(curl -s ip.zhuikan.com)
        if is_valid_ip "$curl_ip"; then
            echo "curl 获取的 IP 地址为: $curl_ip，是一个有效的 IP 地址。"
        else
            echo "curl 获取的 IP 地址为: $curl_ip，不符合 IP 地址的格式。"
            exit 1
        fi


        # 比较两个IP是否一致
        if [ "$curl_ip" == "$record_ip" ]; then
              echo "用户选择的域名的IP地址为$record_ip，与curl获取的IP地址一致。无需更新ip"
              exit 0
        else
              echo "用户选择的域名的IP地址为$record_ip，与curl获取的IP地址不一致。开始更新ip"
#                      payload="{\"Domain\":\"$selected_domain\",\"SubDomain\":\"$subdomain\",\"RecordType\":\"$record_type\",\"RecordLine\":\"$record_line\",\"Value\":\"$curl_ip\",\"RecordId\":$record_id}"
#                      echo $payload
              update_domian_result=$(update_domain_ip "$secret_id" "$secret_key" "$selected_domain" "$subdomain" "$record_type" "$record_line" "$curl_ip" "$record_id")
              echo $update_domian_result
        fi

fi

