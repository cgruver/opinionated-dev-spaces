#!/usr/bin/env bash
set -e
curl https://raw.githubusercontent.com/openvinotoolkit/model_server/refs/heads/releases/2025/4/demos/common/export_models/export_model.py -o /usr/bin/export_model.py
pip3 install -r https://raw.githubusercontent.com/openvinotoolkit/model_server/refs/heads/releases/2025/4/demos/common/export_models/requirements.txt

cat << EOF > /usr/bin/exportModel
#!/usr/bin/env bash

python3 /usr/bin/export_model.py "\$@"
EOF

chmod 755 /usr/bin/exportModel

TEMP_DIR="$(mktemp -d)"
curl -fsSL -o ${TEMP_DIR}/ovms_redhat_python_off.tar.gz https://github.com/openvinotoolkit/model_server/releases/download/v2026.0/ovms_redhat_python_off.tar.gz
tar -x --no-auto-compress -f ${TEMP_DIR}/ovms_redhat_python_off.tar.gz -C ${TEMP_DIR}
mv ${TEMP_DIR}/ovms /usr/local/ovms
rm -rf "${TEMP_DIR}"
