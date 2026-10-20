import importlib.machinery
import importlib.util
from pathlib import Path
import unittest
from unittest import mock

HERE = Path(__file__).resolve().parent
loader = importlib.machinery.SourceFileLoader('komarss', str(HERE.parent / 'contents/code/komarss'))
spec = importlib.util.spec_from_loader(loader.name, loader)
helper = importlib.util.module_from_spec(spec)
loader.exec_module(helper)


class FeedTests(unittest.TestCase):
    def test_rss(self):
        title, items = helper.parse_feed((HERE / 'rss.xml').read_bytes(), 'https://example.com/feed')
        self.assertEqual(title, 'Example News')
        old, new, enc = items
        self.assertEqual(old['title'], 'Older & plain')
        self.assertEqual(old['summary'], 'Hello world')
        self.assertEqual(old['image'], 'https://example.com/inline.jpg')
        self.assertEqual(new['image'], 'https://cdn.example.com/thumb.jpg')
        self.assertGreater(new['timestamp'], old['timestamp'])
        self.assertEqual(enc['link'], 'https://example.com/enc')
        self.assertEqual(enc['image'], 'https://cdn.example.com/pic.png')
        self.assertEqual(enc['timestamp'], 0)

    def test_atom(self):
        title, (entry,) = helper.parse_feed((HERE / 'atom.xml').read_bytes(), 'https://blog.example.org/atom')
        self.assertEqual(title, 'Atom Blog')
        self.assertEqual(entry['title'], 'Atom entry')
        self.assertEqual(entry['link'], 'https://blog.example.org/post')
        self.assertEqual(entry['image'], 'https://blog.example.org/hero.jpg')
        self.assertEqual(entry['summary'], 'Atom summary')

    def test_combine_sorts_dedupes_and_reports_errors(self):
        feeds = {'https://a/rss': (HERE / 'rss.xml').read_bytes(), 'https://b/atom': (HERE / 'atom.xml').read_bytes()}

        def fake_fetch(url):
            if url not in feeds:
                raise ValueError('boom')
            return feeds[url], url

        with mock.patch.object(helper, 'fetch', fake_fetch):
            result = helper.combine(['https://a/rss', 'https://b/atom', 'https://a/rss', 'https://bad'], 3)
        self.assertEqual([i['title'] for i in result['items']], ['Atom entry', 'Newer with media', 'Older & plain'])
        self.assertEqual(result['errors'], [{'url': 'https://bad', 'error': 'boom'}])

    def test_rejects_non_http(self):
        with self.assertRaises(ValueError):
            helper.fetch('file:///etc/passwd')

    def test_shorten(self):
        self.assertTrue(helper.shorten('word ' * 100).endswith('…'))
        self.assertLessEqual(len(helper.shorten('word ' * 100)), helper.SUMMARY_CHARS + 1)


if __name__ == '__main__':
    unittest.main()
