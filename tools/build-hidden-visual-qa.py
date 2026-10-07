"""Build an isolated local debug capture project. Never edits the production project or saves."""
from pathlib import Path
import shutil,subprocess
root=Path(__file__).resolve().parents[1]
out=Path('/tmp/no00-visual-qa-project')
shutil.copytree(root,out,ignore=shutil.ignore_patterns('.git','.godot','build','__pycache__'),dirs_exist_ok=True)
p=out/'project.godot';p.write_text(p.read_text().replace('res://scenes/main.tscn','res://tests/fixtures/no00_visual_scene.tscn'))
p=out/'export_presets.cfg';p.write_text(p.read_text().replace('tests/*,',''))
(out/'build/qa').mkdir(parents=True,exist_ok=True)
subprocess.run(['godot','--headless','--editor','--path',str(out),'--import','--quit'],check=True)
subprocess.run(['godot','--headless','--path',str(out),'--export-debug','Web Playtest',str(out/'build/qa/index.html')],check=True)
print('Local capture build:',out/'build/qa')
