import 'package:flutter_test/flutter_test.dart';
import 'package:jupyter_mobile/core/termux/termux_deploy.dart';

void main() {
  const shared = TermuxDeploy(
    location: TermuxConfigLocation.shared,
    ip: '127.0.0.1',
    port: 8888,
    token: 'changeme',
  );
  const private = TermuxDeploy(
    location: TermuxConfigLocation.private,
    ip: '127.0.0.1',
    port: 9999,
    token: 's3cret',
  );

  test('共享目录：配置与 notebook 落到 /sdcard', () {
    expect(shared.configDir, '/sdcard/JupyterMobile/config');
    expect(shared.notebookDir, '/sdcard/JupyterMobile/notebooks');
    expect(shared.logFile, '/sdcard/JupyterMobile/nb.log');
  });

  test(r'私有目录：配置落到 $HOME/.jupyter', () {
    expect(private.configDir, r'$HOME/.jupyter');
    expect(private.notebookDir, r'$HOME');
    expect(private.logFile, r'$HOME/.jupyter/nb.log');
  });

  test('oneClickScript 下载脚本并安装 jm，配置端口/令牌后启动', () {
    final s = private.oneClickScript();
    expect(s, contains('curl -fsSL'));
    expect(s, contains('jupytermobile.sh'));
    expect(s, contains('bash jupytermobile.sh'));
    expect(s, contains('jm config --port 9999 --token s3cret'));
    expect(s, contains('jm start'));
    expect(s, contains('jupytermobile.sh'));
    expect(s, contains('gitee.com/mathinchina/JupyterMobile'));
  });

  test('writeConfigScript 使用 IdentityProvider.token 且不含废弃项', () {
    final s = private.writeConfigScript();
    expect(s, contains("c.ServerApp.ip = '127.0.0.1'"));
    expect(s, contains('c.ServerApp.port = 9999'));
    expect(s, contains('c.ServerApp.open_browser = False'));
    expect(s, contains("c.IdentityProvider.token = 's3cret'"));
    expect(s, contains('jupyter_server_config.py'));
    expect(s, isNot(contains('c.NotebookApp.token =')));
    expect(s, isNot(contains('c.ServerApp.token =')));
  });

  test('startScript 用 JUPYTER_CONFIG_DIR 指定配置目录并后台运行', () {
    final s = shared.startScript();
    expect(s, contains('JUPYTER_CONFIG_DIR="/sdcard/JupyterMobile/config"'));
    expect(s, contains('nohup jupyter notebook'));
    expect(s, contains('"/sdcard/JupyterMobile/notebooks"'));
    expect(s, contains('/sdcard/JupyterMobile/nb.log'));
  });

  test('stopScript 优先优雅停止，pkill 兜底', () {
    final s = shared.stopScript();
    expect(s, contains('jupyter server stop 8888'));
    expect(s, contains('pkill -f jupyter-notebook'));
  });

  test('nbextensionScript 生成 install+enable 且用 --user', () {
    final s = shared.nbextensionScript('jupyter_contrib_nbextensions');
    expect(s, contains('jupyter nbextension install --user'));
    expect(s, contains('jupyter nbextension enable --user'));
    expect(s, contains('jupyter_contrib_nbextensions'));
  });

  test('labextensionScript 生成 install 命令', () {
    final s = shared.labextensionScript('@jupyterlab/git');
    expect(s, 'jupyter labextension install @jupyterlab/git');
  });
}
