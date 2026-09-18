import re

with open('public/assets/index-Co2L1R-b.js', 'r', encoding='utf-8') as f:
    c = f.read()

matches = list(re.finditer(r'localStorage\.(?:set|get)Item\([\'"]([^\'"]+)[\'"]', c))
keys = set(m.group(1) for m in matches)
for k in sorted(keys):
    if any(x in k.lower() for x in ['token', 'auth', 'user', 'admin', 'session', 'shein', 'takhfid', 'profile', 'login']):
        print('Found key:', k)
