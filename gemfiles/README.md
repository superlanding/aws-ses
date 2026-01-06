# 多版本 Ruby Gemfile 管理

本目录包含针对不同 Ruby 版本优化的 Gemfile 和 Gemfile.lock。

## 文件结构

```
gemfiles/
├── Gemfile.ruby-2.7       # Ruby 2.7.x 的 Gemfile
├── Gemfile.ruby-2.7.lock  # Ruby 2.7.x 的 Gemfile.lock
├── Gemfile.ruby-3.0       # Ruby 3.0.x 的 Gemfile
├── Gemfile.ruby-3.0.lock  # Ruby 3.0.x 的 Gemfile.lock
├── Gemfile.ruby-3.1       # Ruby 3.1.x 的 Gemfile
├── Gemfile.ruby-3.1.lock  # Ruby 3.1.x 的 Gemfile.lock
└── README.md              # 本文件
```

## 为什么需要多个 Gemfile？

### 1. **依赖版本差异**
不同 Ruby 版本需要不同版本的依赖：

- **flexmock**:
  - Ruby 2.7: 使用 `>= 2.4, < 3.0` (2.x 系列)
  - Ruby 3.0+: 使用 `>= 3.0` (3.x 系列支持关键字参数)

- **nokogiri**:
  - Ruby 2.7: 约束为 `~> 1.15.0` (兼容性考虑)
  - Ruby 3.0+: 使用 `>= 1.15.0` (最新版本)

- **net-* gems**:
  - Ruby 3.1+: 需要显式声明 `net-imap`, `net-pop`, `net-smtp`

### 2. **避免版本冲突**
单一 Gemfile.lock 无法满足所有 Ruby 版本的需求，会导致：
- 在 Ruby 2.7 上安装失败（某些 gem 要求 Ruby 3.0+）
- 在 Ruby 3.1 上运行时缺少标准库 gem
- Bundler 版本不一致警告

### 3. **优化依赖树**
每个版本使用最适合的依赖版本，而不是妥协的"最小公分母"。

## 使用方法

### 自动化测试（推荐）

测试脚本会自动选择对应的 Gemfile：

```bash
# 快速测试所有版本
./test_multi_ruby.sh

# 完整测试所有版本
./test_multi_ruby_full.sh
```

### 手动使用特定版本

```bash
# 切换到目标 Ruby 版本
rbenv local 3.1.7

# 使用对应的 Gemfile 安装依赖
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle install

# 运行命令
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle exec rake test

# 或者设置环境变量（在当前 shell 会话中生效）
export BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1
bundle install
bundle exec rake test
```

### 生成新的 Gemfile.lock

如果你修改了某个 Gemfile，需要重新生成 lock 文件：

```bash
# 示例：为 Ruby 3.1 重新生成 lock 文件
rbenv local 3.1.7
rm gemfiles/Gemfile.ruby-3.1.lock
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle install
```

## 版本特定说明

### Ruby 2.7
- 使用 flexmock 2.x 系列（3.x 仅支持 Ruby 3.0+）
- nokogiri 约束为 ~> 1.15.0（避免更新版本的兼容性问题）
- 不需要显式声明 net-* gems（仍在标准库中）

### Ruby 3.0
- 使用 flexmock 3.x 系列（支持关键字参数）
- 可以使用最新版本的 nokogiri
- net-* gems 已从标准库移除，但 mail gem 会自动引入

### Ruby 3.1
- 与 Ruby 3.0 类似
- 显式声明 net-imap、net-pop、net-smtp（最佳实践）
- 支持所有最新的 gem 版本

## 维护指南

### 添加新的 Ruby 版本

1. 创建新的 Gemfile：
```bash
cp gemfiles/Gemfile.ruby-3.1 gemfiles/Gemfile.ruby-3.2
```

2. 根据需要调整依赖版本

3. 生成 lock 文件：
```bash
rbenv local 3.2.x
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.2 bundle install
```

4. 更新测试脚本中的 `RUBY_VERSIONS` 数组

### 更新依赖

当需要更新某个 gem 的版本时：

1. 编辑对应的 Gemfile
2. 删除对应的 .lock 文件
3. 重新运行 `bundle install`
4. 测试确保没有破坏性变更

## Git 管理建议

### 应该提交的文件
```
✅ gemfiles/Gemfile.ruby-*       # 依赖声明
✅ gemfiles/Gemfile.ruby-*.lock  # 锁定的版本
✅ gemfiles/README.md            # 说明文档
```

### 为什么要提交 .lock 文件？
1. **可重现构建**: 确保所有开发者和 CI 使用相同的依赖版本
2. **版本隔离**: 每个 Ruby 版本的依赖树是独立的
3. **调试方便**: 可以追踪依赖变更历史

## 故障排除

### 问题：Bundler 版本不匹配警告
```bash
Warning: the running version of Bundler (2.2.33) is older than the version
that created the lockfile (2.3.14).
```

**解决方案**：忽略此警告，或升级 Bundler：
```bash
gem install bundler:2.3.14
```

### 问题：在 ARM Mac 上编译 nokogiri 失败
**解决方案**：使用系统库：
```bash
bundle config build.nokogiri --use-system-libraries
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-2.7 bundle install
```

### 问题：找不到某个 gem
**解决方案**：确保使用了正确的 Gemfile：
```bash
# 检查当前使用的 Gemfile
echo $BUNDLE_GEMFILE

# 或明确指定
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle exec rake test
```

## CI/CD 集成

### GitHub Actions 示例

```yaml
strategy:
  matrix:
    ruby: ['2.7', '3.0', '3.1']

steps:
  - uses: ruby/setup-ruby@v1
    with:
      ruby-version: ${{ matrix.ruby }}
      bundler-cache: true
      cache-version: ${{ matrix.ruby }}
      working-directory: gemfiles
      gemfile: gemfiles/Gemfile.ruby-${{ matrix.ruby }}
```

详细配置见 `.github/workflows/ruby_compatibility.yml`。

## 参考资源

- [Bundler BUNDLE_GEMFILE 环境变量](https://bundler.io/man/bundle-config.1.html)
- [Ruby Compatibility Table](https://www.fastruby.io/blog/ruby/rails/versions/compatibility-table.html)
- [flexmock Ruby 3 支持](https://github.com/doudou/flexmock/releases)
