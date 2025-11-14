# Tiksar VPN - Windows Desktop Guide

## 🎯 Features

### Dual Connection Modes

#### 1. **VPN Mode** (Recommended)
- Full system VPN with TUN interface
- Routes all traffic through encrypted tunnel
- Works with all applications automatically
- Best for complete privacy and security

#### 2. **Proxy Mode**
- System-wide HTTP/SOCKS proxy
- Automatically configures Windows proxy settings
- Ideal for web browsing and HTTP applications
- Lower resource usage

## 🚀 Getting Started

### First Launch Setup

1. **Select Language**
   - Choose between English or فارسی (Persian)
   - Click "Next" to continue

2. **Privacy & Terms**
   - Review privacy policy and features
   - Click "Get Started" to begin

### Main Interface

#### Connection Panel (Left)
- **Status Indicator**: Shows current connection state
- **Connect/Disconnect Button**: Primary action button
- **Server Selection**: Choose your VPN server
- **Connection Stats**: Real-time upload/download speeds

#### Mode Selector (Right)
- **VPN Mode**: Full system VPN protection
- **Proxy Mode**: System proxy configuration

#### Sidebar Navigation
- 🏠 **Home**: Main connection screen
- ⚡ **Speed Test**: Test connection speed
- 📍 **IP Info**: View current IP and location
- 🔍 **Host Checker**: Check host connectivity
- 🌐 **Servers**: Browse and select servers
- ⚙️ **Settings**: App configuration
- ℹ️ **About**: App information

## 📖 How to Use

### VPN Mode

1. Select **VPN Mode** in the mode selector
2. Click on **Server Selection** to choose a server
3. Click **Connect** button
4. Wait for connection to establish
5. Once connected, all system traffic is encrypted

### Proxy Mode

1. Select **Proxy Mode** in the mode selector
2. Click on **Server Selection** to choose a server
3. Click **Connect** button
4. Windows system proxy will be automatically configured
5. Web browsers and HTTP applications will use the proxy

## ⚙️ Technical Details

### Proxy Configuration

When using Proxy Mode, the app automatically:
- Enables Windows system proxy
- Configures proxy server (127.0.0.1:10808)
- Sets proxy bypass for local addresses
- Flushes DNS cache for immediate effect

### Bypass List

Local addresses are automatically bypassed:
- localhost
- 127.*
- 10.*
- 172.16.* - 172.31.*
- 192.168.*
- `<local>`

### Connection Statistics

Real-time monitoring:
- **Upload Speed**: Current upload rate
- **Download Speed**: Current download rate
- **Duration**: Total connection time

## 🔧 Troubleshooting

### App Won't Start
- Run as Administrator
- Check Windows Defender/Firewall settings
- Ensure .NET Framework is installed

### Proxy Mode Not Working
- Manually check: Settings > Network & Internet > Proxy
- Try restarting browser after connection
- Run `ipconfig /flushdns` in Command Prompt

### VPN Mode Connection Issues
- Check if TUN driver is installed
- Try running app as Administrator
- Disable other VPN software

### DNS Issues
Run these commands in Command Prompt (as Admin):
```cmd
ipconfig /flushdns
ipconfig /release
ipconfig /renew
```

## 🎨 UI Features

- **Modern Dark Theme**: Easy on the eyes
- **Gradient Accents**: Beautiful visual design
- **Smooth Animations**: Polished user experience
- **Real-time Stats**: Live connection monitoring
- **Visual Feedback**: Clear status indicators

## 🔒 Security Features

- **256-bit Encryption**: Military-grade security
- **No Logging**: Zero activity logs
- **Local Bypass**: Keeps local traffic local
- **DNS Protection**: Prevents DNS leaks
- **Automatic Proxy Cleanup**: Removes proxy settings on disconnect

## 📝 Notes

### Proxy Mode
- Requires administrator privileges for registry access
- Browser restart may be needed
- Some applications may need manual proxy configuration

### VPN Mode
- May require TUN/TAP driver installation
- Administrator privileges recommended
- Works with all applications automatically

### Performance
- Proxy Mode: Lower latency, less resource usage
- VPN Mode: Full protection, slightly higher latency

## 🆘 Support

If you encounter issues:
1. Check this guide
2. Try switching between VPN and Proxy modes
3. Restart the application
4. Run as Administrator
5. Check firewall settings

## 📄 Version Information

- **Current Version**: 1.1.1
- **Platform**: Windows 10/11
- **Architecture**: x64
- **Framework**: Flutter 3.35.1+

---

**Tiksar VPN** - Fast, Secure, and Free VPN for Windows

Made with ❤️ for privacy and security
