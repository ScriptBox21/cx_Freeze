import json
import sys

with open("build-test.json") as fp:
    data = json.load(fp)

#print(json.dumps(data, indent=3, ensure_ascii=False))

if len(sys.argv) != 3:
    sys.exit(1)

name = sys.argv[1]
func = sys.argv[2]

test_data = data.get(name, {})

# pre-process requirements
requirements = test_data.get("requirements", [])
if isinstance(requirements, str):
    requirements = [requirements]
req_upgrade = []
req_links = []
for req in requirements:
    if sys.platform == "linux" and req == "wxPython":
        req_links.append("-f https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-18.04 wxPython")
    else:
        if ";" in req:
            req_upgrade.append(req.replace(" ", ""))
        else:
            req_upgrade.append(req)

if func == "app":
    test_app = test_data.get("test_app", [f"test_{name}"])
    if isinstance(test_app, str):
        test_app = [test_app]
    app_array = []
    for app in test_app:
        if ".exe" in app and sys.platform != "win32":
            continue
        app_array.append(app)
    print(" ".join(app_array))

elif func == "req":
    print(" ".join(req_upgrade))

elif func == "req2":
    print(" ".join(req_links))
