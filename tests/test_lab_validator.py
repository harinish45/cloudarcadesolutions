"""
Unit tests for the LabValidator script using standard Python unittest.
"""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

# Ensure scripts directory is on Python path
REPO_ROOT: Path = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))

from validate_labs import (  # noqa: E402
    MarkdownValidator,
    ShellScriptValidator,
    ValidationIssue,
    ValidationSummary,
)


class TestLabValidator(unittest.TestCase):
    """Test suite for MarkdownValidator and ShellScriptValidator."""

    def setUp(self) -> None:
        self.test_dir = tempfile.mkdtemp()
        self.tmp_path = Path(self.test_dir)

    def tearDown(self) -> None:
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_markdown_validator_valid_mermaid(self) -> None:
        """Verifies that standard Mermaid diagrams pass validation."""
        test_file: Path = self.tmp_path / "valid.md"
        test_file.write_text(
            "# Title\n\n```mermaid\nflowchart TD\n  A --> B\n```\n",
            encoding="utf-8"
        )

        validator = MarkdownValidator(self.tmp_path)
        issues = validator.validate_file(test_file)
        self.assertEqual(len(issues), 0)

    def test_markdown_validator_invalid_mermaid_type(self) -> None:
        """Verifies that unsupported Mermaid diagram types generate an issue."""
        test_file: Path = self.tmp_path / "invalid_mermaid.md"
        test_file.write_text(
            "# Title\n\n```mermaid\nunsupportedDiagramType\n  A --> B\n```\n",
            encoding="utf-8"
        )

        validator = MarkdownValidator(self.tmp_path)
        issues = validator.validate_file(test_file)
        self.assertTrue(any("Invalid Mermaid diagram type" in issue.message for issue in issues))

    def test_markdown_validator_unclosed_code_fence(self) -> None:
        """Verifies unclosed code blocks are reported as errors."""
        test_file: Path = self.tmp_path / "unclosed.md"
        test_file.write_text(
            "# Title\n\n```bash\necho 'hello world'\n",
            encoding="utf-8"
        )

        validator = MarkdownValidator(self.tmp_path)
        issues = validator.validate_file(test_file)
        self.assertTrue(any("Unclosed code fence" in issue.message for issue in issues))

    def test_markdown_validator_relative_links(self) -> None:
        """Tests broken vs working relative markdown links."""
        existing_target: Path = self.tmp_path / "target.md"
        existing_target.write_text("# Target", encoding="utf-8")

        doc_file: Path = self.tmp_path / "doc.md"
        doc_file.write_text(
            "[Working Link](target.md)\n[Broken Link](does_not_exist.md)\n[External Link](https://google.com)",
            encoding="utf-8"
        )

        validator = MarkdownValidator(self.tmp_path)
        issues = validator.validate_file(doc_file)
        self.assertEqual(len(issues), 1)
        self.assertIn("Broken relative link target 'does_not_exist.md'", issues[0].message)

    def test_shell_script_validator(self) -> None:
        """Tests shell script safety flag and shebang checks."""
        valid_script: Path = self.tmp_path / "valid.sh"
        valid_script.write_text(
            "#!/usr/bin/env bash\nset -Eeuo pipefail\necho 'Clean execution'\n",
            encoding="utf-8"
        )

        validator = ShellScriptValidator()
        issues = validator.validate_script(valid_script)
        self.assertEqual(len(issues), 0)

        bad_script: Path = self.tmp_path / "bad.sh"
        bad_script.write_text("echo 'No shebang and no safety flags'\n", encoding="utf-8")
        issues_bad = validator.validate_script(bad_script)
        self.assertEqual(len(issues_bad), 2)


if __name__ == "__main__":
    unittest.main()
