# -*- coding: utf-8 -*-
import urllib.request
import json

url = 'https://ai-omoshiro-api.kojifo369.workers.dev/api/generate'

# 1枚引きテスト
data_one = json.dumps({
    'app': 'tarot-reading',
    'params': {
        'mode': 'one-card',
        'cards': [{'name': '愚者', 'isReversed': False, 'meaning': '新しい始まり、自由、冒険'}]
    }
}, ensure_ascii=False).encode('utf-8')

# 3枚引きテスト
data_three = json.dumps({
    'app': 'tarot-reading',
    'params': {
        'mode': 'three-card',
        'cards': [
            {'name': '魔術師', 'isReversed': False, 'meaning': '創造力、意志力'},
            {'name': '女帝', 'isReversed': True, 'meaning': '過保護、停滞'},
            {'name': '太陽', 'isReversed': False, 'meaning': '成功、喜び、活力'}
        ]
    }
}, ensure_ascii=False).encode('utf-8')

# 5枚引きテスト
data_five = json.dumps({
    'app': 'tarot-reading',
    'params': {
        'mode': 'five-card',
        'cards': [
            {'name': '魔術師', 'isReversed': False, 'meaning': '創造力、意志力'},
            {'name': '塔', 'isReversed': True, 'meaning': '崩壊の回避、変化への抵抗'},
            {'name': '女帝', 'isReversed': False, 'meaning': '豊穣、母性、繁栄'},
            {'name': '星', 'isReversed': False, 'meaning': '希望、インスピレーション'},
            {'name': '世界', 'isReversed': False, 'meaning': '完成、達成、統合'}
        ],
        'question': '仕事運'
    }
}, ensure_ascii=False).encode('utf-8')

headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Origin': 'https://solodev-lab.github.io',
    'Referer': 'https://solodev-lab.github.io/tarot-reading/',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}

def count_tokens_approx(text):
    """日本語テキストの大まかなトークン数を推定（1文字≒1-2トークン）"""
    return len(text)

for label, data in [('1枚引き', data_one), ('3枚引き', data_three), ('5枚引き', data_five)]:
    print(f'\n=== {label} ===')
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        res = urllib.request.urlopen(req)
        raw = res.read()
        result = json.loads(raw)
        data = result.get('data', result)
        print(json.dumps(data, ensure_ascii=False, indent=2))

        # overall の文字数
        overall = data.get('overall', '')
        print(f'\n[overall] 文字数: {len(overall)}')

        # 全フィールドの文字数
        total_chars = 0
        for k, v in data.items():
            if isinstance(v, str):
                print(f'  [{k}] {len(v)}文字')
                total_chars += len(v)
        print(f'[テキスト合計] {total_chars}文字')
    except urllib.error.HTTPError as e:
        print(f'Error {e.code}: {e.read().decode("utf-8")}')
