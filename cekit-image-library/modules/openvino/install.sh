#!/usr/bin/env bash

curl https://raw.githubusercontent.com/openvinotoolkit/model_server/refs/heads/releases/2025/4/demos/common/export_models/export_model.py -o /usr/bin/export_model.py
pip3 install -r https://raw.githubusercontent.com/openvinotoolkit/model_server/refs/heads/releases/2025/4/demos/common/export_models/requirements.txt

cat << EOF > /usr/bin/exportModel
#!/usr/bin/env bash

python3 /usr/bin/export_model.py "\$@"
EOF

chmod 755 /usr/bin/exportModel