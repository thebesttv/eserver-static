import sys
from bs4 import BeautifulSoup

def verify_google_tag(content, soup):
    gtag = '''<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-21YM95T3BQ"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-21YM95T3BQ');
</script>'''

    if not gtag in content:
        print('file does not have google tag')
        return False
    else:
        return True


def verify_relative_link(content, soup):
    for link in soup.find_all('a', attrs={}):
        # print(link)
        href = link.get('href')
        if href is None:
            continue
        if href.startswith('/'):
            print(f'link is absolute {link}')
            return False
    return True


def main(html_file):
    if not html_file.endswith('.html'):
        print(f'{html_file} does not end with .html, skiping')
        return True

    print(f'Verifying {html_file}')
    try:
        with open(html_file) as f:
            content = f.read()
            soup = BeautifulSoup(content, 'html.parser')
    except:
        print(f'Failed to open {html_file}')
        return False

    ok = True
    funs = [verify_google_tag, verify_relative_link]
    for f in funs:
        if not f(content, soup):
            ok = False
    return ok

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f'Usage: python {sys.argv[0]} HTML_FILE...')
        exit(1)
    for f in sys.argv[1:]:
        if not main(f):
            print(f'{f} fails check')
            exit(1)
