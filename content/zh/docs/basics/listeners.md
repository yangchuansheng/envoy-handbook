---
keywords:
- envoy
- listener
title: "监听器"
description: "本章节描述了 Envoy 监听器的概念及其配置结构。"
date: 2020-05-06T12:19:59+08:00
draft: false
weight: 3
---

## 监听器（Listener）

**监听器**（`Listener`）就是 Envoy 的监听地址，可以是端口或 `Unix Socket`。Envoy 在单个进程中支持任意数量的监听器。通常建议每台机器只运行一个 Envoy 实例，每个 Envoy 实例的监听器数量没有限制，这样可以简化操作，统计数据也只有一个来源，比较方便统计。目前 Envoy 支持监听 `TCP` 协议和 `UDP` 协议。

### TCP

每个监听器都可以配置多个过[滤器链（Filter Chains）](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener_components.proto#envoy-v3-api-msg-config-listener-v3-filterchain)，监听器会根据 `filter_chain_match` 中的[匹配条件](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener_components.proto#envoy-v3-api-msg-config-listener-v3-filterchainmatch)将流量转交到对应的过滤器链，其中每一个过滤器链都由一个或多个**网络过滤器**（`Network filters`）组成。这些过滤器用于执行不同的代理任务，如速率限制，`TLS` 客户端认证，`HTTP` 连接管理，`MongoDB` 嗅探，原始 TCP 代理等。

除了过滤器链之外，还有一种过滤器叫**监听器过滤器**（Listener filters），它会在过滤器链之前执行，用于操纵连接的**元数据**。这样做的目的是，无需更改 Envoy 的核心代码就可以方便地集成更多功能。例如，当监听的地址协议是 `UDP` 时，就可以指定 UDP 监听器过滤器。

### UDP

Envoy 的监听器也支持 `UDP` 协议，需要在监听器过滤器中指定一种 **UDP 监听器过滤器**（UDP listener filters）。目前有两种 UDP 监听器过滤器：**UDP 代理**（UDP proxy） 和 **DNS 过滤器**（DNSfilter）。UDP 监听器过滤器会被每个 `worker` 线程实例化，且全局生效。实际上，UDP 监听器（UDP Listener）配置了内核参数 `SO_REUSEPORT`，这样内核就会将 UDP 四元组相同的数据散列到同一个 `worker` 线程上。因此，UDP 监听器过滤器是允许面向会话（session）的。

## 监听器配置结构

监听器的配置结构如下：

```json
{
  "name": "...",
  "address": "{...}",
  "filter_chains": [],
  "per_connection_buffer_limit_bytes": "{...}",
  "metadata": "{...}",
  "drain_type": "...",
  "listener_filters": [],
  "listener_filters_timeout": "{...}",
  "continue_on_listener_filters_timeout": "...",
  "transparent": "{...}",
  "freebind": "{...}",
  "socket_options": [],
  "tcp_fast_open_queue_length": "{...}",
  "traffic_direction": "...",
  "udp_listener_config": "{...}",
  "api_listener": "{...}",
  "connection_balance_config": "{...}",
  "reuse_port": "...",
  "access_log": []
}
```

