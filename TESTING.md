# 多版本 Ruby 测试指南

本项目支持 Ruby 2.7, 3.0, 3.1, 3.2 和 3.3。

## 📁 多版本 Gemfile 结构

本项目使用独立的 Gemfile 管理不同 Ruby 版本的依赖：

```
gemfiles/
├── Gemfile.ruby-2.7       # Ruby 2.7.x 专用
├── Gemfile.ruby-2.7.lock
├── Gemfile.ruby-3.0       # Ruby 3.0.x 专用
├── Gemfile.ruby-3.0.lock
├── Gemfile.ruby-3.1       # Ruby 3.1.x 专用
├── Gemfile.ruby-3.1.lock
└── README.md              # 详细说明
```

**为什么需要多个 Gemfile？**
- flexmock: Ruby 2.7 使用 2.x，Ruby 3.0+ 使用 3.x
- nokogiri: 不同版本有不同的兼容性要求
- net-* gems: Ruby 3.1+ 需要显式声明
- 避免单一 Gemfile.lock 的版本冲突

详细说明请查看 `gemfiles/README.md`。

## 本地测试

### 方法一：快速兼容性测试（推荐）

运行以下命令快速测试所有 Ruby 版本的基本兼容性：

```bash
./test_multi_ruby.sh
```

此脚本会：
- 自动切换 Ruby 版本
- **自动选择对应的版本特定 Gemfile**
- 安装所有依赖（包括开发依赖）
- 测试 gem 加载是否成功
- 运行完整测试套件
- 显示详细的测试结果

**优点**：
- ✅ 每个版本使用最优化的依赖
- ✅ 无版本冲突
- ✅ 可重现的构建

### 方法二：完整测试套件

运行完整的测试套件（包含单元测试）：

```bash
./test_multi_ruby_full.sh
```

此脚本会：
- 安装所有依赖（包括开发依赖）
- 运行完整的测试套件
- 验证所有功能

**注意**：在 ARM Mac 上，旧版本 Ruby (2.7.6) 可能无法编译 nokogiri（jeweler 的依赖）。如果遇到编译问题，使用方法一即可。

### 方法三：手动测试单个版本

使用版本特定的 Gemfile：

```bash
# 1. 切换到目标 Ruby 版本
rbenv local 3.1.7

# 2. 使用对应的 Gemfile 安装依赖
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle install

# 3. 测试 gem 加载
ruby -I lib -e "require 'aws/ses'; puts 'Success with Ruby ' + RUBY_VERSION"

# 4. 运行测试
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle exec rake test

# 5. 恢复默认 Ruby 版本
rbenv local --unset
```

**提示**：可以设置环境变量避免重复输入：
```bash
export BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1
bundle install
bundle exec rake test
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
