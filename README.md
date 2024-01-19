# dnspod-ddns
a simple dnspod-ddns shell
一个调用dnspod api 对ip 自动更新的简易脚本。 

## 使用方法
### 手工更新域名ip
```
./ddns.sh
```
按提示依次填入数据即可
### 自动更新域名ip
```
./ddns.sh secret_id=1231231232123 secret_key=aaaaaaa domain=123.baidu.com
```
dnspod 操作域名所需的  secret_id和secret_key需要去以下网址申请： https://console.cloud.tencent.com/cam/capi
#### 注意：泄露 secret_id和secret_key 可能导致域名被盗，所以要绝对保证这两个数据的安全

### 定时自动更新域名ip

启动一个定时任务，按需更新即可
