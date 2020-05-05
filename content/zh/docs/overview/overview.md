---
title: "Envoy 介绍"
date: 2020-05-02T14:04:05+08:00
draft: false
weight: 1
---

`Envoy` 是专为大型现代 SOA（面向服务架构）架构设计的 L7 代理和通信总线，体积小，性能高。它的诞生源于以下理念：

> 对应用程序而言，网络应该是透明的。当网络和应用程序出现故障时，应该能够很容易确定问题的根源。

## 核心功能

实际上，实现上述的目标是非常困难的。为了做到这一点，Envoy 提供了以下高级功能：

+ **非侵入的架构** : `Envoy` 是一个独立进程，设计为伴随每个应用程序服务运行。所有的 `Envoy` 形成一个透明的通信网格，每个应用程序发送消息到本地主机或从本地主机接收消息，不需要知道网络拓扑，对服务的实现语言也完全无感知，这种模式也被称为 `Sidecar`。 

  ![](https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200430142752.png)

+ 由 `C++` 语言实现，拥有强大的定制化能力和优异的性能。

+ **L3/L4/L7 架构** : 传统的网络代理，要么在 `HTTP` 层工作，要么在 `TCP` 层工作。在 `HTTP` 层的话，你将会从传输线路上读取整个 `HTTP` 请求的数据，对它做解析，查看 `HTTP` 头部和 `URL`，并决定接下来要做什么。随后，你将从后端读取整个响应的数据，并将其发送给客户端。但这种做法的缺点就是非常复杂和缓慢，更好的选择是下沉到 `TCP` 层操作：只读取和写入字节，并使用 `IP` 地址，`TCP` 端口号等来决定如何处理事务，但无法根据不同的 `URL` 代理到不同的后端。`Envoy` 支持同时在 3/4 层和 7 层操作，以此应对这两种方法各自都有其实际限制的现实。

+ **顶级 HTTP/2 支持** : 它将 `HTTP/2` 视为一等公民，并且可以在 `HTTP/2` 和 `HTTP/1.1` 之间相互转换（双向），建议使用 `HTTP/2`。

+ **服务发现和动态配置** : 与 `Nginx` 等代理的热加载不同，`Envoy` 可以通过 `API` 来实现其控制平面，控制平面可以集中服务发现，并通过 `API` 接口动态更新数据平面的配置，不需要重启数据平面的代理。不仅如此，控制平面还可以通过 API 将配置进行分层，然后逐层更新，例如：上游集群中的虚拟主机、`HTTP` 路由、监听的套接字等。

+ **gRPC 支持** : [gRPC](http://www.grpc.io/) 是一个来自 `Google` 的 `RPC` 框架，它使用 `HTTP/2` 作为底层多路复用传输协议。Envoy 完美支持 HTTP/2，也可以很方便地支持 `gRPC`。

+ **特殊协议支持** : Envoy 支持对特殊协议在 L7 进行嗅探和统计，包括：[MongoDB](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/mongo_proxy_filter#)、[DynamoDB](https://www.servicemesher.com/envoy/intro/arch_overview/dynamo.html#arch-overview-dynamo) 等。

+ **可观测性** : `Envoy` 的主要目标是使网络透明，可以生成许多流量方面的统计数据，这是其它代理软件很难取代的地方，内置 `stats` 模块，可以集成诸如 `prometheus/statsd` 等监控方案。还可以集成分布式追踪系统，对请求进行追踪。

## 设计目标

Envoy 官方的设计目标是这么说的：

{{< notice info >}}
Envoy 并不是很慢（我们已经花了相当长的时间来优化关键路径）。基于模块化编码，易于测试，而不是性能最优。我们的观点是，在其他语言或者运行效率低很多的系统中，部署和使用 Envoy 能够带来很好的运行效率。
{{< /notice >}}

虽然 `Envoy` 没有把追求极致的性能作为首要目标，但并不表示 `Envoy` 是没有追求的，只是扩展性优先，性能稍微靠边。Envoy 和 `Nginx` 一样，也采用了 **多线程 + 非阻塞 + 异步IO（Libevent）** 的架构，性能仍然很强悍。

## 参考资料

+ [Envoy 是什么？](https://www.servicemesher.com/envoy/intro/what_is_envoy.html)
+ [Lyft Envoy入门教程](http://dockone.io/article/8212)