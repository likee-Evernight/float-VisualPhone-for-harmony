# Float · VisualPhone for HarmonyOS

[English](./README.md) · **中文**

把 [xiaolongbao0709/ai-virtual-phone](https://github.com/xiaolongbao0709/ai-virtual-phone) 打包成鸿蒙 HAP 应用的第三方壳，全屏离线运行。

> 本项目仅为上游 Web 项目提供鸿蒙运行容器，**不修改上游任何业务代码**。

## 特性

- **完全离线运行**：Next.js 静态产物内嵌到 HAP，不依赖 Web 服务器
- **全屏适配**：自适应鸿蒙设备分辨率，无手机壳装饰，内容铺满整个屏幕
- **单机模式**：默认启用 `NEXT_PUBLIC_SELF_HOSTED_MODE=true`，跳过账号门禁
- **保留上游全部单机功能**：聊天、角色卡、世界书、游戏、3D 搭建等

## 环境要求

| 工具 | 版本 |
|---|---|
| DevEco Studio | 5.x |
| HarmonyOS SDK | API 12+ |
| Node.js | 20+（构建上游 Web 项目用） |

## 构建步骤

### 1. 构建上游 Web 项目

```bash
git clone https://github.com/xiaolongbao0709/ai-virtual-phone
cd ai-virtual-phone
```

修改 `next.config.mjs`，加入静态导出配置：

```javascript
const nextConfig = {
   output: 'export',
   assetPrefix: './',
   images: { unoptimized: true },
   // ... 保留其他原有配置
};
```

构建静态产物：

```bash
NEXT_PUBLIC_SELF_HOSTED_MODE=true npm run build
```

成功后会在项目根目录生成 `out/` 目录。

### 2. 复制静态文件

把 `out/` 目录里的**所有内容**复制到本项目的：

```
entry/src/main/resources/rawfile/
```

### 3. 配置签名

1. 复制示例配置：

   ```bash
   cp build-profile-example.json5 build-profile.json5
   ```

2. 用 DevEco Studio 打开本项目

3. `File → Project Structure → Signing Configs` → 勾选 `Automatically generate signature`

4. 登录华为开发者账号，IDE 会自动写入签名信息到 `build-profile.json5`

### 4. 构建 HAP

`Build → Build Hap(s)/APP(s) → Build Hap(s)`

产物在：

```
entry/build/default/outputs/default/entry-default-signed.hap
```

## 包名

```
io.github.xiaolongbao.likeeevernight.float
```

## 项目结构

```
float-visualphone-harmony/
├── AppScope/
│   ├── app.json5                # 应用配置（bundleName、版本号）
│   └── resources/               # 应用图标、名称
├── entry/
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/    # UIAbility 入口（全屏设置）
│   │   │   └── pages/Index.ets  # WebView 主页面（资源拦截、CSS 注入）
│   │   ├── resources/
│   │   │   └── rawfile/         # ★ 上游 Web 静态产物放这里
│   │   └── module.json5         # 模块配置、权限
│   └── build-profile.json5
├── build-profile-example.json5  # 应用级签名配置模板（无签名）
└── README.md
```

## 核心实现说明

### `Index.ets` 的关键技术点

1. **虚拟域名 + SchemeHandler 拦截**  
   把 `https://app.local/` 的请求映射到 `rawfile/` 里的本地文件，绕过 ArkWeb 对 `resource://` 的跨域限制。

2. **HTML 注入**  
   在响应 `index.html` 时，把一段 `<script>` 注入到 `<head>` 最前面，抢在项目代码之前执行。

3. **CSS 覆盖**  
   针对 `.phone-shell` / `.phone-case` / `.phone-frame` 等容器，强制清零 `padding`、`margin`、`border`、`background`，并设置 `100vw × 100vh` 撑满全屏。

4. **环境伪装**  
   覆盖 `navigator.maxTouchPoints`、`matchMedia`、`screen.orientation` 等，让项目以为运行在手机浏览器上。

### `EntryAbility.ets` 的关键技术点

- `setWindowLayoutFullScreen(true)` 让内容延伸到状态栏和导航栏下
- `setWindowSystemBarProperties` 把系统栏设为透明、图标黑色

## 上游项目

- **作者**：xiaolongbao0709
- **仓库**：https://github.com/xiaolongbao0709/ai-virtual-phone
- **协议**：AGPL-3.0-only

## 已知限制

- 只支持鸿蒙设备（HAP 格式）
- 需要用户自行构建上游 `out/` 目录并复制到 `rawfile/`（本仓库不含 Web 产物，尊重上游版权）
- 社区功能（账号、应用市场、游戏大厅等）在上游单机模式下已自动隐藏

## License

**AGPL-3.0-only**（与上游项目保持一致）

上游项目采用 GNU Affero General Public License v3.0 only 开源，本壳项目作为衍生作品，遵循同一协议。详见 [LICENSE](./LICENSE)。

## 致谢

- 上游 Web 项目作者 [xiaolongbao0709](https://github.com/xiaolongbao0709)
- 项目设计与系统抽象受 [SillyTavern](https://github.com/SillyTavern/SillyTavern) 启发