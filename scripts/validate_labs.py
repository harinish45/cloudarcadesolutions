#!/usr/bin/env python3
"""
Google Cloud Arcade Solutions - Automated Lab Validator
Validates repository structure, markdown documents, code blocks,
Mermaid diagram syntax, internal hyperlinks, and bash automation scripts.
"""

from __future__ import annotations

import argparse
import logging
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Pattern, Set, Tuple

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger: logging.Logger = logging.getLogger("LabValidator")


@dataclass
class ValidationIssue:
    """Represents a validation warning or error."""
    file_path: Path
    line_number: Optional[int]
    message: str
    is_error: bool = True


@dataclass
class ValidationSummary:
    """Aggregated results across all validated files."""
    scanned_files_count: int = 0
    scanned_labs_count: int = 0
    issues: List[ValidationIssue] = field(default_factory=list)

    @property
    def error_count(self) -> int:
        return sum(1 for issue in self.issues if issue.is_error)

    @property
    def warning_count(self) -> int:
        return sum(1 for issue in self.issues if not issue.is_error)

    @property
    def is_successful(self) -> bool:
        return self.error_count == 0


class MarkdownValidator:
    """Validates markdown syntax, code fences, Mermaid syntax, and links."""

    LINK_REGEX: Pattern[str] = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')
    MERMAID_OPEN_REGEX: Pattern[str] = re.compile(r'^```mermaid\s*$')
    VALID_MERMAID_TYPES: Set[str] = {
        "flowchart", "graph", "sequenceDiagram", "stateDiagram",
        "stateDiagram-v2", "classDiagram", "erDiagram", "xychart-beta"
    }

    def __init__(self, root_dir: Path) -> None:
        self.root_dir: Path = root_dir

    def validate_file(self, file_path: Path) -> List[ValidationIssue]:
        """Runs all markdown validations on a single file."""
        issues: List[ValidationIssue] = []
        try:
            content: str = file_path.read_text(encoding="utf-8")
        except UnicodeDecodeError as exc:
            issues.append(ValidationIssue(file_path, 0, f"Encoding error: {exc}"))
            return issues

        lines: List[str] = content.splitlines()
        issues.extend(self._check_code_blocks(file_path, lines))
        issues.extend(self._check_links(file_path, lines))
        return issues

    def _check_code_blocks(self, file_path: Path, lines: List[str]) -> List[ValidationIssue]:
        """Ensures all code fences and Mermaid diagrams are valid."""
        issues: List[ValidationIssue] = []
        in_code_block: bool = False
        in_mermaid_block: bool = False
        mermaid_has_type: bool = False
        code_fence_start_line: int = 0

        for line_idx, line in enumerate(lines, start=1):
            stripped: str = line.strip()
            if stripped.startswith("```"):
                if not in_code_block:
                    in_code_block = True
                    code_fence_start_line = line_idx
                    if stripped == "```mermaid":
                        in_mermaid_block = True
                        mermaid_has_type = False
                else:
                    if in_mermaid_block and not mermaid_has_type:
                        issues.append(ValidationIssue(
                            file_path, code_fence_start_line,
                            "Mermaid block has no valid diagram type declaration."
                        ))
                    in_code_block = False
                    in_mermaid_block = False
            elif in_mermaid_block and not mermaid_has_type and stripped:
                first_token: str = stripped.split()[0]
                if any(first_token.startswith(valid) for valid in self.VALID_MERMAID_TYPES):
                    mermaid_has_type = True
                else:
                    issues.append(ValidationIssue(
                        file_path, line_idx,
                        f"Invalid Mermaid diagram type: '{first_token}'."
                    ))

        if in_code_block:
            issues.append(ValidationIssue(
                file_path, code_fence_start_line,
                f"Unclosed code fence starting at line {code_fence_start_line}."
            ))
        return issues

    def _check_links(self, file_path: Path, lines: List[str]) -> List[ValidationIssue]:
        """Validates that internal relative links point to existing files."""
        issues: List[ValidationIssue] = []
        for line_idx, line in enumerate(lines, start=1):
            matches: List[Tuple[str, str]] = self.LINK_REGEX.findall(line)
            for _, link_target in matches:
                target_clean: str = link_target.strip().split("#")[0]
                if not target_clean or target_clean.startswith(("http://", "https://", "mailto:")):
                    continue
                # Resolve relative link from current file parent directory
                resolved_target: Path = (file_path.parent / target_clean).resolve()
                if not resolved_target.exists():
                    issues.append(ValidationIssue(
                        file_path, line_idx,
                        f"Broken relative link target '{link_target}' does not exist.",
                        is_error=True
                    ))
        return issues


