---
keywords:
- envoy
- getenvoy
title: "安装"
description: "本文介绍了如何使用 GetEnvoy 项目和 Docker 来安装 Envoy。"
date: 2020-05-02T15:27:54+08:00
draft: false
weight: 1
---

## GetEnvoy

`Envoy` 本身是很难编译的，需要使用到项目构建工具 [Bazel](https://docs.bazel.build/versions/master/install.html)，为了解决这个问题，`Tetrate` 的工程师（包括 Envoy 的核心贡献者和维护者）发起了 [GetEnvoy](https://www.getenvoy.io) 项目，目标是利用一套经过验证的构建工具来构建 Envoy，并通过常用的软件包管理器来分发，包括：`apt`、`yum` 和 `Homebrew`。安装方式如下：

{{< tabs MacOS CentOS Ubuntu >}}
  {{< tab >}}

  ```bash
  $ brew update

  $ brew install envoy
  ==> Installing envoy

  ==> Downloading https://ghcr.io/v2/homebrew/core/envoy/manifests/1.18.3-1
  ######################################################################## 100.0%
  ==> Downloading https://ghcr.io/v2/homebrew/core/envoy/blobs/sha256:d03fb86b48336c8d3c0f3711cfc3df3557f9fb33c966ceb1caecae1653935e90
  ######################################################################## 100.0%
  ==> Pouring envoy--1.18.3.big_sur.bottle.1.tar.gz
  🍺  /usr/local/Cellar/envoy/1.18.3: 300 files, 119.5MB
  ```

  {{< /tab >}}
  {{< tab >}}

  ```bash
# 安装 yum-config-manager 
$ yum install -y yum-utils
# 添加 Envoy 仓库
$ yum-config-manager --add-repo https://getenvoy.io/linux/centos/tetrate-getenvoy.repo
# 安装 Envoy
$ yum install -y getenvoy-envoy
  ```

  {{< /tab >}}
  {{< tab >}}

  ```bash
# 更新 apt 索引 
$ apt update
# 安装 HTTPS 依赖
$ apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg2 \
  software-properties-common
# 添加 Tetrate GPG 密钥
$ curl -sL 'https://getenvoy.io/gpg' | sudo apt-key add -
# 通过指纹验证密钥
$ apt-key fingerprint 6FF974DB | grep "5270 CEAC"
pub   4096R/6FF974DB 2019-03-01
  Key fingerprint = 5270 CEAC 57F6 3EBD 9EA9  005D 0253 D0B2 6FF9 74DB
uid                  GetEnvoy <getenvoy@tetrate.io>
sub   4096R/7767A960 2019-03-01
# 添加仓库
$ add-apt-repository \
  "deb [arch=amd64] https://dl.bintray.com/tetrate/getenvoy-deb \
  $(lsb_release -cs) \
  stable"
# 安装 Envoy
$ apt update && apt install -y getenvoy-envoy
  ```

  {{< /tab >}}
{{< /tabs >}}

## Docker

`Envoy` 社区不提供已经编译好的二进制的文件，只提供了 `Docker` 镜像（当然现在有 `GetEnvoy` 项目了）。社区提供的镜像位于 [envoyproxy](https://hub.docker.com/u/envoyproxy) 中，常用的有：

+ [envoyproxy/envoy-alpine](https://hub.docker.com/r/envoyproxy/envoy-alpine/tags) : 基于 `alpine` 的发行镜像
+ [envoyproxy/envoy-alpine-dev](https://hub.docker.com/r/envoyproxy/envoy-alpine-dev/tags) : 基于 `alpine` 的 `Nightly` 版本发行镜像
+ [envoyproxy/envoy](https://hub.docker.com/r/envoyproxy/envoy/tags) : 基于 `Ubuntu` 的发行镜像
+ [envoyproxy/envoy-dev](https://hub.docker.com/r/envoyproxy/envoy-dev/tags) : 基于 `Ubuntu` 的 `Nightly` 版本发行镜像

获取镜像：

```bash
$ docker pull envoyproxy/envoy:v1.18.3
```

启动 Envoy 容器时，可以用本地的 `envoy.yaml` 覆盖镜像中的 `envoy.yaml`：

```bash
🐳 → docker run -d --network=host -v `pwd`/envoy.yaml:/etc/envoy/envoy.yaml envoyproxy/envoy:v1.18.3
```

## Windows

Envoy 官方还提供了 Windows 平台的 Docker 镜像，使用方式很简单：

```bash
$ docker pull envoyproxy/envoy-windows-dev:latest
$ docker run --rm envoyproxy/envoy-windows-dev:latest --version
```

## 参考资料

+ [Installing Envoy](https://www.envoyproxy.io/docs/envoy/v1.18.3/start/install)