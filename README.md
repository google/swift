# Google Swift Style Guide 中文版[长期维护项目]

这是 [Google Swift Style Guide 中文版](http://pages.swift.gg/google-swift-style-guide-in-chinese/) 的网站源码。

## 原文地址

[英文原版在线版](https://google.github.io/swift/)

[英文原版源码](https://github.com/google/swift/tree/gh-pages)

## 更新记录

- 2019.12.16 检查更新

- 2019.09.02 检查更新

- 2019.08.23 完成初稿
  * 原文 [节点](https://github.com/google/swift/commit/79459b39f2ab0330ee05a90f20c3f716d8406b24)，2019.06.05

## 贡献力量

如果想做出贡献的话，你可以：

- 参与翻译
- 帮忙校对，挑错别字、病句等等
- 提出修改建议
- 提出术语翻译建议
- 提醒原文有更新

## 翻译建议

如果你有兴趣参与项目，请仔细阅读说明：

排版格式和流程说明：

- 翻译排版格式要求参考 SwiftGG [排版指南](https://github.com/SwiftGGTeam/translation/blob/master/SwiftGG%20排版指南.md)
- Pull Request 发起方式参考 SwiftGG [Pull Request 说明](https://github.com/SwiftGGTeam/translation/blob/master/翻译流程概述及PR说明.md#如何发起-pull-request)

其他说明：

- 相关术语请严格按照术语表来翻译，如果有问题可以发 Issue 大家一起讨论
- 翻译修改 index.md 即可，然后 Pull Request 中只包含此文件，我们会编译成网页发布
- 有其他任何问题都欢迎发 Issue

## 本地开发&测试

1. 安装 Ruby >= 2.0.0。
2. `gem install bundler` —— 需要 root 权限。
3. `bundle install`。
4. `LC_ALL=en_us.UTF-8 bundle exec jekyll serve --baseurl /swift-style`
5. 查看 [http://localhost:4000/swift-style/](http://localhost:4000/swift-style/)。
6. 修改源码、刷新、重复直到完成。

注意:

* 更改了 `_config.yml` 之后需要重新启动本地服务 (步骤 4)。
*  `_config.yml` 的更改不要在 Pull Request 中提交。
