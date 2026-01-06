# Gemfile 迁移指南

## 📋 变更摘要

项目现在使用独立的版本特定 Gemfile，而不是单一的 Gemfile。

### 变更前
```
Gemfile          # 单一 Gemfile for all Ruby versions
Gemfile.lock     # 单一 lock 文件（版本冲突）
```

### 变更后
```
Gemfile          # 保留（向后兼容）
gemfiles/
├── Gemfile.ruby-2.7       # Ruby 2.7.x 专用
├── Gemfile.ruby-2.7.lock
├── Gemfile.ruby-3.0       # Ruby 3.0.x 专用
├── Gemfile.ruby-3.0.lock
├── Gemfile.ruby-3.1       # Ruby 3.1.x 专用
└── Gemfile.ruby-3.1.lock
```

## 🎯 为什么要迁移？

### 问题 1: 依赖版本冲突
单一 Gemfile.lock 无法满足所有 Ruby 版本：

- **flexmock**:
  - Ruby 2.7 只能用 2.x (不支持 Ruby 3 的关键字参数)
  - Ruby 3.0+ 需要 3.x (支持关键字参数)
  
- **nokogiri**:
  - Ruby 2.7 在 ARM Mac 上编译 1.16+ 困难
  - Ruby 3.0+ 可以使用最新版本

- **net-* gems**:
  - Ruby 2.7/3.0: 在标准库中，不需要声明
  - Ruby 3.1+: 需要显式添加到 Gemfile

### 问题 2: Bundler 警告
```
Warning: the running version of Bundler (2.2.33) is older than 
the version that created the lockfile (2.3.14).
```
不同 Ruby 版本自带不同版本的 Bundler。

### 问题 3: 无法优化
使用"最小公分母"版本约束，无法利用新版本的改进。

## 🔄 如何使用新结构

### 自动化测试（推荐）

测试脚本自动处理：

```bash
./test_multi_ruby.sh        # 快速测试
./test_multi_ruby_full.sh   # 完整测试
```

### 手动使用

**之前**：
```bash
rbenv local 3.1.7
bundle install
bundle exec rake test
```

**现在**：
```bash
rbenv local 3.1.7
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle install
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle exec rake test
```

或设置环境变量：
```bash
export BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1
bundle install
bundle exec rake test
```

### 开发工作流

**场景 1: 开发新功能**
```bash
# 使用你的主要开发版本
rbenv local 3.1.7
export BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1
bundle install

# 正常开发
bundle exec rake test
bundle exec rake
```

**场景 2: 测试兼容性**
```bash
# 快速测试所有版本
./test_multi_ruby.sh
```

**场景 3: 添加新依赖**
```bash
# 1. 编辑所有相关的 Gemfile
vim gemfiles/Gemfile.ruby-2.7
vim gemfiles/Gemfile.ruby-3.0
vim gemfiles/Gemfile.ruby-3.1

# 2. 重新生成 lock 文件
rbenv local 2.7.6 && BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-2.7 bundle install
rbenv local 3.0.7 && BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.0 bundle install
rbenv local 3.1.7 && BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle install

# 3. 测试
./test_multi_ruby.sh
```

## 📝 IDE/编辑器配置

### RubyMine / IntelliJ IDEA

1. 打开 Settings → Languages & Frameworks → Ruby SDK and Gems
2. 对于每个 Ruby SDK，设置 Bundler path：
   - Ruby 2.7: `gemfiles/Gemfile.ruby-2.7`
   - Ruby 3.0: `gemfiles/Gemfile.ruby-3.0`
   - Ruby 3.1: `gemfiles/Gemfile.ruby-3.1`

或者在项目根目录创建 `.idea/runConfigurations/` 配置文件，指定 `BUNDLE_GEMFILE` 环境变量。

### VS Code

在 `.vscode/settings.json` 添加：

```json
{
  "ruby.rubocop.configFilePath": ".rubocop.yml",
  "ruby.useLanguageServer": true,
  "ruby.intellisense": "rubyLocate",
  "terminal.integrated.env.osx": {
    "BUNDLE_GEMFILE": "${workspaceFolder}/gemfiles/Gemfile.ruby-3.1"
  }
}
```

### 终端别名

在 `~/.zshrc` 或 `~/.bashrc` 添加：

```bash
# aws-ses project
alias b27='BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-2.7 bundle'
alias b30='BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.0 bundle'
alias b31='BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle'

# 使用方式
# b27 install
# b27 exec rake test
```

## 🚫 常见错误

### 错误 1: 忘记设置 BUNDLE_GEMFILE

**症状**：
```
Could not find rake-13.3.1 in any of the sources
```

**原因**：使用了根目录的 Gemfile 而不是版本特定的

**解决**：
```bash
export BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1
bundle install
```

### 错误 2: 使用错误版本的 Gemfile

**症状**：
```
LoadError: cannot load such file -- some_gem
```

**原因**：Ruby 版本和 Gemfile 不匹配

**解决**：
```bash
# 确保 Ruby 版本和 Gemfile 匹配
ruby -v  # 检查当前 Ruby 版本
echo $BUNDLE_GEMFILE  # 检查当前 Gemfile

# Ruby 2.7 应该使用
export BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-2.7
```

### 错误 3: lock 文件冲突

**症状**：
```
Your bundle is locked to ... but your Gemfile requires ...
```

**解决**：
```bash
# 删除并重新生成 lock 文件
rm gemfiles/Gemfile.ruby-3.1.lock
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle install
```

## 🔍 故障排除命令

```bash
# 检查当前环境
echo "Ruby: $(ruby -v)"
echo "Bundler: $(bundle -v)"
echo "Gemfile: $BUNDLE_GEMFILE"

# 查看已安装的 gems
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle list

# 检查某个 gem 的版本
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle show flexmock

# 清理并重装
rm -rf .bundle
BUNDLE_GEMFILE=gemfiles/Gemfile.ruby-3.1 bundle install
```

## 📚 更多信息

- **详细说明**: `gemfiles/README.md`
- **测试指南**: `TESTING.md`
- **兼容性总结**: `COMPATIBILITY_SUMMARY.md`

## ❓ FAQ

**Q: 我可以继续使用根目录的 Gemfile 吗？**  
A: 可以，但可能遇到版本冲突。建议使用版本特定的 Gemfile。

**Q: 为什么要提交 .lock 文件？**  
A: 确保可重现构建和追踪依赖变更历史。

**Q: CI/CD 如何配置？**  
A: 查看 `.github/workflows/ruby_compatibility.yml` 示例。

**Q: 如何添加新的 Ruby 版本（如 3.2）？**  
A: 复制最接近的 Gemfile，调整依赖，生成 lock 文件。详见 `gemfiles/README.md`。
