# -*- coding: utf-8 -*-
import urllib.request
import json

url = 'https://ai-omoshiro-api.kojifo369.workers.dev/api/generate'
data = json.dumps({
    'app': 'nickname-maker',
    'params': {
        'name': '\u4f50\u91ce\u7422\u78e8',  # 佐野琢磨
        'traits': ['\u5143\u6c17', '\u9762\u767d\u3044'],  # 元気, 面白い
        'taste': 'cute'
    }
}, ensure_ascii=False).encode('utf-8')

headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Origin': 'https://solodev-lab.github.io',
    'Referer': 'https://solodev-lab.github.io/nickname-maker/'
}

req = urllib.request.Request(url, data=data, headers=headers)
try:
    res = urllib.request.urlopen(req)
    print(res.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print(f'Error {e.code}: {e.read().decode("utf-8")}')
