import json, pathlib, yaml
from jsonschema import Draft202012Validator, RefResolver

ROOT = pathlib.Path(__file__).resolve().parents[2]
CONTRACTS = ROOT / 'contracts'
SKILLS = ROOT / 'skills' / 'staged'

def load_schema(name):
    p = CONTRACTS / name
    with p.open('r', encoding='utf-8') as f:
        return json.load(f)

def test_skill_yaml_conforms_to_schema():
    skills_schema = load_schema('skills.v1.json')
    commands_schema = load_schema('kkb.commands.v1.json')
    store = {
        commands_schema.get('$id','kkb.commands.v1'): commands_schema,
        skills_schema.get('$id','kkb.skills.v1'): skills_schema,
    }
    resolver = RefResolver.from_schema(skills_schema, store=store)
    validator = Draft202012Validator(skills_schema, resolver=resolver)

    for yml in SKILLS.glob('*.yaml'):
        data = yaml.safe_load(yml.read_text(encoding='utf-8'))
        errors = sorted(validator.iter_errors(data), key=lambda e: e.path)
        assert not errors, f'Validation errors in {yml}: ' + '; '.join([e.message for e in errors])