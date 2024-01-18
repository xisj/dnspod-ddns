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


# 步骤 0：用户输入秘钥
read -p "请输入您的secret_id: " secret_id
read -p "请输入您的secret_key: " secret_key



token=""

domain_list_json=$(get_domain_list "$secret_id" "$secret_key" )

echo "$domain_list_json"

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


# 获取指定域名的IP地址
curl_ip=$(curl -s ip.zhuikan.com)
dns_ip=$(echo "$response" | jq -r ".Response.RecordList[$selected_index - 1].Value")

# 比较两个IP是否一致
if [ "$curl_ip" == "$dns_ip" ]; then
            echo "用户选择的域名的IP地址与curl获取的IP地址一致。"
    else
                echo "用户选择的域名的IP地址与curl获取的IP地址不一致。"
fi

#payload="{\"Domain\":\"$selected_domain\",\"SubDomain\":\"$subdomain\",\"RecordType\":\"$record_type\",\"RecordLine\":\"$record_line\",\"Value\":\"$curl_ip\",\"RecordId\":$record_id}"

#echo $payload

update_domian_result=$(update_domain_ip "$secret_id" "$secret_key" "$selected_domain" "$subdomain" "$record_type" "$record_line" "$curl_ip" "$record_id")

echo $update_domian_result
