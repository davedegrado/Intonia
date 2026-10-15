"""Unisce i frammenti lib/l10n/parts/<gruppo>.<lingua>.json negli ARB principali.

Uso temporaneo durante la localizzazione: ogni frammento contiene chiavi con un
prefisso diverso; l'unione fallisce su chiavi duplicate.
"""
import glob
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(__file__), '..', 'lib', 'l10n')


def merge(lang):
    path = os.path.join(ROOT, f'app_{lang}.arb')
    with open(path, encoding='utf-8') as f:
        data = json.load(f)
    for part in sorted(glob.glob(os.path.join(ROOT, 'parts', f'*.{lang}.json'))):
        with open(part, encoding='utf-8') as f:
            fragment = json.load(f)
        for key, value in fragment.items():
            if key in data and data[key] != value:
                sys.exit(f'Chiave duplicata {key} in {part}')
            data[key] = value
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


for lang in ('en', 'it'):
    merge(lang)
