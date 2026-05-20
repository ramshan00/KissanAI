import urllib.request
import urllib.error
import json

url = 'https://ramsha00-kissanapp.hf.space/api/antigravity/process'
data = json.dumps({'raw_input': 'I need a tractor urgently', 'user_id': 1}).encode('utf-8')
headers = {'Content-Type': 'application/json'}
req = urllib.request.Request(url, data=data, headers=headers, method='POST')

try:
    response = urllib.request.urlopen(req)
    print(response.read().decode())
except urllib.error.HTTPError as e:
    print(e.read().decode())
