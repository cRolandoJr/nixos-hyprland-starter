"""Pruebas del script real; repos temporales, sin tocar la sesión gráfica."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "dotfiles/hypr/.config/hypr/scripts/waybar-nixos-status.sh"


class FlakeStatusTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.repo = self.home / "projects/nix-config"
        self.env = dict(os.environ, HOME=str(self.home))

    def init_repo(self):
        self.repo.mkdir(parents=True)
        subprocess.run(
            ["git", "init", "--quiet", str(self.repo)],
            env=self.env,
            check=True,
        )

    def status(self):
        result = subprocess.run(
            ["bash", str(SCRIPT)], env=self.env,
            capture_output=True, text=True, check=True,
        )
        return json.loads(result.stdout)

    def test_missing_repository_is_not_clean(self):
        result = self.status()
        self.assertEqual(result["class"], "missing")
        self.assertIn("repositorio no encontrado", result["tooltip"])

    def test_clean_repository(self):
        self.init_repo()
        self.assertEqual(self.status()["class"], "clean")

    def test_untracked_file_is_dirty(self):
        self.init_repo()
        (self.repo / "personal.nix").write_text("{}\n")
        result = self.status()
        self.assertEqual(result["class"], "dirty")
        self.assertIn("dirty (1 archivos)", result["tooltip"])

    def test_broken_git_metadata_reports_error(self):
        self.init_repo()
        (self.repo / ".git/HEAD").write_text("invalid HEAD\n")
        result = self.status()
        self.assertEqual(result["class"], "error")
        self.assertIn("error al consultar Git", result["tooltip"])


if __name__ == "__main__":
    unittest.main()
