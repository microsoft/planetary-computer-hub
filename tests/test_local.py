import ast
import yaml
from pathlib import Path


HERE = Path(__name__)


def test_valid_config():
    with (HERE.parent / "config.yaml").open() as f:
        config = yaml.safe_load(f)
    code = config["dask-gateway"]["gateway"]["extraConfig"]["optionHandler"]
    ast.parse(code)  # it's valid Python