class ShellScriptValidator:
    """Validates bash scripts for best practices, safety flags, and syntax."""

    REQUIRED_SAFETY_FLAGS: Tuple[str, ...] = ("set -Eeuo pipefail", "set -e")

    def validate_script(self, file_path: Path) -> List[ValidationIssue]:
        """Validates a bash shell script."""
        issues: List[ValidationIssue] = []
        try:
            content: str = file_path.read_text(encoding="utf-8")
        except UnicodeDecodeError as exc:
            issues.append(ValidationIssue(file_path, 0, f"Script encoding error: {exc}"))
            return issues

        lines: List[str] = content.splitlines()
        if not lines:
            issues.append(ValidationIssue(file_path, 0, "Shell script is empty."))
            return issues

        # Check shebang
        first_line: str = lines[0].strip()
        if not (first_line.startswith("#!/bin/bash") or first_line.startswith("#!/usr/bin/env bash")):
            issues.append(ValidationIssue(
                file_path, 1,
                f"Missing or invalid bash shebang: '{first_line}'.",
                is_error=False
            ))

        # Check safety flags
        has_safety_flag: bool = any(
            any(flag in line for flag in self.REQUIRED_SAFETY_FLAGS)
            for line in lines[:10]
        )
        if not has_safety_flag:
            issues.append(ValidationIssue(
                file_path, 2,
                "Script lacks recommended safety flags ('set -e' or 'set -Eeuo pipefail').",
                is_error=False
            ))

        return issues


class RepositoryValidator:
    """Orchestrates comprehensive validation of the repository."""

    def __init__(self, root_path: Path) -> None:
        self.root_path: Path = root_path.resolve()
        self.md_validator: MarkdownValidator = MarkdownValidator(self.root_path)
        self.sh_validator: ShellScriptValidator = ShellScriptValidator()

    def run_all_checks(self) -> ValidationSummary:
        """Runs validations across all repository artifacts."""
        summary: ValidationSummary = ValidationSummary()
        logger.info("Starting validation scan at: %s", self.root_path)

        labs_dir: Path = self.root_path / "labs"
        if labs_dir.is_dir():
            lab_dirs: List[Path] = [d for d in labs_dir.iterdir() if d.is_dir()]
            summary.scanned_labs_count = len(lab_dirs)
            logger.info("Found %d lab solution directories.", len(lab_dirs))

        for current_root, _, filenames in os.walk(self.root_path):
            current_path: Path = Path(current_root)
            if ".git" in current_path.parts:
                continue

            for file_name in filenames:
                file_path: Path = current_path / file_name
                summary.scanned_files_count += 1

                if file_name.endswith(".md"):
                    issues: List[ValidationIssue] = self.md_validator.validate_file(file_path)
                    summary.issues.extend(issues)
                elif file_name.endswith(".sh"):
                    issues = self.sh_validator.validate_script(file_path)
                    summary.issues.extend(issues)

        return summary


def main() -> int:
    """CLI entry point for repository validation."""
    parser = argparse.ArgumentParser(description="Google Cloud Arcade Lab Validator")
    parser.add_argument(
        "--path",
        type=Path,
        default=Path.cwd(),
        help="Path to repository root (defaults to current directory)"
    )
    args = parser.parse_args()

    validator: RepositoryValidator = RepositoryValidator(args.path)
    summary: ValidationSummary = validator.run_all_checks()

    logger.info("Validation complete.")
    logger.info("Scanned %d files across %d labs.", summary.scanned_files_count, summary.scanned_labs_count)

    for issue in summary.issues:
        level_str: str = "ERROR" if issue.is_error else "WARNING"
        location: str = f"{issue.file_path.name}:{issue.line_number or 0}"
        logger.log(
            logging.ERROR if issue.is_error else logging.WARNING,
            "[%s] %s - %s",
            level_str, location, issue.message
        )

    if not summary.is_successful:
        logger.error("Validation failed with %d error(s) and %d warning(s).", summary.error_count, summary.warning_count)
        return 1

    logger.info("All checks passed successfully! Zero errors found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
