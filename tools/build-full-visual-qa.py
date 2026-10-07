"""Build an isolated local debug capture project. Never edits the production project or saves."""
from pathlib import Path
import shutil,subprocess,json
root=Path(__file__).resolve().parents[1]
out=Path('/tmp/full-visual-qa-project')
shutil.copytree(root,out,ignore=shutil.ignore_patterns('.git','.godot','build','__pycache__'),dirs_exist_ok=True)
p=out/'project.godot';p.write_text(p.read_text().replace('res://scenes/main.tscn','res://tests/fixtures/full_visual_scene.tscn'))
p=out/'export_presets.cfg';p.write_text(p.read_text().replace('tests/*,',''))
# Embedded local fixture avoids an exported external-script UID warning in Godot Web.
fixture=out/'tests/fixtures/full_visual_scene.tscn'
code=(out/'tests/fixtures/full_visual_scene.gd').read_text()
fixture.write_text('[gd_scene load_steps=2 format=3]\n[sub_resource type="GDScript" id="Fixture"]\nscript/source = '+json.dumps(code,ensure_ascii=False)+'\n[node name="FullVisualFixture" type="Node"]\nscript = SubResource("Fixture")\n')
(out/'build/qa').mkdir(parents=True,exist_ok=True)
subprocess.run(['godot','--headless','--editor','--path',str(out),'--import','--quit'],check=True)
subprocess.run(['godot','--headless','--path',str(out),'--export-debug','Web Playtest',str(out/'build/qa/index.html')],check=True)
print('Local capture build:',out/'build/qa')
