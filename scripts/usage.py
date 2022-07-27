import json
import datetime
import os
import httpx
import argparse
import dateutil.parser



def parse_args(args=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("-r", "--root", default="https://pcc-staging.westeurope.cloudapp.azure.com/compute/hub/api")
    parser.add_argument("-k", "--key", default=os.environ.get("JUPYTERHUB_API_TOKEN"))
    parser.add_argument("-w", "--window", default="90", type=int)
    parser.add_argument("-d", "--dest", type=argparse.FileType("w", encoding="utf-8"), default="-")

    return parser.parse_args(args)


def main(args=None):
    args = parse_args(args)

    root = args.root.rstrip("/")
    token = args.key
    dest = args.dest
    delta = datetime.timedelta(args.window)
    since = datetime.datetime.now(tz=datetime.timezone.utc) - delta

    session = httpx.Client(headers={"Authorization": f"token {token}"})
    r = session.get(f"{root}/users")
    r.raise_for_status()

    users = r.json()

    idle = [
        x for x in users
        if dateutil.parser.isoparse(x["last_activity"]) < since
    ]

    json.dump(idle, dest, indent=2)


if __name__ == "__main__":
    main()
