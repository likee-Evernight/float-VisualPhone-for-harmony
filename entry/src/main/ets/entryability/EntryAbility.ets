import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    // 全面屏适配
    this.enableFullscreen(windowStage);
  }

  /** 让应用内容延伸到状态栏/导航栏下，并把系统栏设为透明 */
  private enableFullscreen(windowStage: window.WindowStage): void {
    try {
      const win: window.Window = windowStage.getMainWindowSync();

      // 1. 布局延伸到状态栏和导航栏下
      win.setWindowLayoutFullScreen(true)
        .then(() => {
          hilog.info(DOMAIN, 'testTag', 'setWindowLayoutFullScreen OK');
        })
        .catch((e: BusinessError) => {
          hilog.error(DOMAIN, 'testTag', 'setWindowLayoutFullScreen failed: %{public}s', JSON.stringify(e));
        });

      // 2. 状态栏 & 导航栏透明，图标黑色
      win.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: '#000000',
        navigationBarColor: '#00000000',
        navigationBarContentColor: '#000000'
      })
        .then(() => {
          hilog.info(DOMAIN, 'testTag', 'setWindowSystemBarProperties OK');
        })
        .catch((e: BusinessError) => {
          hilog.error(DOMAIN, 'testTag', 'setWindowSystemBarProperties failed: %{public}s', JSON.stringify(e));
        });

    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'enableFullscreen exception: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}