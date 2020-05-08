---
title: Envoy 中文指南 
description: Envoy 从入门到实践进阶手册
date: 2020-01-26T04:15:05+09:00
draft: false
updatesBanner: "会魔法？ - &nbsp; [加入组织](https://t.me/gsealyun) &nbsp; 深入交流"
landing:
  height: 500
  image: https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200501224554.png 
  title:
    - Envoy 中文指南
  text:
    - 从入门到实践进阶手册 
  titleColor:
  textColor: 
  spaceBetweenTitleText: 25
  buttons:
    - link: docs/gettingstarted/setup/ 
      text: 快速开始
      color: primary
    - link: docs/practice/ 
      text: 入门实践 
      color: default
  #backgroundImage: 
  #  src: https://hugo-picture.oss-cn-beijing.aliyuncs.com/2020-04-20-envoy_proxy.webp 
  #  height: 600
footer:
  sections:
    - title: 关于我们 
      links:
        - message: 更多精彩内容请关注微信公众号
          img: https://hugo-picture.oss-cn-beijing.aliyuncs.com/2020-04-20-20200405205151.webp 
    - title: 更多资料 
      links:
        - title: Envoy 官方文档
          link: https://www.envoyproxy.io/docs/envoy/latest/ 
        - title: Sealyun 
          link: https://sealyun.com/
        - title: Envoy 创始人博客
          link: https://mattklein123.dev/
    - title: 联系
      links:
        - message: 微信扫码加入高手如云群
          img: https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200430221955.png 
  contents: 
    align: left
    applySinglePageCss: false 
    markdown:
      |
      ## Envoy 中文指南 
      Copyright © 2020. [云原生实验室](https://fuckcloudnative.io)

sections:
  - bgcolor: teal
    type: card
    description: "Envoy 是专为大型现代 SOA（面向服务架构）架构设计的 L7 代理和通信总线，体积小，性能高，它通过一款单一的软件满足了我们的众多需求，而不需要我们去搭配一些工具混合使用。"
    header: 
      title: 为什么选择 Envoy
      hlcolor: "#8bc34a"
      color: '#fff'
      fontSize: 32
      width: 220
    cards:
      - subtitle: SidaCar 模式 
        subtitlePosition: center
        description: "Envoy 是一个独立进程，设计为伴随每个应用程序服务运行。所有的 Envoy 形成一个透明的通信网格，每个应用程序发送消息到本地主机或从本地主机接收消息，不需要知道网络拓扑。"
        image: https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200508201806.png 
        color: white
        button: 
          name: 更多
          link: docs/overview/sidecar/ 
          size: large
          # target: _blank
          color: 'white'
          bgcolor: '#283593'
      - subtitle: L3/L4/L7 架构 
        subtitlePosition: center
        description: "传统的网络代理，要么在 HTTP 层工作，要么在 TCP 层工作。Envoy 支持同时在 3/4 层和 7 层操作，以此应对这两种方法各自都有其实际限制的现实。"
        image: https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200508202645.png 
        color: white
        button: 
          name: 更多
          link: docs/overview/overview/ 
          size: large
          # target: _blank
          color: 'white'
          bgcolor: '#283593'
      - subtitle: 动态更新 
        subtitlePosition: center
        description: "与 Nginx 等代理的热加载不同，Envoy 可以通过 API 来实现其控制平面，控制平面可以集中服务发现，并通过 API 接口动态下发规则更新数据平面的配置，不需要重启数据平面的代理。"
        image: https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200508202858.png 
        color: white
        button: 
          name: 更多
          link: docs/overview/overview/ 
          size: large
          # target: _blank
          color: 'white'
          bgcolor: '#283593'
  - bgcolor: DarkSlateBlue
    type: normal
    description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce id eleifend erat. Integer eget mattis augue. Suspendisse semper laoreet tortor sed convallis. Nulla ac euismod lorem"
    header:
      title: 架构 
      hlcolor: DarkKhaki
      color: "#fff"
      fontSize: 32
      width: 340
    body:
      subtitle: 
      subtitlePosition: left
      description: ""
      color: white
      image: https://cdn.jsdelivr.net/gh/yangchuansheng/imghosting/img/20200504160047.png 
      imagePosition: left 
---
