
cat << EOF > /etc/yum.repos.d/temp.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub

[centos-baseos]
name=CentOS Stream 9 - BaseOS
baseurl=https://mirror.stream.centos.org/9-stream/BaseOS/\$basearch/os/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[centos-appstream]
name=CentOS Stream 9 - AppStream
baseurl=https://mirror.stream.centos.org/9-stream/AppStream/\$basearch/os/
enabled=1
gpgcheck=0
repo_gpgcheck=0

[centos-crb]
name=CentOS Stream 9 - CRB
baseurl=https://mirror.stream.centos.org/9-stream/CRB/\$basearch/os/
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF

dnf clean all
dnf install -y https://dl.fedoraproject.org/pub/epel/epel{,-next}-release-latest-9.noarch.rpm
dnf install -y tigervnc-server novnc google-chrome-stable alsa-firmware alsa-lib alsa-tools-firmware catatonit procps-ng openssl hostname
cp /tmp/artifacts/dschrome /usr/local/bin/dschrome
chmod 755 /usr/local/bin/dschrome
rm /etc/yum.repos.d/temp.repo
dnf clean all