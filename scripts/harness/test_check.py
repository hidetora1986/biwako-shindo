"""Portable regression tests for the harness itself."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("harness_check", Path(__file__).with_name("check.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class HarnessPolicyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        (self.repo / "AGENTS.md").write_text("# agents\n", encoding="utf-8")
        (self.repo / ".harness").mkdir()
        (self.repo / ".harness/project.json").write_text("{}", encoding="utf-8")
        self.policy = {
            "project": "example", "schema_version": 1,
            "forbidden_paths": [".env*", "**/.env*", "**/*.pem", "**/*credentials*.json"],
            "allow_paths": [".env.example", "**/.env.example"],
            "review_required_paths": ["src/**", ".github/workflows/**"],
            "native_ci_checks": ["python -m unittest discover -s tests -v"],
        }

    def tearDown(self):
        self.tmp.cleanup()

    def test_blocks_secret_paths(self):
        for name in (".env", "src/.env.local", "cert/private.pem", "secrets/service-credentials.json"):
            with self.subTest(name=name):
                result = module.evaluate(self.policy, self.repo, [name], diff_verified=True)
                self.assertEqual(result["policy_status"], "BLOCKED")

    def test_allows_example_and_flags_review(self):
        result = module.evaluate(self.policy, self.repo, [".env.example", "src/app.py"], diff_verified=True)
        self.assertEqual(result["policy_status"], "PASS")
        self.assertEqual(result["manual_review_files"], ["src/app.py"])
        self.assertEqual(result["release_status"], "BLOCKED_PENDING_SEPARATE_GATES")

    def test_unverified_diff_fails_closed(self):
        result = module.evaluate(self.policy, self.repo, [], diff_verified=False)
        self.assertEqual(result["policy_status"], "BLOCKED")

    def test_missing_agents_fails(self):
        (self.repo / "AGENTS.md").unlink()
        result = module.evaluate(self.policy, self.repo, [], diff_verified=True)
        self.assertEqual(result["policy_status"], "BLOCKED")

    def test_bad_policy_fails(self):
        bad = self.repo / "bad.json"
        bad.write_text('{"project":"p","schema_version":1,"forbidden_paths":[]}', encoding="utf-8")
        with self.assertRaises(ValueError):
            module.read_config(bad)

    def test_windows_slashes(self):
        self.assertTrue(module.matches(r"folder\.env.local", ["**/.env*"]))


if __name__ == "__main__":
    unittest.main()
