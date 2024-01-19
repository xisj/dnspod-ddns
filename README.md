# dnspod-ddns
a simple dnspod-ddns shell
一个调用dnspod api 对ip 自动更新的简易脚本。 这个脚本使用最新的腾讯云api

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

### 群晖新建定时任务
假设已经将ddns.sh 拷贝到 /root 目录下

![图片](https://github.com/terry2010/dnspod-ddns/assets/1849037/291c6079-e70c-44e6-bfa4-e1acd3ca5c0c)

![图片](https://github.com/terry2010/dnspod-ddns/assets/1849037/b6decc09-5b24-4806-a769-975d7d408d49)

![图片](https://github.com/terry2010/dnspod-ddns/assets/1849037/ff295180-0fa0-479e-9003-3839709fc560)



