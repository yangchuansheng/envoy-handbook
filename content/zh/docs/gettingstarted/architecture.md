---
keywords:
- envoy
- xds
- listen filter
title: "Envoy 架构与配置结构"
description: "本章节描述了 Envoy 的整体架构、Filter 的架构以及配置结构"
date: 2020-05-02T15:27:54+08:00
draft: false
weight: 3
---

## Envoy 架构

Envoy 的架构如图所示：

![](https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200504160047.png)

Envoy 接收到请求后，会先走 `FilterChain`，通过各种 L3/L4/L7 Filter 对请求进行微处理，然后再路由到指定的集群，并通过负载均衡获取一个目标地址，最后再转发出去。

其中每一个环节可以静态配置，也可以动态服务发现，也就是所谓的 `xDS`。这里的 `x` 是一个代词，类似云计算里的 `XaaS` 可以指代 IaaS、PaaS、SaaS 等。

## 配置结构

Envoy 的整体配置结构如下：

```json
{
  "node": "{...}",
  "static_resources": "{...}",
  "dynamic_resources": "{...}",
  "cluster_manager": "{...}",
  "hds_config": "{...}",
  "flags_path": "...",
  "stats_sinks": [],
  "stats_config": "{...}",
  "stats_flush_interval": "{...}",
  "watchdog": "{...}",
  "tracing": "{...}",
  "runtime": "{...}",
  "layered_runtime": "{...}",
  "admin": "{...}",
  "overload_manager": "{...}",
  "enable_dispatcher_stats": "...",
  "header_prefix": "...",
  "stats_server_version_override": "{...}",
  "use_tcp_for_dns_lookups": "..."
}
```

+ **node** : 节点标识，配置的是 Envoy 的标记信息，management server 利用它来标识不同的 Envoy 实例。参考 [core.Node](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/core/base.proto#envoy-api-msg-core-node)
+ **static_resources** : 定义静态配置，是 Envoy 核心工作需要的资源，由 `Listener`、`Cluster` 和 `Secret` 三部分组成。参考 [config.bootstrap.v2.Bootstrap.StaticResources](https://www.envoyproxy.io/docs/envoy/latest/api-v2/config/bootstrap/v2/bootstrap.proto#envoy-api-msg-config-bootstrap-v2-bootstrap-staticresources)
+ **dynamic_resources** : 定义动态配置，通过 `xDS` 来获取配置。可以同时配置动态和静态。
+ **cluster_manager** : 管理所有的上游集群。它封装了连接后端服务的操作，当 `Filter` 认为可以建立连接时，便调用 `cluster_manager` 的 API 来建立连接。`cluster_manager` 负责处理负载均衡、健康检查等细节。
+ **hds_config** : 健康检查服务发现动态配置。
+ **stats_sinks** : 状态输出插件。可以将状态数据输出到多种采集系统中。一般通过 Envoy 的管理接口 `/stats/prometheus` 就可以获取 `Prometheus` 格式的指标，这里的配置应该是为了支持其他的监控系统。
+ **stats_config** : 状态指标配置。
+ **stats_flush_interval** : 状态指标刷新时间。
+ **watchdog** : 看门狗配置。Envoy 内置了一个看门狗系统，可以在 Envoy 没有响应时增加相应的计数器，并根据计数来决定是否关闭 Envoy 服务。
+ **tracing** : 分布式追踪相关配置。
+ **runtime** : 运行时状态配置（已弃用）。
+ **layered_runtime** : 层级化的运行时状态配置。可以静态配置，也可以通过 `RTDS` 动态加载配置。
+ **admin** : 管理接口。
+ **overload_manager** : 过载过滤器。
+ **header_prefix** : Header 字段前缀修改。例如，如果将该字段设为 `X-Foo`，那么 Header 中的 `x-envoy-retry-on` 将被会变成 `x-foo-retry-on`。
+ **use_tcp_for_dns_lookups** : 强制使用 `TCP` 查询 `DNS`。可以在 `Cluster` 的配置中覆盖此配置。

## 过滤器

Envoy 进程中运行着一系列 `Inbound/Outbound` 监听器（Listener），`Inbound` 代理入站流量，`Outbound` 代理出站流量。Listener 的核心就是过滤器链（FilterChain），链中每个过滤器都能够控制流量的处理流程。过滤器链中的过滤器分为两个类别：

+ **网络过滤器**（Network Filters）: 工作在 `L3/L4`，是 Envoy 网络连接处理的核心，处理的是原始字节，分为 `Read`、`Write` 和 `Read/Write` 三类。
+ **HTTP 过滤器**（HTTP Filters）: 工作在 `L7`，由特殊的网络过滤器 `HTTP connection manager` 管理，专门处理 `HTTP1/HTTP2/gRPC` 请求。它将原始字节转换成 `HTTP` 格式，从而可以对 `HTTP` 协议进行精确控制。

除了 `HTTP connection manager` 之外，还有一种特别的网络过滤器叫 `Thrift Proxy`。`Thrift` 是一套包含序列化功能和支持服务通信的 RPC 框架，详情参考[维基百科](https://zh.wikipedia.org/wiki/Thrift)。Thrift Proxy 管理了两个 Filter：[Router](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_protocols/thrift_filters/router_filter) 和 [Rate Limit](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_protocols/thrift_filters/rate_limit_filter)。

除了过滤器链之外，还有一种过滤器叫**监听器过滤器**（Listener Filters），它会在过滤器链之前执行，用于操纵连接的**元数据**。这样做的目的是，无需更改 Envoy 的核心代码就可以方便地集成更多功能。例如，当监听的地址协议是 `UDP` 时，就可以指定 UDP 监听器过滤器。

根据上面的分类，Envoy 过滤器的架构如下图所示：

![](https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200504224710.png)

