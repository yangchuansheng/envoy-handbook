---
keywords:
- envoy
- getenvoy
title: "快速开始"
description: "使用 Envoy 作为边缘代理"
date: 2020-05-02T15:27:54+08:00
draft: false
weight: 2
---

安装完成后，可以通过下面的例子快速体验 `Envoy` 的功能。

本文的示例使用 `Envoy` 作为边缘代理，根据不同的路由配置将请求转发到百度和 `Bing`。指定请求头 `host: baidu.com` 时会将请求转发到 `www.baidu.com`；指定请求头 `host: bing.com` 时会将请求转发到 `cn.bing.com`。

## 配置

Envoy 使用 `YAMl` 配置来控制代理的行为，为了快速开始，我们可以从 `GetEnvoy` 项目上下载静态配置的示例：

```bash
$ wget https://getenvoy.io/samples/basic-front-proxy.yaml
```

{{< notice note >}}
Envoy 代理使用[开源 xDS API](https://www.envoyproxy.io/docs/envoy/latest/api/api) 来交换信息，目前 xDS v2 已被废弃，最新版本的 Envoy 不再支持 xDS v2，建议使用 xDS v3。
{{< /notice >}}

由于国内不可描述的网络原因，最好将示例中的 `google` 改成 `baidu`，**并将 xDS API 改为 v3**，改完后完整的配置文件如下：

{{< expand "basic-front-proxy.yaml" >}}
```yaml
static_resources:
  listeners:
  - address:
      # Tells Envoy to listen on 0.0.0.0:15001
      socket_address:
        address: 0.0.0.0
        port_value: 15001
    filter_chains:
    # Any requests received on this address are sent through this chain of filters
    - filters:
      # If the request is HTTP it will pass through this HTTP filter
      - name: envoy.filters.network.http_connection_manager 
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          codec_type: auto
          stat_prefix: http
        access_log:
          name: envoy.access_loggers.file
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
            path: /dev/stdout
          route_config:
            name: search_route
            virtual_hosts:
            - name: backend
              domains:
              - "*"
              routes:
              # Match on host (:authority in HTTP2) headers
              - match:
                  prefix: "/"
                  headers:
                    - name: ":authority"
                      exact_match: "baidu.com"
                route:
                  # Send request to an endpoint in the Google cluster
                  cluster: baidu
                  host_rewrite_literal: www.baidu.com
              - match:
                  prefix: "/"
                  headers:
                    - name: ":authority"
                      exact_match: "bing.com"
                route:
                  # Send request to an endpoint in the Bing cluster
                  cluster: bing
                  host_rewrite_literal: cn.bing.com
          http_filters:
          - name: envoy.filters.http.router
  clusters:
  - name: baidu
    connect_timeout: 1s
    # Instruct Envoy to continouously resolve DNS of www.google.com asynchronously
    type: logical_dns 
    dns_lookup_family: V4_ONLY
    lb_policy: round_robin
    load_assignment:
      cluster_name: baidu
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: www.baidu.com
                port_value: 80
  - name: bing
    connect_timeout: 1s
    # Instruct Envoy to continouously resolve DNS of www.bing.com asynchronously
    type: logical_dns
    dns_lookup_family: V4_ONLY
    lb_policy: round_robin
    load_assignment:
      cluster_name: bing
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: cn.bing.com
                port_value: 80
admin:
  access_log_path: "/dev/stdout"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 15000
```
{{< /expand >}}

第一次使用 Envoy，可能会觉得它的配置太复杂了，让人眼花缭乱。其实不然，我们不妨先脑补一下网络代理程序的流程，比如作为一个代理，首先要能获取请求流量，通常是采用监听端口的方式实现；其次拿到请求数据后需要对其做微处理，例如附加 `Header` 或校验某个 `Header` 字段的内容等，这里针对来源数据的层次不同，可以分为 `L3/L4/L7`，然后将请求转发出去；转发这里又可以衍生出如果后端是一个集群，需要从中挑选一台机器，如何挑选又涉及到负载均衡等。

脑补完大致流程后，再来看 Envoy 是如何组织配置信息的，先简单解释一下其中的关键字段，详细的解释可以看后面的章节。

+ `listener` : Envoy 的监听地址，就是真正干活的。Envoy 会暴露一个或多个 Listener 来监听客户端的请求。
+ `filter` : 过滤器。在 Envoy 中指的是一些“可插拔”和可组合的逻辑处理层，是 Envoy 核心逻辑处理单元。
+ `route_config` : 路由规则配置。即将请求路由到后端的哪个集群。
+ `cluster` : 服务提供方集群。Envoy 通过服务发现定位集群成员并获取服务，具体路由到哪个集群成员由负载均衡策略决定。

结合关键字段和上面的脑补流程，可以看出 Envoy 的大致处理流程如下：

![](https://jsdelivr.icloudnative.io/gh/yangchuansheng/imghosting1@main/img/20210722124550.webp)

Envoy 内部对请求的处理流程其实跟我们上面脑补的流程大致相同，即对请求的处理流程基本是不变的，而对于变化的部分，即对请求数据的微处理，全部抽象为 `Filter`，例如对请求的读写是 `ReadFilter`、`WriteFilter`，对 `HTTP` 请求数据的编解码是 `StreamEncoderFilter`、`StreamDecoderFilter`，对 `TCP` 的处理是 `TcpProxyFilter`，其继承自 `ReadFilter`，对 `HTTP` 的处理是 `ConnectionManager`，其也是继承自 `ReadFilter` 等等，各个 Filter 最终会组织成一个 `FilterChain`，在收到请求后首先走 `FilterChain`，其次路由到指定集群并做负载均衡获取一个目标地址，然后转发出去。

## 启动 Envoy

配置完成后，就可以通过静态配置文件直接启动 Envoy 了：

```bash
$ envoy -c ./basic-front-proxy.yaml
```

打开一个新的 shell，使用 `curl` 访问 Envoy，并添加 `Header` 字段 `host: baidu.com`：

```bash
$ curl -s -o /dev/null -vvv -H 'Host: baidu.com' 127.0.0.1:15001

* Rebuilt URL to: 127.0.0.1:15001/
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to 127.0.0.1 (127.0.0.1) port 15001 (#0)
> GET / HTTP/1.1
> Host: baidu.com
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< accept-ranges: bytes
< cache-control: private, no-cache, no-store, proxy-revalidate, no-transform
< content-length: 2381
< content-type: text/html
< date: Sun, 03 May 2020 09:46:59 GMT
< etag: "588604c8-94d"
< last-modified: Mon, 23 Jan 2017 13:27:36 GMT
< pragma: no-cache
< server: envoy
< set-cookie: BDORZ=27315; max-age=86400; domain=.baidu.com; path=/
< x-envoy-upstream-service-time: 19
<
{ [1048 bytes data]
* Connection #0 to host 127.0.0.1 left intact
```

可以看到请求被转发到了 `baidu.com`，并且在转发的时候将 host 修改成了 `www.baidu.com`。访问时去掉参数 `-s -o /dev/null` 可以看到完整的响应内容：

```bash
$ curl -vvv -H 'Host: baidu.com' 127.0.0.1:15001

* Rebuilt URL to: 127.0.0.1:15001/
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to 127.0.0.1 (127.0.0.1) port 15001 (#0)
> GET / HTTP/1.1
> Host: baidu.com
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< accept-ranges: bytes
< cache-control: private, no-cache, no-store, proxy-revalidate, no-transform
< content-length: 2381
< content-type: text/html
< date: Sun, 03 May 2020 09:50:07 GMT
< etag: "588604c8-94d"
< last-modified: Mon, 23 Jan 2017 13:27:36 GMT
< pragma: no-cache
< server: envoy
< set-cookie: BDORZ=27315; max-age=86400; domain=.baidu.com; path=/
< x-envoy-upstream-service-time: 37
<
<!DOCTYPE html>
<!--STATUS OK--><html> <head><meta http-equiv=content-type content=text/html;charset=utf-8><meta http-equiv=X-UA-Compatible content=IE=Edge><meta content=always name=referrer><link rel=stylesheet type=text/css href=http://s1.bdstatic.com/r/www/cache/bdorz/baidu.min.css><title>百度一下，你就知道</title></head> <body link=#0000cc> <div id=wrapper> <div id=head> <div class=head_wrapper> <div class=s_form> <div class=s_form_wrapper> <div id=lg> <img hidefocus=true src=//www.baidu.com/img/bd_logo1.png width=270 height=129> </div> <form id=form name=f action=//www.baidu.com/s class=fm> <input type=hidden name=bdorz_come value=1> <input type=hidden name=ie value=utf-8> <input type=hidden name=f value=8> <input type=hidden name=rsv_bp value=1> <input type=hidden name=rsv_idx value=1> <input type=hidden name=tn value=baidu><span class="bg s_ipt_wr"><input id=kw name=wd class=s_ipt value maxlength=255 autocomplete=off autofocus></span><span class="bg s_btn_wr"><input type=submit id=su value=百度一下 class="bg s_btn"></span> </form> </div> </div> <div id=u1> <a href=http://news.baidu.com name=tj_trnews class=mnav>新闻</a> <a href=http://www.hao123.com name=tj_trhao123 class=mnav>hao123</a> <a href=http://map.baidu.com name=tj_trmap class=mnav>地图</a> <a href=http://v.baidu.com name=tj_trvideo class=mnav>视频</a> <a href=http://tieba.baidu.com name=tj_trtieba class=mnav>贴吧</a> <noscript> <a href=http://www.baidu.com/bdorz/login.gif?login&amp;tpl=mn&amp;u=http%3A%2F%2Fwww.baidu.com%2f%3fbdorz_come%3d1 name=tj_login class=lb>登录</a> </noscript> <script>document.write('<a href="http://www.baidu.com/bdorz/login.gif?login&tpl=mn&u='+ encodeURIComponent(window.location.href+ (window.location.search === "" ? "?" : "&")+ "bdorz_come=1")+ '" name="tj_login" class="lb">登录</a>');</script> <a href=//www.baidu.com/more/ name=tj_briicon class=bri style="display: block;">更多产品</a> </div> </div> </div> <div id=ftCon> <div id=ftConw> <p id=lh> <a href=http://home.baidu.com>关于百度</a> <a href=http://ir.baidu.com>About Baidu</a> </p> <p id=cp>&copy;2017&nbsp;Baidu&nbsp;<a href=http://www.baidu.com/duty/>使用百度前必读</a>&nbsp; <a href=http://jianyi.baidu.com/ class=cp-feedback>意见反馈</a>&nbsp;京ICP证030173号&nbsp; <img src=//www.baidu.com/img/gs.gif> </p> </div> </div> </div> </body> </html>
* Connection #0 to host 127.0.0.1 left intact
```

同理可以访问 `bing.com`：

```bash
$ curl -s -o /dev/null -vvv -H 'Host: bing.com' localhost:15001

...
* Connected to 127.0.0.1 (127.0.0.1) port 15001 (#0)
> GET / HTTP/1.1
> Host: bing.com
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< cache-control: private, max-age=0
< content-length: 112683
< content-type: text/html; charset=utf-8
< p3p: CP="NON UNI COM NAV STA LOC CURa DEVa PSAa PSDa OUR IND"
< set-cookie: SRCHD=AF=NOFORM; domain=.bing.com; expires=Tue, 03-May-2022 13:08:55 GMT; path=/
< set-cookie: SRCHUID=V=2&GUID=D8E47780338144C587A3F6EC1D831373&dmnchg=1; domain=.bing.com; expires=Tue, 03-May-2022 13:08:55 GMT; path=/
< set-cookie: SRCHUSR=DOB=20200503; domain=.bing.com; expires=Tue, 03-May-2022 13:08:55 GMT; path=/
< set-cookie: _SS=SID=3E6E525A1E406DCF27B15CE51F6E6C28; domain=.bing.com; path=/
< x-msedge-ref: Ref A: BB80A686B64D4DCAB5713DB6ADF294C8 Ref B: BJ1EDGE0217 Ref C: 2020-05-03T13:08:55Z
< set-cookie: _EDGE_S=F=1&SID=3E6E525A1E406DCF27B15CE51F6E6C28; path=/; httponly; domain=bing.com
< set-cookie: _EDGE_V=1; path=/; httponly; expires=Fri, 28-May-2021 13:08:55 GMT; domain=bing.com
< set-cookie: MUID=20CC7B7828C26CF93BE175C729EC6D8A; samesite=none; path=/; secure; expires=Fri, 28-May-2021 13:08:55 GMT; domain=bing.com
< set-cookie: MUIDB=20CC7B7828C26CF93BE175C729EC6D8A; path=/; httponly; expires=Fri, 28-May-2021 13:08:55 GMT
< date: Sun, 03 May 2020 13:08:53 GMT
< x-envoy-upstream-service-time: 151
< server: envoy
<
{ [6069 bytes data]
```

查看 Envoy 的日志：

```bash
[2020-05-03T13:10:39.968Z] "GET / HTTP/1.1" 200 - 0 2381 50 49 "-" "curl/7.54.0" "201f8fe4-3446-4063-b6f2-b6289100529a" "www.baidu.com" "198.18.5.232:80"
[2020-05-03T13:10:47.501Z] "GET / HTTP/1.1" 200 - 0 112348 263 160 "-" "curl/7.54.0" "d291ec6b-3669-426a-8f79-9be696d8c97a" "cn.bing.com" "198.18.10.118:80"
```

可以看到这两个不同的请求都得到了正确响应。

## 参考资料

+ [浅谈 Service Mesh 体系中的 Envoy](https://juejin.im/entry/5b4818a5f265da0f9a2cd57d)