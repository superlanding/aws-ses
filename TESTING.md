# 多版本 Ruby 测试指南

本项目支持 Ruby 2.7, 3.0, 3.1, 3.2 和 3.3。

## 本地测试

### 方法一：使用自动化脚本（推荐）

运行以下命令测试所有 Ruby 版本：

```bash
./test_multi_ruby.sh
```

此脚本会：
- 自动切换 Ruby 版本
- 安装依赖
- 测试 gem 加载
- 运行测试套件
- 显示详细的测试结果

### 方法二：手动测试单个版本

```bash
# 1. 切换到目标 Ruby 版本
rbenv local 3.1.7

# 2. 清理旧的依赖
rm -f Gemfile.lock

# 3. 安装依赖
bundle install

# 4. 测试 gem 加载
ruby -I lib -e "require 'aws/ses'; puts 'Success with Ruby ' + RUBY_VERSION"

# 5. 运行测试
bundle exec rake test

# 6. 恢复默认 Ruby 版本
rbenv local --unset
```

### 安装所需的 Ruby 版本

如果缺少某些 Ruby 版本，可以使用以下命令安装：

```bash
rbenv install 2.7.6
rbenv install 3.0.7
rbenv install 3.1.7
```

## CI/CD 自动化测试

本项目配置了 GitHub Actions，会在以下情况自动运行测试：
- Push 到 master/main 分支
- 创建 Pull Request

GitHub Actions 会在以下 Ruby 版本上运行测试：
- Ruby 2.7
- Ruby 3.0
- Ruby 3.1
- Ruby 3.2
- Ruby 3.3

查看 `.github/workflows/ruby_compatibility.yml` 了解详情。

## 常见问题

### Gemfile.lock 冲突

不同 Ruby 版本可能生成不同的 Gemfile.lock。建议：
- 在切换版本前删除 `Gemfile.lock`
- 或者不提交 `Gemfile.lock` 到版本控制

### 测试失败但 gem 加载成功

某些测试可能需要 AWS 凭证才能通过。只要 gem 能成功加载，就表示基本兼容性没问题。

### nokogiri 编译错误（仅开发依赖）

如果遇到 nokogiri 编译问题（jeweler 的依赖），可以：
```bash
bundle config build.nokogiri --use-system-libraries
bundle install
```

或者跳过开发依赖：
```bash
bundle install --without development
```
