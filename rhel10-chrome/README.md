
vncserver -foreground -select-de none -httpdPort 8444

DISPLAY=":1"
command=/usr/bin/google-chrome-stable --no-sandbox
