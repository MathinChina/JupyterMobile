import '../core/kernel/kernel_connection_config.dart';
import 'http_kernel_provider.dart';

/// 本机 Termux / Pydroid Provider：地址锁定 127.0.0.1，只填端口 + token。
class ExternalKernelProvider extends HttpKernelProvider {
  ExternalKernelProvider(KernelConnectionConfig config)
      : super(config.copyWith(host: '127.0.0.1'));
}
