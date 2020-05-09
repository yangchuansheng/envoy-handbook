---
keywords:
- envoy
- listener
title: "监听器"
description: "本章节描述了 Envoy 监听器的概念及其配置结构。"
date: 2020-05-08T12:19:59+08:00
draft: false
weight: 1
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

+ **name** : 监听器名称。默认情况下，监听器名称的最大长度限制为 `60` 个字符。可以通过 `--max-obj-name-len` 命令行参数设置为所需的最大长度限制。
+ **address** : 监听器的监听地址，支持网络 Socket 和 `Unix Domain Socket`（UDS） 两种类型。
+ **filter_chains** : 过滤器链的配置。
+ **per_connection_buffer_limit_bytes** : 监听器每个新连接读取和写入缓冲区大小的软限制。默认值是 `1MB`。
+ **listener_filters** : 监听器过滤器在过滤器链之前执行，用于操纵连接的**元数据**。这样做的目的是，无需更改 Envoy 的核心代码就可以方便地集成更多功能。例如，当监听的地址协议是 `UDP` 时，就可以指定 UDP 监听器过滤器。
+ **listener_filters_timeout** : 等待所有监听器过滤器完成操作的超时时间。一旦超时就会关闭 `Socket`，不会创建连接，除非将参数 `continue_on_listener_filters_timeout` 设为 `true`。默认超时时间是 `15s`，如果设为 0 则表示禁用超时功能。
+ **continue_on_listener_filters_timeout** : 布尔值。用来决定监听器过滤器处理超时后是否创建连接，默认为 `false`。
+ **freebind** : 布尔值。用来决定是否设置 Socket 的 `IP_FREEBIND` 选项。如果设置为 true，则允许监听器绑定到本地并不存在的 IP 地址上。默认不设置。
+ **socket_options** : 额外的 `Socket` 选项。
+ **tcp_fast_open_queue_length** : 控制 **TCP 快速打开**（**T**CP **F**ast **O**pen，简称 `TFO`）。`TFO` 是对TCP 连接的一种简化握手手续的拓展，用于提高两端点间连接的打开速度。它通过握手开始时的 SYN 包中的 TFO cookie（一个 TCP 选项）来验证一个之前连接过的客户端。如果验证成功，它可以在三次握手最终的 `ACK` 包收到之前就开始发送数据，这样便跳过了一个绕路的行为，更在传输开始时就降低了延迟。该字段用来限制 `TFO cookie` 队列的长度，如果设为 0，则表示关闭 `TFO`。
+ **traffic_direction** : 定义流量的预期流向。有三个选项：`UNSPECIFIED`、`INBOUND` 和 `OUTBOUND`，分别代表未定义、入站流量和出站流量，默认是 `UNSPECIFIED`。
+ **udp_listener_config** : 如果 `address` 字段的类型是网络 Socket，且协议是 `UDP`，则使用该字段来指定 UDP 监听器。
+ **connection_balance_config** : 监听器连接的负载均衡配置，目前只支持 `TCP`。
+ **reuse_port** : 布尔值。用来决定是否设置 Socket 的 `SO_REUSEPORT` 选项。如果设置为 `true`，则会为每一个 `worker` 线程创建一个 Socket，在有大量连接的情况下，入站连接会均匀分布到各个 `worker` 线程中。如果设置为 `false`，所有的 worker 线程共享同一个 Socket。
+ **access_log** : 日志相关的配置。