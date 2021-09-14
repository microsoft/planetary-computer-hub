import os

import pytest
import requests

import dask_gateway


@pytest.mark.common
class TestCommon:
    """Tests that should run on all deployments"""

    def test_connect_cluster(self):
        cluster = dask_gateway.GatewayCluster()
        client = cluster.get_client()
        cluster.scale(1)
        client.wait_for_workers(1)

        r = requests.get(cluster.dashboard_link)
        assert r.status_code == 200

    def test_has_pc_sdk_subscription_key(self):
        assert "PC_SDK_SUBSCRIPTION_KEY" in os.environ
