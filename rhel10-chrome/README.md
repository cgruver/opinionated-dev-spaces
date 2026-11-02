```bash
if [ ! -d ${HOME}/.config/google-chrome ]
then
  mkdir -p ${HOME}/.config/google-chrome
  touch ${HOME}/.config/google-chrome/'First Run'
fi
rm -f ${HOME}/.config/google-chrome/Singleton{Cookie,Lock,Socket}

if [ ! -d ${HOME}/.vnc ]
then
  mkdir ${HOME}/.vnc
  touch ${HOME}/.vnc/.de-was-selected
  (echo '#!/bin/sh';echo 'unset SESSION_MANAGER';echo 'unset DBUS_SESSION_BUS_ADDRESS';echo 'echo starting Xvnc') > ${HOME}/.vnc/xstartup
  chmod +x ${HOME}/.vnc/xstartup
fi
cat << EOF > ${HOME}/.vnc/kasmvnc.yaml
network:
  websocket_port: 8444
  interface: 0.0.0.0
  protocol: http
  ssl:
    require_ssl: false
  use_ipv4: true
  use_ipv6: false
user_session:
  session_type: exclusive
  concurrent_connections_prompt: false
logging:
  log_writer_name: all
  log_dest: logfile
  level: 30
desktop:
  resolution:
    width: 1280
    height: 1024
  allow_resize: true
  pixel_depth: 24
EOF
VNC_PASSWD=nopasswd
echo -e "${VNC_PASSWD}\n${VNC_PASSWD}\n" | vncpasswd -w -r -u user ${HOME}/.kasmpasswd
/usr/bin/vncserver :0 -disableBasicAuth

export $(dbus-launch)
/usr/bin/google-chrome --display=:0 --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --disable-plugins --disable-plugins-discovery --disable-notifications --disable-sync --mute-audio --dns-prefetch-disable --noremote --start-maximized > /tmp/chrome.out 2>&1 &
```

# Nginx notes: 

sudo mkdir -p /var/run/nginx

# Change ownership of logs, caches, configuration, and PID runtime files
sudo chown -R nginx:nginx /var/log/nginx
sudo chown -R nginx:nginx /var/lib/nginx
sudo chown -R nginx:nginx /var/run/nginx
sudo chown -R nginx:nginx /etc/nginx