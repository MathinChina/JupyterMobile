import 'http_kernel_provider.dart';

/// 远程服务器 Provider：地址/端口/token 由用户填写，连公网或内网服务器。
class RemoteKernelProvider extends HttpKernelProvider {
  RemoteKernelProvider(super.config);
}
