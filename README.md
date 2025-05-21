# 闪电云探针监控面板
### demo :  [https://tz.mjj.link](https://tz.mjj.link)。

## 客户端安装与升级
### linux
```
bash <(curl -Ls https://raw.githubusercontent.com/zzzzpro/shandian_v1/master/client_install.sh)
bash <(curl -Ls https://raw.githubusercontent.com/zzzzpro/shandian_v1/master/client_install.sh) http://your_server_ip:port
```
配置格式：http://1.1.1.1:9999
建议使用域名
### windows
下载tag中最新的exe
cmd 中 首先执行 status_client_x64.exe serverurl

安装成服务使用管理员执行 status_client_x64.exe install


## 服务端安装
```
bash <(curl -Ls https://raw.githubusercontent.com/zzzzpro/shandian_v1/master/server_install.sh)
```

### web
反代http://localhost:9999 及 ws
```
location / {proxy_redirect off;proxy_set_header Host $host;proxy_set_header X-Real-IP $remote_addr;proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;proxy_pass http://127.0.0.1:9999;}

location /ws {proxy_redirect off;proxy_intercept_errors on;proxy_pass http://127.0.0.1:9999;proxy_http_version 1.1;proxy_set_header Upgrade $http_upgrade;proxy_set_header Connection "upgrade";proxy_set_header Host $http_host;proxy_read_timeout 300s;}
```



 前端修改自 [Akile](https://github.com/akile-network/akile_monitor_fe) , 感谢6B。
