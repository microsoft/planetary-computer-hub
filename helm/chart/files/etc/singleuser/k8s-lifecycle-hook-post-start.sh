#/bin/bash
# See https://github.com/neurohackademy/nh2020-jupyterhub/blob/26ed5863d9fbbdb22e0ad4892eb764e35a65431f/chart/files/etc/singleuser/k8s-lifecycle-hook-post-start.sh

# Sync the examples folder, but don't stop the launch if this fails.
echo "Pulling examples"
/srv/conda/envs/notebook/bin/gitpuller https://github.com/microsoft/PlanetaryComputerExamples main /home/jovyan/PlanetaryComputerExamples || true

echo "Setting markdown config"
# Ensure that markdown files are rendered by default.
if [ ! -f ~/.jupyter/lab/user-settings/\@jupyterlab/docmanager-extension/plugin.jupyterlab-settings ]; then
    mkdir -p ~/.jupyter/lab/user-settings/\@jupyterlab/docmanager-extension/ || true
    echo '{defaultViewers: {markdown: "Markdown Preview"}}' > ~/.jupyter/lab/user-settings/\@jupyterlab/docmanager-extension/plugin.jupyterlab-settings
fi

# https://github.com/jupyterlab/jupyterlab/issues/10840
# Work around cell rendering issue by disabling that optimization.
mkdir -p /srv/conda/envs/notebook/share/jupyter/lab/settings/
echo '{"@jupyterlab/notebook-extension:tracker": {"renderCellOnIdle": false,"numberCellsToRenderDirectly": 10000000000000}}' > /srv/conda/envs/notebook/share/jupyter/lab/settings/overrides.json

# Add a sitecustomize module to execute on startup
# Silence dask-gateway warning. Fixed in https://github.com/dask/dask-gateway/pull/416.
echo 'import warnings; warnings.filterwarnings("ignore", "format_bytes")' >> /srv/conda/envs/notebook/lib/python3.8/site-packages/sitecustomize.py

# The docker image puts the plugin files in /opt/conda/share
# We move them into the home directory, if the plugin isn't already installed
echo "[Adding QGIS STAC plugin]"
mkdir -p $HOME/.local/share/QGIS/QGIS3/profiles/default/python/plugins

if [ -d /opt/conda/share/qgis_stac ]; then
    mv -n /opt/conda/share/qgis_stac $HOME/.local/share/QGIS/QGIS3/profiles/default/python/plugins/
fi

# Add an autostart entry for qgis
echo "Adding qgis autostart"
mkdir -p ~/.config/autostart
cat <<EOF > ~/.config/autostart/qgis.desktop
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=qgis
Comment=Startup qgis
Exec=/opt/conda/bin/qgis
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
EOF

# Add Spark default configuration if mounted
if [ -d "/etc/spark-ipython/profile_default/startup" ]; then
    mkdir -p ~/.ipython/profile_default/startup/ && \
    mv /etc/spark-ipython/profile_default/startup/* ~/.ipython/profile_default/startup/
fi

echo "Removing lost+found"
# Remove empty lost+found directories
rmdir ~/lost+found/ || true
