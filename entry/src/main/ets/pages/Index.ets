import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { display, window } from '@kit.ArkUI';

const VIRTUAL_ORIGIN: string = 'https://app.local';
const ENTRY_URL: string = `${VIRTUAL_ORIGIN}/index.html`;

const MOBILE_UA: string =
  'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) ' +
    'Chrome/120.0.0.0 Mobile Safari/537.36';

const IGNORED_PATHS: string[] = [
  'manifest.webmanifest', 'manifest.json', 'favicon.ico', 'sw.js', 'service-worker.js',
];

interface DeviceMetrics {
  w: number;
  h: number;
  dpr: number;
  isPortrait: boolean;
}

@Entry
@Component
struct Index {
  controller: webview.WebviewController = new webview.WebviewController();
  schemeHandler: webview.WebSchemeHandler = new webview.WebSchemeHandler();
  metrics: DeviceMetrics = { w: 390, h: 844, dpr: 3, isPortrait: true };

  @State debugText: string = '等待页面加载...';
  @State showDebug: boolean = false;   // 修复完默认关

  aboutToAppear(): void {
    this.metrics = this.getDeviceMetrics();
    try {
      webview.WebviewController.setWebDebuggingAccess(true, 8888);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`调试开关设置失败: ${err.code} ${err.message}`);
    }
    this.ensureFullscreen();
  }

  private ensureFullscreen(): void {
    try {
      window.getLastWindow(getContext(this)).then((win) => {
        win.setWindowLayoutFullScreen(true).catch((e: BusinessError) => {
          console.warn(`fullscreen: ${e.code} ${e.message}`);
        });
        win.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          statusBarContentColor: '#000000',
          navigationBarColor: '#00000000',
          navigationBarContentColor: '#000000'
        }).catch((e: BusinessError) => {
          console.warn(`barprops: ${e.code} ${e.message}`);
        });
      }).catch((e: BusinessError) => {
        console.warn(`getLastWindow: ${e.code} ${e.message}`);
      });
    } catch (e) {
      const err = e as BusinessError;
      console.warn(`全屏异常: ${err.code} ${err.message}`);
    }
  }

  private getDeviceMetrics(): DeviceMetrics {
    try {
      const d = display.getDefaultDisplaySync();
      const dpr: number = d.densityPixels && d.densityPixels > 0 ? d.densityPixels : 3;
      let physW: number = d.width;
      let physH: number = d.height;
      if (d.rotation === 1 || d.rotation === 3) {
        const t = physW; physW = physH; physH = t;
      }
      const w: number = Math.round(physW / dpr);
      const h: number = Math.round(physH / dpr);
      return { w, h, dpr, isPortrait: h >= w };
    } catch (e) {
      return { w: 390, h: 844, dpr: 3, isPortrait: true };
    }
  }

  private buildPatchScript(m: DeviceMetrics): string {
    // ★ 真正起作用的 CSS：把 app-root / wrap / case / frame / shell 全部清零、透明、撑满
    const cssOverride = `
/* ---------- html / body ---------- */
html, body {
  margin: 0 !important;
  padding: 0 !important;
  width: 100vw !important;
  max-width: 100vw !important;
  height: 100vh !important;
  max-height: 100vh !important;
  overflow: hidden !important;
  background: transparent !important;
  background-color: transparent !important;
}

/* ---------- 所有嵌套层：清零 + 透明 + 撑满 ---------- */
.app-root,
.phone-shell-wrap,
.splash-shell-wrap,
.phone-case,
.phone-frame,
.phone-shell,
.splash-phone-screen {
  padding: 0 !important;
  margin: 0 !important;
  background: transparent !important;
  background-color: transparent !important;
  background-image: none !important;
  border: none !important;
  border-radius: 0 !important;
  box-shadow: none !important;
  outline: none !important;
  width: 100vw !important;
  max-width: 100vw !important;
  min-width: 0 !important;
  height: 100vh !important;
  max-height: 100vh !important;
  min-height: 0 !important;
  box-sizing: border-box !important;
  zoom: 1 !important;
  transform: none !important;
  position: static !important;
}

/* ---------- 干掉伪元素：音量键、装饰点 ---------- */
.phone-shell-wrap::before,
.phone-shell-wrap::after,
.phone-case::before,
.phone-case::after,
.phone-frame::before,
.phone-frame::after,
.phone-shell::before,
.phone-shell::after,
.splash-shell-wrap::before,
.splash-shell-wrap::after,
.app-root::before,
.app-root::after {
  content: none !important;
  display: none !important;
}`;

    return `<script>/* __ark_mobile_patch__ */(function(){
  'use strict';

  /* ★★★ 反复确保样式表插入成功 */
  function injectStyle() {
    try {
      var existing = document.getElementById('__ark_shell_kill__');
      if (existing) {
        // 已存在，更新内容（防止被清空）
        existing.textContent = ${JSON.stringify(cssOverride)};
        return;
      }
      var s = document.createElement('style');
      s.id = '__ark_shell_kill__';
      s.textContent = ${JSON.stringify(cssOverride)};
      var head = document.head || document.documentElement;
      if (head.firstChild) head.insertBefore(s, head.firstChild);
      else head.appendChild(s);
      console.log('[patch] style injected');
    } catch(e){}
  }

  injectStyle();
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', injectStyle);
  }
  setTimeout(injectStyle, 50);
  setTimeout(injectStyle, 200);
  setTimeout(injectStyle, 600);
  setTimeout(injectStyle, 1500);
  setTimeout(injectStyle, 3000);

  /* 环境伪装 */
  try { Object.defineProperty(navigator, 'maxTouchPoints', { get: function(){ return 5; }, configurable: true }); } catch(e){}
  try { Object.defineProperty(navigator, 'platform', { get: function(){ return 'iPhone'; }, configurable: true }); } catch(e){}
  try { Object.defineProperty(navigator, 'vendor', { get: function(){ return 'Apple Computer, Inc.'; }, configurable: true }); } catch(e){}
  try { Object.defineProperty(navigator, 'userAgentData', { get: function(){ return undefined; }, configurable: true }); } catch(e){}
  try { Object.defineProperty(window, 'ontouchstart', { value: null, configurable: true }); } catch(e){}
  try { if (typeof TouchEvent === 'undefined') { window.TouchEvent = function(){}; } } catch(e){}

  try {
    var origMM = window.matchMedia ? window.matchMedia.bind(window) : null;
    function fakeMM(m, q){
      return { matches: m, media: q, onchange: null,
        addListener: function(){}, removeListener: function(){},
        addEventListener: function(){}, removeEventListener: function(){},
        dispatchEvent: function(){ return false; } };
    }
    window.matchMedia = function(q){
      var s = String(q || '');
      if (/pointer\\s*:\\s*coarse/i.test(s))     return fakeMM(true,  s);
      if (/pointer\\s*:\\s*fine/i.test(s))       return fakeMM(false, s);
      if (/hover\\s*:\\s*none/i.test(s))         return fakeMM(true,  s);
      if (/hover\\s*:\\s*hover/i.test(s))        return fakeMM(false, s);
      if (/any-pointer\\s*:\\s*coarse/i.test(s)) return fakeMM(true,  s);
      if (/any-pointer\\s*:\\s*fine/i.test(s))   return fakeMM(false, s);
      if (/any-hover\\s*:\\s*none/i.test(s))     return fakeMM(true,  s);
      if (/any-hover\\s*:\\s*hover/i.test(s))    return fakeMM(false, s);
      if (origMM) return origMM(q);
      return fakeMM(false, s);
    };
  } catch(e){}

  console.log('[patch] injected');
})();</script>`;
  }

  private guessMime(path: string): string {
    if (path.endsWith('.js') || path.endsWith('.mjs')) return 'text/javascript';
    if (path.endsWith('.css')) return 'text/css';
    if (path.endsWith('.html') || path.endsWith('.htm')) return 'text/html';
    if (path.endsWith('.json')) return 'application/json';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.svg')) return 'image/svg+xml';
    if (path.endsWith('.ico')) return 'image/x-icon';
    if (path.endsWith('.woff')) return 'font/woff';
    if (path.endsWith('.woff2')) return 'font/woff2';
    if (path.endsWith('.ttf')) return 'font/ttf';
    if (path.endsWith('.otf')) return 'font/otf';
    if (path.endsWith('.mp3')) return 'audio/mpeg';
    if (path.endsWith('.mp4')) return 'video/mp4';
    if (path.endsWith('.webm')) return 'video/webm';
    if (path.endsWith('.wasm')) return 'application/wasm';
    return 'application/octet-stream';
  }

  private patchHtmlIfNeeded(path: string, data: Uint8Array): Uint8Array {
    if (!path.endsWith('.html') && !path.endsWith('.htm')) return data;
    try {
      const decoder = new util.TextDecoder('utf-8');
      let html = decoder.decodeToString(data);
      if (html.indexOf('__ark_mobile_patch__') >= 0) return data;

      const script = this.buildPatchScript(this.metrics);
      const patched = html.replace(/<head([^>]*)>/i, (_: string, attrs: string) => {
        return `<head${attrs}>${script}`;
      });
      const finalHtml = patched === html
        ? html.replace(/<html([^>]*)>/i, (_: string, attrs: string) => `<html${attrs}>${script}`)
        : patched;

      const encoder = new util.TextEncoder();
      return encoder.encodeInto(finalHtml);
    } catch (e) {
      const err = e as BusinessError;
      console.error(`[ArkWeb] patchHtml 失败: ${err.code} ${err.message}`);
      return data;
    }
  }

  private safeRespond(
    resourceHandler: webview.WebResourceHandler,
    status: number, mime: string, buffer: ArrayBuffer,
  ): boolean {
    try {
      const response: webview.WebSchemeHandlerResponse = new webview.WebSchemeHandlerResponse();
      response.setStatus(status);
      response.setStatusText(status === 200 ? 'OK' : 'Not Found');
      response.setMimeType(mime);
      response.setEncoding('utf-8');
      resourceHandler.didReceiveResponse(response);
      resourceHandler.didReceiveResponseBody(buffer);
      resourceHandler.didFinish();
      return true;
    } catch (e) {
      return false;
    }
  }

  private handleRequest(
    request: webview.WebSchemeHandlerRequest,
    resourceHandler: webview.WebResourceHandler,
  ): boolean {
    let url: string = '';
    try {
      url = request.getRequestUrl();
    } catch (e) {
      return true;
    }
    if (!url.startsWith(VIRTUAL_ORIGIN)) return false;

    let path: string = url.slice(VIRTUAL_ORIGIN.length);
    path = path.split('?')[0].split('#')[0];
    while (path.startsWith('/')) path = path.slice(1);
    if (path === '' || path.endsWith('/')) path += 'index.html';

    for (const ignored of IGNORED_PATHS) {
      if (path === ignored || path.endsWith('/' + ignored)) {
        this.safeRespond(resourceHandler, 200, 'application/json', new ArrayBuffer(0));
        return true;
      }
    }

    let data: Uint8Array;
    try {
      const rm = getContext(this).resourceManager;
      data = rm.getRawFileContentSync(path);
    } catch (e) {
      this.safeRespond(resourceHandler, 404, 'text/plain', new ArrayBuffer(0));
      return true;
    }

    data = this.patchHtmlIfNeeded(path, data);

    try {
      const buffer: ArrayBuffer = new ArrayBuffer(data.byteLength);
      new Uint8Array(buffer).set(data);
      this.safeRespond(resourceHandler, 200, this.guessMime(path), buffer);
    } catch (e) {
      console.error(`[ArkWeb] 响应失败: ${path}`);
    }
    return true;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Web({
        src: '',
        controller: this.controller,
      })
        .width('100%')
        .height('100%')
        .metaViewport(true)
        .userAgent(MOBILE_UA)
        .javaScriptAccess(true)
        .fileAccess(true)
        .domStorageAccess(true)
        .imageAccess(true)
        .onlineImageAccess(true)
        .mixedMode(MixedMode.All)
        .cacheMode(CacheMode.Default)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.KEYBOARD],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )
        .onControllerAttached(() => {
          this.metrics = this.getDeviceMetrics();
          this.schemeHandler.onRequestStart(
            (request: webview.WebSchemeHandlerRequest,
              resourceHandler: webview.WebResourceHandler): boolean => {
              return this.handleRequest(request, resourceHandler);
            },
          );
          this.controller.setWebSchemeHandler('https', this.schemeHandler);
          try {
            this.controller.loadUrl(ENTRY_URL);
          } catch (e) {
            console.error(`[ArkWeb] loadUrl 失败`);
          }
        })
        .onPageEnd((e) => {
          if (!this.showDebug) return;
          setTimeout(() => {
            try {
              this.controller.runJavaScript(`
                (function(){
                  function m(sel){
                    var el = document.querySelector(sel);
                    if (!el) return sel + ': MISSING';
                    var r = el.getBoundingClientRect();
                    var cs = getComputedStyle(el);
                    return sel + ': x=' + Math.round(r.left) + ' y=' + Math.round(r.top) +
                      ' w=' + Math.round(r.width) + ' h=' + Math.round(r.height) +
                      ' pad=' + cs.paddingTop + ',' + cs.paddingLeft +
                      ' bg=' + cs.backgroundColor;
                  }
                  var lines = [];
                  lines.push('innerW=' + window.innerWidth + ' innerH=' + window.innerHeight);
                  lines.push('our_style=' + (document.getElementById('__ark_shell_kill__') ? 'EXISTS' : 'MISSING'));
                  lines.push(m('.app-root'));
                  lines.push(m('.phone-shell-wrap'));
                  lines.push(m('.phone-case'));
                  lines.push(m('.phone-frame'));
                  lines.push(m('.phone-shell'));
                  return lines.join('\\n');
                })()
              `).then((result: string) => {
                this.debugText = result;
              }).catch((err: BusinessError) => {
                this.debugText = `runJS 失败: ${err.message}`;
              });
            } catch (e) {
              const err = e as BusinessError;
              this.debugText = `异常: ${err.message}`;
            }
          }, 3000);
        })
        .onConsole((e) => {
          console.log('[H5]', e.message.getMessage());
          return true;
        })

      if (this.showDebug) {
        Column() {
          Text('点击隐藏').fontSize(10).fontColor('#FFFF00').margin({ bottom: 2 })
          Text(this.debugText).fontSize(9).fontColor('#FFFFFF').lineHeight(13)
        }
        .backgroundColor('#CC000000')
        .padding(8)
        .margin({ top: 100, left: 8, right: 8 })
        .borderRadius(6)
        .width('95%')
        .onClick(() => { this.showDebug = false; })
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea(
      [SafeAreaType.SYSTEM],
      [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
    )
  }
}