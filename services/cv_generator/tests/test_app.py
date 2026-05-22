import json
import unittest

from app import build_cv


class CvGeneratorRuntimeTest(unittest.TestCase):
    def test_builds_html_cv_artifact(self):
        result = build_cv(
            {
                "profile": {
                    "name": "Ada Lovelace",
                    "headline": "AI worker orchestration specialist",
                    "summary": "Builds careful automation systems.",
                    "experience": ["Designed agent workflows"],
                    "skills": ["Python", "Governance"],
                },
                "template": "modern",
                "locale": "en-US",
                "export_format": "html",
            }
        )

        self.assertEqual(result["service"], "cv-generator")
        self.assertEqual(result["status"], "generated")
        self.assertEqual(result["export_format"], "html")
        self.assertIn("Ada Lovelace", result["artifact"]["html"])
        self.assertIn("sha256", result["artifact"])

    def test_requires_profile_object(self):
        with self.assertRaisesRegex(ValueError, "profile"):
            build_cv({"export_format": "html"})

    def test_rejects_unknown_export_format(self):
        with self.assertRaisesRegex(ValueError, "export_format"):
            build_cv({"profile": {"name": "Ada"}, "export_format": "exe"})

    def test_result_is_json_serializable(self):
        result = build_cv({"profile": {"name": "Ada"}, "export_format": "json"})
        encoded = json.dumps(result)
        self.assertIn("cv-generator", encoded)


if __name__ == "__main__":
    unittest.main()
