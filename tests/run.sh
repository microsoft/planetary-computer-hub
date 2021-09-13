#!/usr/bin/env bash
set -eu

export JUPYTERHUB_USER="pangeotestbot-40microsoft-2ecom"
export API_USERNAME="pangeotestbot@microsoft.com"
export POD="jupyter-${JUPYTERHUB_USER}"

# TODO: test prod deployments
export TOKEN=${TEST_BOT_TOKEN}

# Start a server
echo "[Staring singleuser server for ${API_USERNAME}]"
curl -X POST -H "Authorization: token ${TOKEN}" "${JUPYTERHUB_URL}/hub/api/users/${API_USERNAME}/server"

while [[ $(kubectl -n ${ENVIRONMENT} get pods ${POD} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done

# Copy the test file
kubectl -n ${ENVIRONMENT} cp tests/test.py ${POD}:/tmp/test.py
kubectl -n ${ENVIRONMENT} cp tests/pytest.ini ${POD}:/tmp/pytest.ini

# Run the tests
echo "[Running tests]"
kubectl -n ${ENVIRONMENT} exec ${POD} -- /srv/conda/envs/notebook/bin/python3 -m pip install pytest
kubectl -n ${ENVIRONMENT} exec ${POD} -- /srv/conda/envs/notebook/bin/pytest -v /tmp/test.py
RET=$?

echo "[Cleaning up]"
# Cleanup
curl -X DELETE -H "Authorization: token ${TOKEN}" "${JUPYTERHUB_URL}/hub/api/users/${API_USERNAME}/server"

exit $RET
