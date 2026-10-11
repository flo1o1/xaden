import pickle
import subprocess

import requests
import yaml


def fixtures(cursor, user_input, app):
    # ruleid: python-subprocess-shell-true
    subprocess.run(user_input, shell=True)
    # ok: python-subprocess-shell-true
    subprocess.run(["ls", user_input])
    # ruleid: python-eval-exec
    eval(user_input)
    # ruleid: python-unsafe-deserialization
    pickle.loads(user_input)
    # ruleid: python-yaml-unsafe-load
    yaml.load(user_input)
    # ok: python-yaml-unsafe-load
    yaml.load(user_input, Loader=yaml.SafeLoader)
    # ruleid: python-sql-built-from-strings
    cursor.execute(f"SELECT * FROM users WHERE name = '{user_input}'")
    # ok: python-sql-built-from-strings
    cursor.execute("SELECT * FROM users WHERE name = %s", (user_input,))
    # ruleid: python-tls-verification-disabled
    requests.get("https://example.invalid", verify=False)
    # ruleid: python-debug-server
    app.run(debug=True)
