"""Regression tests for defects the editorial gate must detect."""

import datetime as dt
import unittest

from check_content import check_metadata, check_readme


class ContentChecks(unittest.TestCase):
    def test_duplicate_and_unsorted_entries(self):
        text = "\n".join([
            "- 🌍 [Zed](https://example.org/tool) – A tool.",
            "- 🌍 [Alpha](https://example.org/tool/) – Another listing.",
        ])
        errors = check_readme(text)
        self.assertTrue(any("alphabetical" in e for e in errors))
        self.assertTrue(any("duplicate" in e for e in errors))

    def test_official_marker_rejects_lookalike_domains(self):
        self.assertTrue(check_readme("- 🧠 [Tool](https://mistral.ai.evil.example/tool) – A tool."))

    def test_valid_resource(self):
        self.assertEqual(check_readme("- 🧠 [SDK](https://github.com/mistralai/client-python) – Official SDK."), [])

    def test_future_or_stale_reviews_fail(self):
        data = {"last_reviewed": "2026-09-04", "max_age_days": 31,
                "audit": "audits/2026-09-04.md", "link_exceptions": []}
        text = "Last editorial review: 2026-09-04."
        for today in [dt.date(2026, 9, 3), dt.date(2026, 10, 6)]:
            self.assertTrue(check_metadata(data, text, today))
        self.assertEqual(check_metadata(data, text, dt.date(2026, 9, 4)), [])

    def test_expired_exception_fails(self):
        data = {"last_reviewed": "2026-09-04", "max_age_days": 31,
                "audit": "audits/2026-09-04.md", "link_exceptions": [{
                    "url": "https://example.org", "reason": "Login",
                    "evidence": "https://example.org/help",
                    "checked_at": "2026-08-27", "expires_on": "2026-09-03"}]}
        self.assertTrue(check_metadata(data, "Last editorial review: 2026-09-04.", dt.date(2026, 9, 4)))


if __name__ == "__main__":
    unittest.main()
