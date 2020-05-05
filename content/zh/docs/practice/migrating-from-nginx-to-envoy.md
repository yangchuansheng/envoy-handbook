---
keywords:
- envoy
- nginx
title: "从 Nginx 迁移到 Envoy Proxy"
description: "本章节将会带你了解 Envoy Proxy 的核心功能，以及如何将现有的 Nginx 配置文件迁移到 Envoy Proxy 中。"
date: 2020-05-02T15:27:54+08:00
draft: false
weight: 1
---

本章节主题是如何从 `Nginx` 迁移到 `Envoy Proxy`，你可以将任何以前的经验和对 Nginx 的理解直接应用于 `Envoy Proxy` 中。

主要内容：

+ 配置 Envoy Proxy 的 server 配置项
+ 配置 Envoy Proxy 以将流量代理到外部服务
+ 配置访问日志和错误日志

学完本教程之后，你将会了解 `Envoy Proxy` 的核心功能，以及如何将现有的 Nginx 配置文件迁移到 Envoy Proxy 中。

## Nginx 与 Envoy Proxy 的核心模块

先来看一个 Nginx 配置文件的完整示例，该配置文件取自于 [Nginx wiki](https://www.nginx.com/resources/wiki/start/topics/examples/fullexample2/)，内容如下：

```bash
$ cat nginx.conf

user  www www;
pid /var/run/nginx.pid;
worker_processes  2;

events {
  worker_connections   2000;
}

http {
  gzip on;
  gzip_min_length  1100;
  gzip_buffers     4 8k;
  gzip_types       text/plain;

  log_format main      '$remote_addr - $remote_user [$time_local]  '
    '"$request" $status $bytes_sent '
    '"$http_referer" "$http_user_agent" '
    '"$gzip_ratio"';

  log_format download  '$remote_addr - $remote_user [$time_local]  '
    '"$request" $status $bytes_sent '
    '"$http_referer" "$http_user_agent" '
    '"$http_range" "$sent_http_content_range"';


  upstream targetCluster {
    172.18.0.3:80;
    172.18.0.4:80;
  }

  server {
    listen        8080;
    server_name   one.example.com  www.one.example.com;

    access_log   /var/log/nginx.access_log  main;
    error_log  /var/log/nginx.error_log  info;

    location / {
      proxy_pass         http://targetCluster/;
      proxy_redirect     off;

      proxy_set_header   Host             $host;
      proxy_set_header   X-Real-IP        $remote_addr;
    }
  }
}
```

Nginx 的配置通常分为三个关键要素：

1. 配置 Server 块、日志和 `gzip` 功能，这些配置对全局生效，可以应用于所有示例。
2. 配置 Nginx 以接收 `8080` 端口上对域名 `one.example.com` 的访问请求。
3. 将 URL 的不同路径的流量转发到不同的目标后端。

并不是所有的 Nginx 配置项都适用于 Envoy Proxy，其中有一些配置在 Envoy 中可以忽略。Envoy Proxy 有四个关键组件，可以用来匹配 Nginx 的核心配置块：

+ **监听器（Listener）**：监听器定义了 Envoy 如何处理入站请求，目前 Envoy 仅支持基于 TCP 的监听器。一旦建立连接之后，就会将该请求传递给一组过滤器（filter）进行处理。
+ **过滤器（Filter）**：过滤器是处理入站和出站流量的链式结构的一部分。在过滤器链上可以集成很多特定功能的过滤器，例如，通过集成 `GZip` 过滤器可以在数据发送到客户端之前压缩数据。
+ **路由（Router）**：路由用来将流量转发到具体的目标实例，目标实例在 Envoy 中被定义为集群。
+ **集群（Cluster）**：集群定义了流量的目标端点，同时还包括一些其他可选配置，如负载均衡策略等。

接下来我们将使用这四个关键组件创建一个 Envoy Proxy 配置文件，以匹配前面定义的 Nginx 配置文件。

## Nginx 配置迁移

Nginx 配置文件的第一部分定义了 Nginx 本身运行的工作特性。

### Worker 连接数

下面的配置定义了 Nginx 的 worker 进程数和最大连接数，这表明了 Nginx 是如何通过自身的弹性能力来满足各种需求的。

```bash
worker_processes  2;

events {
  worker_connections   2000;
}
```

而 Envoy Proxy 则以不同的方式来管理 `Worker` 进程和连接。默认情况下，Envoy 为系统中的每个硬件线程生成一个工作线程。（可以通过 `--concurrency` 选项控制）。每个 `Worker` 线程是一个“非阻塞”事件循环，负责监听每个侦听器，接受新连接，为每个连接实例化过滤器栈，以及处理所有连接生命周期内 IO 事件。所有进一步的处理都在 `Worker` 线程内完成，其中包括转发。

Envoy 中的所有连接池都和 Worker 线程绑定。 尽管 `HTTP/2` 连接池一次只与每个上游主机建立一个连接，但如果有四个 Worker，则每个上游主机在稳定状态下将有四个 `HTTP/2` 连接。Envoy 以这种方式工作的原因是将所有连接都在单个 Worker 线程中处理，这样几乎所有代码都可以在无锁的情况下编写，就像它是单线程一样。拥有太多的 Worker 将浪费内存，创建更多空闲连接，并导致连接池命中率降低。

你可以在 [Envoy Proxy 博客](https://blog.envoyproxy.io/envoy-threading-model-a8d44b922310)上找到更多信息。

### HTTP 配置

Nginx 的下一个配置块是 HTTP 块，包括资源的媒体类型（mime type）、默认超时和 gzip 压缩配置。这些功能在 Envoy Proxy 中都是通过过滤器来实现的，下文将会详细讨论。

## Server 配置迁移

在 HTTP 配置块中，Nginx 配置指定了监听 8080 端口并接收对域名 `one.example.com` 和 `www.one.example.com` 的访问请求。

```bash
 server {
    listen        80;
    server_name   one.example.com  www.one.example.com;
```

这部分配置在 Envoy 中是由 `Listener` 管理的。

### Envoy 监听器

让 Envoy 能正常工作最重要的一步是定义监听器。首先需要创建一个配置文件用来描述 Envoy 的运行参数。

下面的配置项将创建一个新的监听器并将其绑定到 `8080` 端口。

```yaml
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address: { address: 0.0.0.0, port_value: 8080 }
```

这里不需要定义 `server_name`，域名将会交给过滤器来处理。

## Location 配置迁移

当请求进入 Nginx 时，Location 块定义了如何处理流量的元数据，以及如何转发处理后的流量。在下面的配置项中，进入站点的所有流量都被代理到名为 `targetCluster` 的上游集群。上游集群定了用来接收流量的后端实例，下一节再详细讨论。

```bash
location / {
    proxy_pass         http://targetCluster/;
    proxy_redirect     off;

    proxy_set_header   Host             $host;
    proxy_set_header   X-Real-IP        $remote_addr;
}
```

这部分配置在 Envoy 中是由过滤器管理的。

### Envoy 过滤器

对于静态配置文件而言，过滤器定义了如何处理传入请求。这里我们将会创建一个与上一节 Nginx 配置中的 `server_names` 相匹配的过滤器，当收到与过滤器中定义的域名和路由相匹配的入站请求时，就会将该请求的流量转发到指定的集群。这里的集群相当于 Nginx 中的 `upstream` 配置。

```yaml
filter_chains:
- filters:
  - name: envoy.http_connection_manager
    config:
      codec_type: auto
      stat_prefix: ingress_http
      route_config:
        name: local_route
        virtual_hosts:
        - name: backend
          domains:
            - "one.example.com"
            - "www.one.example.com"
          routes:
          - match:
              prefix: "/"
            route:
              cluster: targetCluster
      http_filters:
      - name: envoy.router
```

`envoy.http_connection_manager` 是 Envoy 中的内置 HTTP 过滤器。除了该过滤器，Envoy 中还内置了一些其他过滤器，包括 Redis、Mongo、TCP 等，完整的过滤器列表请参考 [Envoy 官方文档](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/listener/listener.proto#envoy-api-file-envoy-api-v2-listener-listener-proto)。

## Proxy 与 upstream 配置迁移

在 Nginx 中，`upstream` 配置项定义了用来接收流量的目标服务集群。下面的 upstream 配置项分配了两个后端实例：

```bash
upstream targetCluster {
  172.18.0.3:80;
  172.18.0.4:80;
}
```

这部分配置在 Envoy 中是由集群（Cluster）管理的。

### Envoy 集群

`upstream` 配置项在 Envoy 中被定义为 `Cluster`。Cluster 中的 `hosts` 列表用来处理被过滤器转发的流量，其中 `hosts` 的访问策略（例如超时）也在 `Cluster` 中进行配置，这有利于更精细化地控制超时和负载均衡。

```yaml
clusters:
- name: targetCluster
  connect_timeout: 0.25s
  type: STRICT_DNS
  dns_lookup_family: V4_ONLY
  lb_policy: ROUND_ROBIN
  hosts: [
    { socket_address: { address: 172.18.0.3, port_value: 80 }},
    { socket_address: { address: 172.18.0.4, port_value: 80 }}
  ]
```

当使用 `STRICT_DNS` 类型的服务发现时，Envoy 将持续并异步地解析指定的 DNS 目标。DNS 结果中每个返回的 IP 地址将被视为上游集群中的显式主机。这意味着如果查询返回三个 IP 地址，Envoy 将假定该集群有三台主机，并且所有三台主机应该负载均衡。如果有主机从 DNS 返回结果中删除，则 Envoy 会认为它不再存在，并且会将它从所有的当前连接池中排除。更多详细内容请参考 [Envoy 官方文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/service_discovery#strict-dns)。

## 日志配置迁移

最后一部分需要迁移的配置是应用日志。Envoy Proxy 默认情况下没有将日志持久化到磁盘中，而是遵循云原生方法，其中所有应用程序日志都输出到 `stdout` 和 `stderr`。

关于用户请求信息的访问日志属于可选项，默认情况下是禁用的。要为 HTTP 请求启用访问日志，请在 `envoy.http_connection_manager` 过滤器中添加 `access_log` 配置项，日志路径可以是块设备（如 stdout），也可以是磁盘上的文件，具体取决于你的需求。

下面的配置项将所有的访问日志传递给 stdout：

```yaml
access_log:
- name: envoy.file_access_log
  config:
    path: "/dev/stdout"
```


将该配置项复制到 `envoy.http_connection_manager` 过滤器的配置中，完整的过滤器配置如下：

```yaml
- name: envoy.http_connection_manager
  config:
    codec_type: auto
    stat_prefix: ingress_http
    access_log:
    - name: envoy.file_access_log
      config:
        path: "/dev/stdout"
    route_config:
```

Envoy 默认情况下使用格式化字符串来输出 HTTP 请求的详细日志：

```bash
[%START_TIME%] "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%"
%RESPONSE_CODE% %RESPONSE_FLAGS% %BYTES_RECEIVED% %BYTES_SENT% %DURATION%
%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%"
"%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%UPSTREAM_HOST%"\n
```

本示例中的日志输出如下所示：

```bash
[2018-11-23T04:51:00.281Z] "GET / HTTP/1.1" 200 - 0 58 4 1 "-" "curl/7.47.0" "f21ebd42-6770-4aa5-88d4-e56118165a7d" "one.example.com" "172.18.0.4:80"
```

可以通过设置格式化字段来自定义日志输出内容，例如：

```yaml
access_log:
- name: envoy.file_access_log
  config:
    path: "/dev/stdout"
    format: "[%START_TIME%] "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%" %RESPONSE_CODE% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%UPSTREAM_HOST%"\n"
```

你也可以通过设置 `json_format` 字段来输出 `JSON` 格式的日志，例如：

```yaml
access_log:
- name: envoy.file_access_log
  config:
    path: "/dev/stdout"
    json_format: {"protocol": "%PROTOCOL%", "duration": "%DURATION%", "request_method": "%REQ(:METHOD)%"}
```

关于 Envoy 日志配置的更多详细配置请参考 [https://www.envoyproxy.io/docs/envoy/latest/configuration/access_log#config-access-log-format-dictionaries](https://www.envoyproxy.io/docs/envoy/latest/configuration/access_log#config-access-log-format-dictionaries)。

在生产环境中使用 Envoy Proxy 时，日志不是获取可观察性的唯一方法，Envoy 中还内置了更高级的功能，如分布式追踪和监控指标。你可以在[分布式追踪文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/tracing)中找到更多详细内容。

完整的 Envoy 配置文件如下所示：

```yaml
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address: { address: 0.0.0.0, port_value: 8080 }
    filter_chains:
    - filters:
      - name: envoy.http_connection_manager
        config:
          codec_type: auto
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: backend
              domains:
                - "one.example.com"
                - "www.one.example.com"
              routes:
              - match:
                  prefix: "/"
                route:
                  cluster: targetCluster
          http_filters:
          - name: envoy.router
  clusters:
  - name: targetCluster
    connect_timeout: 0.25s
    type: STRICT_DNS
    dns_lookup_family: V4_ONLY
    lb_policy: ROUND_ROBIN
    hosts: [
      { socket_address: { address: 172.18.0.3, port_value: 80 }},
      { socket_address: { address: 172.18.0.4, port_value: 80 }}
    ]

admin:
  access_log_path: /tmp/admin_access.log
  address:
    socket_address: { address: 0.0.0.0, port_value: 9090 }
```

## 启动 Envoy Proxy

现在已经将 Nginx 的所有配置转化为 Envoy Proxy 的配置，接下来就是启动 Envoy 实例并进行测试。

### 以普通用户身份运行

在 Nginx 配置文件的顶部有一行配置 `user  www www;`，表示以低权限用户身份运行 Nginx 以提高安全性。而 Envoy 则采用云原生的方法来管理进程所有者，当我们通过容器来启动 Envoy Proxy 时，可以通过命令行参数来指定一个低权限用户。

### 启动 Envoy Proxy

下面的命令将通过容器启动 Envoy Proxy，该命令将 Envoy 容器暴露在 `80` 端口上以监听入站请求，但容器内的 Envoy Proxy 监听在 `8080` 端口上。通过 `--user` 参数以允许进程以低权限用户身份运行。

```bash
$ docker run --name proxy1 -p 80:8080 --user 1000:1000 -v /root/envoy.yaml:/etc/envoy/envoy.yaml envoyproxy/envoy
```

### 测试

启动代理之后，现在就可以进行访问测试了。下面的 `curl` 命令使用 Envoy 配置文件中定义的 请求头文件中的 `Host` 字段发出请求：

```bash
$ curl -H "Host: one.example.com" localhost -i
```

如果不出意外，该请求将会返回 `503` 错误，因为上游集群还没有运行，处于不可用状态，Envoy Proxy 找不到可用的目标后端来处理该请求。下面就来启动相应的 HTTP 服务：

```bash
$ docker run -d katacoda/docker-http-server
$ docker run -d katacoda/docker-http-server
```

启动这些服务之后，Envoy 就可以成功将流量代理到目标后端：

```bash
$ curl -H "Host: one.example.com" localhost -i
```

现在你应该会看到请求已被成功响应，并且可以从日志中看到哪个容器响应了该请求。

### 附加的 HTTP 响应头文件

如果请求成功，你会在请求的响应头文件中看到一些附加的字段，这些字段包含了上游主机处理请求所花费的时间（以毫秒为单位）。如果客户端想要确定因为网络延迟导致的请求处理延时，这些字段将会很有帮助。

```bash
x-envoy-upstream-service-time: 0
server: envoy
```
