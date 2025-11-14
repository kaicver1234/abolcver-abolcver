enum ConnectionMode {
  vpn,
  proxy,
}

class ConnectionModeExtension {
  static String getTitle(ConnectionMode mode) {
    switch (mode) {
      case ConnectionMode.vpn:
        return 'VPN Mode';
      case ConnectionMode.proxy:
        return 'Proxy Mode';
    }
  }

  static String getDescription(ConnectionMode mode) {
    switch (mode) {
      case ConnectionMode.vpn:
        return 'Full system VPN with TUN interface';
      case ConnectionMode.proxy:
        return 'System-wide HTTP/SOCKS proxy';
    }
  }
}
