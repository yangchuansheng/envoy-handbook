<div align="center">
  <p>
    <b>Envoy 中文指南 - 从入门到实践进阶手册 👋</b>
  </p>
  <p>
     <i>Envoy 是专为大型现代 SOA（面向服务架构）架构设计的 L7 代理和通信总线，体积小，性能高，它通过一款单一的软件满足了我们的众多需求，而不需要我们去搭配一些工具混合使用。本指南包括了本人平时在使用 Envoy 时的参考指南和实践总结，形成一个系统化的参考指南以方便查阅。欢迎大家关注和添加完善内容。</i>
  </p>
  <p>
  
  [![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/yangchuansheng/envoy-handbook/)
  [![Website](https://img.shields.io/website?url=https%3A%2F%2Fpostwoman.io&logo=Postwoman)](https://fuckcloudnative.io/envoy-handbook/)
  [![Chat on Telegram](https://img.shields.io/badge/chat-Telegram-blueviolet?logo=Telegram)](https://t.me/gsealyun)

  </p>
</div>

---

### 🏠 [Homepage](https://fuckcloudnative.io/envoy-handbook/)

**文档: _[中文文档](https://fuckcloudnative.io/envoy-handbook/), [英文文档](https://www.envoyproxy.io/docs/envoy/latest)，[博客](https://fuckcloudnative.io)_**

**加入组织: _[Telegram](https://t.me/gsealyun)_**

![](https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200504160047.png)

## 👋 为什么选择 Envoy

### 非侵入架构

Envoy 是一个独立进程，设计为伴随每个应用程序服务运行。所有的 Envoy 形成一个透明的通信网格，每个应用程序发送消息到本地主机或从本地主机接收消息，不需要知道网络拓扑，对服务的实现语言也完全无感知，这种模式也被称为 Sidecar。

![](https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200430142752.png)

### L3/L4/L7 架构

传统的网络代理，要么在 HTTP 层工作，要么在 TCP 层工作。Envoy 支持同时在 3/4 层和 7 层操作，以此应对这两种方法各自都有其实际限制的现实。 

### 动态更新

与 Nginx 等代理的热加载不同，Envoy 可以通过 API 来实现其控制平面，控制平面可以集中服务发现，并通过 API 接口动态下发规则更新数据平面的配置，不需要重启数据平面的代理。

## ✅ Envoy 的特性

- [x] 非侵入的架构
- [x] 由 C++ 语言实现，拥有强大的定制化能力和优异的性能
- [x] L3/L4/L7 架构
- [x] 顶级 HTTP/2 支持
- [x] 服务发现和动态配置
- [x] gRPC 支持
- [x] 特殊协议支持
- [x] 可观测性

## 作者

👤 **米开朗基杨**

* Github: [@yangchuansheng](https://github.com/yangchuansheng)
* Wechat: yangchuansheng572887

## 支持我

如果觉得这个项目对你有帮助，请给我一个 ⭐️ 吧！