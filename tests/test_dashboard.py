import json
import threading
import unittest
from http.server import HTTPServer
from urllib.error import HTTPError
from urllib.request import urlopen

from dashboard import Handler


class DashboardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = HTTPServer(("127.0.0.1", 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=3)

    def test_home(self):
        with urlopen(self.base + "/") as response:
            self.assertEqual(response.status, 200)
            self.assertIn("text/html", response.headers["Content-Type"])
            self.assertIn("Netizen Dev Dashboard", response.read().decode())

    def test_status(self):
        with urlopen(self.base + "/api/status") as response:
            self.assertEqual(response.status, 200)
            self.assertIn("application/json", response.headers["Content-Type"])
            data = json.load(response)
            self.assertEqual(data["status"], "Çalışıyor")
            self.assertTrue(data["python"])
            self.assertTrue(data["time"])

    def test_unknown_path(self):
        with self.assertRaises(HTTPError) as caught:
            urlopen(self.base + "/missing")
        self.assertEqual(caught.exception.code, 404)


if __name__ == "__main__":
    unittest.main()
